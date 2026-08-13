class_name KarmanyMap41ContentSession
extends RefCounted

var match_seed: int = 0
var _hidden_content: Dictionary = {}
var _fixed_content: Dictionary = {}
var _fallback_reports: Dictionary = {}
var configured: bool = false

func configure(
	seed_value: int,
	hidden_content: Dictionary,
	fixed_content: Dictionary,
	fallback_reports: Dictionary
) -> bool:
	match_seed = seed_value
	_hidden_content = hidden_content.duplicate()
	_fixed_content = fixed_content.duplicate()
	_fallback_reports = fallback_reports.duplicate(true)
	configured = _validate_assignments()
	return configured

func apply_public_state(board_state: KarmanyBoardState) -> bool:
	if not configured or board_state == null:
		return false
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		if not board_state.has_coord(coord):
			return false
		var level: int = int(levels[coord])
		if level == KarmanyTileData.TileLevel.START or level == KarmanyTileData.TileLevel.SANCTUARY:
			var fixed_tile := _fixed_content.get(coord) as KarmanyTileData
			if fixed_tile == null:
				return false
			if not board_state.set_tile_data(coord, fixed_tile):
				return false
			if not board_state.set_revealed(coord, true):
				return false
		else:
			if not board_state.set_tile_data(coord, null):
				return false
			if not board_state.set_revealed(coord, false):
				return false
	return true

func reveal_into_board_state(
	board_state: KarmanyBoardState,
	coord: Vector2i
) -> bool:
	if not configured or board_state == null or not board_state.has_coord(coord):
		return false
	var structural_level: int = KarmanyCanonicalMap41Layout.build_level_map().get(coord, -1)
	if (
		structural_level != KarmanyTileData.TileLevel.N1
		and structural_level != KarmanyTileData.TileLevel.N2
		and structural_level != KarmanyTileData.TileLevel.N3
	):
		return false
	if board_state.is_revealed(coord):
		return false

	var tile := _hidden_content.get(coord) as KarmanyTileData
	if tile == null or tile.level != structural_level:
		return false
	if not board_state.set_tile_data(coord, tile):
		return false
	if not board_state.set_revealed(coord, true):
		board_state.set_tile_data(coord, null)
		return false
	return true

func get_public_tile_data(
	board_state: KarmanyBoardState,
	coord: Vector2i
) -> KarmanyTileData:
	if board_state == null or not board_state.has_coord(coord):
		return null
	if not board_state.is_revealed(coord):
		return null
	return board_state.get_tile_data(coord)

func get_assignment_fingerprint() -> String:
	if not configured:
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for level in [KarmanyTileData.TileLevel.N1, KarmanyTileData.TileLevel.N2, KarmanyTileData.TileLevel.N3]:
		for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
			var tile := _hidden_content.get(coord) as KarmanyTileData
			if tile == null:
				return ""
			parts.append("%d,%d=%s" % [coord.x, coord.y, tile.tile_id])
	return "|".join(parts)

func get_fallback_report() -> Dictionary:
	return _fallback_reports.duplicate(true)

func get_hidden_slot_count() -> int:
	return _hidden_content.size()

func _validate_assignments() -> bool:
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	if levels.size() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return false
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		var level: int = int(levels[coord])
		if level == KarmanyTileData.TileLevel.START or level == KarmanyTileData.TileLevel.SANCTUARY:
			var fixed_tile := _fixed_content.get(coord) as KarmanyTileData
			if fixed_tile == null or fixed_tile.level != level:
				return false
		else:
			var hidden_tile := _hidden_content.get(coord) as KarmanyTileData
			if hidden_tile == null or hidden_tile.level != level:
				return false
	return _hidden_content.size() == (
		KarmanyCanonicalMap41Layout.N1_COUNT
		+ KarmanyCanonicalMap41Layout.N2_COUNT
		+ KarmanyCanonicalMap41Layout.N3_COUNT
	)
