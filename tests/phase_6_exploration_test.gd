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

	var first_target := Vector2i(0, -1)
	var second_target := Vector2i(-1, 0)
	var third_target := Vector2i(-1, 1)

	var first_tile_data := _make_test_tile("TEST-EXP-A", 2, 100)
	var second_tile_data := _make_test_tile("TEST-EXP-B", 3, 100)
	var third_tile_data := _make_test_tile("TEST-EXP-C", 4, 100)

	_configure_hidden_cell(board_scene, board_state, first_target, first_tile_data)
	_configure_hidden_cell(board_scene, board_state, second_target, second_tile_data)
	_configure_hidden_cell(board_scene, board_state, third_target, third_tile_data)

	if turn_manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 6 ERROR: El turno deberia comenzar con 2 acciones.")

	if player_state.mn != 2:
		test_passed = false
		push_error("FASE 6 ERROR: MN inicial deberia ser 2.")

	if not bool(board_scene.call("try_explore_trainer_to", first_target)):
		test_passed = false
		push_error("FASE 6 ERROR: La primera exploracion legal fue rechazada.")

	if not board_state.is_revealed(first_target):
		test_passed = false
		push_error("FASE 6 ERROR: La primera loseta no quedo revelada.")

	if player_state.current_coord != first_target:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador no entro en la primera loseta explorada.")

	if player_state.mn != 4:
		test_passed = false
		push_error(
			"FASE 6 ERROR: La primera exploracion debia aplicar solo on_explore +2; MN=%s."
			% player_state.mn
		)

	if turn_manager.actions_remaining != 1:
		test_passed = false
		push_error("FASE 6 ERROR: La primera exploracion debe dejar 1 accion.")

	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador activo cambio despues de la primera accion.")

	# Nueva regla: Explorar puede repetirse como segunda accion si el nuevo destino oculto es legal.
	if not bool(board_scene.call("try_explore_trainer_to", second_target)):
		test_passed = false
		push_error("FASE 6 ERROR: La segunda exploracion legal fue rechazada.")

	if not board_state.is_revealed(second_target):
		test_passed = false
		push_error("FASE 6 ERROR: La segunda loseta no quedo revelada.")

	if player_state.current_coord != second_target:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador no entro en la segunda loseta explorada.")

	if player_state.mn != 7:
		test_passed = false
		push_error(
			"FASE 6 ERROR: Dos on_explore (+2,+3) debian dejar MN=7 y nunca ejecutar Entrada; MN=%s."
			% player_state.mn
		)

	if turn_manager.actions_remaining != 0:
		test_passed = false
		push_error("FASE 6 ERROR: Dos exploraciones deben consumir las 2 acciones.")

	if turn_manager.get_action_usage(
		KarmanyExplorationRules.ACTION_ID_EXPLORE
	) != 2:
		test_passed = false
		push_error("FASE 6 ERROR: Deben registrarse 2 acciones Explorar en el turno.")

	if turn_manager.get_active_player() != player_state:
		test_passed = false
		push_error("FASE 6 ERROR: El jugador activo cambio antes de finalizar formalmente el turno.")

	# Una tercera accion queda bloqueada por presupuesto, no por un limite especial de Explorar.
	if bool(board_scene.call("try_explore_trainer_to", third_target)):
		test_passed = false
		push_error("FASE 6 ERROR: Se permitio una tercera accion sin presupuesto.")

	if board_state.is_revealed(third_target):
		test_passed = false
		push_error("FASE 6 ERROR: La tercera loseta se revelo sin acciones disponibles.")

	if not turn_manager.end_turn():
		test_passed = false
		push_error("FASE 6 ERROR: No se pudo cerrar el turno tras consumir 2 acciones.")

	var next_player := turn_manager.get_active_player()

	if next_player == null or next_player.player_id != &"player_2":
		test_passed = false
		push_error("FASE 6 ERROR: El turno no avanzo a player_2.")

	print("")
	print("Explorar 1: ", first_target, " -> on_explore +2 MN")
	print("Explorar 2: ", second_target, " -> on_explore +3 MN")
	print("Entrada durante Explorar: NO")
	print("Uso de Explorar en el turno: 2")
	print("MN final de player_1: ", player_state.mn)
	print("Siguiente jugador tras 2 acciones: ", next_player.player_id if next_player != null else &"")
	print("")

	_finish_test(test_passed, board_scene)


func _configure_hidden_cell(
	board_scene: Node,
	board_state: KarmanyBoardState,
	coord: Vector2i,
	tile_data: KarmanyTileData
) -> void:
	board_state.set_tile_data(coord, tile_data)
	board_state.set_revealed(coord, false)
	board_scene.call("_refresh_tile_view_from_state", coord)


func _make_test_tile(
	tile_id: String,
	on_explore_mn: int,
	entry_mn: int
) -> KarmanyTileData:
	var tile_data := KarmanyTileData.new()
	tile_data.tile_id = tile_id
	tile_data.display_name = "Loseta de prueba de exploracion"
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


func _finish_test(
	test_passed: bool,
	board_scene: Node
) -> void:
	print("================================")

	if test_passed:
		print("FASE 6 OK - Explorar puede repetirse y solo resuelve on_explore.")
	else:
		push_error("FASE 6 ERROR - Revisar sistema de exploracion.")

	print("================================")
	board_scene.queue_free()
