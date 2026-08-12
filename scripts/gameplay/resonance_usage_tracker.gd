class_name KarmanyResonanceUsageTracker
extends RefCounted


var _combat_users: Dictionary = {}
var _in_play: Dictionary = {}


func can_use_in_combat(
	player_id: StringName,
	combat_id: StringName
) -> bool:
	if player_id == &"" or combat_id == &"":
		return false

	var users: Dictionary = _combat_users.get(
		combat_id,
		{}
	)
	return not users.has(player_id)


func register_combat_play(
	player_id: StringName,
	combat_id: StringName,
	card: KarmanyResonanceData
) -> bool:
	if card == null:
		return false
	if not can_use_in_combat(player_id, combat_id):
		return false

	var users: Dictionary = _combat_users.get(
		combat_id,
		{}
	)
	users[player_id] = card
	_combat_users[combat_id] = users

	var cards: Array = _in_play.get(
		combat_id,
		[]
	)
	cards.append(card)
	_in_play[combat_id] = cards
	return true


func get_card_played_by(
	player_id: StringName,
	combat_id: StringName
) -> KarmanyResonanceData:
	if player_id == &"" or combat_id == &"":
		return null

	var users: Dictionary = _combat_users.get(
		combat_id,
		{}
	)
	var value: Variant = users.get(player_id, null)
	if value is KarmanyResonanceData:
		return value as KarmanyResonanceData
	return null


func get_in_play(
	combat_id: StringName
) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	var cards: Array = _in_play.get(
		combat_id,
		[]
	)

	for card in cards:
		if card is KarmanyResonanceData:
			result.append(card)

	return result


func finish_combat(
	combat_id: StringName,
	deck: KarmanyResonanceDeck
) -> int:
	if combat_id == &"" or deck == null:
		return 0

	var cards := get_in_play(combat_id)
	var discarded: int = 0

	for card in cards:
		if deck.discard_card(card):
			discarded += 1

	_combat_users.erase(combat_id)
	_in_play.erase(combat_id)
	return discarded


func clear_combat(combat_id: StringName) -> void:
	_combat_users.erase(combat_id)
	_in_play.erase(combat_id)


func clear() -> void:
	_combat_users.clear()
	_in_play.clear()
