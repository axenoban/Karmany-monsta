class_name KarmanyAeternaRewardChoiceRequest
extends RefCounted


const OPTION_RESONANCES: StringName = &"aeterna_reward_resonances"
const EQUIPMENT_PREFIX: String = "aeterna_reward_equipment:"

enum RewardKind {
	NONE,
	RESONANCES,
	ANCESTRAL_EQUIPMENT,
}

var request_id: int = 0
var player_id: StringName = &""
var round_number: int = 0
var actions_remaining: int = 0
var requires_equipment_replacement: bool = false

var _resolved: bool = false
var _option_ids: Array[StringName] = []
var _equipment_by_option: Dictionary = {}
var _current_equipment_ids: Array[StringName] = []
var _resolved_selection: Dictionary = {}


func configure(
	p_request_id: int,
	player: KarmanyPlayerState,
	p_round_number: int,
	p_actions_remaining: int,
	market: KarmanyEquipmentMarket,
	allow_resonances: bool
) -> bool:
	if request_id != 0 or _resolved:
		return false
	if p_request_id <= 0 or player == null or player.player_id == &"":
		return false
	if p_round_number <= 0 or p_actions_remaining < 0 or market == null:
		return false

	request_id = p_request_id
	player_id = player.player_id
	round_number = p_round_number
	actions_remaining = p_actions_remaining
	requires_equipment_replacement = player.equipment_inventory.is_full()

	for current in player.get_equipped_equipment():
		if current != null:
			_current_equipment_ids.append(current.equipment_id)

	if allow_resonances:
		_option_ids.append(OPTION_RESONANCES)

	var visible := market.get_visible()
	for index in range(visible.size()):
		var equipment: KarmanyEquipmentData = visible[index]
		if equipment == null:
			continue
		if equipment.rarity != KarmanyEquipmentData.Rarity.ANCESTRAL:
			continue
		if player.equipment_inventory.has_equipment_id(equipment.equipment_id):
			continue
		var option_id := StringName("%s%d:%s" % [
			EQUIPMENT_PREFIX,
			index,
			String(equipment.equipment_id),
		])
		_option_ids.append(option_id)
		_equipment_by_option[option_id] = {
			"market_index": index,
			"equipment_id": equipment.equipment_id,
			"display_name": equipment.display_name,
		}

	return not _option_ids.is_empty()


func is_resolved() -> bool:
	return _resolved


func get_option_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_option_ids)
	return result


func get_equipment_options() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for option_id in _option_ids:
		if not _equipment_by_option.has(option_id):
			continue
		var row: Dictionary = _equipment_by_option[option_id]
		var copy: Dictionary = row.duplicate(true)
		copy["option_id"] = option_id
		result.append(copy)
	return result


func get_current_equipment_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_current_equipment_ids)
	return result


func has_resonance_option() -> bool:
	return _option_ids.has(OPTION_RESONANCES)


func matches_state(
	player: KarmanyPlayerState,
	market: KarmanyEquipmentMarket
) -> bool:
	if player == null or market == null or player.player_id != player_id:
		return false
	if player.equipment_inventory.is_full() != requires_equipment_replacement:
		return false
	var current_ids: Array[StringName] = []
	for current in player.get_equipped_equipment():
		if current != null:
			current_ids.append(current.equipment_id)
	if current_ids != _current_equipment_ids:
		return false
	for option_id in _equipment_by_option.keys():
		var row: Dictionary = _equipment_by_option[option_id]
		var index: int = int(row.get("market_index", -1))
		var expected_id: StringName = StringName(row.get("equipment_id", ""))
		var current := market.get_visible_at(index)
		if current == null or current.equipment_id != expected_id:
			return false
	return true


func resolve_option(
	option_id: StringName,
	discard_equipment_id: StringName = &""
) -> Dictionary:
	if _resolved or not _option_ids.has(option_id):
		return {}
	if option_id == OPTION_RESONANCES:
		_resolved_selection = {
			"kind": RewardKind.RESONANCES,
			"option_id": option_id,
		}
		_resolved = true
		return _resolved_selection.duplicate(true)
	if not _equipment_by_option.has(option_id):
		return {}
	if requires_equipment_replacement:
		if discard_equipment_id == &"" or not _current_equipment_ids.has(discard_equipment_id):
			return {}
	elif discard_equipment_id != &"":
		return {}

	var row: Dictionary = _equipment_by_option[option_id]
	_resolved_selection = {
		"kind": RewardKind.ANCESTRAL_EQUIPMENT,
		"option_id": option_id,
		"market_index": int(row.get("market_index", -1)),
		"equipment_id": StringName(row.get("equipment_id", "")),
		"discard_equipment_id": discard_equipment_id,
	}
	_resolved = true
	return _resolved_selection.duplicate(true)


func get_resolved_selection() -> Dictionary:
	return _resolved_selection.duplicate(true)
