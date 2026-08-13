class_name KarmanyAeternaState
extends RefCounted


var defeated: bool = false
var defeated_by_player_id: StringName = &""
var defeated_round: int = 0

var _sanctuary_attunement_used: Dictionary = {}
var _aeterna_sync_used: Dictionary = {}
var _post_defeat_ek_round_by_player: Dictionary = {}


func reset() -> void:
	defeated = false
	defeated_by_player_id = &""
	defeated_round = 0
	_sanctuary_attunement_used.clear()
	_aeterna_sync_used.clear()
	_post_defeat_ek_round_by_player.clear()


func has_used_sanctuary_attunement(player_id: StringName) -> bool:
	return bool(_sanctuary_attunement_used.get(player_id, false))


func mark_sanctuary_attunement_used(player_id: StringName) -> bool:
	if player_id == &"" or has_used_sanctuary_attunement(player_id):
		return false
	_sanctuary_attunement_used[player_id] = true
	return true


func has_used_aeterna_sync(player_id: StringName) -> bool:
	return bool(_aeterna_sync_used.get(player_id, false))


func mark_aeterna_sync_used(player_id: StringName) -> bool:
	if player_id == &"" or has_used_aeterna_sync(player_id):
		return false
	_aeterna_sync_used[player_id] = true
	return true


func mark_defeated(player_id: StringName, round_number: int) -> bool:
	if defeated or player_id == &"" or round_number <= 0:
		return false
	defeated = true
	defeated_by_player_id = player_id
	defeated_round = round_number
	return true


func can_collect_post_defeat_ek(player_id: StringName, round_number: int) -> bool:
	if not defeated or player_id == &"" or round_number <= 0:
		return false
	return int(_post_defeat_ek_round_by_player.get(player_id, 0)) != round_number


func mark_post_defeat_ek_collected(player_id: StringName, round_number: int) -> bool:
	if not can_collect_post_defeat_ek(player_id, round_number):
		return false
	_post_defeat_ek_round_by_player[player_id] = round_number
	return true
