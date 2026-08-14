class_name KarmanyLocalMultiplayerSession
extends RefCounted


const MIN_LOCAL_PLAYERS: int = 2
const MAX_LOCAL_PLAYERS: int = 4


var players: Array[KarmanyPlayerState] = []
var starting_coords: Array[Vector2i] = []
var unit_ids: Array[StringName] = []
var turn_manager: KarmanyTurnManager = null
var legacy_points: KarmanyLegacyPointsController = null
var legacy_mode_config: KarmanyLegacyModeConfig = null
var configured: bool = false


func setup_local_players(player_count: int) -> bool:
	if player_count < MIN_LOCAL_PLAYERS or player_count > MAX_LOCAL_PLAYERS:
		return false

	var selected_starts := get_starting_coords_for_count(player_count)
	if selected_starts.size() != player_count:
		return false

	var new_players: Array[KarmanyPlayerState] = []
	var new_unit_ids: Array[StringName] = []
	var seen_ids: Dictionary = {}
	var seen_coords: Dictionary = {}

	for index in range(player_count):
		var player_id := StringName("player_%d" % (index + 1))
		var unit_id := StringName("trainer_player_%d" % (index + 1))
		var start_coord: Vector2i = selected_starts[index]

		if player_id == &"" or unit_id == &"":
			return false
		if seen_ids.has(player_id) or seen_coords.has(start_coord):
			return false

		var player := KarmanyPlayerState.new()
		player.setup_new_game(player_id, start_coord)
		new_players.append(player)
		new_unit_ids.append(unit_id)
		seen_ids[player_id] = true
		seen_coords[start_coord] = true

	var new_turn_manager := KarmanyTurnManager.new()
	if not new_turn_manager.setup_players(new_players):
		return false

	var new_mode_config := KarmanyLegacyModeConfig.new()
	if not new_mode_config.configure_standard(KarmanyLegacyModeConfig.MapFormat.MAP_41):
		return false

	var new_legacy_points := KarmanyLegacyPointsController.new()
	if not new_legacy_points.configure(new_players, new_mode_config):
		return false

	players.clear()
	starting_coords.clear()
	unit_ids.clear()
	for player in new_players:
		players.append(player)
	for coord in selected_starts:
		starting_coords.append(coord)
	for unit_id in new_unit_ids:
		unit_ids.append(unit_id)

	turn_manager = new_turn_manager
	legacy_mode_config = new_mode_config
	legacy_points = new_legacy_points
	configured = true
	return true


func start_match() -> bool:
	if not configured or turn_manager == null:
		return false
	return turn_manager.start_match()


func get_player_count() -> int:
	return players.size()


func get_player_by_id(player_id: StringName) -> KarmanyPlayerState:
	for player in players:
		if player != null and player.player_id == player_id:
			return player
	return null


func get_unit_id_for_player(player_id: StringName) -> StringName:
	for index in range(players.size()):
		var player: KarmanyPlayerState = players[index]
		if player != null and player.player_id == player_id:
			return unit_ids[index]
	return &""


func get_player_legacy_points(player_id: StringName) -> int:
	if legacy_points == null:
		return 0
	return legacy_points.get_total(player_id)


func is_player_turn(player_id: StringName) -> bool:
	if turn_manager == null or not turn_manager.is_running:
		return false
	var active_player := turn_manager.get_active_player()
	return active_player != null and active_player.player_id == player_id


func register_initial_occupancy(board_state: KarmanyBoardState) -> bool:
	if not configured or board_state == null:
		return false
	if starting_coords.size() != players.size() or unit_ids.size() != players.size():
		return false

	# The current validated BoardState models one trainer occupant per tile.
	# Phase 33 preserves that rule: it never overwrites a different occupant.
	for index in range(starting_coords.size()):
		var coord: Vector2i = starting_coords[index]
		var expected_unit_id: StringName = unit_ids[index]
		if not board_state.has_coord(coord):
			return false
		var existing_unit_id: StringName = board_state.get_occupying_unit_id(coord)
		if existing_unit_id != &"" and existing_unit_id != expected_unit_id:
			return false

	for index in range(starting_coords.size()):
		if not board_state.set_unit_occupant(starting_coords[index], unit_ids[index]):
			return false
	return true


func clear_registered_occupancy(board_state: KarmanyBoardState) -> void:
	if board_state == null:
		return
	for index in range(starting_coords.size()):
		var coord: Vector2i = starting_coords[index]
		if not board_state.has_coord(coord):
			continue
		if board_state.get_occupying_unit_id(coord) == unit_ids[index]:
			board_state.clear_unit_occupant(coord)


static func get_starting_coords_for_count(player_count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var canonical_starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	if canonical_starts.size() != 4:
		return result

	match player_count:
		2:
			# East / West are an exact opposite pair in the canonical layout.
			result.append(canonical_starts[0])
			result.append(canonical_starts[2])
		3:
			# Any three of the four symmetric accesses have the same distance
			# profile (5, 6, 8). Keep canonical order for deterministic setup.
			result.append(canonical_starts[0])
			result.append(canonical_starts[1])
			result.append(canonical_starts[2])
		4:
			for coord in canonical_starts:
				result.append(coord)

	return result
