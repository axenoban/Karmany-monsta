extends Node


const BOARD_SCENE: PackedScene = preload(
	"res://scenes/board/board_3d_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 6 ACTION MATRIX TEST")
	print("================================")

	var test_passed: bool = true

	if not await _test_move_move():
		test_passed = false

	if not await _test_explore_explore():
		test_passed = false

	if not await _test_explore_move():
		test_passed = false

	if not await _test_move_explore():
		test_passed = false

	print("")
	print("================================")

	if test_passed:
		print("FASE 6 MATRIZ OK - Mover y Explorar desplazan y resuelven efectos distintos.")
	else:
		push_error("FASE 6 MATRIZ ERROR - Revisar combinaciones de acciones.")

	print("================================")


func _test_move_move() -> bool:
	var board_scene := _spawn_board()
	await get_tree().process_frame

	var board_state := board_scene.get("board_state") as KarmanyBoardState
	var player_state := board_scene.get("player_state") as KarmanyPlayerState
	var turn_manager := board_scene.get("turn_manager") as KarmanyTurnManager
	var trainer_unit := board_scene.get("trainer_unit") as KarmanyTrainerUnit3D

	if not _core_is_valid(board_state, player_state, turn_manager, trainer_unit, "Mover + Mover"):
		board_scene.queue_free()
		await get_tree().process_frame
		return false

	var target_a := Vector2i(1, 0)
	var target_b := Vector2i(1, -1)

	_configure_cell(
		board_scene,
		board_state,
		target_a,
		_make_test_tile("MM-A", 100, 1),
		true
	)
	_configure_cell(
		board_scene,
		board_state,
		target_b,
		_make_test_tile("MM-B", 100, 2),
		true
	)

	var ok := true

	if not bool(board_scene.call("try_move_trainer_to", target_a)):
		ok = _fail("Mover + Mover: la primera accion Mover fue rechazada.")

	if player_state.current_coord != target_a:
		ok = _fail("Mover + Mover: el jugador no llego al primer destino.")

	if player_state.mn != 3:
		ok = _fail("Mover + Mover: la primera Entrada debia llevar MN 2 -> 3; MN=%s." % player_state.mn)

	if turn_manager.actions_remaining != 1:
		ok = _fail("Mover + Mover: despues de la primera accion debe quedar 1 accion.")

	if turn_manager.get_active_player() != player_state:
		ok = _fail("Mover + Mover: el jugador activo cambio despues de la primera accion.")

	if not bool(board_scene.call("try_move_trainer_to", target_b)):
		ok = _fail("Mover + Mover: la segunda accion Mover fue rechazada.")

	if player_state.current_coord != target_b:
		ok = _fail("Mover + Mover: el jugador no llego al segundo destino.")

	if player_state.mn != 5:
		ok = _fail("Mover + Mover: las Entradas +1 y +2 debian dejar MN=5; MN=%s." % player_state.mn)

	if turn_manager.actions_remaining != 0:
		ok = _fail("Mover + Mover: dos movimientos deben consumir las 2 acciones.")

	if turn_manager.get_action_usage(KarmanyMovementRules.ACTION_ID_MOVE) != 2:
		ok = _fail("Mover + Mover: el TurnManager no registro 2 acciones Mover.")

	if turn_manager.get_action_usage(KarmanyExplorationRules.ACTION_ID_EXPLORE) != 0:
		ok = _fail("Mover + Mover: se registro Explorar sin haber explorado.")

	var target_tile := board_scene.call("get_tile_view", target_b) as KarmanyHexTile3D
	if target_tile != null and trainer_unit.global_position.distance_to(target_tile.unit_anchor.global_position) > 0.001:
		ok = _fail("Mover + Mover: la unidad 3D no termino en el UnitAnchor correcto.")

	print("Mover + Mover: ", "OK" if ok else "ERROR")
	print("  MN: 2 -> ", player_state.mn, " | acciones restantes: ", turn_manager.actions_remaining)

	board_scene.queue_free()
	await get_tree().process_frame
	return ok


func _test_explore_explore() -> bool:
	var board_scene := _spawn_board()
	await get_tree().process_frame

	var board_state := board_scene.get("board_state") as KarmanyBoardState
	var player_state := board_scene.get("player_state") as KarmanyPlayerState
	var turn_manager := board_scene.get("turn_manager") as KarmanyTurnManager
	var trainer_unit := board_scene.get("trainer_unit") as KarmanyTrainerUnit3D

	if not _core_is_valid(board_state, player_state, turn_manager, trainer_unit, "Explorar + Explorar"):
		board_scene.queue_free()
		await get_tree().process_frame
		return false

	var target_a := Vector2i(0, -1)
	var target_b := Vector2i(-1, 0)

	_configure_cell(
		board_scene,
		board_state,
		target_a,
		_make_test_tile("EE-A", 2, 100),
		false
	)
	_configure_cell(
		board_scene,
		board_state,
		target_b,
		_make_test_tile("EE-B", 3, 100),
		false
	)

	var ok := true

	if not bool(board_scene.call("try_explore_trainer_to", target_a)):
		ok = _fail("Explorar + Explorar: la primera exploracion fue rechazada.")

	if player_state.current_coord != target_a:
		ok = _fail("Explorar + Explorar: el jugador no entro en la primera loseta.")

	if not board_state.is_revealed(target_a):
		ok = _fail("Explorar + Explorar: la primera loseta no quedo revelada.")

	if player_state.mn != 4:
		ok = _fail("Explorar + Explorar: on_explore +2 debia llevar MN 2 -> 4; MN=%s." % player_state.mn)

	if turn_manager.actions_remaining != 1:
		ok = _fail("Explorar + Explorar: despues de la primera exploracion debe quedar 1 accion.")

	if turn_manager.get_active_player() != player_state:
		ok = _fail("Explorar + Explorar: el jugador activo cambio tras la primera accion.")

	if not bool(board_scene.call("try_explore_trainer_to", target_b)):
		ok = _fail("Explorar + Explorar: la segunda exploracion legal fue rechazada.")

	if player_state.current_coord != target_b:
		ok = _fail("Explorar + Explorar: el jugador no entro en la segunda loseta.")

	if not board_state.is_revealed(target_b):
		ok = _fail("Explorar + Explorar: la segunda loseta no quedo revelada.")

	if player_state.mn != 7:
		ok = _fail("Explorar + Explorar: on_explore +2 y +3 debian dejar MN=7 sin Entrada; MN=%s." % player_state.mn)

	if turn_manager.actions_remaining != 0:
		ok = _fail("Explorar + Explorar: dos exploraciones deben consumir las 2 acciones.")

	if turn_manager.get_action_usage(KarmanyExplorationRules.ACTION_ID_EXPLORE) != 2:
		ok = _fail("Explorar + Explorar: el TurnManager no registro 2 acciones Explorar.")

	if turn_manager.get_action_usage(KarmanyMovementRules.ACTION_ID_MOVE) != 0:
		ok = _fail("Explorar + Explorar: se registro Mover sin haberlo usado.")

	print("Explorar + Explorar: ", "OK" if ok else "ERROR")
	print("  MN: 2 -> ", player_state.mn, " | acciones restantes: ", turn_manager.actions_remaining)

	board_scene.queue_free()
	await get_tree().process_frame
	return ok


func _test_explore_move() -> bool:
	var board_scene := _spawn_board()
	await get_tree().process_frame

	var board_state := board_scene.get("board_state") as KarmanyBoardState
	var player_state := board_scene.get("player_state") as KarmanyPlayerState
	var turn_manager := board_scene.get("turn_manager") as KarmanyTurnManager
	var trainer_unit := board_scene.get("trainer_unit") as KarmanyTrainerUnit3D

	if not _core_is_valid(board_state, player_state, turn_manager, trainer_unit, "Explorar + Mover"):
		board_scene.queue_free()
		await get_tree().process_frame
		return false

	var explore_target := Vector2i(0, -1)
	var move_target := Vector2i(1, -1)

	_configure_cell(
		board_scene,
		board_state,
		explore_target,
		_make_test_tile("EM-E", 2, 100),
		false
	)
	_configure_cell(
		board_scene,
		board_state,
		move_target,
		_make_test_tile("EM-M", 100, 1),
		true
	)

	var ok := true

	if not bool(board_scene.call("try_explore_trainer_to", explore_target)):
		ok = _fail("Explorar + Mover: Explorar fue rechazado.")

	if player_state.mn != 4:
		ok = _fail("Explorar + Mover: Explorar debia aplicar solo on_explore +2.")

	if not bool(board_scene.call("try_move_trainer_to", move_target)):
		ok = _fail("Explorar + Mover: Mover fue rechazado.")

	if player_state.current_coord != move_target:
		ok = _fail("Explorar + Mover: el jugador no termino en la loseta movida.")

	if player_state.mn != 5:
		ok = _fail("Explorar + Mover: resultado esperado MN=5 (+2 explorar, +1 entrada); MN=%s." % player_state.mn)

	if turn_manager.actions_remaining != 0:
		ok = _fail("Explorar + Mover: las dos acciones no agotaron el turno.")

	if turn_manager.get_action_usage(KarmanyExplorationRules.ACTION_ID_EXPLORE) != 1:
		ok = _fail("Explorar + Mover: se esperaba 1 Explorar.")

	if turn_manager.get_action_usage(KarmanyMovementRules.ACTION_ID_MOVE) != 1:
		ok = _fail("Explorar + Mover: se esperaba 1 Mover.")

	print("Explorar + Mover: ", "OK" if ok else "ERROR")
	print("  MN: 2 -> ", player_state.mn, " | acciones restantes: ", turn_manager.actions_remaining)

	board_scene.queue_free()
	await get_tree().process_frame
	return ok


func _test_move_explore() -> bool:
	var board_scene := _spawn_board()
	await get_tree().process_frame

	var board_state := board_scene.get("board_state") as KarmanyBoardState
	var player_state := board_scene.get("player_state") as KarmanyPlayerState
	var turn_manager := board_scene.get("turn_manager") as KarmanyTurnManager
	var trainer_unit := board_scene.get("trainer_unit") as KarmanyTrainerUnit3D

	if not _core_is_valid(board_state, player_state, turn_manager, trainer_unit, "Mover + Explorar"):
		board_scene.queue_free()
		await get_tree().process_frame
		return false

	var move_target := Vector2i(1, 0)
	var explore_target := Vector2i(0, 1)

	_configure_cell(
		board_scene,
		board_state,
		move_target,
		_make_test_tile("ME-M", 100, 1),
		true
	)
	_configure_cell(
		board_scene,
		board_state,
		explore_target,
		_make_test_tile("ME-E", 2, 100),
		false
	)

	var ok := true

	if not bool(board_scene.call("try_move_trainer_to", move_target)):
		ok = _fail("Mover + Explorar: Mover fue rechazado.")

	if player_state.mn != 3:
		ok = _fail("Mover + Explorar: Mover debia aplicar solo Entrada +1.")

	if not bool(board_scene.call("try_explore_trainer_to", explore_target)):
		ok = _fail("Mover + Explorar: Explorar fue rechazado.")

	if player_state.current_coord != explore_target:
		ok = _fail("Mover + Explorar: el jugador no termino en la loseta explorada.")

	if player_state.mn != 5:
		ok = _fail("Mover + Explorar: resultado esperado MN=5 (+1 entrada, +2 explorar); MN=%s." % player_state.mn)

	if turn_manager.actions_remaining != 0:
		ok = _fail("Mover + Explorar: las dos acciones no agotaron el turno.")

	if turn_manager.get_action_usage(KarmanyMovementRules.ACTION_ID_MOVE) != 1:
		ok = _fail("Mover + Explorar: se esperaba 1 Mover.")

	if turn_manager.get_action_usage(KarmanyExplorationRules.ACTION_ID_EXPLORE) != 1:
		ok = _fail("Mover + Explorar: se esperaba 1 Explorar.")

	print("Mover + Explorar: ", "OK" if ok else "ERROR")
	print("  MN: 2 -> ", player_state.mn, " | acciones restantes: ", turn_manager.actions_remaining)

	board_scene.queue_free()
	await get_tree().process_frame
	return ok


func _spawn_board() -> Node3D:
	var board_scene := BOARD_SCENE.instantiate() as Node3D
	add_child(board_scene)
	return board_scene


func _core_is_valid(
	board_state: KarmanyBoardState,
	player_state: KarmanyPlayerState,
	turn_manager: KarmanyTurnManager,
	trainer_unit: KarmanyTrainerUnit3D,
	scenario_name: String
) -> bool:
	if board_state == null:
		return _fail("%s: BoardState no disponible." % scenario_name)

	if player_state == null:
		return _fail("%s: PlayerState no disponible." % scenario_name)

	if turn_manager == null:
		return _fail("%s: TurnManager no disponible." % scenario_name)

	if trainer_unit == null:
		return _fail("%s: TrainerUnit3D no disponible." % scenario_name)

	if turn_manager.get_active_player() != player_state:
		return _fail("%s: player_1 no es el jugador activo inicial." % scenario_name)

	if turn_manager.actions_remaining != 2:
		return _fail("%s: el turno no comenzo con 2 acciones." % scenario_name)

	return true


func _configure_cell(
	board_scene: Node3D,
	board_state: KarmanyBoardState,
	coord: Vector2i,
	tile_data: KarmanyTileData,
	revealed: bool
) -> void:
	board_state.set_tile_data(coord, tile_data)
	board_state.set_revealed(coord, revealed)
	board_scene.call("_refresh_tile_view_from_state", coord)


func _make_test_tile(
	tile_id: String,
	on_explore_mn: int,
	entry_mn: int
) -> KarmanyTileData:
	var tile_data := KarmanyTileData.new()
	tile_data.tile_id = tile_id
	tile_data.display_name = "Loseta de prueba %s" % tile_id
	tile_data.level = KarmanyTileData.TileLevel.N1
	tile_data.on_explore_text = "Obtén %s MN al explorar." % on_explore_mn
	tile_data.entry_bonus_text = "Obtén %s MN al entrar mediante Mover." % entry_mn

	var on_explore_effect := KarmanyEffectData.new()
	on_explore_effect.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	on_explore_effect.resource_type = KarmanyEffectData.ResourceType.MN
	on_explore_effect.amount = on_explore_mn
	on_explore_effect.description = tile_data.on_explore_text

	var entry_effect := KarmanyEffectData.new()
	entry_effect.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	entry_effect.resource_type = KarmanyEffectData.ResourceType.MN
	entry_effect.amount = entry_mn
	entry_effect.description = tile_data.entry_bonus_text

	var explore_effects: Array[KarmanyEffectData] = [
		on_explore_effect
	]
	var entry_effects: Array[KarmanyEffectData] = [
		entry_effect
	]

	tile_data.on_explore_effects = explore_effects
	tile_data.entry_effects = entry_effects

	return tile_data


func _fail(message: String) -> bool:
	push_error("FASE 6 MATRIZ ERROR: %s" % message)
	return false
