extends Node


func _ready() -> void:

	print("")
	print("================================")
	print("KARMANY MONSTA - HEX GRID TEST")
	print("================================")

	var center := Vector2i(0, 0)

	print("")
	print("Centro: ", center)

	var neighbors := KarmanyHexGridMath.get_neighbors(center)


	print("")
	print("VECINOS DEL CENTRO")

	for i in range(neighbors.size()):
		print(
			"Vecino ",
			i,
			": ",
			neighbors[i]
		)


	var test_passed: bool = true


	# TEST 1
	# Un hexágono debe tener exactamente 6 vecinos.

	if neighbors.size() != 6:
		test_passed = false
		push_error(
			"HEX ERROR: El centro no tiene 6 vecinos."
		)


	# TEST 2
	# Todos los vecinos deben estar a distancia 1.

	for neighbor in neighbors:

		var neighbor_distance := (
			KarmanyHexGridMath.distance(
				center,
				neighbor
			)
		)

		if neighbor_distance != 1:
			test_passed = false

			push_error(
				"HEX ERROR: %s no está a distancia 1."
				% neighbor
			)


	# TEST 3
	# Comprobación de adyacencia.

	var adjacent_tile := Vector2i(1, 0)

	if not KarmanyHexGridMath.are_adjacent(
		center,
		adjacent_tile
	):
		test_passed = false
		push_error(
			"HEX ERROR: (1,0) debería ser adyacente."
		)


	# TEST 4
	# Una loseta más lejana NO debe ser adyacente.

	var distant_tile := Vector2i(2, -1)

	if KarmanyHexGridMath.are_adjacent(
		center,
		distant_tile
	):
		test_passed = false
		push_error(
			"HEX ERROR: (2,-1) no debería ser adyacente."
		)


	# TEST 5
	# Su distancia debe ser exactamente 2.

	var calculated_distance := (
		KarmanyHexGridMath.distance(
			center,
			distant_tile
		)
	)

	print("")
	print(
		"Distancia de ",
		center,
		" a ",
		distant_tile,
		": ",
		calculated_distance
	)

	if calculated_distance != 2:
		test_passed = false

		push_error(
			"HEX ERROR: La distancia esperada era 2."
		)


	print("")
	print("POSICIONES 3D")

	print(
		"Centro: ",
		KarmanyHexGridMath.axial_to_world(
			center,
			1.0
		)
	)

	for neighbor in neighbors:
		print(
			neighbor,
			" -> ",
			KarmanyHexGridMath.axial_to_world(
				neighbor,
				1.0
			)
		)


	print("")
	print("================================")

	if test_passed:
		print(
			"FASE 1C OK - Sistema hexagonal correcto."
		)
	else:
		push_error(
			"FASE 1C ERROR - Revisar sistema hexagonal."
		)

	print("================================")
