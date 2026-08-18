class_name KarmanyCombatResonanceChoiceRequest
extends RefCounted


var request_id: int = 0
var player_id: StringName = &""
var round_number: int = 0
var actions_remaining: int = 0
var action_type: int = -1
var action_label: String = ""
var target_coord: Vector2i = Vector2i.ZERO

var _resolved: bool = false
var _resolved_option_id: StringName = &""
var _resolved_resonance_id: StringName = &""
var _none_option_id: StringName = &""
var _option_ids: Array[StringName] = []
var _card_by_option_id: Dictionary = {}
var _snapshot_resonance_ids: Array[StringName] = []


func configure(
	p_request_id: int,
	p_player_id: StringName,
	p_round_number: int,
	p_actions_remaining: int,
	p_action_type: int,
	p_action_label: String,
	p_target_coord: Vector2i,
	p_cards: Array[KarmanyResonanceData],
	p_hand_snapshot: Array[KarmanyResonanceData]
) -> bool:
	if (
		request_id != 0
		or not _option_ids.is_empty()
		or not _card_by_option_id.is_empty()
		or not _snapshot_resonance_ids.is_empty()
	):
		return false
	if p_request_id <= 0 or p_player_id == &"" or p_round_number <= 0 or p_actions_remaining <= 0:
		return false
	if not _is_combat_action_type(p_action_type) or p_action_label.is_empty() or p_cards.is_empty():
		return false

	var hand_ids: Dictionary = {}
	var snapshot_ids: Array[StringName] = []
	for card in p_hand_snapshot:
		if card == null or not card.is_valid_definition():
			return false
		if card.resonance_id == &"" or hand_ids.has(card.resonance_id):
			return false
		hand_ids[card.resonance_id] = true
		snapshot_ids.append(card.resonance_id)

	var selectable_ids: Dictionary = {}
	for card in p_cards:
		if card == null or not card.is_valid_definition():
			return false
		if not card.can_use_in(KarmanyResonanceUseContext.WINDOW_COMBAT):
			return false
		if not hand_ids.has(card.resonance_id) or selectable_ids.has(card.resonance_id):
			return false
		selectable_ids[card.resonance_id] = true

	request_id = p_request_id
	player_id = p_player_id
	round_number = p_round_number
	actions_remaining = p_actions_remaining
	action_type = p_action_type
	action_label = p_action_label
	target_coord = p_target_coord
	_snapshot_resonance_ids.assign(snapshot_ids)

	_none_option_id = StringName("combat_resonance_%d_none" % request_id)
	_option_ids.append(_none_option_id)
	for index in range(p_cards.size()):
		var card: KarmanyResonanceData = p_cards[index]
		var option_id := StringName("combat_resonance_%d_%d" % [request_id, index + 1])
		_option_ids.append(option_id)
		_card_by_option_id[option_id] = card
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
		if option_id == _none_option_id:
			result.append({
				"option_id": option_id,
				"resonance_id": &"",
				"display_name": "Sin Resonancia",
				"printed_power": 0,
				"rules_text": "Resolver este combate sin jugar Resonancia.",
				"is_none": true,
			})
			continue
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
			"is_none": false,
		})
	return result


func has_option(option_id: StringName) -> bool:
	if _resolved or option_id == &"":
		return false
	return option_id == _none_option_id or _card_by_option_id.has(option_id)


func is_resolved() -> bool:
	return _resolved


func get_resolved_option_id() -> StringName:
	return _resolved_option_id


func get_resolved_resonance_id() -> StringName:
	return _resolved_resonance_id


func matches_cards(cards: Array[KarmanyResonanceData]) -> bool:
	if cards.size() != _snapshot_resonance_ids.size():
		return false
	for index in range(cards.size()):
		var card: KarmanyResonanceData = cards[index]
		if card == null or card.resonance_id != _snapshot_resonance_ids[index]:
			return false
	return true


func resolve_option(option_id: StringName) -> bool:
	if not has_option(option_id):
		return false
	_resolved = true
	_resolved_option_id = option_id
	if option_id == _none_option_id:
		_resolved_resonance_id = &""
		return true
	var card: KarmanyResonanceData = _card_by_option_id.get(option_id, null) as KarmanyResonanceData
	if card == null:
		_resolved = false
		_resolved_option_id = &""
		return false
	_resolved_resonance_id = card.resonance_id
	return true


func _is_combat_action_type(value: int) -> bool:
	match value:
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
			return true
		KarmanyAiActionCandidate.ActionType.PVP:
			return true
		KarmanyAiActionCandidate.ActionType.AETERNA:
			return true
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
			return true
	return false
