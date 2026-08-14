class_name KarmanyBoardState
extends RefCounted


var _cells: Dictionary = {}


func clear() -> void:
	_cells.clear()


func add_cell(
	coord: Vector2i,
	tile_data: KarmanyTileData = null,
	revealed: bool = false,
	structural_level: int = -1
) -> bool:
	if _cells.has(coord):
		return false

	_cells[coord] = KarmanyBoardCellState.new(
		coord,
		tile_data,
		revealed,
		structural_level
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
	if cell.structural_level < 0 and tile_data != null:
		cell.structural_level = int(tile_data.level)
	return true


func get_tile_data(coord: Vector2i) -> KarmanyTileData:
	var cell := get_cell(coord)

	if cell == null:
		return null

	return cell.tile_data


func set_structural_level(
	coord: Vector2i,
	level: int
) -> bool:
	var cell := get_cell(coord)
	if cell == null or level < -1:
		return false
	cell.structural_level = level
	return true


func get_structural_level(coord: Vector2i) -> int:
	var cell := get_cell(coord)
	if cell == null:
		return -1
	return cell.structural_level


func has_structural_level(coord: Vector2i) -> bool:
	return get_structural_level(coord) >= 0


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


func set_beast(
	coord: Vector2i,
	beast_state: KarmanyBeastRuntimeState
) -> bool:
	if beast_state == null or not beast_state.is_blocking():
		return false

	var cell := get_cell(coord)
	if cell == null or cell.has_beast():
		return false
	if beast_state.coord != coord:
		return false

	cell.beast_state = beast_state
	return true


func get_beast(coord: Vector2i) -> KarmanyBeastRuntimeState:
	var cell := get_cell(coord)
	if cell == null:
		return null
	if not cell.has_beast():
		return null
	return cell.beast_state


func clear_beast(coord: Vector2i) -> KarmanyBeastRuntimeState:
	var cell := get_cell(coord)
	if cell == null:
		return null

	var previous := cell.beast_state
	cell.beast_state = null
	return previous


func has_beast(coord: Vector2i) -> bool:
	var cell := get_cell(coord)
	return cell != null and cell.has_beast()


func is_blocked_by_beast(coord: Vector2i) -> bool:
	var cell := get_cell(coord)
	return cell != null and cell.is_blocked_by_beast()


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
