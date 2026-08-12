class_name KarmanyPvpTruceTracker
extends RefCounted


var _last_pvp_round_by_pair: Dictionary = {}


func clear() -> void:
	_last_pvp_round_by_pair.clear()


func can_attack(
	attacker_id: StringName,
	defender_id: StringName,
	round_number: int
) -> bool:
	if attacker_id == &"" or defender_id == &"":
		return false
	if attacker_id == defender_id or round_number <= 0:
		return false

	var key := _make_key(attacker_id, defender_id)
	return int(_last_pvp_round_by_pair.get(key, -1)) != round_number


func register_pvp(
	attacker_id: StringName,
	defender_id: StringName,
	round_number: int
) -> bool:
	if not can_attack(attacker_id, defender_id, round_number):
		return false

	_last_pvp_round_by_pair[
		_make_key(attacker_id, defender_id)
	] = round_number
	return true


func has_truce(
	attacker_id: StringName,
	defender_id: StringName,
	round_number: int
) -> bool:
	if attacker_id == &"" or defender_id == &"":
		return false
	if round_number <= 0:
		return false

	return int(
		_last_pvp_round_by_pair.get(
			_make_key(attacker_id, defender_id),
			-1
		)
	) == round_number


func _make_key(
	attacker_id: StringName,
	defender_id: StringName
) -> String:
	return "%s>%s" % [
		String(attacker_id),
		String(defender_id)
	]
