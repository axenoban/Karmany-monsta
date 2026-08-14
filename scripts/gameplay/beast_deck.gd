class_name KarmanyBeastDeck
extends RefCounted


var tier: int = -1
var _draw_pile: Array[KarmanyBeastData] = []
var _discard_pile: Array[KarmanyBeastData] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(
	cards: Array[KarmanyBeastData],
	shuffle_cards: bool = true,
	seed_value: int = 0
) -> bool:
	if cards.is_empty():
		return false

	var detected_tier: int = -1
	for card in cards:
		if card == null or not card.is_valid_definition():
			return false
		if detected_tier == -1:
			detected_tier = card.tier
		elif card.tier != detected_tier:
			return false

	tier = detected_tier
	_draw_pile.clear()
	_discard_pile.clear()
	for card in cards:
		_draw_pile.append(card)

	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

	if shuffle_cards:
		_shuffle_draw_pile()

	return true


func draw_card() -> KarmanyBeastData:
	if _draw_pile.is_empty():
		_recycle_discard()
	if _draw_pile.is_empty():
		return null

	return _draw_pile.pop_front()


func discard_card(card: KarmanyBeastData) -> bool:
	if card == null or not card.is_valid_definition():
		return false
	if tier == -1 or card.tier != tier:
		return false

	_discard_pile.append(card)
	return true


func get_draw_count() -> int:
	return _draw_pile.size()


func get_discard_count() -> int:
	return _discard_pile.size()


func is_empty() -> bool:
	return _draw_pile.is_empty() and _discard_pile.is_empty()


func _recycle_discard() -> void:
	if _discard_pile.is_empty():
		return

	for card in _discard_pile:
		_draw_pile.append(card)
	_discard_pile.clear()
	_shuffle_draw_pile()


func _shuffle_draw_pile() -> void:
	for index in range(_draw_pile.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var card := _draw_pile[index]
		_draw_pile[index] = _draw_pile[swap_index]
		_draw_pile[swap_index] = card
