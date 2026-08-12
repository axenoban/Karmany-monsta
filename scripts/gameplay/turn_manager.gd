class_name KarmanyTurnManager
extends RefCounted


signal round_started(round_number: int)
signal round_ended(round_number: int)
signal turn_started(
	player: KarmanyPlayerState,
	round_number: int,
	actions_available: int
)
signal turn_ended(
	player: KarmanyPlayerState,
	round_number: int
)
signal action_spent(
	player: KarmanyPlayerState,
	cost: int,
	actions_remaining: int
)


const MIN_PLAYERS: int = 2
const MAX_PLAYERS: int = 4
const ACTIONS_PER_TURN: int = 2


var players: Array[KarmanyPlayerState] = []
var current_round: int = 0
var active_player_index: int = -1
var actions_remaining: int = 0
var is_running: bool = false

var _action_usage_this_turn: Dictionary = {}


func setup_players(
	p_players: Array[KarmanyPlayerState]
) -> bool:
	if is_running:
		return false

	if (
		p_players.size() < MIN_PLAYERS
		or p_players.size() > MAX_PLAYERS
	):
		return false

	var seen_ids: Dictionary = {}

	for player in p_players:
		if player == null or player.player_id == &"":
			return false

		if seen_ids.has(player.player_id):
			return false

		seen_ids[player.player_id] = true

	players.clear()

	for player in p_players:
		players.append(player)

	current_round = 0
	active_player_index = -1
	actions_remaining = 0
	_action_usage_this_turn.clear()

	return true


func start_match() -> bool:
	if is_running:
		return false

	if (
		players.size() < MIN_PLAYERS
		or players.size() > MAX_PLAYERS
	):
		return false

	is_running = true
	current_round = 1
	active_player_index = 0
	actions_remaining = ACTIONS_PER_TURN
	_action_usage_this_turn.clear()

	round_started.emit(current_round)
	turn_started.emit(
		get_active_player(),
		current_round,
		actions_remaining
	)

	return true


func get_player_count() -> int:
	return players.size()


func get_active_player() -> KarmanyPlayerState:
	if not is_running:
		return null

	if (
		active_player_index < 0
		or active_player_index >= players.size()
	):
		return null

	return players[active_player_index]


func get_player_by_id(
	player_id: StringName
) -> KarmanyPlayerState:
	for player in players:
		if player.player_id == player_id:
			return player

	return null


func can_spend_action(cost: int = 1) -> bool:
	if not is_running:
		return false

	if cost <= 0:
		return false

	return actions_remaining >= cost


func spend_action(cost: int = 1) -> bool:
	return _spend_action_internal(
		cost,
		&""
	)


func spend_action_for(
	action_id: StringName,
	cost: int = 1
) -> bool:
	if action_id == &"":
		return false

	return _spend_action_internal(
		cost,
		action_id
	)


func get_action_usage(action_id: StringName) -> int:
	if action_id == &"":
		return 0

	return int(
		_action_usage_this_turn.get(
			action_id,
			0
		)
	)


func has_used_action(action_id: StringName) -> bool:
	return get_action_usage(action_id) > 0


func _spend_action_internal(
	cost: int,
	action_id: StringName
) -> bool:
	if not can_spend_action(cost):
		return false

	var player := get_active_player()

	if player == null:
		return false

	actions_remaining -= cost

	if action_id != &"":
		_action_usage_this_turn[action_id] = (
			get_action_usage(action_id) + 1
		)

	action_spent.emit(
		player,
		cost,
		actions_remaining
	)

	return true


func can_end_turn() -> bool:
	if not is_running:
		return false

	if get_active_player() == null:
		return false

	return actions_remaining == 0


func end_turn() -> bool:
	if not can_end_turn():
		return false

	var ending_player := get_active_player()

	if ending_player == null:
		return false

	turn_ended.emit(
		ending_player,
		current_round
	)

	var was_last_player := (
		active_player_index == players.size() - 1
	)

	if was_last_player:
		round_ended.emit(current_round)
		current_round += 1
		active_player_index = 0
		round_started.emit(current_round)
	else:
		active_player_index += 1

	actions_remaining = ACTIONS_PER_TURN
	_action_usage_this_turn.clear()

	turn_started.emit(
		get_active_player(),
		current_round,
		actions_remaining
	)

	return true
