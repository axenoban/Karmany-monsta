extends Node


const GARRAVOL: KarmanyBeastData = preload("res://data/beasts/b_01_garravol.tres")


@onready var prototype: KarmanyPhase20BoardUXBridge = $Phase20BoardUXPrototype


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 20 BOARD UX TEST")
	print("================================")

	var ok: bool = true
	ok = _test_initial_highlights() and ok
	ok = _test_selection_and_invalid_feedback() and ok
	ok = _test_blocked_beast_feedback() and ok
	ok = _test_move_explore_refresh_and_turn_change() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 20 OK - Resaltados, seleccion, bloqueos, contexto y feedback validados.")
	else:
		push_error("FASE 20 ERROR - Revisar UX de tablero.")
	print("================================")


func _test_initial_highlights() -> bool:
	var ok: bool = true
	var move_coords: Array[Vector2i] = prototype.get_move_highlights()
	var explore_coords: Array[Vector2i] = prototype.get_explore_highlights()
	var blocked_coords: Array[Vector2i] = prototype.get_blocked_highlights()

	ok = _expect(move_coords.size() == 2, "El sandbox inicial debe resaltar 2 destinos de Mover.") and ok
	ok = _expect(explore_coords.size() == 3, "El sandbox inicial debe resaltar 3 destinos de Explorar.") and ok
	ok = _expect(blocked_coords.is_empty(), "No debe haber bloqueos iniciales.") and ok

	for coord in move_coords:
		var tile: KarmanyHexTile3D = prototype.board_prototype.get_tile_view(coord)
		ok = _expect(tile != null and tile.get_ux_hint() == KarmanyHexTile3D.UxHint.MOVE, "Destino Mover sin hint verde.") and ok

	for coord in explore_coords:
		var tile: KarmanyHexTile3D = prototype.board_prototype.get_tile_view(coord)
		ok = _expect(tile != null and tile.get_ux_hint() == KarmanyHexTile3D.UxHint.EXPLORE, "Destino Explorar sin hint azul.") and ok

	print("Resaltado inicial Mover=2 / Explorar=3: ", "OK" if ok else "ERROR")
	return ok


func _test_selection_and_invalid_feedback() -> bool:
	var ok: bool = true
	var hidden_coord := Vector2i(0, -1)
	var hidden_tile: KarmanyHexTile3D = prototype.board_prototype.get_tile_view(hidden_coord)
	ok = _expect(hidden_tile != null, "No existe loseta oculta de prueba.") and ok
	if hidden_tile == null:
		return false

	hidden_tile.tile_clicked.emit(hidden_tile)
	var context: String = _get_hud_context()
	ok = _expect(hidden_tile.is_selected(), "La loseta clicada debe permanecer seleccionada.") and ok
	ok = _expect(context.contains("Oculta"), "El HUD debe identificar una loseta oculta.") and ok
	ok = _expect(context.contains("Explorar: DISPONIBLE"), "El HUD debe indicar Explorar disponible.") and ok
	ok = _expect(not context.contains("Bosque de Raices"), "Una loseta oculta no debe revelar su contenido en el HUD.") and ok

	var actions_before: int = prototype.board_prototype.turn_manager.actions_remaining
	prototype.hud.move_button.pressed.emit()
	context = _get_hud_context()
	ok = _expect(prototype.board_prototype.turn_manager.actions_remaining == actions_before, "Mover invalido no debe gastar accion.") and ok
	ok = _expect(context.contains("Mover no disponible"), "El HUD debe mostrar feedback de Mover invalido.") and ok
	ok = _expect(context.contains("oculta"), "El feedback debe explicar que Mover no entra en loseta oculta.") and ok

	print("Seleccion + contexto oculto + feedback invalido: ", "OK" if ok else "ERROR")
	return ok


func _test_blocked_beast_feedback() -> bool:
	var ok: bool = true
	var blocked_coord := Vector2i(1, 0)
	var beast := KarmanyBeastRuntimeState.new()
	ok = _expect(
		beast.configure(GARRAVOL, &"phase20_garravol", blocked_coord),
		"No se pudo preparar Bestia de bloqueo."
	) and ok
	ok = _expect(
		prototype.board_prototype.board_state.set_beast(blocked_coord, beast),
		"No se pudo colocar Bestia en el tablero."
	) and ok

	prototype.refresh_board_ux()
	var blocked_coords: Array[Vector2i] = prototype.get_blocked_highlights()
	var blocked_tile: KarmanyHexTile3D = prototype.board_prototype.get_tile_view(blocked_coord)
	ok = _expect(blocked_coords.has(blocked_coord), "La loseta con Bestia debe figurar bloqueada.") and ok
	ok = _expect(blocked_tile != null and blocked_tile.get_ux_hint() == KarmanyHexTile3D.UxHint.BLOCKED, "La loseta con Bestia debe usar hint bloqueado.") and ok

	if blocked_tile != null:
		blocked_tile.tile_clicked.emit(blocked_tile)
		var context: String = _get_hud_context()
		ok = _expect(context.contains("BLOQUEADA"), "El HUD debe mostrar estado BLOQUEADA.") and ok
		ok = _expect(context.contains("Garravol"), "El HUD debe identificar la Bestia visible que bloquea.") and ok

		var actions_before: int = prototype.board_prototype.turn_manager.actions_remaining
		prototype.hud.move_button.pressed.emit()
		context = _get_hud_context()
		ok = _expect(prototype.board_prototype.turn_manager.actions_remaining == actions_before, "Bestia bloqueando no debe consumir Mover.") and ok
		ok = _expect(context.contains("bloqueada por una Bestia"), "El feedback debe explicar el bloqueo por Bestia.") and ok

	prototype.board_prototype.board_state.clear_beast(blocked_coord)
	prototype.refresh_board_ux()
	ok = _expect(prototype.get_blocked_highlights().is_empty(), "Al retirar la Bestia debe desaparecer el bloqueo visual.") and ok

	print("Estado bloqueado + motivo exacto de Bestia: ", "OK" if ok else "ERROR")
	return ok


func _test_move_explore_refresh_and_turn_change() -> bool:
	var ok: bool = true
	var move_coord := Vector2i(1, 0)
	var move_tile: KarmanyHexTile3D = prototype.board_prototype.get_tile_view(move_coord)
	ok = _expect(move_tile != null, "No existe destino revelado para Mover.") and ok
	if move_tile == null:
		return false

	move_tile.tile_clicked.emit(move_tile)
	prototype.hud.move_button.pressed.emit()
	ok = _expect(prototype.board_prototype.player_state.current_coord == move_coord, "Mover desde HUD debe desplazar al Entrenador.") and ok
	ok = _expect(prototype.board_prototype.turn_manager.actions_remaining == 1, "Mover debe dejar 1 accion.") and ok

	var explore_coords: Array[Vector2i] = prototype.get_explore_highlights()
	ok = _expect(not explore_coords.is_empty(), "Tras Mover debe recalcular destinos de Explorar.") and ok
	if explore_coords.is_empty():
		return false

	var explore_coord: Vector2i = explore_coords[0]
	var explore_tile: KarmanyHexTile3D = prototype.board_prototype.get_tile_view(explore_coord)
	ok = _expect(explore_tile != null, "No existe destino recalculado de Explorar.") and ok
	if explore_tile == null:
		return false

	explore_tile.tile_clicked.emit(explore_tile)
	prototype.hud.explore_button.pressed.emit()
	ok = _expect(prototype.board_prototype.player_state.current_coord == explore_coord, "Explorar desde HUD debe desplazar al Entrenador.") and ok
	ok = _expect(prototype.board_prototype.board_state.is_revealed(explore_coord), "Explorar debe revelar la loseta.") and ok
	ok = _expect(prototype.board_prototype.turn_manager.actions_remaining == 0, "Mover+Explorar debe consumir las 2 acciones.") and ok
	ok = _expect(prototype.hud.get_action_button_enabled(KarmanyGameHUD.ACTION_END_TURN), "Finalizar turno debe habilitarse con 0 acciones.") and ok

	prototype.hud.end_turn_button.pressed.emit()
	ok = _expect(prototype.board_prototype.turn_manager.get_active_player() == prototype.board_prototype.prototype_second_player_state, "Debe pasar el turno a player_2.") and ok
	ok = _expect(prototype.get_move_highlights().is_empty(), "Sin unidad visual de player_2 no deben inventarse resaltados de Mover.") and ok
	ok = _expect(prototype.get_explore_highlights().is_empty(), "Sin unidad visual de player_2 no deben inventarse resaltados de Explorar.") and ok

	print("Refresh tras Mover/Explorar + cambio de turno: ", "OK" if ok else "ERROR")
	return ok


func _get_hud_context() -> String:
	var snapshot: Dictionary = prototype.hud.get_snapshot()
	return String(snapshot.get("action_context", ""))


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 20 ERROR: %s" % message)
	return false
