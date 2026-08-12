class_name KarmanyPvpAuthorizationContext
extends RefCounted


enum RangeMode {
	SAME_TILE,
	ADJACENT,
	SAME_OR_ADJACENT,
	CUSTOM
}


var source_id: StringName = &""
var range_mode: RangeMode = RangeMode.SAME_OR_ADJACENT
var custom_range_handler: Callable = Callable()


func is_valid() -> bool:
	if source_id == &"":
		return false
	if range_mode == RangeMode.CUSTOM:
		return custom_range_handler.is_valid()
	return true


func is_target_in_range(
	board_state: KarmanyBoardState,
	attacker_coord: Vector2i,
	defender_coord: Vector2i
) -> bool:
	if not is_valid() or board_state == null:
		return false
	if not board_state.has_coord(attacker_coord):
		return false
	if not board_state.has_coord(defender_coord):
		return false

	match range_mode:
		RangeMode.SAME_TILE:
			return attacker_coord == defender_coord
		RangeMode.ADJACENT:
			return board_state.are_existing_coords_adjacent(
				attacker_coord,
				defender_coord
			)
		RangeMode.SAME_OR_ADJACENT:
			return (
				attacker_coord == defender_coord
				or board_state.are_existing_coords_adjacent(
					attacker_coord,
					defender_coord
				)
			)
		RangeMode.CUSTOM:
			var custom_result: Variant = custom_range_handler.call(
				board_state,
				attacker_coord,
				defender_coord
			)
			if custom_result is bool:
				return bool(custom_result)

	return false
