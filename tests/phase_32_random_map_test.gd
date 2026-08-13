extends Node

const PHASE_32_SCENE: PackedScene = preload("res://scenes/ui/phase_32_random_map_prototype.tscn")

var pools: KarmanyMap41TilePools = KarmanyMap41TilePools.new()

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 32 RANDOM MAP TEST")
	print("================================")

	var ok: bool = pools.load_from_project()
	if not ok:
		push_error("FASE 32 ERROR: No se pudieron cargar pools de losetas.")
		return

	ok = _test_phase_31_starting_adjacency_regression() and ok
	ok = _test_same_seed_same_map() and ok
	ok = _test_different_seed_different_map() and ok
	ok = _test_hidden_identity_not_public() and ok
	ok = _test_fallback_is_balanced_and_reported() and ok
	ok = _test_one_hundred_seeds_level_integrity() and ok
	var visual_ok: bool = await _test_visual_probe()
	ok = visual_ok and ok

	print("")
	print("================================")
	if ok:
		print("FASE 32 OK - Randomizacion determinista, ocultamiento y fallback validados.")
	else:
		push_error("FASE 32 ERROR - Revisar el primer fallo del generador.")
	print("================================")

func _test_phase_31_starting_adjacency_regression() -> bool:
	var starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	var expected: Array[Vector2i] = [
		Vector2i(4, -2),
		Vector2i(-1, 4),
		Vector2i(-4, 2),
		Vector2i(1, -4)
	]
	if starts != expected:
		return _fail("Las coordenadas Iniciales canonicas de Fase 31 cambiaron.")

	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for start_coord in starts:
		var map_neighbors: int = 0
		var n1_neighbors: int = 0
		for neighbor in KarmanyHexGridMath.get_neighbors(start_coord):
			if not levels.has(neighbor):
				continue
			map_neighbors += 1
			if int(levels[neighbor]) == KarmanyTileData.TileLevel.N1:
				n1_neighbors += 1
		if map_neighbors != 2 or n1_neighbors != 2:
			return _fail("Inicial %s debe tener exactamente 2 vecinos del mapa, ambos N1." % start_coord)

	print("Regresion F31: cuatro Iniciales fijas + 2 adyacencias N1 exactas: OK")
	return true

func _test_same_seed_same_map() -> bool:
	var first := KarmanyMap41ContentGenerator.generate(32001, pools)
	var second := KarmanyMap41ContentGenerator.generate(32001, pools)
	if first == null or second == null:
		return _fail("No se pudieron generar dos mapas con la misma seed.")
	var first_fingerprint: String = first.get_assignment_fingerprint()
	var second_fingerprint: String = second.get_assignment_fingerprint()
	if first_fingerprint.is_empty() or first_fingerprint != second_fingerprint:
		return _fail("La misma seed no produjo la misma distribucion.")
	print("Misma match_seed -> misma distribucion: OK")
	return true

func _test_different_seed_different_map() -> bool:
	var first := KarmanyMap41ContentGenerator.generate(32001, pools)
	var second := KarmanyMap41ContentGenerator.generate(32002, pools)
	if first == null or second == null:
		return _fail("No se pudieron generar mapas para seeds distintas.")
	if first.get_assignment_fingerprint() == second.get_assignment_fingerprint():
		return _fail("Seeds 32001 y 32002 produjeron la misma distribucion.")
	print("Seed distinta -> distribucion distinta: OK")
	return true

func _test_hidden_identity_not_public() -> bool:
	var session := KarmanyMap41ContentGenerator.generate(32100, pools)
	var board := _build_empty_canonical_board()
	if session == null or board == null or not session.apply_public_state(board):
		return _fail("No se pudo preparar el estado publico para prueba de ocultamiento.")

	for level in [KarmanyTileData.TileLevel.N1, KarmanyTileData.TileLevel.N2, KarmanyTileData.TileLevel.N3]:
		for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
			if board.is_revealed(coord):
				return _fail("Una posicion oculta aparece revelada antes de explorar.")
			if board.get_tile_data(coord) != null:
				return _fail("BoardState expone identidad de una loseta oculta.")
			if session.get_public_tile_data(board, coord) != null:
				return _fail("La API publica de Fase 32 expone identidad oculta.")

	print("Contenido oculto ausente de BoardState/API publica antes de explorar: OK")
	return true

func _test_fallback_is_balanced_and_reported() -> bool:
	var session := KarmanyMap41ContentGenerator.generate(32200, pools)
	if session == null:
		return _fail("No se pudo generar sesion para validar fallback.")
	var reports := session.get_fallback_report()
	var target_counts: Dictionary = {
		KarmanyTileData.TileLevel.N1: KarmanyCanonicalMap41Layout.N1_COUNT,
		KarmanyTileData.TileLevel.N2: KarmanyCanonicalMap41Layout.N2_COUNT,
		KarmanyTileData.TileLevel.N3: KarmanyCanonicalMap41Layout.N3_COUNT
	}

	for level in target_counts.keys():
		var report_value: Variant = reports.get(level, {})
		if not (report_value is Dictionary):
			return _fail("Falta reporte fallback para un nivel.")
		var level_report: Dictionary = report_value
		var target_count: int = int(target_counts[level])
		var pool_size: int = pools.get_pool_size(int(level))
		var should_use_fallback: bool = pool_size < target_count
		if bool(level_report.get("used_fallback", false)) != should_use_fallback:
			return _fail("El indicador fallback no coincide con disponibilidad real.")
		if not should_use_fallback:
			continue

		var usage_value: Variant = level_report.get("usage_counts", {})
		var repeated_value: Variant = level_report.get("repeated", {})
		if not (usage_value is Dictionary) or not (repeated_value is Dictionary):
			return _fail("Fallback no registro uso/repeticiones.")
		var usage_counts: Dictionary = usage_value
		var repeated: Dictionary = repeated_value
		if usage_counts.size() != pool_size or repeated.is_empty():
			return _fail("Fallback no registro correctamente los recursos repetidos.")

		var minimum_count: int = target_count
		var maximum_count: int = 0
		for count_value in usage_counts.values():
			var count: int = int(count_value)
			minimum_count = mini(minimum_count, count)
			maximum_count = maxi(maximum_count, count)
		if maximum_count - minimum_count > 1:
			return _fail("Fallback distribuyo repeticiones de forma desequilibrada.")

	print("Fallback Alpha por nivel: repeticiones uniformes y registradas: OK")
	return true

func _test_one_hundred_seeds_level_integrity() -> bool:
	for seed_offset in range(100):
		var seed_value: int = 40000 + seed_offset
		var session := KarmanyMap41ContentGenerator.generate(seed_value, pools)
		var board := _build_empty_canonical_board()
		if session == null or board == null or not session.apply_public_state(board):
			return _fail("Seed %d no pudo preparar BoardState." % seed_value)
		if board.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
			return _fail("Seed %d altero la geometria de 41 posiciones." % seed_value)

		if not _validate_fixed_tiles(board):
			return _fail("Seed %d altero Iniciales o Legendaria." % seed_value)

		var revealed_counts: Dictionary = {
			KarmanyTileData.TileLevel.N1: 0,
			KarmanyTileData.TileLevel.N2: 0,
			KarmanyTileData.TileLevel.N3: 0
		}
		for level in [KarmanyTileData.TileLevel.N1, KarmanyTileData.TileLevel.N2, KarmanyTileData.TileLevel.N3]:
			for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
				if board.get_tile_data(coord) != null or board.is_revealed(coord):
					return _fail("Seed %d expuso una identidad antes de explorar." % seed_value)
				if not session.reveal_into_board_state(board, coord):
					return _fail("Seed %d no pudo revelar %s." % [seed_value, coord])
				var tile := board.get_tile_data(coord)
				if tile == null or tile.level != level:
					return _fail("Seed %d asigno contenido a nivel incorrecto." % seed_value)
				revealed_counts[level] = int(revealed_counts[level]) + 1

		if int(revealed_counts[KarmanyTileData.TileLevel.N1]) != 18:
			return _fail("Seed %d no lleno 18 N1." % seed_value)
		if int(revealed_counts[KarmanyTileData.TileLevel.N2]) != 12:
			return _fail("Seed %d no lleno 12 N2." % seed_value)
		if int(revealed_counts[KarmanyTileData.TileLevel.N3]) != 6:
			return _fail("Seed %d no lleno 6 N3." % seed_value)

	print("100 seeds: niveles correctos, 18 N1 + 12 N2 + 6 N3, I/L fijas y geometria intacta: OK")
	return true

func _validate_fixed_tiles(board: KarmanyBoardState) -> bool:
	var starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	var expected_ids: Array[String] = ["I-01", "I-02", "I-03", "I-04"]
	for index in range(starts.size()):
		var tile := board.get_tile_data(starts[index])
		if tile == null or tile.level != KarmanyTileData.TileLevel.START:
			return false
		if tile.tile_id != expected_ids[index] or not board.is_revealed(starts[index]):
			return false
	var legendary := board.get_tile_data(KarmanyCanonicalMap41Layout.LEGENDARY_COORD)
	return (
		legendary != null
		and legendary.tile_id == "L-01"
		and legendary.level == KarmanyTileData.TileLevel.SANCTUARY
		and board.is_revealed(KarmanyCanonicalMap41Layout.LEGENDARY_COORD)
	)

func _test_visual_probe() -> bool:
	var prototype := PHASE_32_SCENE.instantiate() as KarmanyPhase32RandomMapBridge
	if prototype == null:
		return _fail("No se pudo instanciar la escena visual de Fase 32.")
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame

	var ok: bool = true
	if not prototype.setup_ok:
		ok = _fail("La escena visual de Fase 32 no completo setup.")
	else:
		var first_fingerprint: String = prototype.get_assignment_fingerprint()
		if first_fingerprint.is_empty():
			ok = _fail("La escena visual no expone fingerprint diagnostico.")
		elif not prototype.set_seed_and_regenerate(32002):
			ok = _fail("La escena visual no pudo regenerar con otra seed.")
		elif first_fingerprint == prototype.get_assignment_fingerprint():
			ok = _fail("La escena visual no cambio distribucion al cambiar seed.")
		else:
			var target_coord: Vector2i = KarmanyCanonicalMap41Layout.get_coords_for_level(KarmanyTileData.TileLevel.N1)[0]
			if prototype.phase_31.board_state.get_tile_data(target_coord) != null:
				ok = _fail("La escena visual expuso identidad N1 antes de explorar.")
			elif not prototype.reveal_coord(target_coord):
				ok = _fail("La escena visual no pudo revelar una N1 seleccionable.")
			elif prototype.phase_31.board_state.get_tile_data(target_coord) == null:
				ok = _fail("Explorar visual no materializo contenido publico.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("Probe F6: regeneracion por seed + ocultamiento + revelado visual: OK")
	return ok

func _build_empty_canonical_board() -> KarmanyBoardState:
	var board := KarmanyBoardState.new()
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		if not board.add_cell(coord, null, false):
			return null
	return board

func _fail(message: String) -> bool:
	push_error("FASE 32 ERROR: %s" % message)
	return false
