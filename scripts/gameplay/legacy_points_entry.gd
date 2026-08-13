class_name KarmanyLegacyPointsEntry
extends RefCounted


enum SourceType {
	BEAST,
	PVP,
	PUBLIC_OBJECTIVE,
	TRAINER_MISSION,
	MILESTONE,
	AETERNA,
	RISK_REWARD,
	CARD_EFFECT,
	OTHER
}


var player_id: StringName = &""
var source_type: SourceType = SourceType.OTHER
var source_id: StringName = &""
var points: int = 0
var round_number: int = 0
var unique_key: StringName = &""
var note: String = ""


func configure(
	p_player_id: StringName,
	p_source_type: int,
	p_source_id: StringName,
	p_points: int,
	p_round_number: int,
	p_unique_key: StringName = &"",
	p_note: String = ""
) -> bool:
	if p_player_id == &"" or p_source_id == &"":
		return false
	if p_points <= 0 or p_round_number <= 0:
		return false
	if p_source_type < SourceType.BEAST or p_source_type > SourceType.OTHER:
		return false

	player_id = p_player_id
	source_type = p_source_type
	source_id = p_source_id
	points = p_points
	round_number = p_round_number
	unique_key = p_unique_key
	note = p_note
	return true
