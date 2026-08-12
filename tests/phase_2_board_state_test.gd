extends Node


const CENTER_TILE_DATA: KarmanyTileData = preload(
	"res://data/tiles/i_01_refugio_valle_jade.tres"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 2 BOARD STATE TEST")
	print("================================")

	var test_passed: bool = true
	var state := KarmanyBoardState.new()
	var center := Vector2i.ZERO

	state.add_cell(
		center,
		CENTER_TILE_DATA,
		CENTER_TILE_DATA.starts_revealed
	)

	for neighbor in KarmanyHexGridMath.get_neighbors(center):
		state.add_cell(neighbor, null, false)

	if state.get_cell_count() != 7:
		test_passed = false
		push_error(
			"FASE 2 ERROR: Se esperaban 7 coordenadas logicas y hay %s."
			% state.get_cell_count()
		)

	if not state.has_coord(center):
		test_passed = false
		push_error("FASE 2 ERROR: Falta la coordenada central (0, 0).")

	var center_data := state.get_tile_data(center)

	if center_data == null:
		test_passed = false
		push_error("FASE 2 ERROR: El centro no tiene KarmanyTileData.")
	elif center_data.tile_id != "I-01":
		test_passed = false
		push_error(
			"FASE 2 ERROR: El centro deberia ser I-01 y es %s."
			% center_data.tile_id
		)

	if not state.is_revealed(center):
		test_passed = false
		push_error("FASE 2 ERROR: I-01 deberia comenzar revelada.")

	var existing_neighbors := state.get_existing_neighbors(center)

	if existing_neighbors.size() != 6:
		test_passed = false
		push_error(
			"FASE 2 ERROR: El centro deberia tener 6 vecinos existentes y tiene %s."
			% existing_neighbors.size()
		)

	for neighbor in existing_neighbors:
		if state.is_revealed(neighbor):
			test_passed = false
			push_error(
				"FASE 2 ERROR: La coordenada %s deberia comenzar oculta."
				% neighbor
			)

		if not state.are_existing_coords_adjacent(center, neighbor):
			test_passed = false
			push_error(
				"FASE 2 ERROR: %s deberia ser adyacente al centro."
				% neighbor
			)

	var reveal_test_coord := Vector2i(1, 0)

	if not state.set_revealed(reveal_test_coord, true):
		test_passed = false
		push_error("FASE 2 ERROR: No se pudo actualizar el estado revelado.")
	elif not state.is_revealed(reveal_test_coord):
		test_passed = false
		push_error("FASE 2 ERROR: El estado revelado no se conservo.")

	state.set_revealed(reveal_test_coord, false)

	var occupant_test_coord := Vector2i(1, -1)
	var test_unit_id: StringName = &"trainer_test"

	if not state.set_unit_occupant(occupant_test_coord, test_unit_id):
		test_passed = false
		push_error("FASE 2 ERROR: No se pudo registrar un ocupante logico.")
	elif not state.is_occupied(occupant_test_coord):
		test_passed = false
		push_error("FASE 2 ERROR: La ocupacion no fue registrada.")
	elif state.get_occupying_unit_id(occupant_test_coord) != test_unit_id:
		test_passed = false
		push_error("FASE 2 ERROR: El ID del ocupante no coincide.")

	if not state.clear_unit_occupant(occupant_test_coord):
		test_passed = false
		push_error("FASE 2 ERROR: No se pudo limpiar la ocupacion.")
	elif state.is_occupied(occupant_test_coord):
		test_passed = false
		push_error("FASE 2 ERROR: La coordenada sigue ocupada despues de limpiar.")

	print("")
	print("Coordenadas logicas: ", state.get_cell_count())
	print("Centro: ", center_data.tile_id if center_data != null else "sin datos")
	print("Vecinos existentes del centro: ", existing_neighbors.size())
	print("Ocupacion desacoplada de nodos 3D: OK")
	print("")
	print("================================")

	if test_passed:
		print("FASE 2 OK - BoardState logico validado.")
	else:
		push_error("FASE 2 ERROR - Revisar BoardState.")

	print("================================")
