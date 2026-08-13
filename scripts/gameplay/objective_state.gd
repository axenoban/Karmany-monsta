class_name KarmanyObjectiveState
extends RefCounted


var objective_data: KarmanyObjectiveData = null
var claimed_by_player_id: StringName = &""
var claimed_round: int = 0


func configure(data: KarmanyObjectiveData) -> bool:
	if data == null or not data.is_valid_definition():
		return false
	objective_data = data
	claimed_by_player_id = &""
	claimed_round = 0
	return true


func is_claimed() -> bool:
	return claimed_by_player_id != &""


func claim(player_id: StringName, round_number: int) -> bool:
	if is_claimed() or player_id == &"" or round_number <= 0:
		return false
	claimed_by_player_id = player_id
	claimed_round = round_number
	return true
