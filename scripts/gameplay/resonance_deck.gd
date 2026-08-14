class_name KarmanyResonanceDeck
extends RefCounted


signal deck_changed


const INITIAL_HAND_SIZE: int = 5


var _draw_pile: Array[KarmanyResonanceData] = []
var _discard_pile: Array[KarmanyResonanceData] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shuffle_on_recycle: bool = true


func setup(
	cards: Array[KarmanyResonanceData],
	shuffle_deck: bool = false,
	seed_value: int = 0
) -> bool:
	if cards.is_empty():
		return false

	var seen_ids: Dictionary = {}
	for card in cards:
		if card == null or not card.is_valid_definition():
			return false
		if seen_ids.has(card.resonance_id):
			return false
		seen_ids[card.resonance_id] = true

	_draw_pile.clear()
	_discard_pile.clear()

	for card in cards:
		_draw_pile.append(card)

	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

	_shuffle_on_recycle = true
	if shuffle_deck:
		_shuffle_array(_draw_pile)

	deck_changed.emit()
	return true


func get_draw_count() -> int:
	return _draw_pile.size()


func get_discard_count() -> int:
	return _discard_pile.size()


func get_discarded() -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	for card in _discard_pile:
		result.append(card)
	return result


func draw_one() -> KarmanyResonanceData:
	if _draw_pile.is_empty():
		_recycle_discard()

	if _draw_pile.is_empty():
		return null

	var card: KarmanyResonanceData = _draw_pile.pop_front()
	deck_changed.emit()
	return card


func draw_to_hand(
	hand: KarmanyResonanceHand,
	amount: int
) -> int:
	if hand == null or amount <= 0:
		return 0

	var drawn: int = 0
	for _index in range(amount):
		var card := draw_one()
		if card == null:
			break
		if not hand.add_card(card):
			_draw_pile.push_front(card)
			break
		drawn += 1

	return drawn


func deal_initial_hand(player: KarmanyPlayerState) -> bool:
	if player == null:
		return false
	if player.resonance_hand.get_count() != 0:
		return false
	return draw_to_hand(
		player.resonance_hand,
		INITIAL_HAND_SIZE
	) == INITIAL_HAND_SIZE


func discard_card(card: KarmanyResonanceData) -> bool:
	if card == null or not card.is_valid_definition():
		return false
	_discard_pile.append(card)
	deck_changed.emit()
	return true


func _recycle_discard() -> void:
	if _discard_pile.is_empty():
		return

	for card in _discard_pile:
		_draw_pile.append(card)
	_discard_pile.clear()

	if _shuffle_on_recycle:
		_shuffle_array(_draw_pile)

	deck_changed.emit()


func _shuffle_array(cards: Array[KarmanyResonanceData]) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var temp: KarmanyResonanceData = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temp
