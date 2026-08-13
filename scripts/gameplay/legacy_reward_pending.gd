class_name KarmanyLegacyRewardPending
extends RefCounted


enum SourceType {
	PUBLIC_OBJECTIVE,
	TRAINER_MISSION
}


var source_type: SourceType = SourceType.PUBLIC_OBJECTIVE
var source_id: StringName = &""
var player_id: StringName = &""
var legacy_points: int = 0
var round_number: int = 0
var consumed: bool = false


func configure(
	p_source_type: int,
	p_source_id: StringName,
	p_player_id: StringName,
	p_legacy_points: int,
	p_round_number: int
) -> bool:
	if p_source_id == &"" or p_player_id == &"":
		return false
	if p_legacy_points <= 0 or p_round_number <= 0:
		return false
	if p_source_type < SourceType.PUBLIC_OBJECTIVE or p_source_type > SourceType.TRAINER_MISSION:
		return false

	source_type = p_source_type
	source_id = p_source_id
	player_id = p_player_id
	legacy_points = p_legacy_points
	round_number = p_round_number
	consumed = false
	return true


func mark_consumed() -> bool:
	if consumed:
		return false
	consumed = true
	return true
