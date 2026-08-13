extends Node

const PHASE_31_SCENE: PackedScene = preload("res://scenes/ui/phase_31_map_41_prototype.tscn")

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 31 MAPA 41 TEST")
	print("================================")

	var ok: bool = true
	ok = _test_total_and_level_counts() and ok
	ok = _test_connectivity() and ok
	ok = _test_starting_positions() and ok
	ok = _test_legendary_center() and ok
	ok = _test_hidden_level_structure() and ok
	ok = await _test_visual_map_and_camera() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 31 OK - Mapa canonico de 41 posiciones validado.")
	else:
		push_error("FASE 31 ERROR - Revisar geometria, visual o camara.")
	print("================================")

func _test_total_and_level_counts() -> bool:
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	if levels.size() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("El mapa no contiene exactamente 41 posiciones.")

	var counts := KarmanyCanonicalMap41Layout.get_level_counts()
	var expected: Dictionary = {
		KarmanyTileData.TileLevel.START: KarmanyCanonicalMap41Layout.START_COUNT,
		KarmanyTileData.TileLevel.N1: KarmanyCanonicalMap41Layout.N1_COUNT,
		KarmanyTileData.TileLevel.N2: KarmanyCanonicalMap41Layout.N2_COUNT,
		KarmanyTileData.TileLevel.N3: KarmanyCanonicalMap41Layout.N3_COUNT,
		KarmanyTileData.TileLevel.SANCTUARY: KarmanyCanonicalMap41Layout.LEGENDARY_COUNT
	}
	for level in expected.keys():
		if int(counts.get(level, -1)) != int(expected[level]):
			return _fail("Conteo incorrecto para nivel %s." % KarmanyCanonicalMap41Layout.get_level_short_name(int(level)))

	print("41 posiciones + conteos I4/N1-18/N2-12/N3-6/L1: OK")
	return true

func _test_connectivity() -> bool:
	if not KarmanyCanonicalMap41Layout.is_connected():
		return _fail("La geometria no forma un unico mapa conectado.")
	print("Conectividad por lados completos desde centro hasta Iniciales: OK")
	return true

func _test_starting_positions() -> bool:
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	var starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	if starts.size() != KarmanyCanonicalMap41Layout.START_COUNT:
		return _fail("Deben existir exactamente cuatro posiciones Iniciales.")

	var seen: Dictionary = {}
	for start_coord in starts:
		if seen.has(start_coord):
			return _fail("Hay posiciones Iniciales duplicadas.")
		seen[start_coord] = true
		if KarmanyHexGridMath.distance(Vector2i.ZERO, start_coord) != 4:
			return _fail("Una Inicial no esta fuera del anillo N1.")
		if int(levels.get(start_coord, -1)) != KarmanyTileData.TileLevel.START:
			return _fail("Una coordenada Inicial no esta marcada como START.")

		var touches_n1: bool = false
		for neighbor in KarmanyHexGridMath.get_neighbors(start_coord):
			if int(levels.get(neighbor, -1)) == KarmanyTileData.TileLevel.N1:
				touches_n1 = true
				break
		if not touches_n1:
			return _fail("Una Inicial externa no conecta directamente con N1.")

	if starts[0] + starts[2] != Vector2i.ZERO:
		return _fail("El primer par de Iniciales no esta equilibrado.")
	if starts[1] + starts[3] != Vector2i.ZERO:
		return _fail("El segundo par de Iniciales no esta equilibrado.")

	print("Cuatro Iniciales externas, distintas, conectadas y equilibradas: OK")
	return true

func _test_legendary_center() -> bool:
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	if int(levels.get(Vector2i.ZERO, -1)) != KarmanyTileData.TileLevel.SANCTUARY:
		return _fail("El centro (0,0) no es Legendario.")
	if KarmanyCanonicalMap41Layout.get_coords_for_level(KarmanyTileData.TileLevel.SANCTUARY).size() != 1:
		return _fail("Debe existir un unico centro Legendario.")
	print("Centro Legendario unico en (0,0): OK")
	return true

func _test_hidden_level_structure() -> bool:
	var board_state := KarmanyBoardState.new()
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		var level: int = int(levels[coord])
		var revealed: bool = (
			level == KarmanyTileData.TileLevel.START
			or level == KarmanyTileData.TileLevel.SANCTUARY
		)
		if not board_state.add_cell(coord, null, revealed):
			return _fail("No se pudo materializar una posicion en BoardState.")

	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		var level: int = int(levels[coord])
		if level == KarmanyTileData.TileLevel.N1 or level == KarmanyTileData.TileLevel.N2 or level == KarmanyTileData.TileLevel.N3:
			if board_state.is_revealed(coord):
				return _fail("Un slot N1/N2/N3 fue revelado antes de asignar contenido.")

	print("N1/N2/N3 conservan contenido oculto con nivel estructural conocido: OK")
	return true

func _test_visual_map_and_camera() -> bool:
	var prototype := PHASE_31_SCENE.instantiate() as KarmanyPhase31Map41Bridge
	if prototype == null:
		return _fail("No se pudo instanciar la escena visual de Fase 31.")

	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame

	var ok: bool = true
	if not prototype.setup_ok:
		ok = _fail("La escena visual no completo su setup.")
	elif prototype.board_state.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		ok = _fail("BoardState visual no contiene 41 posiciones.")
	elif prototype.get_visual_tile_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		ok = _fail("No se generaron 41 losetas visuales.")
	elif not prototype.camera_controller.is_configured():
		ok = _fail("La camara estrategica no quedo configurada.")
	elif prototype.camera_controller.get_max_distance() < 20.0:
		ok = _fail("El zoom maximo sigue dimensionado para el prototipo pequeno.")
	elif not KarmanyCanonicalMap41Layout.get_starting_coords().has(prototype.player_state.current_coord):
		ok = _fail("El entrenador de prueba no aparece en una Inicial externa.")
	else:
		var bounds := prototype.camera_controller.get_bounds()
		if bounds.size.x < 12.0 or bounds.size.y < 13.0:
			ok = _fail("Los limites de camara no abarcan el mapa completo.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("41 losetas visuales + entrenador externo + camara y bounds dinamicos: OK")
	return ok

func _fail(message: String) -> bool:
	push_error("FASE 31 ERROR: %s" % message)
	return false
