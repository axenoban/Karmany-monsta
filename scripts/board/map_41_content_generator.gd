class_name KarmanyMap41ContentGenerator
extends RefCounted

const I01: KarmanyTileData = preload("res://data/tiles/i_01_refugio_valle_jade.tres")
const I02: KarmanyTileData = preload("res://data/tiles/i_02_campamento_rio_bruma.tres")
const I03: KarmanyTileData = preload("res://data/tiles/i_03_puesto_rocoso.tres")
const I04: KarmanyTileData = preload("res://data/tiles/i_04_sendero_primer_vinculo.tres")
const L01: KarmanyTileData = preload("res://data/tiles/l_01_santuario_de_aeterna.tres")

static func generate(
	match_seed: int,
	pools: KarmanyMap41TilePools,
	log_fallback: bool = true
) -> KarmanyMap41ContentSession:
	if pools == null or not pools.loaded:
		return null

	var hidden_content: Dictionary = {}
	var fallback_reports: Dictionary = {}
	for level in [KarmanyTileData.TileLevel.N1, KarmanyTileData.TileLevel.N2, KarmanyTileData.TileLevel.N3]:
		var coords := KarmanyCanonicalMap41Layout.get_coords_for_level(level)
		var pool := pools.get_pool(level)
		if pool.is_empty() or coords.is_empty():
			return null

		var rng := RandomNumberGenerator.new()
		rng.seed = _derive_level_seed(match_seed, level)
		var generated := _generate_level(pool, coords.size(), rng)
		var tiles: Array = generated.get("tiles", [])
		if tiles.size() != coords.size():
			return null

		for index in range(coords.size()):
			var tile := tiles[index] as KarmanyTileData
			if tile == null or tile.level != level:
				return null
			hidden_content[coords[index]] = tile

		fallback_reports[level] = generated
		if log_fallback and bool(generated.get("used_fallback", false)):
			print(
				"FASE 32 ALPHA TILE POOL FALLBACK ",
				KarmanyCanonicalMap41Layout.get_level_short_name(level),
				" | pool ", pool.size(),
				" -> slots ", coords.size(),
				" | repetidos ", generated.get("repeated", {})
			)

	var fixed_content := _build_fixed_content()
	var session := KarmanyMap41ContentSession.new()
	if not session.configure(match_seed, hidden_content, fixed_content, fallback_reports):
		return null
	return session

static func _generate_level(
	pool: Array[KarmanyTileData],
	target_count: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	if pool.size() < target_count:
		return KarmanyAlphaTilePoolFallback.build_balanced(pool, target_count, rng)

	var shuffled := KarmanyAlphaTilePoolFallback.shuffled_copy(pool, rng)
	var selected: Array[KarmanyTileData] = []
	var usage_counts: Dictionary = {}
	for index in range(target_count):
		var tile: KarmanyTileData = shuffled[index]
		selected.append(tile)
		usage_counts[tile.tile_id] = 1
	return {
		"tiles": selected,
		"usage_counts": usage_counts,
		"repeated": {},
		"used_fallback": false
	}

static func _build_fixed_content() -> Dictionary:
	var starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	if starts.size() != 4:
		return {}
	return {
		starts[0]: I01,
		starts[1]: I02,
		starts[2]: I03,
		starts[3]: I04,
		KarmanyCanonicalMap41Layout.LEGENDARY_COORD: L01
	}

static func _derive_level_seed(match_seed: int, level: int) -> int:
	return match_seed + (level + 1) * 1000003 + 32000000
