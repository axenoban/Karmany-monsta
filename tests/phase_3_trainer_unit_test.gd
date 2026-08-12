extends Node


const BOARD_SCENE: PackedScene = preload(
	"res://scenes/board/board_3d_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 3 TRAINER UNIT TEST")
	print("================================")

	var test_passed: bool = true
	var board_scene := BOARD_SCENE.instantiate()
	add_child(board_scene)

	await get_tree().process_frame

	var board_state := board_scene.get("board_state") as KarmanyBoardState
	var player_state := board_scene.get("player_state") as KarmanyPlayerState
	var trainer_unit := board_scene.get("trainer_unit") as KarmanyTrainerUnit3D

	if board_state == null:
		test_passed = false
		push_error("FASE 3 ERROR: BoardState no esta disponible.")

	if player_state == null:
		test_passed = false
		push_error("FASE 3 ERROR: PlayerState no esta disponible.")

	if trainer_unit == null:
		test_passed = false
		push_error("FASE 3 ERROR: TrainerUnit3D no fue creado.")

	if not test_passed:
		_finish_test(false, board_scene)
		return

	var start_coord := Vector2i.ZERO
	var trainer_unit_id: StringName = trainer_unit.unit_id

	if player_state.player_id != &"player_1":
		test_passed = false
		push_error("FASE 3 ERROR: El Entrenador no esta asociado a player_1.")

	if trainer_unit.get_player_id() != player_state.player_id:
		test_passed = false
		push_error("FASE 3 ERROR: La unidad 3D no conserva su asociacion al jugador.")

	if player_state.current_coord != start_coord:
		test_passed = false
		push_error(
			"FASE 3 ERROR: La coordenada inicial deberia ser (0, 0) y es %s."
			% player_state.current_coord
		)

	if board_state.get_occupying_unit_id(start_coord) != trainer_unit_id:
		test_passed = false
		push_error("FASE 3 ERROR: BoardState no registra al Entrenador en el centro.")

	var start_tile := board_scene.call("get_tile_view", start_coord) as KarmanyHexTile3D

	if start_tile == null:
		test_passed = false
		push_error("FASE 3 ERROR: No se encontro la vista 3D del hexagono inicial.")
	elif trainer_unit.global_position.distance_to(
		start_tile.unit_anchor.global_position
	) > 0.001:
		test_passed = false
		push_error("FASE 3 ERROR: El Entrenador no esta colocado en UnitAnchor.")

	# Direct technical relocation only. This is not the gameplay Move action.
	var target_coord := Vector2i(1, 0)
	var placed: bool = board_scene.call("place_trainer_at", target_coord)

	if not placed:
		test_passed = false
		push_error("FASE 3 ERROR: No se pudo recolocar tecnicamente al Entrenador.")

	if player_state.current_coord != target_coord:
		test_passed = false
		push_error("FASE 3 ERROR: PlayerState no actualizo la coordenada del Entrenador.")

	if board_state.is_occupied(start_coord):
		test_passed = false
		push_error("FASE 3 ERROR: La coordenada anterior continua ocupada.")

	if board_state.get_occupying_unit_id(target_coord) != trainer_unit_id:
		test_passed = false
		push_error("FASE 3 ERROR: La nueva coordenada no registra al Entrenador.")

	var target_tile := board_scene.call("get_tile_view", target_coord) as KarmanyHexTile3D

	if target_tile == null:
		test_passed = false
		push_error("FASE 3 ERROR: No se encontro la vista 3D del destino.")
	elif trainer_unit.global_position.distance_to(
		target_tile.unit_anchor.global_position
	) > 0.001:
		test_passed = false
		push_error("FASE 3 ERROR: La unidad visual no siguio al nuevo UnitAnchor.")

	var coord_before_invalid_test := player_state.current_coord

	if board_scene.call("place_trainer_at", Vector2i(99, 99)):
		test_passed = false
		push_error("FASE 3 ERROR: Se acepto una coordenada inexistente.")

	if player_state.current_coord != coord_before_invalid_test:
		test_passed = false
		push_error("FASE 3 ERROR: Un destino inexistente modifico la posicion logica.")

	print("")
	print("Jugador asociado: ", player_state.player_id)
	print("Unidad: ", trainer_unit_id)
	print("Inicio: ", start_coord)
	print("Recolocacion tecnica: ", target_coord)
	print("UnitAnchor sincronizado: OK")
	print("BoardState sincronizado: OK")
	print("")

	_finish_test(test_passed, board_scene)


func _finish_test(
	test_passed: bool,
	board_scene: Node
) -> void:
	print("================================")

	if test_passed:
		print("FASE 3 OK - Entrenador 3D y posicion logica validados.")
	else:
		push_error("FASE 3 ERROR - Revisar unidad de Entrenador.")

	print("================================")
	board_scene.queue_free()
