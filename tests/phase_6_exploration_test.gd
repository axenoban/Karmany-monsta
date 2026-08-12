extends Node


const BOARD_SCENE: PackedScene = preload(
	"res://scenes/board/board_3d_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 6 EXPLORATION TEST")
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
		push_error("FASE 6 ERROR: BoardState no esta disponible.")

	if player_state == null:
		test_passed = false
		push_error("FASE 6 ERROR: PlayerState no esta disponible.")

	if turn_manager == null:
		test_passed = false
		push_error("FASE 6 ERROR: TurnManager no esta disponible.")

	if trainer_unit == null:
		test_passed = false
		push_error("FASE 6 ERROR: TrainerUnit3D no esta disponible.")

	if not test_passed:
		_finish_test(false, board_scene)
		return

	var start_coord := Vector2i.ZERO
	var explore_target := Vector2i(0, -1)
	var second_hidden_target := Vector2i(-1, 0)
	var move_target := Vector2i(1, -1)

	# Fixture controlado: demuestra que Explorar ejecuta SOLO on_explore.
	var test_tile_data := KarmanyTileData.new()
	test_tile_data.tile_id = "TEST-EXP-01"
	test_tile_data.display_name = "Loseta de prueba de exploracion"
	test_tile_data.level = KarmanyTileData.TileLevel.N1
	test_tile_data.on_explore_text = "Obtén 2 MN al explorar."
	test_tile_data.entry_bonus_text = "Obtén 50 MN al entrar."

	var on_explore_effect := KarmanyEffectData.new()
	on_explore_effect.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	on_explore_effect.resource_type = KarmanyEffectData.ResourceType.MN
	on_explore_effect.amount = 2
	on_explore_effect.description = "Obtén 2 MN al explorar."

	var entry_effect := KarmanyEffectData.new()
	entry_effect.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	entry_effect.resource_type = KarmanyEffectData.ResourceType.MN
	entry_effect.amount = 50
	entry_effect.description = "No debe ejecutarse al Explorar."

	var explore_effects: Array[KarmanyEffectData] = [
		on_explore_effect
	]
	var entry_effects: Array[KarmanyEffectData] = [
		entry_effect
	]

	test_tile_data.on_explore_effects = explore_effects
	test_tile_data.entry_effects = entry_effects

	board_state.set_tile_data(
		explore_target,
		test_tile_data
	)
	board_state.set_tile_data(
		second_hidden_target,
		test_tile_data
	)

	var explore_tile := board_scene.call(
		"get_tile_view",
		explore_target
	) as KarmanyHexTile3D

	if explore_tile == null:
		test_passed = false
		push_error("FASE 6 ERROR: No existe la loseta de exploracion.")
	else:
		if explore_tile.tile_data != null:
			test_passed = false
			push_error("FASE 6 ERROR: La vista 3D filtro datos de una loseta oculta.")

	if board_state.is_revealed(explore_target):
		test_passed = false
		push_error("FASE 6 ERROR: El destino deberia comenzar oculto.")

	if turn_manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 6 ERROR: El turno deberia comenzar con 2 acciones.")

	if player_state.mn != 2:
		test_passed = false
		push_error("FASE 6 ERROR: MN inicial deberia ser 2.")

	var explorable_neighbors := KarmanyExplorationRules.get_explorable_neighbors(
		board_state,
		turn_manager,
		player_state
	)

	if not explorable_neighbors.has(explore_target):
		test_passed = false
		push_error("FASE 6 ERROR: El destino oculto adyacente no fue identificado como explorable.")

	# Explorar una loseta ya revelada debe rechazarse sin consumir accion.
	var revealed_target := Vector2i(1, 0)

	if bool(board_scene.call("try_explore_trainer_to", revealed_target)):
		test_passed = false
		push_error("FASE 6 ERROR: Se permitio Explorar una loseta ya revelada.")

	if turn_manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 6 ERROR: Exploracion ilegal consumio una accion.")

	# Primera accion: Explorar.
	if explore_tile != null:
		explore_tile.tile_clicked.emit(explore_tile)

		if not bool(board_scene.call("try_explore_selected_trainer")):
			test_passed = false
			push_error("FASE 6 ERROR: La exploracion legal fue rechazada.")

	if not board_state.is_revealed(explore_target):
		test_passed = false
		push_error("FASE 6 ERROR: La loseta no quedo revelada.")

	if player_state.current_coord != explore_target:
		test_passed = false
		push_error("FASE 6 ERROR: PlayerState no entro en la loseta explorada.")

	if board_state.get_occupying_unit_id(explore_target) != trainer_unit.unit_id:
		test_passed = false
		push_error("FASE 6 ERROR: BoardState no registro la unidad en la loseta explorada.")

	if board_state.is_occupied(start_coord):
		test_passed = false
		push_error("FASE 6 ERROR: El origen continuo ocupado tras explorar.")

	if player_state.mn != 4:
		test_passed = false
		push_error(
			"FASE 6 ERROR: on_explore debia llevar MN 2 -> 4 sin activar Entrada; MN=%s."
			% player_state.mn
		)

	if turn_manager.actions_remaining != 1:
		test_passed = false
		push_error("FASE 6 ERROR: Explorar deberia consumir exactamente 1 accion.")

	if turn_manager.get_action_usage(
		KarmanyExplorationRules.ACTION_ID_EXPLORE
	) != 1:
		test_passed = false
		push_error("FASE 6 ERROR: No se registro Explorar como usado este turno.")

	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador cambio tras su primera accion.")

	if explore_tile != null:
		if explore_tile.tile_data != test_tile_data:
			test_passed = false
			push_error("FASE 6 ERROR: La vista no recibio los datos al revelar la loseta.")

		if trainer_unit.global_position.distance_to(
			explore_tile.unit_anchor.global_position
		) > 0.001:
			test_passed = false
			push_error("FASE 6 ERROR: La unidad 3D no llego al UnitAnchor explorado.")

	# Una segunda exploracion en el mismo turno debe rechazarse.
	var second_hidden_tile := board_scene.call(
		"get_tile_view",
		second_hidden_target
	) as KarmanyHexTile3D

	if second_hidden_tile != null:
		second_hidden_tile.tile_clicked.emit(second_hidden_tile)

		if bool(board_scene.call("try_explore_selected_trainer")):
			test_passed = false
			push_error("FASE 6 ERROR: Se permitio Explorar dos veces en el mismo turno.")

	if turn_manager.actions_remaining != 1:
		test_passed = false
		push_error("FASE 6 ERROR: La segunda exploracion ilegal consumio una accion.")

	if board_state.is_revealed(second_hidden_target):
		test_passed = false
		push_error("FASE 6 ERROR: La segunda loseta se revelo ilegalmente.")

	# Segunda accion valida del mismo jugador: Mover a una revelada adyacente.
	if not bool(board_scene.call("try_move_trainer_to", move_target)):
		test_passed = false
		push_error("FASE 6 ERROR: La segunda accion Mover fue rechazada.")

	if player_state.current_coord != move_target:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador no termino en el destino de Mover.")

	if turn_manager.actions_remaining != 0:
		test_passed = false
		push_error("FASE 6 ERROR: Explorar + Mover deberian consumir las 2 acciones.")

	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador activo cambio antes de finalizar sus 2 acciones.")

	if not turn_manager.end_turn():
		test_passed = false
		push_error("FASE 6 ERROR: No se pudo finalizar el turno tras 2 acciones.")

	var next_player := turn_manager.get_active_player()

	if next_player == null or next_player.player_id != &"player_2":
		test_passed = false
		push_error("FASE 6 ERROR: El turno no avanzo a player_2.")

	if turn_manager.get_action_usage(
		KarmanyExplorationRules.ACTION_ID_EXPLORE
	) != 0:
		test_passed = false
		push_error("FASE 6 ERROR: El limite de Explorar no se reinicio para el nuevo turno.")

	print("")
	print("Explorada: ", explore_target)
	print("on_explore: MN 2 -> ", player_state.mn)
	print("Entrada durante Explorar: NO")
	print("Segunda exploracion del turno: RECHAZADA")
	print("Accion 2 del mismo jugador: Mover")
	print("Siguiente jugador: ", next_player.player_id if next_player != null else &"")
	print("")

	_finish_test(test_passed, board_scene)


func _finish_test(
	test_passed: bool,
	board_scene: Node
) -> void:
	print("================================")

	if test_passed:
		print("FASE 6 OK - Exploracion, revelado y on_explore validados.")
	else:
		push_error("FASE 6 ERROR - Revisar sistema de exploracion.")

	print("================================")
	board_scene.queue_free()
