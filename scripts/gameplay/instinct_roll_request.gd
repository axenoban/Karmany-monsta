class_name KarmanyInstinctRollRequest
extends RefCounted


var request_id: int = 0
var player_id: StringName = &""
var round_number: int = 0
var actions_remaining: int = 0
var action_type: int = -1
var action_label: String = ""
var target_coord: Vector2i = Vector2i.ZERO

var _resolved: bool = false
var _roll_value: int = 0
var _defense_adjustment: int = 0


func configure(
	p_request_id: int,
	p_player_id: StringName,
	p_round_number: int,
	p_actions_remaining: int,
	p_action_type: int,
	p_action_label: String,
	p_target_coord: Vector2i
) -> bool:
	if request_id != 0 or _resolved or _roll_value != 0:
		return false
	if p_request_id <= 0 or p_player_id == &"" or p_round_number <= 0:
		return false
	if p_actions_remaining <= 0 or p_action_label.is_empty():
		return false
	if not _is_supported_instinct_action(p_action_type):
		return false

	request_id = p_request_id
	player_id = p_player_id
	round_number = p_round_number
	actions_remaining = p_actions_remaining
	action_type = p_action_type
	action_label = p_action_label
	target_coord = p_target_coord
	return true


func is_resolved() -> bool:
	return _resolved


func get_roll_value() -> int:
	return _roll_value


func get_defense_adjustment() -> int:
	return _defense_adjustment


func get_result() -> Dictionary:
	if not _resolved:
		return {}
	return {
		"request_id": request_id,
		"player_id": player_id,
		"round_number": round_number,
		"actions_remaining": actions_remaining,
		"action_type": action_type,
		"action_label": action_label,
		"target_coord": target_coord,
		"roll": _roll_value,
		"defense_adjustment": _defense_adjustment,
	}


func resolve_roll(roll_value: int) -> bool:
	if _resolved or roll_value < 1 or roll_value > 6:
		return false
	_roll_value = roll_value
	_defense_adjustment = KarmanyCombatResolver.get_instinct_adjustment(roll_value)
	_resolved = true
	return true


func _is_supported_instinct_action(value: int) -> bool:
	match value:
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
			return true
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
			return true
	return false
