class_name KarmanyEquipmentMarket
extends RefCounted


signal market_changed


const MARKET_SIZE: int = 4


var _visible: Array[KarmanyEquipmentData] = []
var _draw_pile: Array[KarmanyEquipmentData] = []
var _discard_pile: Array[KarmanyEquipmentData] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shuffle_on_recycle: bool = true


func setup(
	deck: Array[KarmanyEquipmentData],
	shuffle_deck: bool = false,
	seed: int = 0
) -> bool:
	if deck.size() < MARKET_SIZE:
		return false

	var seen_ids: Dictionary = {}
	for equipment in deck:
		if equipment == null or not equipment.is_valid_definition():
			return false
		if seen_ids.has(equipment.equipment_id):
			return false
		seen_ids[equipment.equipment_id] = true

	_visible.clear()
	_draw_pile.clear()
	_discard_pile.clear()

	for equipment in deck:
		_draw_pile.append(equipment)

	if seed != 0:
		_rng.seed = seed
	else:
		_rng.randomize()

	_shuffle_on_recycle = shuffle_deck
	if shuffle_deck:
		_shuffle_array(_draw_pile)

	_refill_visible()
	return _visible.size() == MARKET_SIZE


func get_visible() -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	for equipment in _visible:
		result.append(equipment)
	return result


func get_visible_count() -> int:
	return _visible.size()


func get_visible_at(index: int) -> KarmanyEquipmentData:
	if index < 0 or index >= _visible.size():
		return null
	return _visible[index]


func get_draw_count() -> int:
	return _draw_pile.size()


func get_discard_count() -> int:
	return _discard_pile.size()


func take_visible(index: int) -> KarmanyEquipmentData:
	if index < 0 or index >= _visible.size():
		return null

	var equipment: KarmanyEquipmentData = _visible[index]
	_visible.remove_at(index)
	_refill_visible()
	market_changed.emit()
	return equipment


func discard_visible(index: int) -> KarmanyEquipmentData:
	if index < 0 or index >= _visible.size():
		return null

	var equipment: KarmanyEquipmentData = _visible[index]
	_visible.remove_at(index)
	_discard_pile.append(equipment)
	_refill_visible()
	market_changed.emit()
	return equipment


func _refill_visible() -> void:
	while _visible.size() < MARKET_SIZE:
		var next_equipment := _draw_one()
		if next_equipment == null:
			break
		_visible.append(next_equipment)


func _draw_one() -> KarmanyEquipmentData:
	if _draw_pile.is_empty():
		_recycle_discard()

	if _draw_pile.is_empty():
		return null

	return _draw_pile.pop_front()


func _recycle_discard() -> void:
	if _discard_pile.is_empty():
		return

	for equipment in _discard_pile:
		_draw_pile.append(equipment)
	_discard_pile.clear()

	if _shuffle_on_recycle:
		_shuffle_array(_draw_pile)


func _shuffle_array(items: Array[KarmanyEquipmentData]) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var temp: KarmanyEquipmentData = items[index]
		items[index] = items[swap_index]
		items[swap_index] = temp
