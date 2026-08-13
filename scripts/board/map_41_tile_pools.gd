class_name KarmanyMap41TilePools
extends RefCounted

const TILE_DIRECTORY: String = "res://data/tiles"

var _pools: Dictionary = {}
var loaded: bool = false

func load_from_project() -> bool:
	_pools = {
		KarmanyTileData.TileLevel.N1: [],
		KarmanyTileData.TileLevel.N2: [],
		KarmanyTileData.TileLevel.N3: []
	}
	loaded = false

	var directory := DirAccess.open(TILE_DIRECTORY)
	if directory == null:
		push_error("FASE 32 ERROR: No se pudo abrir %s." % TILE_DIRECTORY)
		return false

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()
	for file_name in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var path: String = "%s/%s" % [TILE_DIRECTORY, file_name]
		var tile := ResourceLoader.load(path) as KarmanyTileData
		if tile == null:
			continue
		if not _pools.has(tile.level):
			continue
		var pool: Array = _pools[tile.level]
		pool.append(tile)
		_pools[tile.level] = pool

	for level in [KarmanyTileData.TileLevel.N1, KarmanyTileData.TileLevel.N2, KarmanyTileData.TileLevel.N3]:
		if get_pool(level).is_empty():
			push_error("FASE 32 ERROR: Pool %s sin recursos .tres." % KarmanyCanonicalMap41Layout.get_level_short_name(level))
			return false

	loaded = true
	return true

func get_pool(level: int) -> Array[KarmanyTileData]:
	var result: Array[KarmanyTileData] = []
	var source: Array = _pools.get(level, [])
	for value in source:
		if value is KarmanyTileData:
			result.append(value as KarmanyTileData)
	return result

func get_pool_size(level: int) -> int:
	return get_pool(level).size()

func get_pool_counts() -> Dictionary:
	return {
		KarmanyTileData.TileLevel.N1: get_pool_size(KarmanyTileData.TileLevel.N1),
		KarmanyTileData.TileLevel.N2: get_pool_size(KarmanyTileData.TileLevel.N2),
		KarmanyTileData.TileLevel.N3: get_pool_size(KarmanyTileData.TileLevel.N3)
	}
