class_name KarmanyPhase46ContextPresenter
extends Node


const INVALID_COORD: Vector2i = Vector2i(999, 999)

var controller: KarmanyPhase46AlphaHudController = null
var strip_label: Label = null
var details_button: Button = null
var details_dialog: AcceptDialog = null
var _refresh_accumulator: float = 0.0


func _ready() -> void:
	call_deferred("_attach")


func _process(delta: float) -> void:
	if controller == null or strip_label == null:
		return
	_refresh_accumulator += delta
	if _refresh_accumulator < 0.2:
		return
	_refresh_accumulator = 0.0
	_refresh_strip()


func _attach() -> void:
	controller = get_parent() as KarmanyPhase46AlphaHudController
	if controller == null or controller.hud_root == null or controller.phase_38 == null:
		push_error("FASE 46 ERROR: context presenter no encontro HUD/controller.")
		return

	var panel := PanelContainer.new()
	panel.name = "ContextStrip"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-255, 94)
	panel.size = Vector2(510, 58)
	controller.hud_root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	strip_label = Label.new()
	strip_label.name = "ContextSummary"
	strip_label.custom_minimum_size = Vector2(398, 0)
	strip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(strip_label)

	details_button = Button.new()
	details_button.text = "Contexto"
	details_button.tooltip_text = "Entrenador, reserva, loseta seleccionada, contenido revelado, requisitos, limites, Bestias, PvP y Aeterna."
	details_button.pressed.connect(_open_details)
	row.add_child(details_button)

	details_dialog = AcceptDialog.new()
	details_dialog.name = "ContextInspector"
	details_dialog.title = "Contexto de partida"
	details_dialog.min_size = Vector2i(620, 430)
	controller.hud_root.add_child(details_dialog)
	_refresh_strip()


func _refresh_strip() -> void:
	if controller == null or controller.phase_38 == null:
		return
	var session := controller.phase_38.full_session
	if session == null or session.runtime == null:
		return
	var runtime := session.runtime
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if human == null:
		return
	var trainer: KarmanyTrainerData = session.trainer_by_player.get(human.player_id, null) as KarmanyTrainerData
	var reserve_names := _get_reserve_names(human)
	var selected := _get_selected_coord()
	var selected_text := "Sin seleccion"
	if selected != INVALID_COORD and runtime.board_state.has_coord(selected):
		if runtime.board_state.is_revealed(selected):
			var tile := runtime.get_public_tile_data(selected)
			selected_text = tile.display_name if tile != null else "Revelada"
		else:
			selected_text = "OCULTA %s" % str(selected)
	strip_label.text = "Entrenador: %s · Reserva: %s\nSeleccion: %s" % [
		trainer.display_name if trainer != null else "?",
		"ninguna" if reserve_names.is_empty() else ", ".join(reserve_names),
		selected_text,
	]


func _open_details() -> void:
	if details_dialog == null:
		return
	details_dialog.dialog_text = _build_details_text()
	details_dialog.popup_centered()


func _build_details_text() -> String:
	if controller == null or controller.phase_38 == null:
		return "Contexto no disponible."
	var session := controller.phase_38.full_session
	if session == null or session.runtime == null:
		return "Sesion no disponible."
	var runtime := session.runtime
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if human == null:
		return "P1 no disponible."
	var lines := PackedStringArray()

	var trainer: KarmanyTrainerData = session.trainer_by_player.get(human.player_id, null) as KarmanyTrainerData
	lines.append("ENTRENADOR")
	if trainer == null:
		lines.append("No disponible.")
	else:
		lines.append("%s · %s" % [trainer.display_name, trainer.title])
		lines.append("Estilo: %s" % trainer.strategic_style)
		lines.append("Pasiva: %s" % trainer.passive_text)
		lines.append("Activa: %s" % trainer.active_text)
		lines.append("Setup: %s" % trainer.setup_bonus_text)

	lines.append("\nKARMANY DE RESERVA")
	var reserves := _get_reserve_states(human)
	if reserves.is_empty():
		lines.append("Ninguno.")
	else:
		for state in reserves:
			if state == null or state.karmany_data == null:
				continue
			var data := state.karmany_data
			lines.append("• %s · %s · Poder %d" % [data.display_name, data.get_rank_label(), data.power])

	lines.append("\nLOSETA SELECCIONADA / CONTENIDO REVELADO")
	var selected := _get_selected_coord()
	if selected == INVALID_COORD or not runtime.board_state.has_coord(selected):
		lines.append("No hay una loseta seleccionada.")
		return "\n".join(lines)
	lines.append("Coordenada: %s" % str(selected))
	if not runtime.board_state.is_revealed(selected):
		lines.append("OCULTA. Nivel estructural: %s. Su identidad y contenido no se revelan desde el HUD." % _level_label(runtime.get_public_level(selected)))
		return "\n".join(lines)

	var tile := runtime.get_public_tile_data(selected)
	if tile == null:
		lines.append("Revelada sin definicion publica disponible.")
		return "\n".join(lines)
	lines.append("%s · %s" % [tile.display_name, _level_label(tile.level)])
	if not tile.on_explore_text.strip_edges().is_empty():
		lines.append("Al Explorar: %s" % tile.on_explore_text)
	if not tile.entry_bonus_text.strip_edges().is_empty():
		lines.append("Entrada: %s" % tile.entry_bonus_text)
	if not tile.later_use_text.strip_edges().is_empty():
		lines.append("Interactuar / requisitos / costes: %s" % tile.later_use_text)
	if not tile.limit_text.strip_edges().is_empty():
		lines.append("Limites: %s" % tile.limit_text)

	var beast := runtime.board_state.get_beast(selected)
	lines.append("\nBESTIA")
	if beast == null or beast.beast_data == null:
		lines.append("No hay Bestia revelada en esta loseta.")
	else:
		var beast_data := beast.beast_data
		lines.append("%s · %s · Defensa base %d" % [
			beast_data.display_name,
			beast_data.get_tier_label(),
			beast_data.base_defense,
		])
		lines.append("Regla: %s" % beast_data.rules_text)
		lines.append("Victoria: %s" % beast_data.reward_text)
		lines.append("Derrota: %s" % beast_data.defeat_text)

	var other_players := PackedStringArray()
	for player in runtime.local_session.players:
		if player != null and player != human and player.current_coord == selected:
			other_players.append(String(player.player_id))
	lines.append("\nPVP")
	lines.append(
		"Entrenadores rivales en la loseta: %s" % (
			"ninguno" if other_players.is_empty() else ", ".join(other_players)
		)
	)
	lines.append("Disponibilidad de accion PvP actual: %s" % ("SI" if _pending_action_contains(KarmanyAiActionCandidate.ActionType.PVP) else "NO"))

	lines.append("\nAETERNA")
	if runtime.coordinator.aeterna_state.defeated:
		lines.append("Aeterna Draconis ya fue derrotada en esta partida.")
	else:
		lines.append("Aeterna no ha sido derrotada.")
	lines.append("Disponibilidad de accion Aeterna actual: %s" % ("SI" if _pending_action_contains(KarmanyAiActionCandidate.ActionType.AETERNA) else "NO"))
	return "\n".join(lines)


func _get_selected_coord() -> Vector2i:
	if controller == null or controller.phase_38 == null or controller.phase_38.phase_37 == null:
		return INVALID_COORD
	var phase_36 := controller.phase_38.phase_37.phase_36
	if phase_36 == null:
		return INVALID_COORD
	return phase_36.get_selected_coord()


func _get_reserve_states(player: KarmanyPlayerState) -> Array[KarmanyRuntimeState]:
	var result: Array[KarmanyRuntimeState] = []
	if player == null:
		return result
	var active := player.get_active_karmany()
	for state in player.get_linked_karmanys():
		if state != null and state != active:
			result.append(state)
	return result


func _get_reserve_names(player: KarmanyPlayerState) -> PackedStringArray:
	var result := PackedStringArray()
	for state in _get_reserve_states(player):
		if state != null and state.karmany_data != null:
			result.append(state.karmany_data.display_name)
	return result


func _pending_action_contains(action_type: int) -> bool:
	if controller == null or controller.phase_38 == null:
		return false
	var session := controller.phase_38.full_session
	if session == null:
		return false
	var request := session.get_pending_human_choice_request()
	if request == null:
		return false
	for row in request.get_options():
		if int(row.get("action_type", -1)) == action_type:
			return true
	return false


func _level_label(level: int) -> String:
	match level:
		KarmanyTileData.TileLevel.START:
			return "Inicio"
		KarmanyTileData.TileLevel.N1:
			return "N1"
		KarmanyTileData.TileLevel.N2:
			return "N2"
		KarmanyTileData.TileLevel.N3:
			return "N3"
		KarmanyTileData.TileLevel.SANCTUARY:
			return "Santuario"
	return "?"
