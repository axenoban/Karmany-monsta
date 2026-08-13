class_name KarmanyProgressTracker
extends RefCounted


signal progress_changed(player_id: StringName)


var _events_by_player: Dictionary = {}
var _states_by_player: Dictionary = {}


func clear() -> void:
	_events_by_player.clear()
	_states_by_player.clear()


func record_event(
	player_id: StringName,
	event_id: StringName,
	round_number: int,
	payload: Dictionary = {}
) -> bool:
	if player_id == &"" or event_id == &"" or round_number <= 0:
		return false

	var events: Array = _events_by_player.get(player_id, [])
	events.append({
		"event_id": event_id,
		"round": round_number,
		"payload": payload.duplicate(true)
	})
	_events_by_player[player_id] = events
	progress_changed.emit(player_id)
	return true


func set_state_int(
	player_id: StringName,
	state_id: StringName,
	value: int
) -> bool:
	if player_id == &"" or state_id == &"":
		return false

	var states: Dictionary = _states_by_player.get(player_id, {})
	states[state_id] = value
	_states_by_player[player_id] = states
	progress_changed.emit(player_id)
	return true


func get_state_int(
	player_id: StringName,
	state_id: StringName,
	default_value: int = 0
) -> int:
	var states: Dictionary = _states_by_player.get(player_id, {})
	return int(states.get(state_id, default_value))


func is_condition_met(
	player_id: StringName,
	condition: KarmanyProgressConditionData
) -> bool:
	if player_id == &"" or condition == null:
		return false
	if not condition.is_valid_definition():
		return false

	match condition.condition_type:
		KarmanyProgressConditionData.ConditionType.EVENT_COUNT:
			return _count_matching_events(player_id, condition) >= condition.threshold
		KarmanyProgressConditionData.ConditionType.DISTINCT_FIELD_COUNT:
			return _count_distinct_field_values(player_id, condition) >= condition.threshold
		KarmanyProgressConditionData.ConditionType.STATE_INT_AT_LEAST:
			return get_state_int(player_id, condition.state_id) >= condition.threshold
		KarmanyProgressConditionData.ConditionType.EVENT_EXISTS:
			return _count_matching_events(player_id, condition) >= 1
		KarmanyProgressConditionData.ConditionType.EVENTS_IN_DISTINCT_ROUNDS:
			return _has_events_in_distinct_rounds(player_id, condition)

	return false


func are_conditions_met(
	player_id: StringName,
	conditions: Array[KarmanyProgressConditionData]
) -> bool:
	if player_id == &"" or conditions.is_empty():
		return false
	for condition in conditions:
		if not is_condition_met(player_id, condition):
			return false
	return true


func get_event_count(
	player_id: StringName,
	event_id: StringName
) -> int:
	var condition := KarmanyProgressConditionData.new()
	condition.condition_type = KarmanyProgressConditionData.ConditionType.EVENT_COUNT
	condition.event_id = event_id
	condition.threshold = 1
	return _count_matching_events(player_id, condition)


func _count_matching_events(
	player_id: StringName,
	condition: KarmanyProgressConditionData
) -> int:
	var total: int = 0
	for event in _get_events(player_id):
		if _event_matches(event, condition.event_id, condition):
			total += 1
	return total


func _count_distinct_field_values(
	player_id: StringName,
	condition: KarmanyProgressConditionData
) -> int:
	var seen: Dictionary = {}
	for event in _get_events(player_id):
		if not _event_matches(event, condition.event_id, condition):
			continue
		var payload: Dictionary = event.get("payload", {})
		if not payload.has(condition.field_id):
			continue
		seen[payload[condition.field_id]] = true
	return seen.size()


func _has_events_in_distinct_rounds(
	player_id: StringName,
	condition: KarmanyProgressConditionData
) -> bool:
	var primary_rounds: Dictionary = {}
	var secondary_rounds: Dictionary = {}

	for event in _get_events(player_id):
		var event_id: StringName = event.get("event_id", &"")
		var round_number: int = int(event.get("round", 0))
		if round_number < condition.minimum_round:
			continue
		if event_id == condition.event_id:
			primary_rounds[round_number] = true
		elif event_id == condition.secondary_event_id:
			secondary_rounds[round_number] = true

	for primary_round in primary_rounds.keys():
		for secondary_round in secondary_rounds.keys():
			if int(primary_round) != int(secondary_round):
				return true
	return false


func _event_matches(
	event: Dictionary,
	event_id: StringName,
	condition: KarmanyProgressConditionData
) -> bool:
	if event.get("event_id", &"") != event_id:
		return false
	if int(event.get("round", 0)) < condition.minimum_round:
		return false

	var payload: Dictionary = event.get("payload", {})
	if condition.required_int_field != &"":
		if not payload.has(condition.required_int_field):
			return false
		if int(payload[condition.required_int_field]) < condition.required_int_minimum:
			return false

	if condition.required_string_field != &"":
		if not payload.has(condition.required_string_field):
			return false
		if String(payload[condition.required_string_field]) != condition.required_string_value:
			return false

	return true


func _get_events(player_id: StringName) -> Array:
	return _events_by_player.get(player_id, [])
