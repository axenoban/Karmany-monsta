class_name KarmanyPhase46PresentationSafeController
extends KarmanyPhase46AlphaHudController


var _last_public_reveal_state: int = -1


func _build_hud() -> void:
	super._build_hud()
	if hud_root == null:
		return

	# El HUD raiz solo organiza la capa F46. Las zonas transparentes deben dejar
	# pasar la interaccion al tablero 3D desde el primer frame, no depender de
	# que un presenter diferido lo corrija despues.
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	super._process(delta)
	_apply_hud_layout()


func _refresh(force: bool) -> void:
	# Detectar la transicion visual antes del refresh base es importante: el
	# snapshot logico puede no cambiar cuando F35 termina una animacion. Sin
	# este force de transicion, el HUD podria quedarse mostrando "Zona oculta"
	# hasta la siguiente mutacion de gameplay.
	var reveal_state: int = -1
	if phase_38 != null and phase_38.full_session != null:
		var session := phase_38.full_session
		if session.runtime != null:
			var human := session.runtime.local_session.get_player_by_id(session.runtime.human_player_id)
			if human != null:
				reveal_state = 1 if _is_coord_publicly_revealed(human.current_coord) else 0
	var effective_force: bool = force
	if reveal_state >= 0 and reveal_state != _last_public_reveal_state:
		effective_force = true
		_last_public_reveal_state = reveal_state

	# La implementacion base sigue siendo responsable de snapshot, ChoiceRouter
	# y actualizacion. Esta capa solo aplica la compuerta visual ya existente en
	# F35/F36 antes de que el frame pueda presentarse al jugador.
	super._refresh(effective_force)
	if hud_root == null or not hud_root.visible:
		return
	if reveal_state != 0:
		return

	# Durante la ventana en que gameplay ya revelo logicamente una loseta pero
	# F35 aun no termino su presentacion, ninguna decision dependiente de ese
	# contenido puede aparecer en el HUD.
	_choice_data.clear()
	_selected_option_ids.clear()
	_replacement_equipment_id = &""
	_last_choice_signature = ""
	_clear_children(choice_options)
	_clear_children(replacement_options)
	choice_prompt.text = "Revelando loseta... espera a que termine la presentacion."
	confirm_button.disabled = true
	confirm_button.text = "CONFIRMAR DECISION"


func _render_snapshot(snapshot: Dictionary) -> void:
	var safe_snapshot: Dictionary = snapshot.duplicate(true)
	var coord: Vector2i = safe_snapshot.get("position", Vector2i.ZERO)
	if not _is_coord_publicly_revealed(coord):
		var original_zone: Dictionary = safe_snapshot.get("zone", {})
		safe_snapshot["zone"] = {
			"display_name": "Zona oculta",
			"level": String(original_zone.get("level", "?")),
			"coord": coord,
		}
		safe_snapshot["visible_effects"] = PackedStringArray()
		safe_snapshot["recent_events"] = PackedStringArray([
			"Revelacion visual en curso: identidad y efectos temporalmente ocultos."
		])
	super._render_snapshot(safe_snapshot)
	_append_public_scoreboard(safe_snapshot)


func _append_public_scoreboard(snapshot: Dictionary) -> void:
	if objective_label == null:
		return
	var rows: Array = snapshot.get("participants", [])
	if rows.is_empty():
		return
	var score_parts := PackedStringArray()
	for row_value in rows:
		if not (row_value is Dictionary):
			continue
		var row: Dictionary = row_value
		var player_id := String(row.get("player_id", "?"))
		var pl: int = int(row.get("pl", 0))
		score_parts.append("%s %d PL" % [player_id, pl])
	if score_parts.is_empty():
		return
	objective_label.text += "\n\n[b]Marcador publico[/b]\n%s" % " · ".join(score_parts)


func _update_choice_controls() -> void:
	super._update_choice_controls()
	_apply_choice_selection_feedback()


func _apply_choice_selection_feedback() -> void:
	if choice_options == null or _choice_data.is_empty():
		return
	var buttons := choice_options.get_children()
	var button_index: int = 0
	var repeated: bool = bool(_choice_data.get("allow_repeated_options", false))
	for row_value in _choice_data.get("options", []):
		if not (row_value is Dictionary):
			continue
		var row: Dictionary = row_value
		var option_id := StringName(row.get("option_id", ""))
		if option_id == &"":
			continue
		if button_index >= buttons.size():
			break
		var button := buttons[button_index] as Button
		button_index += 1
		if button == null:
			continue
		var base_label := String(row.get("label", String(option_id)))
		var selected_count: int = _selected_option_ids.count(option_id)
		if repeated:
			button.text = "[%d] %s" % [selected_count, base_label]
		else:
			button.text = "%s %s" % ["✓" if selected_count > 0 else "○", base_label]

	if replacement_options == null:
		return
	var replacement_ids: Array = _choice_data.get("replacement_equipment_ids", [])
	if replacement_ids.is_empty():
		return
	var replacement_buttons := replacement_options.get_children()
	for index in range(replacement_ids.size()):
		var child_index: int = index + 1
		if child_index >= replacement_buttons.size():
			break
		var button := replacement_buttons[child_index] as Button
		if button == null:
			continue
		var equipment_id := StringName(replacement_ids[index])
		button.text = "%s %s" % ["✓" if equipment_id == _replacement_equipment_id else "○", String(equipment_id)]


func _on_inspect_tile() -> void:
	if phase_38 == null or phase_38.full_session == null:
		return
	var session := phase_38.full_session
	if session.runtime == null:
		return
	var human := session.runtime.local_session.get_player_by_id(session.runtime.human_player_id)
	if human == null:
		return
	if not _is_coord_publicly_revealed(human.current_coord):
		_show_inspector({
			"title": "Zona oculta",
			"subtitle": str(human.current_coord),
			"body": "La identidad, reglas y efectos apareceran cuando finalice la revelacion visual.",
		})
		return
	super._on_inspect_tile()


func _get_phase_36() -> KarmanyPhase36MatchUxBridge:
	if phase_38 == null or phase_38.phase_37 == null:
		return null
	return phase_38.phase_37.phase_36


func _is_coord_publicly_revealed(coord: Vector2i) -> bool:
	if phase_38 == null or phase_38.full_session == null:
		return false
	var session := phase_38.full_session
	if session.runtime == null or not session.runtime.board_state.has_coord(coord):
		return false
	if not session.runtime.board_state.is_revealed(coord):
		return false
	var phase_36 := _get_phase_36()
	if phase_36 == null:
		return false
	# F36 ya compone la vista publica usando la compuerta visual F35. Reusar
	# esa fuente evita crear una segunda semantica de revelacion.
	return not phase_36.get_location_summary(coord).contains("OCULTA")


func _apply_hud_layout() -> void:
	if hud_root == null:
		return
	var player := hud_root.find_child("PlayerPanel", true, false) as Control
	var objective := hud_root.find_child("ObjectivePanel", true, false) as Control
	var choice := hud_root.find_child("ChoicePanel", true, false) as Control
	var feedback := hud_root.find_child("FeedbackBanner", true, false) as PanelContainer
	var context_strip := hud_root.find_child("ContextStrip", true, false) as PanelContainer
	if feedback == null or context_strip == null:
		return

	# Geometria en coordenadas del padre: position no es un offset del anchor.
	# Reservar primero las decisiones; los laterales conservan scroll legible.
	var extent := hud_root.size
	var margin := 12.0
	var gap := 8.0
	var choice_height := maxf(172.0, choice.get_combined_minimum_size().y)
	var choice_width := minf(860.0, extent.x - margin * 2.0)
	_place_panel(choice, Rect2((extent.x - choice_width) / 2.0,
		extent.y - margin - choice_height, choice_width, choice_height))
	var side_top := 66.0
	var side_height := maxf(0.0, minf(395.0, choice.position.y - gap - side_top))
	_place_panel(player, Rect2(margin, side_top, 300.0, side_height))
	_place_panel(objective, Rect2(extent.x - margin - 340.0, side_top, 340.0, side_height))
	var center_left := player.position.x + player.size.x + gap
	var center_width := objective.position.x - gap - center_left
	var context_summary := hud_root.find_child("ContextSummary", true, false) as Label
	if context_summary != null:
		context_summary.custom_minimum_size = Vector2.ZERO
		context_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var feedback_label := feedback.get_child(0) as Label
	if feedback_label != null:
		feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_panel(feedback, Rect2(center_left, side_top, center_width,
		maxf(34.0, feedback.get_combined_minimum_size().y)))
	_place_panel(context_strip, Rect2(center_left,
		feedback.position.y + feedback.size.y + gap, center_width,
		maxf(58.0, context_strip.get_combined_minimum_size().y)))


func _place_panel(panel: Control, rect: Rect2) -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = rect.position
	panel.size = rect.size
