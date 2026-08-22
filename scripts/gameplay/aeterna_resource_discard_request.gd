class_name KarmanyAeternaResourceDiscardRequest
extends RefCounted


var request_id: int = 0
var player_id: StringName = &""
var round_number: int = 0
var actions_remaining: int = 0
var required_count: int = 0

var _resolved: bool = false
var _available_counts: Dictionary = {}
var _resolved_resources: Array[int] = []


func configure(
	p_request_id: int,
	player: KarmanyPlayerState,
	p_round_number: int,
	p_actions_remaining: int,
	p_required_count: int
) -> bool:
	if request_id != 0 or _resolved:
		return false
	if p_request_id <= 0 or player == null or player.player_id == &"":
		return false
	if p_round_number <= 0 or p_actions_remaining < 0 or p_required_count <= 0:
		return false

	request_id = p_request_id
	player_id = player.player_id
	round_number = p_round_number
	actions_remaining = p_actions_remaining
	required_count = p_required_count
	_available_counts = {
		KarmanyEffectData.ResourceType.MN: player.get_resource(KarmanyEffectData.ResourceType.MN),
		KarmanyEffectData.ResourceType.MR: player.get_resource(KarmanyEffectData.ResourceType.MR),
		KarmanyEffectData.ResourceType.EK: player.get_resource(KarmanyEffectData.ResourceType.EK),
	}
	var total_available: int = 0
	for value in _available_counts.values():
		total_available += int(value)
	return total_available >= required_count


func is_resolved() -> bool:
	return _resolved


func get_available_counts() -> Dictionary:
	return _available_counts.duplicate(true)


func matches_resources(player: KarmanyPlayerState) -> bool:
	if player == null or player.player_id != player_id:
		return false
	for resource_type in _available_counts.keys():
		if player.get_resource(int(resource_type)) != int(_available_counts[resource_type]):
			return false
	return true


func resolve_resources(resource_types: Array[int]) -> Array[int]:
	var empty_result: Array[int] = []
	if _resolved or resource_types.size() != required_count:
		return empty_result
	var requested_counts: Dictionary = {}
	for resource_type in resource_types:
		if not _available_counts.has(resource_type):
			return empty_result
		requested_counts[resource_type] = int(requested_counts.get(resource_type, 0)) + 1
		if int(requested_counts[resource_type]) > int(_available_counts[resource_type]):
			return empty_result
	_resolved_resources.assign(resource_types)
	_resolved = true
	var result: Array[int] = []
	result.assign(_resolved_resources)
	return result


func get_resolved_resources() -> Array[int]:
	var result: Array[int] = []
	result.assign(_resolved_resources)
	return result
