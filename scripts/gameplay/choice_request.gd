class_name KarmanyChoiceRequest
extends RefCounted


var request_id: int = 0
var player_id: StringName = &""
var round_number: int = 0
var actions_remaining: int = 0

var _resolved: bool = false
var _resolved_option_id: StringName = &""
var _option_ids: Array[StringName] = []
var _candidate_by_option_id: Dictionary = {}


func configure(
	p_request_id: int,
	p_player_id: StringName,
	p_round_number: int,
	p_actions_remaining: int,
	p_candidates: Array[KarmanyAiActionCandidate]
) -> bool:
	if request_id != 0 or not _option_ids.is_empty() or not _candidate_by_option_id.is_empty():
		return false
	if p_request_id <= 0 or p_player_id == &"" or p_round_number <= 0 or p_actions_remaining <= 0:
		return false
	if p_candidates.is_empty():
		return false
	for candidate in p_candidates:
		if candidate == null or not candidate.is_valid():
			return false

	request_id = p_request_id
	player_id = p_player_id
	round_number = p_round_number
	actions_remaining = p_actions_remaining
	for index in range(p_candidates.size()):
		var option_id := StringName("choice_%d_%d" % [request_id, index + 1])
		_option_ids.append(option_id)
		_candidate_by_option_id[option_id] = p_candidates[index]
	return true


func get_option_count() -> int:
	return _option_ids.size()


func get_option_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_option_ids)
	return result


func get_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for option_id in _option_ids:
		var candidate: KarmanyAiActionCandidate = _candidate_by_option_id.get(
			option_id,
			null
		) as KarmanyAiActionCandidate
		if candidate == null:
			continue
		result.append({
			"option_id": option_id,
			"action_type": candidate.action_type,
			"action_name": candidate.get_action_name(),
			"label": candidate.debug_label,
			"target_coord": candidate.target_coord,
			"option_index": candidate.option_index,
		})
	return result


func has_option(option_id: StringName) -> bool:
	return not _resolved and _candidate_by_option_id.has(option_id)


func is_resolved() -> bool:
	return _resolved


func get_resolved_option_id() -> StringName:
	return _resolved_option_id


func resolve_option(option_id: StringName) -> KarmanyAiActionCandidate:
	if _resolved or option_id == &"" or not _candidate_by_option_id.has(option_id):
		return null
	var candidate: KarmanyAiActionCandidate = _candidate_by_option_id.get(
		option_id,
		null
	) as KarmanyAiActionCandidate
	if candidate == null:
		return null
	_resolved = true
	_resolved_option_id = option_id
	return candidate
