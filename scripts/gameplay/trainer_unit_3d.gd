class_name KarmanyTrainerUnit3D
extends Node3D


var player_state: KarmanyPlayerState = null
var unit_id: StringName = &""


func configure(
	p_player_state: KarmanyPlayerState,
	p_unit_id: StringName
) -> bool:
	if p_player_state == null or p_unit_id == &"":
		return false

	player_state = p_player_state
	unit_id = p_unit_id
	return true


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
	return snap_visual_to(anchor)


func snap_visual_to(
	anchor: Marker3D,
	visual_offset: Vector3 = Vector3.ZERO
) -> bool:
	# Presentation-only placement. This method never changes PlayerState and
	# allows visual interpolation/offsets to observe gameplay without governing it.
	if anchor == null:
		return false

	global_position = anchor.global_position + visual_offset
	global_rotation = Vector3.ZERO
	return true
