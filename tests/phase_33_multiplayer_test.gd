extends Node


const PHASE_33_SCENE: PackedScene = preload("res://scenes/ui/phase_33_multiplayer_prototype.tscn")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 33 MULTIPLAYER TEST")
	print("================================")

	var ok: bool = true
	ok = _test_phase_31_connectivity_regression() and ok
	ok = _test_two_player_setup() and ok
	ok = _test_three_player_setup() and ok
	ok = _test_four_player_setup() and ok
	ok = _test_independent_player_state() and ok
	ok = _test_initial_occupancy_guard() and ok
	ok = _test_turn_cycles_for_all_player_counts() and ok
	ok = _test_phase_32_random_map_regression() and ok
	var visual_ok: bool = await _test_visual_probe()
	ok = visual_ok and ok

	print("")
	print("================================")
	if ok:
		print("FASE 33 OK - Multijugador local 2-4, turnos y setups canonicos validados.")
	else:
		push_error("FASE 33 ERROR - Revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_phase_31_connectivity_regression() -> bool:
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		return _fail("La API valida is_fully_connected() no confirma conectividad F31.")

	var starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	var expected: Array[Vector2i] = [
		Vector2i(4, -2),
		Vector2i(-1, 4),
		Vector2i(-4, 2),
		Vector2i(1, -4)
	]
	if starts != expected:
		return _fail("Las cuatro coordenadas Iniciales canonicas cambiaron.")

	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for start_coord in starts:
		var n1_neighbors: int = 0
		var map_neighbors: int = 0
		for neighbor in KarmanyHexGridMath.get_neighbors(start_coord):
			if not levels.has(neighbor):
				continue
			map_neighbors += 1
			if int(levels[neighbor]) == KarmanyTileData.TileLevel.N1:
				n1_neighbors += 1
		if map_neighbors != 2 or n1_neighbors != 2:
			return _fail("Inicial %s perdio sus 2 adyacencias N1 exactas." % start_coord)

	print("Regresion F31: is_fully_connected + coordenadas + 2 vecinos N1: OK")
	return true


func _test_two_player_setup() -> bool:
	var session := _create_session(2)
	if session == null:
		return _fail("Setup 2P no pudo construirse.")
	if not _validate_common_session(session, 2):
		return false
	if session.starting_coords[0] + session.starting_coords[1] != Vector2i.ZERO:
		return _fail("2P no utiliza posiciones Iniciales opuestas.")
	if KarmanyHexGridMath.distance(session.starting_coords[0], session.starting_coords[1]) != 8:
		return _fail("2P no conserva la separacion maxima canonica de 8 hexes.")
	print("Setup 2P: Iniciales opuestas y participantes unicos: OK")
	return true


func _test_three_player_setup() -> bool:
	var session := _create_session(3)
	if session == null:
		return _fail("Setup 3P no pudo construirse.")
	if not _validate_common_session(session, 3):
		return false

	var minimum_distance: int = 999
	for first_index in range(session.starting_coords.size()):
		for second_index in range(first_index + 1, session.starting_coords.size()):
			minimum_distance = mini(
				minimum_distance,
				KarmanyHexGridMath.distance(
					session.starting_coords[first_index],
					session.starting_coords[second_index]
				)
			)
	if minimum_distance < 5:
		return _fail("Setup 3P no mantiene una distribucion espacial razonablemente equilibrada.")
	print("Setup 3P: tres Iniciales unicas, separacion minima >= 5: OK")
	return true


func _test_four_player_setup() -> bool:
	var session := _create_session(4)
	if session == null:
		return _fail("Setup 4P no pudo construirse.")
	if not _validate_common_session(session, 4):
		return false
	if session.starting_coords != KarmanyCanonicalMap41Layout.get_starting_coords():
		return _fail("4P no utiliza exactamente las cuatro Iniciales canonicas.")
	print("Setup 4P: una Inicial canonica por participante: OK")
	return true


func _test_independent_player_state() -> bool:
	var session := _create_session(4)
	if session == null:
		return _fail("No se pudo preparar sesion para independencia de PlayerState.")

	for first_index in range(session.players.size()):
		for second_index in range(first_index + 1, session.players.size()):
			var first: KarmanyPlayerState = session.players[first_index]
			var second: KarmanyPlayerState = session.players[second_index]
			if first == second:
				return _fail("Dos participantes comparten la misma instancia KarmanyPlayerState.")
			if first.resource_inventory == second.resource_inventory:
				return _fail("Dos participantes comparten ResourceInventory.")
			if first.karmany_roster == second.karmany_roster:
				return _fail("Dos participantes comparten KarmanyRoster.")
			if first.equipment_inventory == second.equipment_inventory:
				return _fail("Dos participantes comparten EquipmentInventory.")
			if first.resonance_hand == second.resonance_hand:
				return _fail("Dos participantes comparten ResonanceHand.")

	var untouched_player: KarmanyPlayerState = session.players[1]
	var untouched_mn: int = untouched_player.mn
	session.players[0].mn += 3
	if untouched_player.mn != untouched_mn:
		return _fail("Modificar recursos de P1 altero recursos de P2.")

	for player in session.players:
		if session.legacy_points == null or not session.legacy_points.has_player(player.player_id):
			return _fail("Un participante no tiene registro independiente de PL.")
		if session.get_player_legacy_points(player.player_id) != 0:
			return _fail("Un participante no inicia con 0 PL.")

	print("PlayerState/recursos/Karmanys/equipos/resonancias/PL independientes: OK")
	return true


func _test_initial_occupancy_guard() -> bool:
	var session := _create_session(4)
	var board := _build_empty_canonical_board()
	if session == null or board == null:
		return _fail("No se pudo preparar prueba de ocupacion 4P.")
	if not session.register_initial_occupancy(board):
		return _fail("No se pudieron registrar cuatro ocupantes iniciales.")
	for index in range(session.starting_coords.size()):
		if board.get_occupying_unit_id(session.starting_coords[index]) != session.unit_ids[index]:
			return _fail("La ocupacion inicial no coincide con su participante.")

	var guarded_session := _create_session(2)
	var guarded_board := _build_empty_canonical_board()
	if guarded_session == null or guarded_board == null:
		return _fail("No se pudo preparar guard contra sobrescritura.")
	var guarded_coord: Vector2i = guarded_session.starting_coords[0]
	var foreign_unit: StringName = &"foreign_trainer"
	if not guarded_board.set_unit_occupant(guarded_coord, foreign_unit):
		return _fail("No se pudo preparar ocupante externo para la prueba.")
	if guarded_session.register_initial_occupancy(guarded_board):
		return _fail("El setup multijugador intento sobrescribir un ocupante ajeno.")
	if guarded_board.get_occupying_unit_id(guarded_coord) != foreign_unit:
		return _fail("El guard de ocupacion altero un ocupante ajeno.")
	for index in range(1, guarded_session.starting_coords.size()):
		if guarded_board.is_occupied(guarded_session.starting_coords[index]):
			return _fail("Un fallo de ocupacion dejo un setup parcial en el tablero.")

	print("BoardState: 4 unidades distintas y sin sobrescritura accidental: OK")
	return true


func _test_turn_cycles_for_all_player_counts() -> bool:
	for player_count in [2, 3, 4]:
		var session := _create_session(player_count)
		if session == null or not session.start_match():
			return _fail("No se pudo iniciar secuencia de turnos %dP." % player_count)
		var manager := session.turn_manager
		if manager.current_round != 1:
			return _fail("%dP no inicio en ronda 1." % player_count)

		for player_index in range(player_count):
			var expected_player: KarmanyPlayerState = session.players[player_index]
			if manager.get_active_player() != expected_player:
				return _fail("%dP perdio el orden de turno en indice %d." % [player_count, player_index])
			if manager.actions_remaining != 2:
				return _fail("%s no recibio exactamente 2 acciones." % expected_player.player_id)
			if manager.end_turn():
				return _fail("%s pudo terminar turno con acciones pendientes." % expected_player.player_id)
			if not manager.spend_action() or not manager.spend_action():
				return _fail("%s no pudo consumir sus 2 acciones." % expected_player.player_id)
			if manager.spend_action():
				return _fail("%s pudo consumir una tercera accion." % expected_player.player_id)
			if not manager.end_turn():
				return _fail("%s no pudo cerrar turno tras 2 acciones." % expected_player.player_id)

		if manager.current_round != 2:
			return _fail("%dP no avanzo a ronda 2 despues del ultimo participante." % player_count)
		if manager.get_active_player() != session.players[0]:
			return _fail("%dP no regreso a P1 al iniciar nueva ronda." % player_count)
		if manager.actions_remaining != 2:
			return _fail("P1 no recibio 2 acciones al iniciar ronda 2 en %dP." % player_count)

	print("TurnManager 2P/3P/4P: secuencias, 2 acciones y cambio de ronda: OK")
	return true


func _test_phase_32_random_map_regression() -> bool:
	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("Regresion F32 no pudo cargar pools N1/N2/N3.")
	var content_session := KarmanyMap41ContentGenerator.generate(33033, pools)
	var board := _build_empty_canonical_board()
	if content_session == null or board == null or not content_session.apply_public_state(board):
		return _fail("Regresion F32 no pudo aplicar mapa determinista.")
	if board.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("F33 altero la geometria de 41 posiciones.")
	for level in [KarmanyTileData.TileLevel.N1, KarmanyTileData.TileLevel.N2, KarmanyTileData.TileLevel.N3]:
		for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
			if board.is_revealed(coord) or board.get_tile_data(coord) != null:
				return _fail("F33 expuso contenido oculto de F32 antes de explorar.")
	print("Regresion F32: seed/pools/ocultamiento conservados: OK")
	return true


func _test_visual_probe() -> bool:
	var prototype := PHASE_33_SCENE.instantiate() as KarmanyPhase33MultiplayerBridge
	if prototype == null:
		return _fail("No se pudo instanciar escena visual F33.")
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame

	var ok: bool = true
	if not prototype.setup_ok or prototype.get_participant_count() != 4:
		ok = _fail("Escena F33 no completo su setup visual 4P inicial.")
	else:
		for player_count in [2, 3, 4]:
			if not prototype.setup_player_count(player_count):
				ok = _fail("Escena F33 no pudo cambiar a %dP." % player_count)
				break
			if prototype.get_participant_count() != player_count:
				ok = _fail("Escena F33 perdio participantes en setup %dP." % player_count)
				break
			if prototype.trainer_units.size() != player_count:
				ok = _fail("Escena F33 no sincronizo TrainerUnit3D para %dP." % player_count)
				break

	if ok and not prototype.setup_player_count(4):
		ok = _fail("Escena F33 no pudo restaurar 4P para probar turnos.")
	if ok:
		for expected_index in range(4):
			var expected_id := StringName("player_%d" % (expected_index + 1))
			if prototype.get_active_player_id() != expected_id:
				ok = _fail("Probe visual no muestra el turno esperado de %s." % expected_id)
				break
			if not prototype.consume_action() or not prototype.consume_action():
				ok = _fail("Probe visual no pudo consumir 2 acciones de %s." % expected_id)
				break
			if not prototype.finish_turn():
				ok = _fail("Probe visual no pudo avanzar despues de %s." % expected_id)
				break
	if ok:
		if prototype.multiplayer_session.turn_manager.current_round != 2:
			ok = _fail("Probe visual 4P no inicio ronda 2 tras P4.")
		elif prototype.get_active_player_id() != &"player_1":
			ok = _fail("Probe visual 4P no regreso a player_1 en ronda 2.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("Probe F6: 2P/3P/4P + cuatro TrainerUnit3D + secuencia P1-P4: OK")
	return ok


func _validate_common_session(
	session: KarmanyLocalMultiplayerSession,
	expected_count: int
) -> bool:
	if session.get_player_count() != expected_count:
		return _fail("La sesion no conserva %d participantes." % expected_count)
	if session.turn_manager == null or session.turn_manager.get_player_count() != expected_count:
		return _fail("TurnManager no conserva %d participantes." % expected_count)
	if session.starting_coords.size() != expected_count or session.unit_ids.size() != expected_count:
		return _fail("Colecciones de setup no coinciden con %d participantes." % expected_count)

	var canonical_starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	var seen_ids: Dictionary = {}
	var seen_coords: Dictionary = {}
	var seen_units: Dictionary = {}
	for index in range(expected_count):
		var player: KarmanyPlayerState = session.players[index]
		var expected_id := StringName("player_%d" % (index + 1))
		if player == null or player.player_id != expected_id:
			return _fail("ID de participante inesperado en indice %d." % index)
		if seen_ids.has(player.player_id):
			return _fail("ID de participante duplicado: %s." % player.player_id)
		if player.current_coord == Vector2i.ZERO or not canonical_starts.has(player.current_coord):
			return _fail("%s no inicia en una Inicial canonica valida." % player.player_id)
		if seen_coords.has(player.current_coord):
			return _fail("Dos participantes comparten Inicial durante setup.")
		if session.unit_ids[index] == &"" or seen_units.has(session.unit_ids[index]):
			return _fail("Unit ID vacio o duplicado en setup.")
		if session.turn_manager.players[index] != player:
			return _fail("TurnManager no conserva la misma instancia PlayerState.")
		seen_ids[player.player_id] = true
		seen_coords[player.current_coord] = true
		seen_units[session.unit_ids[index]] = true
	return true


func _create_session(player_count: int) -> KarmanyLocalMultiplayerSession:
	var session := KarmanyLocalMultiplayerSession.new()
	if not session.setup_local_players(player_count):
		return null
	return session


func _build_empty_canonical_board() -> KarmanyBoardState:
	var board := KarmanyBoardState.new()
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		if not board.add_cell(coord, null, false):
			return null
	return board


func _fail(message: String) -> bool:
	push_error("FASE 33 ERROR: %s" % message)
	return false
