class_name KarmanyMissionAssignment
extends RefCounted


enum Status {
	SECRET,
	COMPLETED_REVEALED
}


var player_id: StringName = &""
var mission_data: KarmanyMissionData = null
var status: Status = Status.SECRET
var completed_round: int = 0
var reward_legacy_points_pending: int = 0
var reward_effect_results: Array[KarmanyEffectResult] = []


func configure(
	p_player_id: StringName,
	p_mission_data: KarmanyMissionData
) -> bool:
	if p_player_id == &"":
		return false
	if p_mission_data == null or not p_mission_data.is_valid_definition():
		return false
	player_id = p_player_id
	mission_data = p_mission_data
	status = Status.SECRET
	completed_round = 0
	reward_legacy_points_pending = 0
	reward_effect_results.clear()
	return true


func is_completed() -> bool:
	return status == Status.COMPLETED_REVEALED


func is_visible_to(viewer_player_id: StringName) -> bool:
	return viewer_player_id == player_id or is_completed()
