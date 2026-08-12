class_name KarmanyBoardState
extends RefCounted


var _cells: Dictionary = {}


func clear() -> void:
	_cells.clear()


func add_cell(
	coord: Vector2i,
	tile_data: KarmanyTileData = null,
	revealed: bool = false
) -> bool:
	if _cells.has(coord):
		return false

	_cells[coord] = KarmanyBoardCellState.new(
		coord,
		tile_data,
		revealed
	)

	return true


func has_coord(coord: Vector2i) -> bool:
	return _cells.has(coord)


func get_cell_count() -> int:
	return _cells.size()


func get_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for coord in _cells.keys():
		result.append(coord)

	return result


func get_cell(coord: Vector2i) -> KarmanyBoardCellState:
	if not _cells.has(coord):
		return null

	return _cells[coord] as KarmanyBoardCellState


func set_tile_data(
	coord: Vector2i,
	tile_data: KarmanyTileData
) -> bool:
	var cell := get_cell(coord)

	if cell == null:
		return false

	cell.tile_data = tile_data
	return true


func get_tile_data(coord: Vector2i) -> KarmanyTileData:
	var cell := get_cell(coord)

	if cell == null:
		return null

	return cell.tile_data


func set_revealed(
	coord: Vector2i,
	value: bool
) -> bool:
	var cell := get_cell(coord)

	if cell == null:
		return false

	cell.revealed = value
	return true


func is_revealed(coord: Vector2i) -> bool:
	var cell := get_cell(coord)

	if cell == null:
		return false

	return cell.revealed


func set_unit_occupant(
	coord: Vector2i,
	unit_id: StringName
) -> bool:
	if unit_id == &"":
		return false

	var cell := get_cell(coord)

	if cell == null:
		return false

	cell.occupying_unit_id = unit_id
	return true


func clear_unit_occupant(coord: Vector2i) -> bool:
	var cell := get_cell(coord)

	if cell == null:
		return false

	cell.occupying_unit_id = &""
	return true


func get_occupying_unit_id(coord: Vector2i) -> StringName:
	var cell := get_cell(coord)

	if cell == null:
		return &""

	return cell.occupying_unit_id


func is_occupied(coord: Vector2i) -> bool:
	var cell := get_cell(coord)

	if cell == null:
		return false

	return cell.is_occupied()


func get_existing_neighbors(
	coord: Vector2i
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if not has_coord(coord):
		return result

	for neighbor in KarmanyHexGridMath.get_neighbors(coord):
		if has_coord(neighbor):
			result.append(neighbor)

	return result


func are_existing_coords_adjacent(
	a: Vector2i,
	b: Vector2i
) -> bool:
	if not has_coord(a) or not has_coord(b):
		return false

	return KarmanyHexGridMath.are_adjacent(a, b)
