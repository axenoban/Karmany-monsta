class_name KarmanyCanonicalMap41Layout
extends RefCounted

const TOTAL_CELL_COUNT: int = 41
const START_COUNT: int = 4
const N1_COUNT: int = 18
const N2_COUNT: int = 12
const N3_COUNT: int = 6
const LEGENDARY_COUNT: int = 1
const LEGENDARY_COORD: Vector2i = Vector2i.ZERO

static func get_starting_coords() -> Array[Vector2i]:
	return [
		Vector2i(4, -2),
		Vector2i(-1, 4),
		Vector2i(-4, 2),
		Vector2i(1, -4)
	]

static func build_level_map() -> Dictionary:
	var levels: Dictionary = {}
	levels[LEGENDARY_COORD] = KarmanyTileData.TileLevel.SANCTUARY
	for q in range(-3, 4):
		for r in range(-3, 4):
			var coord := Vector2i(q, r)
			var radius: int = KarmanyHexGridMath.distance(LEGENDARY_COORD, coord)
			match radius:
				1:
					levels[coord] = KarmanyTileData.TileLevel.N3
				2:
					levels[coord] = KarmanyTileData.TileLevel.N2
				3:
					levels[coord] = KarmanyTileData.TileLevel.N1
	for start_coord in get_starting_coords():
		levels[start_coord] = KarmanyTileData.TileLevel.START
	return levels

static func get_coords_for_level(level: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var levels := build_level_map()
	for q in range(-4, 5):
		for r in range(-4, 5):
			var coord := Vector2i(q, r)
			if levels.has(coord) and int(levels[coord]) == level:
				result.append(coord)
	return result

static func get_level_counts() -> Dictionary:
	var counts: Dictionary = {
		KarmanyTileData.TileLevel.START: 0,
		KarmanyTileData.TileLevel.N1: 0,
		KarmanyTileData.TileLevel.N2: 0,
		KarmanyTileData.TileLevel.N3: 0,
		KarmanyTileData.TileLevel.SANCTUARY: 0
	}
	for level_value in build_level_map().values():
		var level: int = int(level_value)
		counts[level] = int(counts.get(level, 0)) + 1
	return counts

static func _compute_full_connectivity() -> bool:
	var levels := build_level_map()
	var pending: Array[Vector2i] = [LEGENDARY_COORD]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current: Vector2i = pending.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		for neighbor in KarmanyHexGridMath.get_neighbors(current):
			if levels.has(neighbor) and not visited.has(neighbor):
				pending.append(neighbor)
	return visited.size() == levels.size()

static func is_fully_connected() -> bool:
	return _compute_full_connectivity()

static func get_level_short_name(level: int) -> String:
	match level:
		KarmanyTileData.TileLevel.START:
			return "I"
		KarmanyTileData.TileLevel.N1:
			return "N1"
		KarmanyTileData.TileLevel.N2:
			return "N2"
		KarmanyTileData.TileLevel.N3:
			return "N3"
		KarmanyTileData.TileLevel.SANCTUARY:
			return "L"
		_:
			return "?"
