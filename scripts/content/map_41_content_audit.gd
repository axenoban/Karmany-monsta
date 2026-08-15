class_name KarmanyMap41ContentAudit
extends RefCounted


const TILE_DIRECTORY: String = "res://data/tiles"


static func get_expected_ids_for_level(level: int) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for id_value in KarmanyV074CanonicalRuntimeCatalog.TILE_IDS:
		var tile_id: String = String(id_value)
		if get_expected_level_for_id(tile_id) == level:
			result.append(tile_id)
	return result


static func get_expected_level_for_id(tile_id: String) -> int:
	if tile_id.begins_with("I-"):
		return KarmanyTileData.TileLevel.START
	if tile_id.begins_with("N1-"):
		return KarmanyTileData.TileLevel.N1
	if tile_id.begins_with("N2-"):
		return KarmanyTileData.TileLevel.N2
	if tile_id.begins_with("N3-"):
		return KarmanyTileData.TileLevel.N3
	if tile_id.begins_with("L-"):
		return KarmanyTileData.TileLevel.SANCTUARY
	return -1


static func get_target_slot_count(level: int) -> int:
	if level == KarmanyTileData.TileLevel.START:
		return KarmanyCanonicalMap41Layout.START_COUNT
	if level == KarmanyTileData.TileLevel.N1:
		return KarmanyCanonicalMap41Layout.N1_COUNT
	if level == KarmanyTileData.TileLevel.N2:
		return KarmanyCanonicalMap41Layout.N2_COUNT
	if level == KarmanyTileData.TileLevel.N3:
		return KarmanyCanonicalMap41Layout.N3_COUNT
	if level == KarmanyTileData.TileLevel.SANCTUARY:
		return KarmanyCanonicalMap41Layout.LEGENDARY_COUNT
	return 0


static func get_level_label(level: int) -> String:
	if level == KarmanyTileData.TileLevel.START:
		return "I"
	if level == KarmanyTileData.TileLevel.N1:
		return "N1"
	if level == KarmanyTileData.TileLevel.N2:
		return "N2"
	if level == KarmanyTileData.TileLevel.N3:
		return "N3"
	if level == KarmanyTileData.TileLevel.SANCTUARY:
		return "L"
	return "?"


static func get_definition_issues(tile: KarmanyTileData) -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray()
	if tile == null:
		issues.append("Resource nulo")
		return issues
	if tile.tile_id.strip_edges().is_empty():
		issues.append("tile_id vacio")
		return issues
	if not KarmanyV074CanonicalRuntimeCatalog.TILE_IDS.has(tile.tile_id):
		issues.append("tile_id no pertenece al catalogo canonico v0.74")
	var expected_level: int = get_expected_level_for_id(tile.tile_id)
	if expected_level < 0 or tile.level != expected_level:
		issues.append("nivel no coincide con tile_id")
	if tile.display_name.strip_edges().is_empty():
		issues.append("display_name vacio")
	if tile.function_tags.is_empty():
		issues.append("function_tags vacio")
	if tile.on_explore_text.strip_edges().is_empty():
		issues.append("on_explore_text vacio")
	if tile.entry_bonus_text.strip_edges().is_empty():
		issues.append("entry_bonus_text vacio")
	if tile.later_use_text.strip_edges().is_empty():
		issues.append("later_use_text vacio")
	if tile.limit_text.strip_edges().is_empty():
		issues.append("limit_text vacio")
	if tile.interaction_profile_id == &"":
		issues.append("interaction_profile_id vacio")
	if not tile.has_universal_interaction_definition():
		issues.append("Uso posterior no cumple contrato universal F39")
	if tile.level == KarmanyTileData.TileLevel.START and not tile.starts_revealed:
		issues.append("loseta inicial no marcada starts_revealed")
	return issues


static func build_inventory(pools: KarmanyMap41TilePools = null) -> Dictionary:
	var tiles: Array[KarmanyTileData] = KarmanyPhase37AlphaContentCatalog.get_tiles()
	var levels: Array[int] = [
		KarmanyTileData.TileLevel.START,
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3,
		KarmanyTileData.TileLevel.SANCTUARY
	]
	var rows: Dictionary = {}
	var complete_total: int = 0
	var incomplete_total: int = 0

	for level in levels:
		var expected_ids: PackedStringArray = get_expected_ids_for_level(level)
		var materialized_ids: PackedStringArray = PackedStringArray()
		var complete_ids: PackedStringArray = PackedStringArray()
		var incomplete_ids: PackedStringArray = PackedStringArray()
		var issues_by_id: Dictionary = {}

		for tile in tiles:
			if tile == null or tile.level != level:
				continue
			materialized_ids.append(tile.tile_id)
			var issues: PackedStringArray = get_definition_issues(tile)
			if issues.is_empty():
				complete_ids.append(tile.tile_id)
				complete_total += 1
			else:
				incomplete_ids.append(tile.tile_id)
				issues_by_id[tile.tile_id] = issues
				incomplete_total += 1

		materialized_ids.sort()
		complete_ids.sort()
		incomplete_ids.sort()
		var pending_ids: PackedStringArray = PackedStringArray()
		for expected_id in expected_ids:
			if not materialized_ids.has(expected_id):
				pending_ids.append(expected_id)

		var target_slots: int = get_target_slot_count(level)
		var pool_size: int = materialized_ids.size()
		if (
			pools != null
			and pools.loaded
			and level in [
				KarmanyTileData.TileLevel.N1,
				KarmanyTileData.TileLevel.N2,
				KarmanyTileData.TileLevel.N3
			]
		):
			pool_size = pools.get_pool_size(level)
		var uses_fallback: bool = (
			level in [
				KarmanyTileData.TileLevel.N1,
				KarmanyTileData.TileLevel.N2,
				KarmanyTileData.TileLevel.N3
			]
			and pool_size < target_slots
		)
		rows[level] = {
			"label": get_level_label(level),
			"target_slots": target_slots,
			"expected_ids": expected_ids,
			"expected_count": expected_ids.size(),
			"materialized_ids": materialized_ids,
			"materialized_count": materialized_ids.size(),
			"complete_ids": complete_ids,
			"complete_count": complete_ids.size(),
			"incomplete_ids": incomplete_ids,
			"incomplete_count": incomplete_ids.size(),
			"issues_by_id": issues_by_id,
			"pending_ids": pending_ids,
			"pending_count": pending_ids.size(),
			"pool_size": pool_size,
			"fallback_required": uses_fallback,
			"minimum_repeated_placements": maxi(target_slots - pool_size, 0) if uses_fallback else 0
		}

	return {
		"canonical_id_count": KarmanyV074CanonicalRuntimeCatalog.TILE_IDS.size(),
		"materialized_count": tiles.size(),
		"complete_count": complete_total,
		"incomplete_count": incomplete_total,
		"pending_count": maxi(
			KarmanyV074CanonicalRuntimeCatalog.TILE_IDS.size() - tiles.size(),
			0
		),
		"levels": rows
	}


static func count_tile_resource_files() -> int:
	var directory := DirAccess.open(TILE_DIRECTORY)
	if directory == null:
		return 0
	var count: int = 0
	for file_name in directory.get_files():
		if file_name.ends_with(".tres"):
			count += 1
	return count
