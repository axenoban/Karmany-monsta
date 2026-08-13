class_name KarmanyProgressConditionData
extends Resource


enum ConditionType {
	EVENT_COUNT,
	DISTINCT_FIELD_COUNT,
	STATE_INT_AT_LEAST,
	EVENT_EXISTS,
	EVENTS_IN_DISTINCT_ROUNDS
}


@export_group("Condition")
@export var condition_type: ConditionType = ConditionType.EVENT_COUNT
@export var event_id: StringName = &""
@export var secondary_event_id: StringName = &""
@export var threshold: int = 1
@export var field_id: StringName = &""
@export var state_id: StringName = &""
@export var minimum_round: int = 0

@export_group("Optional Event Filter")
@export var required_int_field: StringName = &""
@export var required_int_minimum: int = 0
@export var required_string_field: StringName = &""
@export var required_string_value: String = ""

@export_group("Presentation")
@export_multiline var description: String = ""


func is_valid_definition() -> bool:
	if threshold <= 0:
		return false

	match condition_type:
		ConditionType.EVENT_COUNT, ConditionType.EVENT_EXISTS:
			return event_id != &""
		ConditionType.DISTINCT_FIELD_COUNT:
			return event_id != &"" and field_id != &""
		ConditionType.STATE_INT_AT_LEAST:
			return state_id != &""
		ConditionType.EVENTS_IN_DISTINCT_ROUNDS:
			return event_id != &"" and secondary_event_id != &""

	return false
