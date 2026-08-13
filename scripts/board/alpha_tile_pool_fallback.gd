class_name KarmanyAlphaTilePoolFallback
extends RefCounted

static func build_balanced(
	pool: Array[KarmanyTileData],
	target_count: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var result_tiles: Array[KarmanyTileData] = []
	var usage_counts: Dictionary = {}
	if pool.is_empty() or target_count <= 0 or rng == null:
		return {
			"tiles": result_tiles,
			"usage_counts": usage_counts,
			"repeated": {},
			"used_fallback": false
		}

	var cycle: Array[KarmanyTileData] = _copy_pool(pool)
	_shuffle_in_place(cycle, rng)
	for index in range(target_count):
		if index > 0 and index % cycle.size() == 0:
			_shuffle_in_place(cycle, rng)
		var tile: KarmanyTileData = cycle[index % cycle.size()]
		result_tiles.append(tile)
		var tile_id: String = tile.tile_id
		usage_counts[tile_id] = int(usage_counts.get(tile_id, 0)) + 1

	var repeated: Dictionary = {}
	for tile_id in usage_counts.keys():
		var count: int = int(usage_counts[tile_id])
		if count > 1:
			repeated[tile_id] = count

	return {
		"tiles": result_tiles,
		"usage_counts": usage_counts,
		"repeated": repeated,
		"used_fallback": pool.size() < target_count
	}

static func shuffled_copy(
	pool: Array[KarmanyTileData],
	rng: RandomNumberGenerator
) -> Array[KarmanyTileData]:
	var result: Array[KarmanyTileData] = _copy_pool(pool)
	_shuffle_in_place(result, rng)
	return result

static func _copy_pool(pool: Array[KarmanyTileData]) -> Array[KarmanyTileData]:
	var result: Array[KarmanyTileData] = []
	for tile in pool:
		if tile != null:
			result.append(tile)
	return result

static func _shuffle_in_place(
	values: Array[KarmanyTileData],
	rng: RandomNumberGenerator
) -> void:
	if values.size() < 2:
		return
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		if swap_index == index:
			continue
		var temporary: KarmanyTileData = values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary
