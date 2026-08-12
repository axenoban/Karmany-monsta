class_name KarmanyResonanceHand
extends RefCounted


signal hand_changed
signal discard_requested(amount: int)


const BASE_HAND_LIMIT: int = 5


var hand_limit: int = BASE_HAND_LIMIT
var _cards: Array[KarmanyResonanceData] = []
var _pending_discard_count: int = 0


func clear() -> void:
	_cards.clear()
	_pending_discard_count = 0
	hand_limit = BASE_HAND_LIMIT
	hand_changed.emit()


func get_count() -> int:
	return _cards.size()


func get_hand_limit() -> int:
	return hand_limit


func set_hand_limit(value: int) -> bool:
	if value < 0:
		return false
	hand_limit = value
	hand_changed.emit()
	return true


func get_all() -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	for card in _cards:
		result.append(card)
	return result


func get_card_by_id(resonance_id: StringName) -> KarmanyResonanceData:
	for card in _cards:
		if card != null and card.resonance_id == resonance_id:
			return card
	return null


func has_card_id(resonance_id: StringName) -> bool:
	return get_card_by_id(resonance_id) != null


func add_card(card: KarmanyResonanceData) -> bool:
	if card == null or not card.is_valid_definition():
		return false
	_cards.append(card)
	hand_changed.emit()
	return true


func remove_card_by_id(resonance_id: StringName) -> KarmanyResonanceData:
	for index in range(_cards.size()):
		var card: KarmanyResonanceData = _cards[index]
		if card != null and card.resonance_id == resonance_id:
			_cards.remove_at(index)
			hand_changed.emit()
			return card
	return null


func get_pending_discard_count() -> int:
	return _pending_discard_count


func request_discard(amount: int) -> bool:
	if amount <= 0:
		return false
	if _pending_discard_count + amount > _cards.size():
		return false

	_pending_discard_count += amount
	discard_requested.emit(amount)
	return true


func request_end_turn_limit_discard() -> int:
	var projected_count: int = maxi(
		0,
		_cards.size() - _pending_discard_count
	)
	var additional: int = maxi(
		0,
		projected_count - hand_limit
	)

	if additional > 0:
		_pending_discard_count += additional
		discard_requested.emit(additional)

	return additional


func resolve_pending_discard(
	resonance_ids: Array[StringName],
	deck: KarmanyResonanceDeck
) -> bool:
	if deck == null:
		return false
	if resonance_ids.size() != _pending_discard_count:
		return false

	var seen_ids: Dictionary = {}
	for resonance_id in resonance_ids:
		if resonance_id == &"" or seen_ids.has(resonance_id):
			return false
		if not has_card_id(resonance_id):
			return false
		seen_ids[resonance_id] = true

	for resonance_id in resonance_ids:
		var card := remove_card_by_id(resonance_id)
		if card == null:
			return false
		deck.discard_card(card)

	_pending_discard_count = 0
	hand_changed.emit()
	return true
