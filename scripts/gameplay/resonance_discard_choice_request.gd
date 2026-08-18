class_name KarmanyResonanceDiscardChoiceRequest
extends RefCounted


var request_id: int = 0
var player_id: StringName = &""
var round_number: int = 0
var required_count: int = 0

var _resolved: bool = false
var _resolved_option_ids: Array[StringName] = []
var _option_ids: Array[StringName] = []
var _card_by_option_id: Dictionary = {}
var _snapshot_resonance_ids: Array[StringName] = []


func configure(
	p_request_id: int,
	p_player_id: StringName,
	p_round_number: int,
	p_required_count: int,
	p_cards: Array[KarmanyResonanceData]
) -> bool:
	if request_id != 0 or not _option_ids.is_empty() or not _card_by_option_id.is_empty():
		return false
	if p_request_id <= 0 or p_player_id == &"" or p_round_number <= 0:
		return false
	if p_required_count <= 0 or p_cards.is_empty() or p_required_count > p_cards.size():
		return false

	var seen_resonance_ids: Dictionary = {}
	for card in p_cards:
		if card == null or not card.is_valid_definition():
			return false
		if card.resonance_id == &"" or seen_resonance_ids.has(card.resonance_id):
			return false
		seen_resonance_ids[card.resonance_id] = true

	request_id = p_request_id
	player_id = p_player_id
	round_number = p_round_number
	required_count = p_required_count
	for index in range(p_cards.size()):
		var card: KarmanyResonanceData = p_cards[index]
		var option_id := StringName("resonance_discard_%d_%d" % [request_id, index + 1])
		_option_ids.append(option_id)
		_card_by_option_id[option_id] = card
		_snapshot_resonance_ids.append(card.resonance_id)
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
		var card: KarmanyResonanceData = _card_by_option_id.get(option_id, null) as KarmanyResonanceData
		if card == null:
			continue
		result.append({
			"option_id": option_id,
			"resonance_id": card.resonance_id,
			"display_name": card.display_name,
			"printed_power": card.printed_power,
			"use_windows": card.use_windows.duplicate(),
			"rules_text": card.rules_text,
		})
	return result


func is_resolved() -> bool:
	return _resolved


func get_resolved_option_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_resolved_option_ids)
	return result


func matches_cards(cards: Array[KarmanyResonanceData]) -> bool:
	if cards.size() != _snapshot_resonance_ids.size():
		return false
	for index in range(cards.size()):
		var card: KarmanyResonanceData = cards[index]
		if card == null or card.resonance_id != _snapshot_resonance_ids[index]:
			return false
	return true


func resolve_options(option_ids: Array[StringName]) -> Array[StringName]:
	var empty_result: Array[StringName] = []
	if _resolved or option_ids.size() != required_count:
		return empty_result

	var seen_option_ids: Dictionary = {}
	var selected_resonance_ids: Array[StringName] = []
	for option_id in option_ids:
		if option_id == &"" or seen_option_ids.has(option_id) or not _card_by_option_id.has(option_id):
			return empty_result
		seen_option_ids[option_id] = true
		var card: KarmanyResonanceData = _card_by_option_id.get(option_id, null) as KarmanyResonanceData
		if card == null:
			return empty_result
		selected_resonance_ids.append(card.resonance_id)

	_resolved = true
	_resolved_option_ids.assign(option_ids)
	return selected_resonance_ids
