extends Node


const TEST_SEEDS = [40001, 40017, 40103, 40211, 40999]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 40 MAP41 CONTENT TEST")
	print("================================")

	var ok: bool = true
	ok = _test_geometry() and ok
	ok = _test_catalog_and_materialized_content() and ok
	ok = _test_pools_and_fallback() and ok
	ok = _test_seed_determinism_and_effective_variety() and ok
	ok = _test_hidden_privacy_and_public_reveal() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 40 OK - catalogo MAP41 auditado, fallback medido, seeds y privacidad validados.")
	else:
		push_error("FASE 40 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_geometry() -> bool:
	var level_map: Dictionary = KarmanyCanonicalMap41Layout.build_level_map()
	if level_map.size() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("La geometria no contiene 41 posiciones.")
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		return _fail("La geometria canonica de 41 posiciones no esta conectada.")

	var counts: Dictionary = {}
	for level_value in level_map.values():
		var level: int = int(level_value)
		counts[level] = int(counts.get(level, 0)) + 1
	if int(counts.get(KarmanyTileData.TileLevel.START, 0)) != 4:
		return _fail("La geometria no contiene exactamente 4 posiciones iniciales.")
	if int(counts.get(KarmanyTileData.TileLevel.N1, 0)) != 18:
		return _fail("La geometria no contiene exactamente 18 posiciones N1.")
	if int(counts.get(KarmanyTileData.TileLevel.N2, 0)) != 12:
		return _fail("La geometria no contiene exactamente 12 posiciones N2.")
	if int(counts.get(KarmanyTileData.TileLevel.N3, 0)) != 6:
		return _fail("La geometria no contiene exactamente 6 posiciones N3.")
	if int(counts.get(KarmanyTileData.TileLevel.SANCTUARY, 0)) != 1:
		return _fail("La geometria no contiene exactamente 1 posicion Legendaria.")
	if int(level_map.get(Vector2i.ZERO, -1)) != KarmanyTileData.TileLevel.SANCTUARY:
		return _fail("El centro del mapa dejo de ser la posicion Legendaria.")

	var expected_starts: Array[Vector2i] = [
		Vector2i(4, -2),
		Vector2i(-1, 4),
		Vector2i(-4, 2),
		Vector2i(1, -4)
	]
	var actual_starts: Array[Vector2i] = KarmanyCanonicalMap41Layout.get_start_coords()
	if actual_starts != expected_starts:
		return _fail("Las cuatro posiciones iniciales cambiaron respecto al baseline aprobado.")
	return true


func _test_catalog_and_materialized_content() -> bool:
	if KarmanyV074CanonicalRuntimeCatalog.TILE_IDS.size() != 41:
		return _fail("El catalogo canonico v0.74 no declara exactamente 41 IDs de loseta.")

	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("No se pudieron cargar los pools de loseta.")
	var inventory: Dictionary = KarmanyMap41ContentAudit.build_inventory(pools)
	if int(inventory.get("canonical_id_count", 0)) != 41:
		return _fail("La auditoria F40 no reconoce las 41 identidades esperadas.")
	if int(inventory.get("materialized_count", 0)) != KarmanyMap41ContentAudit.count_tile_resource_files():
		return _fail("Existe un .tres de loseta que el catalogo no pudo materializar como KarmanyTileData.")
	if int(inventory.get("incomplete_count", -1)) != 0:
		return _fail("Existe al menos una identidad materializada con informacion obligatoria incompleta.")

	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEEDS[0]):
		return _fail("No se pudo configurar runtime para validar interpretacion F39.")
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		return _fail("FullMatchSession rechazo contenido durante la auditoria F40.")
	if session.universal_tile_interactions == null:
		return _fail("F39 no expuso su servicio universal de Interactuar.")

	var seen_ids: Dictionary = {}
	for tile in KarmanyPhase37AlphaContentCatalog.get_tiles():
		if tile == null:
			return _fail("El catalogo F37 devolvio una loseta nula.")
		if seen_ids.has(tile.tile_id):
			return _fail("tile_id materializado duplicado: %s." % tile.tile_id)
		seen_ids[tile.tile_id] = true
		var issues: PackedStringArray = KarmanyMap41ContentAudit.get_definition_issues(tile)
		if not issues.is_empty():
			return _fail("%s incompleta: %s" % [tile.tile_id, " / ".join(issues)])
		if not session.universal_tile_interactions.is_tile_definition_valid(tile):
			return _fail("F39 no puede interpretar el Uso posterior de %s." % tile.tile_id)

	var rows_value: Variant = inventory.get("levels", {})
	if not (rows_value is Dictionary):
		return _fail("La auditoria F40 no produjo filas por nivel.")
	var rows: Dictionary = rows_value
	for level in [
		KarmanyTileData.TileLevel.START,
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3,
		KarmanyTileData.TileLevel.SANCTUARY
	]:
		var row_value: Variant = rows.get(level, {})
		if not (row_value is Dictionary):
			return _fail("Falta fila de auditoria para nivel %d." % level)
		var row: Dictionary = row_value
		print(
			"F40 AUDIT | %s | materializadas=%d/%d | pendientes=%d | fallback=%s | repeticiones_minimas=%d"
			% [
				String(row.get("label", "?")),
				int(row.get("materialized_count", 0)),
				int(row.get("expected_count", 0)),
				int(row.get("pending_count", 0)),
				str(bool(row.get("fallback_required", false))),
				int(row.get("minimum_repeated_placements", 0))
			]
		)
	return true


func _test_pools_and_fallback() -> bool:
	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("No se pudieron cargar pools para validar fallback.")
	var seen_global: Dictionary = {}
	for level in [
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3
	]:
		var pool: Array[KarmanyTileData] = pools.get_pool(level)
		var expected_ids: PackedStringArray = KarmanyMap41ContentAudit.get_expected_ids_for_level(level)
		if pool.is_empty():
			return _fail("Pool %s vacio." % KarmanyMap41ContentAudit.get_level_label(level))
		for tile in pool:
			if tile == null:
				return _fail("Pool contiene Resource nulo.")
			if tile.level != level:
				return _fail("Contaminacion de nivel en pool %s: %s." % [KarmanyMap41ContentAudit.get_level_label(level), tile.tile_id])
			if not expected_ids.has(tile.tile_id):
				return _fail("Pool utiliza ID canonico inexistente para su nivel: %s." % tile.tile_id)
			if seen_global.has(tile.tile_id):
				return _fail("Una identidad aparece en mas de un pool: %s." % tile.tile_id)
			seen_global[tile.tile_id] = level

		var target_count: int = KarmanyMap41ContentAudit.get_target_slot_count(level)
		var rng := RandomNumberGenerator.new()
		rng.seed = 400000 + level
		var fallback: Dictionary = KarmanyAlphaTilePoolFallback.build_balanced(
			pool,
			target_count,
			rng
		)
		var generated_value: Variant = fallback.get("tiles", [])
		if not (generated_value is Array) or generated_value.size() != target_count:
			return _fail("Fallback no cubrio todos los slots de %s." % KarmanyMap41ContentAudit.get_level_label(level))
		if bool(fallback.get("used_fallback", false)) != (pool.size() < target_count):
			return _fail("Reporte used_fallback inconsistente en %s." % KarmanyMap41ContentAudit.get_level_label(level))
		for tile_value in generated_value:
			var generated_tile := tile_value as KarmanyTileData
			if generated_tile == null or generated_tile.level != level:
				return _fail("Fallback mezclo niveles en %s." % KarmanyMap41ContentAudit.get_level_label(level))

	# Fixture estructural aislado: demuestra que F32 sigue pudiendo cubrir mas
	# slots que identidades sin declarar una nueva loseta canonica ejecutable.
	var tiny_pool: Array[KarmanyTileData] = [pools.get_pool(KarmanyTileData.TileLevel.N1)[0]]
	var tiny_rng := RandomNumberGenerator.new()
	tiny_rng.seed = 404040
	var tiny_result: Dictionary = KarmanyAlphaTilePoolFallback.build_balanced(
		tiny_pool,
		3,
		tiny_rng
	)
	var tiny_tiles_value: Variant = tiny_result.get("tiles", [])
	if not bool(tiny_result.get("used_fallback", false)):
		return _fail("El fallback F32 dejo de activarse con pool menor que slots.")
	if not (tiny_tiles_value is Array) or tiny_tiles_value.size() != 3:
		return _fail("El fallback F32 no completo el fixture de 3 slots.")
	return true


func _test_seed_determinism_and_effective_variety() -> bool:
	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("No se pudieron cargar pools para pruebas de seed.")

	var fingerprints: Dictionary = {}
	for seed_value in TEST_SEEDS:
		var first := KarmanyMap41ContentGenerator.generate(seed_value, pools, false)
		var second := KarmanyMap41ContentGenerator.generate(seed_value, pools, false)
		if first == null or second == null:
			return _fail("Seed %d no pudo generar contenido MAP41." % seed_value)
		var first_fingerprint: String = first.get_assignment_fingerprint()
		var second_fingerprint: String = second.get_assignment_fingerprint()
		if first_fingerprint.is_empty() or first_fingerprint != second_fingerprint:
			return _fail("Seed %d no es determinista." % seed_value)
		fingerprints[first_fingerprint] = true
		if first.get_hidden_slot_count() != 36:
			return _fail("Seed %d no genero 36 slots ocultos N1+N2+N3." % seed_value)

		var report: Dictionary = first.get_fallback_report()
		for level in [
			KarmanyTileData.TileLevel.N1,
			KarmanyTileData.TileLevel.N2,
			KarmanyTileData.TileLevel.N3
		]:
			var level_report_value: Variant = report.get(level, {})
			if not (level_report_value is Dictionary):
				return _fail("Seed %d carece de reporte para nivel %d." % [seed_value, level])
			var level_report: Dictionary = level_report_value
			var target: int = KarmanyMap41ContentAudit.get_target_slot_count(level)
			var pool_size: int = pools.get_pool_size(level)
			if int(level_report.get("target_count", 0)) != target:
				return _fail("Seed %d altero conteo estructural de %s." % [seed_value, KarmanyMap41ContentAudit.get_level_label(level)])
			if int(level_report.get("pool_size", 0)) != pool_size:
				return _fail("Seed %d reporto un pool_size incoherente." % seed_value)
			var usage_value: Variant = level_report.get("usage_counts", {})
			if pool_size < target:
				if not bool(level_report.get("used_fallback", false)):
					return _fail("Seed %d no activo fallback requerido en %s." % [seed_value, KarmanyMap41ContentAudit.get_level_label(level)])
				if not (usage_value is Dictionary) or usage_value.size() != pool_size:
					return _fail("Seed %d no utilizo toda la variedad real disponible de %s." % [seed_value, KarmanyMap41ContentAudit.get_level_label(level)])

	if fingerprints.size() < 2:
		return _fail("Seeds distintas no produjeron ninguna distribucion valida diferente.")
	print("F40 VARIEDAD | seeds=%d | fingerprints_distintos=%d" % [TEST_SEEDS.size(), fingerprints.size()])
	return true


func _test_hidden_privacy_and_public_reveal() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, 40808):
		return _fail("No se pudo configurar runtime para prueba de privacidad.")
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		return _fail("No se pudo configurar F39 para prueba de privacidad F40.")
	var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if player == null:
		return _fail("Jugador humano inexistente en prueba de privacidad.")

	var hidden_coord: Vector2i = _first_hidden_coord(runtime)
	if hidden_coord == Vector2i(999, 999):
		return _fail("No se encontro una posicion N1/N2/N3 oculta.")
	if runtime.get_public_tile_data(hidden_coord) != null:
		return _fail("Una posicion oculta expuso KarmanyTileData antes de Explorar.")
	if runtime.board_state.get_tile_data(hidden_coord) != null:
		return _fail("BoardState contiene identidad privada antes de revelar.")
	var public_snapshot: Dictionary = runtime.get_public_ai_snapshot(hidden_coord)
	if public_snapshot.has("tile_id") or public_snapshot.has("display_name"):
		return _fail("Snapshot publico de posicion oculta filtro identidad o nombre.")
	if int(public_snapshot.get("level", -1)) < KarmanyTileData.TileLevel.N1:
		return _fail("La posicion oculta perdio su nivel estructural publico.")

	var hidden_preview: Dictionary = session.universal_tile_interactions.get_public_preview(
		player,
		hidden_coord
	)
	if bool(hidden_preview.get("visible", true)):
		return _fail("Preview F39 marco como visible una posicion oculta.")
	if String(hidden_preview.get("interaction_text", "")) != "OCULTA":
		return _fail("Preview F39 filtro el Uso posterior antes de revelar.")
	if hidden_preview.has("tile_id"):
		return _fail("Preview F39 filtro tile_id antes de revelar.")

	if not runtime.content_session.reveal_into_board_state(
		runtime.board_state,
		hidden_coord
	):
		return _fail("No se pudo revelar la posicion mediante ContentSession.")
	var revealed_tile: KarmanyTileData = runtime.get_public_tile_data(hidden_coord)
	if revealed_tile == null:
		return _fail("La posicion revelada no expuso su identidad publica.")
	if revealed_tile.level != runtime.get_public_level(hidden_coord):
		return _fail("La identidad revelada no coincide con el nivel estructural.")
	if not session.universal_tile_interactions.is_tile_definition_valid(revealed_tile):
		return _fail("La identidad revelada no es interpretable por F39.")
	var revealed_preview: Dictionary = session.universal_tile_interactions.get_public_preview(
		player,
		hidden_coord
	)
	if not bool(revealed_preview.get("visible", false)):
		return _fail("Preview no hizo publica la loseta despues de revelarla.")
	if String(revealed_preview.get("interaction_text", "")) != revealed_tile.later_use_text:
		return _fail("Preview revelado no coincide con later_use_text canonico.")
	return true


func _first_hidden_coord(runtime: KarmanyMultiAiAlphaRuntime) -> Vector2i:
	for level in [
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3
	]:
		for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
			if runtime.board_state.has_coord(coord) and not runtime.board_state.is_revealed(coord):
				return coord
	return Vector2i(999, 999)


func _fail(message: String) -> bool:
	push_error("FASE 40 TEST ERROR: %s" % message)
	return false
