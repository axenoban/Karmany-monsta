class_name KarmanyBoardCellState
extends RefCounted


var coord: Vector2i
var tile_data: KarmanyTileData
var revealed: bool
var occupying_unit_id: StringName = &""
var beast_state: KarmanyBeastRuntimeState = null


func _init(
	p_coord: Vector2i,
	p_tile_data: KarmanyTileData = null,
	p_revealed: bool = false
) -> void:
	coord = p_coord
	tile_data = p_tile_data
	revealed = p_revealed


func is_occupied() -> bool:
	return occupying_unit_id != &""


func has_beast() -> bool:
	return beast_state != null and beast_state.is_blocking()


func is_blocked_by_beast() -> bool:
	return has_beast()
