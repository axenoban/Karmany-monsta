class_name KarmanyPhase46PresentationSafeController
extends KarmanyPhase46AlphaHudController


var _secondary_layout_adjusted: bool = false


func _build_hud() -> void:
	super._build_hud()
	if hud_root == null:
		return

	# El HUD raiz solo organiza la capa F46. Las zonas transparentes deben dejar
	# pasar la interaccion al tablero 3D desde el primer frame, no depender de
	# que un presenter diferido lo corrija despues.
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# A 1152x648 el ChoicePanel comienza alrededor de y=464. El panel derecho
	# debe terminar antes de esa franja; su ScrollContainer conserva todo el
	# contenido sin solaparlo con las decisiones humanas.
	var objective_panel := hud_root.find_child("ObjectivePanel", true, false) as PanelContainer
	if objective_panel != null:
		objective_panel.size.y = 390.0


func _process(delta: float) -> void:
	super._process(delta)
	_apply_secondary_layout_once()


func _refresh(force: bool) -> void:
	# La implementacion base sigue siendo responsable de snapshot, ChoiceRouter
	# y actualizacion. Esta capa solo aplica la compuerta visual ya existente en
	# F35/F36 antes de que el frame pueda presentarse al jugador.
	super._refresh(force)
	if hud_root == null or not hud_root.visible:
		return
	if phase_38 == null or phase_38.full_session == null:
		return
	var session := phase_38.full_session
	if session.runtime == null:
		return
	var human := session.runtime.local_session.get_player_by_id(session.runtime.human_player_id)
	if human == null or _is_coord_publicly_revealed(human.current_coord):
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


func _apply_secondary_layout_once() -> void:
	if _secondary_layout_adjusted or hud_root == null:
		return
	var feedback := hud_root.find_child("FeedbackBanner", true, false) as PanelContainer
	var context_strip := hud_root.find_child("ContextStrip", true, false) as PanelContainer
	if feedback == null or context_strip == null:
		return

	# La columna central util a 1152px queda entre PlayerPanel (x<=312) y
	# ObjectivePanel (x>=800). Mantener ambos avisos dentro de esa columna evita
	# solapamientos sin reducir el area del tablero mas de lo necesario.
	feedback.position = Vector2(-256.0, 56.0)
	feedback.size = Vector2(470.0, 34.0)
	context_strip.position = Vector2(-260.0, 94.0)
	context_strip.size = Vector2(470.0, 58.0)
	var context_summary := hud_root.find_child("ContextSummary", true, false) as Label
	if context_summary != null:
		context_summary.custom_minimum_size = Vector2(350.0, 0.0)
	_secondary_layout_adjusted = true
