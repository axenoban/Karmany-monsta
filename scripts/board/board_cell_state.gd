class_name KarmanyBoardCellState
extends RefCounted


var coord: Vector2i
var tile_data: KarmanyTileData
var revealed: bool
var occupying_unit_id: StringName = &""


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
