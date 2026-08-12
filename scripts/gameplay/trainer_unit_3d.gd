class_name KarmanyTrainerUnit3D
extends Node3D


var player_state: KarmanyPlayerState = null
var unit_id: StringName = &""


func configure(
	p_player_state: KarmanyPlayerState,
	p_unit_id: StringName
) -> void:
	player_state = p_player_state
	unit_id = p_unit_id

	if unit_id != &"":
		name = String(unit_id)


func get_player_id() -> StringName:
	if player_state == null:
		return &""

	return player_state.player_id


func get_coord() -> Vector2i:
	if player_state == null:
		return Vector2i.ZERO

	return player_state.current_coord


func place_at(
	anchor: Marker3D,
	coord: Vector2i
) -> bool:
	if player_state == null or anchor == null:
		return false

	player_state.set_board_position(coord)
	global_position = anchor.global_position
	global_rotation = Vector3.ZERO

	return true
