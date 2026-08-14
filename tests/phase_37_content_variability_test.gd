extends Node


const TEST_SEEDS: Array[int] = [37001, 37017, 37103, 37211]
const CYCLES_PER_SEED: int = 2


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 37 CONTENT / VARIABILITY TEST")
	print("================================")

	var ok: bool = true
	ok = _test_content_inventory() and ok
	ok = _test_runtime_content_connections() and ok
	ok = _test_same_seed_reproducibility() and ok
	ok = _test_multi_seed_variability() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 37 CONTENT OK - catalogo real, privacidad y variabilidad por seed validados.")
	else:
		push_error("FASE 37 CONTENT ERROR - revisar el primer fallo real.")
	print("================================")


func _test_content_inventory() -> bool:
	var inventory: Dictionary = KarmanyPhase37AlphaContentCatalog.build_inventory()
	var expected_existing: Dictionary = {
		"trainers": 8,
		"tiles": 13,
		"karmanys": 13,
		"beasts": 7,
		"equipment": 9,
		"resonances": 13,
		"objectives": 8,
		"missions": 9
	}
	for key in expected_existing.keys():
		var row_value: Variant = inventory.get(key, {})
		if not (row_value is Dictionary):
			return _fail("Inventario sin categoria %s." % key)
		var row: Dictionary = row_value
		if int(row.get("existing", -1)) != int(expected_existing[key]):
			return _fail(
				"Conteo materializado inesperado para %s: %d."
				% [key, int(row.get("existing", -1))]
			)

	var level_counts: Dictionary = {}
	for tile in KarmanyPhase37AlphaContentCatalog.get_tiles():
		level_counts[int(tile.level)] = int(level_counts.get(int(tile.level), 0)) + 1
	var expected_levels: Dictionary = {
		KarmanyTileData.TileLevel.START: 4,
		KarmanyTileData.TileLevel.N1: 4,
		KarmanyTileData.TileLevel.N2: 2,
		KarmanyTileData.TileLevel.N3: 2,
		KarmanyTileData.TileLevel.SANCTUARY: 1
	}
	for level_value in expected_levels.keys():
		if int(level_counts.get(level_value, 0)) != int(expected_levels[level_value]):
			return _fail("Distribucion de losetas materializadas incorrecta en nivel %d." % int(level_value))

	var tile_row: Dictionary = inventory.get("tiles", {})
	if int(tile_row.get("existing", 0)) >= KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("El test esperaba confirmar que el fallback de losetas aun es necesario.")

	print("Inventario real: I=4 N1=4 N2=2 N3=2 L=1 | K=13 B=7 EQ=9 R=13 OP=8 ME=9: OK")
	return true


func _test_runtime_content_connections() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEEDS[0]):
		return _fail("Runtime F37 no pudo configurarse con catalogo real.")

	if runtime.objectives_missions.get_public_objectives().size() != 8:
		return _fail("Runtime no conecto los 8 Objetivos Publicos materializados ejecutables.")
	if runtime.equipment_market.get_visible_count() != KarmanyEquipmentMarket.MARKET_SIZE:
		return _fail("Mercado real no contiene 4 Equipos visibles.")
	if runtime.resonance_deck.get_draw_count() != KarmanyPhase37AlphaContentCatalog.get_runtime_resonances().size():
		return _fail("Mazo de Resonancias no usa el pool seguro real.")

	for player in runtime.local_session.players:
		var own := runtime.get_secret_mission_for_viewer(player.player_id, player.player_id)
		if own == null:
			return _fail("%s no recibio Mision Secreta de setup." % String(player.player_id))
		for other in runtime.local_session.players:
			if other == player:
				continue
			if runtime.get_secret_mission_for_viewer(player.player_id, other.player_id) != null:
				return _fail("%s pudo ver la Mision privada de %s." % [player.player_id, other.player_id])

	if runtime.get_karmany_pool_for_rank(KarmanyData.Rank.N1).is_empty():
		return _fail("No existe pool Karmany N1 seguro conectado.")
	if runtime.beast_decks_by_tier.is_empty():
		return _fail("No se construyo ningun mazo de Bestias desde contenido seguro.")

	var notes: String = "\n".join(runtime.get_alpha_content_notes())
	if not notes.contains("ALPHA TILE POOL FALLBACK"):
		return _fail("Runtime no informa que el fallback de 41 losetas sigue siendo necesario.")

	print("Runtime: 8 Objetivos, Misiones privadas, mercado, Resonancias, Karmanys y Bestias conectados: OK")
	return true


func _test_same_seed_reproducibility() -> bool:
	var first := KarmanyMultiAiAlphaRuntime.new()
	var second := KarmanyMultiAiAlphaRuntime.new()
	if not first.configure_new(4, TEST_SEEDS[1]) or not second.configure_new(4, TEST_SEEDS[1]):
		return _fail("No se pudieron crear dos partidas con la misma seed.")
	if first.content_session.get_assignment_fingerprint() != second.content_session.get_assignment_fingerprint():
		return _fail("Misma seed produce mapas F32 distintos.")
	if _equipment_signature(first) != _equipment_signature(second):
		return _fail("Misma seed produce mercados iniciales distintos.")
	if _mission_signature(first) != _mission_signature(second):
		return _fail("Misma seed produce asignacion de Misiones distinta.")

	print("Misma seed: mapa + mercado + Misiones reproducibles: OK")
	return true


func _test_multi_seed_variability() -> bool:
	var map_signatures: Dictionary = {}
	var equipment_signatures: Dictionary = {}
	var mission_signatures: Dictionary = {}
	var ai_signatures: Dictionary = {}
	var revealed_signatures: Dictionary = {}

	for seed_value in TEST_SEEDS:
		var runtime := KarmanyMultiAiAlphaRuntime.new()
		if not runtime.configure_new(4, seed_value):
			return _fail("Seed %d no pudo configurar runtime." % seed_value)

		map_signatures[runtime.content_session.get_assignment_fingerprint()] = true
		equipment_signatures[_equipment_signature(runtime)] = true
		mission_signatures[_mission_signature(runtime)] = true

		var ai_steps: PackedStringArray = PackedStringArray()
		for _cycle in range(CYCLES_PER_SEED):
			var manager := runtime.local_session.turn_manager
			if manager.get_active_player() == null:
				return _fail("Seed %d perdio jugador activo." % seed_value)
			if runtime.ai_match_controller.is_human_player(manager.get_active_player().player_id):
				if not runtime.simulate_human_probe_turn():
					return _fail("Seed %d no pudo cerrar turno humano probe." % seed_value)

			while manager.is_running and runtime.ai_match_controller.is_ai_player(manager.get_active_player().player_id):
				var ai_id: StringName = manager.get_active_player().player_id
				if not runtime.ai_match_controller.run_current_ai_turn():
					return _fail("Seed %d fallo turno IA %s." % [seed_value, ai_id])
				for diagnostic in runtime.ai_match_controller.last_turn_diagnostics:
					if not bool(diagnostic.get("success", false)):
						continue
					ai_steps.append("%s:%s" % [
						String(ai_id),
						String(diagnostic.get("action_label", ""))
					])

		ai_signatures["|".join(ai_steps)] = true
		revealed_signatures[_revealed_signature(runtime)] = true
		print("Seed %d | mercado=%s | mision=%s | IA=%s | reveladas=%s" % [
			seed_value,
			_equipment_signature(runtime),
			_mission_signature(runtime),
			"|".join(ai_steps),
			_revealed_signature(runtime)
		])

	if map_signatures.size() < 2:
		return _fail("Las seeds no generan variacion de mapa.")

	var secondary_dimensions: int = 0
	if equipment_signatures.size() >= 2:
		secondary_dimensions += 1
	if mission_signatures.size() >= 2:
		secondary_dimensions += 1
	if ai_signatures.size() >= 2:
		secondary_dimensions += 1
	if revealed_signatures.size() >= 2:
		secondary_dimensions += 1
	if secondary_dimensions < 2:
		return _fail("La variabilidad no es significativa fuera del fingerprint del mapa.")

	print("Variabilidad significativa: mapa + %d dimensiones secundarias: OK" % secondary_dimensions)
	return true


func _equipment_signature(runtime: KarmanyMultiAiAlphaRuntime) -> String:
	var ids: PackedStringArray = PackedStringArray()
	for equipment in runtime.equipment_market.get_visible():
		ids.append(String(equipment.equipment_id))
	return ",".join(ids)


func _mission_signature(runtime: KarmanyMultiAiAlphaRuntime) -> String:
	var ids: PackedStringArray = PackedStringArray()
	for player in runtime.local_session.players:
		var mission := runtime.get_secret_mission_for_viewer(player.player_id, player.player_id)
		ids.append(String(mission.mission_id) if mission != null else "-")
	return ",".join(ids)


func _revealed_signature(runtime: KarmanyMultiAiAlphaRuntime) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for coord in runtime.board_state.get_coords():
		if not runtime.board_state.is_revealed(coord):
			continue
		var tile := runtime.get_public_tile_data(coord)
		if tile == null or tile.level == KarmanyTileData.TileLevel.START:
			continue
		parts.append("%s@%d,%d" % [String(tile.tile_id), coord.x, coord.y])
	parts.sort()
	return ";".join(parts)


func _fail(message: String) -> bool:
	push_error("FASE 37 CONTENT TEST ERROR: %s" % message)
	return false
