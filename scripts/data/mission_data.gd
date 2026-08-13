class_name KarmanyMissionData
extends Resource


enum CompletionTiming {
	DURING_TURN,
	END_TURN
}


@export_group("Identity")
@export var mission_id: StringName = &""
@export var trainer_id: StringName = &""
@export var trainer_display_name: String = ""
@export var display_name: String = ""
@export var recommended_first_game: bool = false

@export_group("Rules")
@export_multiline var condition_text: String = ""
@export var completion_timing: CompletionTiming = CompletionTiming.DURING_TURN
@export var reward_legacy_points: int = 4
@export var reward_effects: Array[KarmanyEffectData] = []
@export var conditions: Array[KarmanyProgressConditionData] = []


func is_valid_definition() -> bool:
	if mission_id == &"" or trainer_id == &"":
		return false
	if trainer_display_name.is_empty() or display_name.is_empty():
		return false
	if condition_text.is_empty() or reward_legacy_points <= 0:
		return false
	if conditions.is_empty():
		return false
	for condition in conditions:
		if condition == null or not condition.is_valid_definition():
			return false
	for effect in reward_effects:
		if effect == null:
			return false
	return true
