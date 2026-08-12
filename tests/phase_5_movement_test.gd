extends Node


const BOARD_SCENE: PackedScene = preload(
	"res://scenes/board/board_3d_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 5 MOVEMENT TEST")
	print("================================")

	var test_passed: bool = true
	var board_scene := BOARD_SCENE.instantiate()
	add_child(board_scene)

	await get_tree().process_frame

	var board_state := board_scene.get("board_state") as KarmanyBoardState
	var player_state := board_scene.get("player_state") as KarmanyPlayerState
	var turn_manager := board_scene.get("turn_manager") as KarmanyTurnManager
	var trainer_unit := board_scene.get("trainer_unit") as KarmanyTrainerUnit3D

	if board_state == null:
		test_passed = false
		push_error("FASE 5 ERROR: BoardState no esta disponible.")

	if player_state == null:
		test_passed = false
		push_error("FASE 5 ERROR: PlayerState no esta disponible.")

	if turn_manager == null:
		test_passed = false
		push_error("FASE 5 ERROR: TurnManager no esta disponible.")

	if trainer_unit == null:
		test_passed = false
		push_error("FASE 5 ERROR: TrainerUnit3D no esta disponible.")

	if not test_passed:
		_finish_test(false, board_scene)
		return

	var start_coord := Vector2i.ZERO
	var target_a := Vector2i(1, 0)
	var target_b := Vector2i(1, -1)
	var hidden_target := Vector2i(0, -1)

	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 5 ERROR: player_1 deberia ser el jugador activo.")

	if turn_manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 5 ERROR: El turno deberia comenzar con 2 acciones.")

	# Mover no puede entrar en una loseta oculta y no debe consumir accion.
	var hidden_tile := board_scene.call("get_tile_view", hidden_target) as KarmanyHexTile3D

	if hidden_tile == null:
		test_passed = false
		push_error("FASE 5 ERROR: No se encontro la loseta oculta de prueba.")
	else:
		hidden_tile.tile_clicked.emit(hidden_tile)

		if bool(board_scene.call("try_move_selected_trainer")):
			test_passed = false
			push_error("FASE 5 ERROR: Mover entro ilegalmente en una loseta oculta.")

	if player_state.current_coord != start_coord:
		test_passed = false
		push_error("FASE 5 ERROR: Un movimiento invalido modifico la posicion.")

	if turn_manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 5 ERROR: Un movimiento invalido consumio una accion.")

	# Primera accion: centro -> destino A revelado y adyacente.
	var target_tile_a := board_scene.call("get_tile_view", target_a) as KarmanyHexTile3D

	if target_tile_a == null:
		test_passed = false
		push_error("FASE 5 ERROR: No se encontro el destino A.")
	else:
		target_tile_a.tile_clicked.emit(target_tile_a)

		if not bool(board_scene.call("try_move_selected_trainer")):
			test_passed = false
			push_error("FASE 5 ERROR: El primer Mover legal fue rechazado.")

	if player_state.current_coord != target_a:
		test_passed = false
		push_error("FASE 5 ERROR: PlayerState no llego al destino A.")

	if board_state.get_occupying_unit_id(target_a) != trainer_unit.unit_id:
		test_passed = false
		push_error("FASE 5 ERROR: BoardState no registro al Entrenador en destino A.")

	if board_state.is_occupied(start_coord):
		test_passed = false
		push_error("FASE 5 ERROR: La loseta inicial quedo ocupada despues de Mover.")

	if turn_manager.actions_remaining != 1:
		test_passed = false
		push_error("FASE 5 ERROR: El primer Mover deberia dejar 1 accion.")

	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 5 ERROR: El jugador cambio despues de solo 1 accion.")

	if target_tile_a != null and trainer_unit.global_position.distance_to(
		target_tile_a.unit_anchor.global_position
	) > 0.001:
		test_passed = false
		push_error("FASE 5 ERROR: La unidad 3D no llego al UnitAnchor de destino A.")

	# Un destino existente y revelado pero no adyacente debe rechazarse.
	var non_adjacent := Vector2i(-1, 0)
	board_state.set_revealed(non_adjacent, true)

	var non_adjacent_validation := KarmanyMovementRules.validate_move(
		board_state,
		turn_manager,
		player_state,
		non_adjacent
	)

	if non_adjacent_validation != KarmanyMovementRules.MoveValidation.NOT_ADJACENT:
		test_passed = false
		push_error(
			"FASE 5 ERROR: Se esperaba NOT_ADJACENT y se obtuvo %s."
			% non_adjacent_validation
		)

	# Segunda accion: destino A -> destino B. Ambos son adyacentes y revelados.
	var target_tile_b := board_scene.call("get_tile_view", target_b) as KarmanyHexTile3D

	if target_tile_b == null:
		test_passed = false
		push_error("FASE 5 ERROR: No se encontro el destino B.")
	else:
		target_tile_b.tile_clicked.emit(target_tile_b)

		if not bool(board_scene.call("try_move_selected_trainer")):
			test_passed = false
			push_error("FASE 5 ERROR: El segundo Mover legal fue rechazado.")

	if player_state.current_coord != target_b:
		test_passed = false
		push_error("FASE 5 ERROR: PlayerState no llego al destino B.")

	if turn_manager.actions_remaining != 0:
		test_passed = false
		push_error("FASE 5 ERROR: Dos movimientos deberian consumir las 2 acciones.")

	# Aclaracion del flujo: el jugador no cambia entre Accion 1 y Accion 2.
	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 5 ERROR: El jugador activo cambio antes del fin de turno.")

	# Con 0 acciones no puede ejecutar un tercer Mover.
	var center_tile := board_scene.call("get_tile_view", start_coord) as KarmanyHexTile3D

	if center_tile != null:
		center_tile.tile_clicked.emit(center_tile)

		if bool(board_scene.call("try_move_selected_trainer")):
			test_passed = false
			push_error("FASE 5 ERROR: Se permitio un tercer movimiento sin acciones.")

	if player_state.current_coord != target_b:
		test_passed = false
		push_error("FASE 5 ERROR: El tercer intento altero la posicion.")

	# Solo tras consumir las dos acciones se permite cerrar el turno y pasar a player_2.
	if not turn_manager.end_turn():
		test_passed = false
		push_error("FASE 5 ERROR: No se pudo cerrar el turno tras consumir 2 acciones.")

	var next_player := turn_manager.get_active_player()

	if next_player == null or next_player.player_id != &"player_2":
		test_passed = false
		push_error("FASE 5 ERROR: El turno no avanzo a player_2.")

	print("")
	print("Inicio: ", start_coord)
	print("Accion 1 Mover: ", target_a)
	print("Accion 2 Mover: ", target_b)
	print("Acciones restantes antes de fin de turno: 0")
	print("Siguiente jugador tras cerrar turno: ", next_player.player_id if next_player != null else &"")
	print("Movimiento logico + 3D: OK")
	print("")

	_finish_test(test_passed, board_scene)


func _finish_test(
	test_passed: bool,
	board_scene: Node
) -> void:
	print("================================")

	if test_passed:
		print("FASE 5 OK - Movimiento legal, coste de accion y turno validados.")
	else:
		push_error("FASE 5 ERROR - Revisar sistema de movimiento.")

	print("================================")
	board_scene.queue_free()
