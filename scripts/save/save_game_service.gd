class_name KarmanySaveGameService
extends RefCounted


const FORMAT_ID: String = "karmany_monsta_save"
const FORMAT_VERSION: int = 1


static func capture(context: KarmanySaveGameContext) -> Dictionary:
	if context == null or not context.is_valid():
		return {}
	return {
		"format": FORMAT_ID,
		"version": FORMAT_VERSION,
		"turn": _capture_turn(context.turn_manager),
		"board": _capture_board(context.board_state),
		"players": _capture_players(context.players),
		"resonance_deck": _capture_resonance_deck(context.resonance_deck),
		"equipment_market": _capture_equipment_market(context.equipment_market),
		"beast_decks": _capture_beast_decks(context.beast_decks),
		"legacy_points": _capture_legacy_points(context.legacy_points),
		"objectives_missions": _capture_objectives_missions(context.objectives_missions),
		"coordinator": _capture_coordinator(context.coordinator)
	}


static func save_to_path(context: KarmanySaveGameContext, path: String) -> bool:
	if path.is_empty():
		return false
	var snapshot: Dictionary = capture(context)
	if snapshot.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(snapshot, "  "))
	file.close()
	return true


static func load_snapshot_from_path(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	var snapshot: Dictionary = parsed
	if not is_supported_snapshot(snapshot):
		return {}
	return snapshot


static func restore_from_path(context: KarmanySaveGameContext, path: String) -> bool:
	var snapshot := load_snapshot_from_path(path)
	if snapshot.is_empty():
		return false
	return restore(context, snapshot)


static func is_supported_snapshot(snapshot: Dictionary) -> bool:
	return (
		String(snapshot.get("format", "")) == FORMAT_ID
		and int(snapshot.get("version", 0)) == FORMAT_VERSION
		and snapshot.has("turn")
		and snapshot.has("board")
		and snapshot.has("players")
	)


static func restore(context: KarmanySaveGameContext, snapshot: Dictionary) -> bool:
	if context == null or not context.is_valid() or not is_supported_snapshot(snapshot):
		return false
	if not _restore_players(context.players, snapshot.get("players", [])):
		return false
	if not _restore_board(context.board_state, snapshot.get("board", [])):
		return false
	if not _restore_resonance_deck(context.resonance_deck, snapshot.get("resonance_deck", {})):
		return false
	if not _restore_equipment_market(context.equipment_market, snapshot.get("equipment_market", {})):
		return false
	if not _restore_beast_decks(context.beast_decks, snapshot.get("beast_decks", {})):
		return false
	if not _restore_legacy_points(context.legacy_points, context.players, snapshot.get("legacy_points", {})):
		return false
	if not _restore_objectives_missions(context.objectives_missions, context.turn_manager, context.players, snapshot.get("objectives_missions", {})):
		return false
	if not _restore_coordinator(context.coordinator, snapshot.get("coordinator", {})):
		return false
	if not _restore_turn(context.turn_manager, context.players, snapshot.get("turn", {})):
		return false
	if context.coordinator.is_finished:
		context.coordinator.final_evaluation = context.legacy_points.evaluate_end_of_round(
			context.turn_manager.current_round
		)
	return true


static func _capture_turn(turn_manager: KarmanyTurnManager) -> Dictionary:
	var usage: Array = []
	for action_id in turn_manager._action_usage_this_turn.keys():
		usage.append({
			"action_id": String(action_id),
			"count": int(turn_manager._action_usage_this_turn[action_id])
		})
	return {
		"current_round": turn_manager.current_round,
		"active_player_index": turn_manager.active_player_index,
		"actions_remaining": turn_manager.actions_remaining,
		"is_running": turn_manager.is_running,
		"action_usage": usage
	}


static func _restore_turn(turn_manager: KarmanyTurnManager, players: Array[KarmanyPlayerState], data: Dictionary) -> bool:
	if data.is_empty() or players.is_empty():
		return false
	turn_manager.players.clear()
	for player in players:
		turn_manager.players.append(player)
	turn_manager.current_round = int(data.get("current_round", 0))
	turn_manager.active_player_index = int(data.get("active_player_index", -1))
	turn_manager.actions_remaining = int(data.get("actions_remaining", 0))
	turn_manager.is_running = bool(data.get("is_running", false))
	turn_manager._action_usage_this_turn.clear()
	for value in data.get("action_usage", []):
		if not (value is Dictionary):
			continue
		var record: Dictionary = value
		var action_id := StringName(String(record.get("action_id", "")))
		if action_id != &"":
			turn_manager._action_usage_this_turn[action_id] = int(record.get("count", 0))
	if turn_manager.is_running:
		if turn_manager.current_round <= 0:
			return false
		if turn_manager.active_player_index < 0 or turn_manager.active_player_index >= players.size():
			return false
		if turn_manager.actions_remaining < 0 or turn_manager.actions_remaining > KarmanyTurnManager.ACTIONS_PER_TURN:
			return false
	return true


static func _capture_board(board_state: KarmanyBoardState) -> Array:
	var result: Array = []
	for coord in board_state.get_coords():
		var cell := board_state.get_cell(coord)
		if cell == null:
			continue
		var record: Dictionary = {
			"coord": _coord_to_array(coord),
			"tile": _resource_path(cell.tile_data),
			"revealed": cell.revealed,
			"unit": String(cell.occupying_unit_id)
		}
		if cell.beast_state != null and cell.beast_state.is_blocking():
			record["beast"] = {
				"instance_id": String(cell.beast_state.instance_id),
				"data": _resource_path(cell.beast_state.beast_data),
				"coord": _coord_to_array(cell.beast_state.coord),
				"defeated": cell.beast_state.defeated
			}
		result.append(record)
	return result


static func _restore_board(board_state: KarmanyBoardState, data: Array) -> bool:
	if data.is_empty():
		return false
	board_state.clear()
	for value in data:
		if not (value is Dictionary):
			return false
		var record: Dictionary = value
		var coord := _array_to_coord(record.get("coord", []))
		var tile: KarmanyTileData = null
		var tile_path: String = String(record.get("tile", ""))
		if not tile_path.is_empty():
			tile = load(tile_path) as KarmanyTileData
			if tile == null:
				return false
		if not board_state.add_cell(coord, tile, bool(record.get("revealed", false))):
			return false
		var unit_id := StringName(String(record.get("unit", "")))
		if unit_id != &"" and not board_state.set_unit_occupant(coord, unit_id):
			return false
		var beast_value: Variant = record.get("beast", null)
		if beast_value is Dictionary:
			var beast_record: Dictionary = beast_value
			var beast_data := load(String(beast_record.get("data", ""))) as KarmanyBeastData
			if beast_data == null:
				return false
			var beast_state := KarmanyBeastRuntimeState.new()
			if not beast_state.configure(
				beast_data,
				StringName(String(beast_record.get("instance_id", ""))),
				_array_to_coord(beast_record.get("coord", []))
			):
				return false
			if bool(beast_record.get("defeated", false)):
				beast_state.mark_defeated()
			else:
				if not board_state.set_beast(coord, beast_state):
					return false
	return true


static func _capture_players(players: Array[KarmanyPlayerState]) -> Array:
	var result: Array = []
	for player in players:
		var roster: Array = []
		for runtime in player.get_linked_karmanys():
			roster.append({
				"instance_id": String(runtime.instance_id),
				"data": _resource_path(runtime.karmany_data),
				"owner": String(runtime.owner_player_id),
				"bond_state": int(runtime.bond_state)
			})
		result.append({
			"player_id": String(player.player_id),
			"coord": _coord_to_array(player.current_coord),
			"resources": [player.mn, player.mr, player.ek, player.fa],
			"roster": roster,
			"active_karmany": String(player.karmany_roster.get_active_instance_id()),
			"equipment": _capture_resource_array(player.get_equipped_equipment()),
			"resonance_hand": _capture_resource_array(player.get_resonance_hand()),
			"resonance_hand_limit": player.resonance_hand.get_hand_limit(),
			"pending_resonance_discard": player.resonance_hand.get_pending_discard_count()
		})
	return result


static func _restore_players(players: Array[KarmanyPlayerState], data: Array) -> bool:
	if players.size() != data.size():
		return false
	for index in range(players.size()):
		if not (data[index] is Dictionary):
			return false
		var player := players[index]
		var record: Dictionary = data[index]
		player.setup_new_game(
			StringName(String(record.get("player_id", ""))),
			_array_to_coord(record.get("coord", []))
		)
		var resources: Array = record.get("resources", [])
		if resources.size() != 4:
			return false
		for resource_type in range(4):
			if not player.resource_inventory.set_resource(resource_type, int(resources[resource_type])):
				return false
		for runtime_value in record.get("roster", []):
			if not (runtime_value is Dictionary):
				return false
			var runtime_record: Dictionary = runtime_value
			var karmany_data := load(String(runtime_record.get("data", ""))) as KarmanyData
			if karmany_data == null:
				return false
			var runtime := KarmanyRuntimeState.new()
			if not runtime.configure(karmany_data, StringName(String(runtime_record.get("instance_id", "")))):
				return false
			runtime.set_owner_player_id(StringName(String(runtime_record.get("owner", ""))))
			if not runtime.set_bond_state(int(runtime_record.get("bond_state", KarmanyRuntimeState.BondState.UNBOUND))):
				return false
			if runtime.is_linked() and not player.add_linked_karmany(runtime):
				return false
		var active_id := StringName(String(record.get("active_karmany", "")))
		if active_id != &"" and not player.set_active_karmany(active_id):
			return false
		for path_value in record.get("equipment", []):
			var equipment := load(String(path_value)) as KarmanyEquipmentData
			if equipment == null or not player.add_equipment(equipment):
				return false
		for path_value in record.get("resonance_hand", []):
			var card := load(String(path_value)) as KarmanyResonanceData
			if card == null or not player.resonance_hand.add_card(card):
				return false
		if not player.resonance_hand.set_hand_limit(int(record.get("resonance_hand_limit", KarmanyResonanceHand.BASE_HAND_LIMIT))):
			return false
		var pending: int = int(record.get("pending_resonance_discard", 0))
		if pending > 0 and not player.resonance_hand.request_discard(pending):
			return false
	return true


static func _capture_resonance_deck(deck: KarmanyResonanceDeck) -> Dictionary:
	return {
		"draw": _capture_resource_array(deck._draw_pile),
		"discard": _capture_resource_array(deck._discard_pile),
		"rng_state": str(deck._rng.state),
		"shuffle_on_recycle": deck._shuffle_on_recycle
	}


static func _restore_resonance_deck(deck: KarmanyResonanceDeck, data: Dictionary) -> bool:
	deck._draw_pile.clear()
	deck._discard_pile.clear()
	for path_value in data.get("draw", []):
		var card := load(String(path_value)) as KarmanyResonanceData
		if card == null:
			return false
		deck._draw_pile.append(card)
	for path_value in data.get("discard", []):
		var card := load(String(path_value)) as KarmanyResonanceData
		if card == null:
			return false
		deck._discard_pile.append(card)
	deck._shuffle_on_recycle = bool(data.get("shuffle_on_recycle", true))
	deck._rng.state = int(String(data.get("rng_state", "0")))
	deck.deck_changed.emit()
	return true


static func _capture_equipment_market(market: KarmanyEquipmentMarket) -> Dictionary:
	return {
		"visible": _capture_resource_array(market._visible),
		"draw": _capture_resource_array(market._draw_pile),
		"discard": _capture_resource_array(market._discard_pile),
		"rng_state": str(market._rng.state)
	}


static func _restore_equipment_market(market: KarmanyEquipmentMarket, data: Dictionary) -> bool:
	market._visible.clear()
	market._draw_pile.clear()
	market._discard_pile.clear()
	for path_value in data.get("visible", []):
		var equipment := load(String(path_value)) as KarmanyEquipmentData
		if equipment == null:
			return false
		market._visible.append(equipment)
	for path_value in data.get("draw", []):
		var equipment := load(String(path_value)) as KarmanyEquipmentData
		if equipment == null:
			return false
		market._draw_pile.append(equipment)
	for path_value in data.get("discard", []):
		var equipment := load(String(path_value)) as KarmanyEquipmentData
		if equipment == null:
			return false
		market._discard_pile.append(equipment)
	market._rng.state = int(String(data.get("rng_state", "0")))
	market.market_changed.emit()
	return true


static func _capture_beast_decks(decks: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for deck_id in decks.keys():
		var deck := decks[deck_id] as KarmanyBeastDeck
		if deck == null:
			continue
		result[String(deck_id)] = {
			"tier": deck.tier,
			"draw": _capture_resource_array(deck._draw_pile),
			"discard": _capture_resource_array(deck._discard_pile),
			"rng_state": str(deck._rng.state)
		}
	return result


static func _restore_beast_decks(decks: Dictionary, data: Dictionary) -> bool:
	for deck_id in decks.keys():
		var key: String = String(deck_id)
		if not data.has(key):
			return false
		var record: Dictionary = data[key]
		var deck := decks[deck_id] as KarmanyBeastDeck
		if deck == null:
			return false
		deck.tier = int(record.get("tier", -1))
		deck._draw_pile.clear()
		deck._discard_pile.clear()
		for path_value in record.get("draw", []):
			var beast := load(String(path_value)) as KarmanyBeastData
			if beast == null:
				return false
			deck._draw_pile.append(beast)
		for path_value in record.get("discard", []):
			var beast := load(String(path_value)) as KarmanyBeastData
			if beast == null:
				return false
			deck._discard_pile.append(beast)
		deck._rng.state = int(String(record.get("rng_state", "0")))
	return true


static func _capture_legacy_points(controller: KarmanyLegacyPointsController) -> Dictionary:
	var totals: Array = []
	for player_id in controller._totals.keys():
		totals.append({"player_id": String(player_id), "total": int(controller._totals[player_id])})
	var entries: Array = []
	for entry in controller._entries:
		entries.append({
			"player_id": String(entry.player_id),
			"source_type": int(entry.source_type),
			"source_id": String(entry.source_id),
			"points": entry.points,
			"round": entry.round_number,
			"unique_key": String(entry.unique_key),
			"note": entry.note
		})
	return {
		"mode": int(controller.mode_config.mode),
		"map_format": int(controller.mode_config.map_format),
		"round_limit": controller.mode_config.standard_round_limit,
		"race_target": controller.mode_config.race_target_points,
		"totals": totals,
		"entries": entries
	}


static func _restore_legacy_points(controller: KarmanyLegacyPointsController, players: Array[KarmanyPlayerState], data: Dictionary) -> bool:
	var mode := KarmanyLegacyModeConfig.new()
	var mode_type: int = int(data.get("mode", KarmanyLegacyModeConfig.Mode.STANDARD))
	var map_format: int = int(data.get("map_format", KarmanyLegacyModeConfig.MapFormat.MAP_22))
	var configured: bool = false
	if mode_type == KarmanyLegacyModeConfig.Mode.LEGACY_RACE:
		configured = mode.configure_legacy_race(map_format, int(data.get("race_target", 0)))
	else:
		configured = mode.configure_standard(map_format, int(data.get("round_limit", 0)))
	if not configured or not controller.configure(players, mode):
		return false
	for total_value in data.get("totals", []):
		if total_value is Dictionary:
			var total_record: Dictionary = total_value
			controller._totals[StringName(String(total_record.get("player_id", "")))] = int(total_record.get("total", 0))
	controller._entries.clear()
	controller._unique_awards.clear()
	for entry_value in data.get("entries", []):
		if not (entry_value is Dictionary):
			return false
		var record: Dictionary = entry_value
		var entry := KarmanyLegacyPointsEntry.new()
		if not entry.configure(
			StringName(String(record.get("player_id", ""))),
			int(record.get("source_type", KarmanyLegacyPointsEntry.SourceType.OTHER)),
			StringName(String(record.get("source_id", ""))),
			int(record.get("points", 0)),
			int(record.get("round", 0)),
			StringName(String(record.get("unique_key", ""))),
			String(record.get("note", ""))
		):
			return false
		controller._entries.append(entry)
		if entry.unique_key != &"":
			controller._unique_awards[entry.unique_key] = true
	return true


static func _capture_objectives_missions(manager: KarmanyObjectiveMissionManager) -> Dictionary:
	var objectives: Array = []
	for state_value in manager._objective_states.values():
		var state := state_value as KarmanyObjectiveState
		if state == null or state.objective_data == null:
			continue
		objectives.append({
			"data": _resource_path(state.objective_data),
			"claimed_by": String(state.claimed_by_player_id),
			"claimed_round": state.claimed_round
		})
	var missions: Array = []
	for assignment_value in manager._mission_assignments.values():
		var assignment := assignment_value as KarmanyMissionAssignment
		if assignment == null or assignment.mission_data == null:
			continue
		missions.append({
			"player_id": String(assignment.player_id),
			"data": _resource_path(assignment.mission_data),
			"status": int(assignment.status),
			"completed_round": assignment.completed_round,
			"reward_pl_pending": assignment.reward_legacy_points_pending
		})
	var pending_rewards: Array = []
	for reward in manager._pending_legacy_rewards:
		pending_rewards.append({
			"source_type": int(reward.source_type),
			"source_id": String(reward.source_id),
			"player_id": String(reward.player_id),
			"legacy_points": reward.legacy_points,
			"round": reward.round_number,
			"consumed": reward.consumed
		})
	return {
		"objectives": objectives,
		"missions": missions,
		"pending_rewards": pending_rewards,
		"progress_events": _capture_progress_events(manager.progress_tracker),
		"progress_states": _capture_progress_states(manager.progress_tracker)
	}


static func _restore_objectives_missions(manager: KarmanyObjectiveMissionManager, turn_manager: KarmanyTurnManager, players: Array[KarmanyPlayerState], data: Dictionary) -> bool:
	var objective_data: Array[KarmanyObjectiveData] = []
	for value in data.get("objectives", []):
		if not (value is Dictionary):
			return false
		var objective := load(String((value as Dictionary).get("data", ""))) as KarmanyObjectiveData
		if objective == null:
			return false
		objective_data.append(objective)
	if objective_data.is_empty() or not manager.configure(turn_manager, objective_data):
		return false
	for value in data.get("objectives", []):
		var record: Dictionary = value
		var objective := load(String(record.get("data", ""))) as KarmanyObjectiveData
		var state := manager.get_objective_state(objective.objective_id)
		if state == null:
			return false
		state.claimed_by_player_id = StringName(String(record.get("claimed_by", "")))
		state.claimed_round = int(record.get("claimed_round", 0))
	var player_by_id: Dictionary = {}
	for player in players:
		player_by_id[player.player_id] = player
	for value in data.get("missions", []):
		if not (value is Dictionary):
			return false
		var record: Dictionary = value
		var player_id := StringName(String(record.get("player_id", "")))
		var player := player_by_id.get(player_id, null) as KarmanyPlayerState
		var mission := load(String(record.get("data", ""))) as KarmanyMissionData
		if player == null or mission == null:
			return false
		if not manager.assign_secret_mission(player, mission.trainer_id, mission):
			return false
		var assignment := manager.get_mission_assignment(player_id)
		assignment.status = int(record.get("status", KarmanyMissionAssignment.Status.SECRET))
		assignment.completed_round = int(record.get("completed_round", 0))
		assignment.reward_legacy_points_pending = int(record.get("reward_pl_pending", 0))
	manager._pending_legacy_rewards.clear()
	for value in data.get("pending_rewards", []):
		if not (value is Dictionary):
			return false
		var record: Dictionary = value
		var reward := KarmanyLegacyRewardPending.new()
		if not reward.configure(
			int(record.get("source_type", 0)),
			StringName(String(record.get("source_id", ""))),
			StringName(String(record.get("player_id", ""))),
			int(record.get("legacy_points", 0)),
			int(record.get("round", 0))
		):
			return false
		reward.consumed = bool(record.get("consumed", false))
		manager._pending_legacy_rewards.append(reward)
	_restore_progress(manager.progress_tracker, data)
	return true


static func _capture_progress_events(tracker: KarmanyProgressTracker) -> Array:
	var result: Array = []
	for player_id in tracker._events_by_player.keys():
		var events_out: Array = []
		for event_value in tracker._events_by_player[player_id]:
			var event: Dictionary = event_value
			events_out.append({
				"event_id": String(event.get("event_id", &"")),
				"round": int(event.get("round", 0)),
				"payload": _json_safe(event.get("payload", {}))
			})
		result.append({"player_id": String(player_id), "events": events_out})
	return result


static func _capture_progress_states(tracker: KarmanyProgressTracker) -> Array:
	var result: Array = []
	for player_id in tracker._states_by_player.keys():
		var states: Dictionary = tracker._states_by_player[player_id]
		var states_out: Array = []
		for state_id in states.keys():
			states_out.append({"state_id": String(state_id), "value": int(states[state_id])})
		result.append({"player_id": String(player_id), "states": states_out})
	return result


static func _restore_progress(tracker: KarmanyProgressTracker, data: Dictionary) -> void:
	tracker.clear()
	for player_value in data.get("progress_events", []):
		if not (player_value is Dictionary):
			continue
		var player_record: Dictionary = player_value
		var player_id := StringName(String(player_record.get("player_id", "")))
		for event_value in player_record.get("events", []):
			if event_value is Dictionary:
				var event: Dictionary = event_value
				tracker.record_event(
					player_id,
					StringName(String(event.get("event_id", ""))),
					int(event.get("round", 0)),
					event.get("payload", {})
				)
	for player_value in data.get("progress_states", []):
		if not (player_value is Dictionary):
			continue
		var player_record: Dictionary = player_value
		var player_id := StringName(String(player_record.get("player_id", "")))
		for state_value in player_record.get("states", []):
			if state_value is Dictionary:
				var state_record: Dictionary = state_value
				tracker.set_state_int(
					player_id,
					StringName(String(state_record.get("state_id", ""))),
					int(state_record.get("value", 0))
				)


static func _capture_coordinator(coordinator: KarmanyMatchCoordinator) -> Dictionary:
	var books: Array = []
	for player_id in coordinator._book_states.keys():
		var state := coordinator._book_states[player_id] as KarmanyBookProgressState
		if state != null:
			books.append({"player_id": String(player_id), "level": state.level})
	var previous_coords: Array = []
	for player_id in coordinator._previous_coord_by_player.keys():
		previous_coords.append({
			"player_id": String(player_id),
			"coord": _coord_to_array(coordinator._previous_coord_by_player[player_id])
		})
	return {
		"books": books,
		"previous_coords": previous_coords,
		"combat_serial": coordinator._combat_serial,
		"is_finished": coordinator.is_finished,
		"encounters": _capture_encounters(coordinator.encounter_resolver),
		"aeterna": _capture_aeterna(coordinator.aeterna_state),
		"pvp_truce": _string_key_dictionary(coordinator.pvp_truce_tracker._last_pvp_round_by_pair),
		"forge_usage": _string_key_dictionary(coordinator.forge_controller._conversion_used_by_player)
	}


static func _restore_coordinator(coordinator: KarmanyMatchCoordinator, data: Dictionary) -> bool:
	coordinator._book_states.clear()
	for value in data.get("books", []):
		if not (value is Dictionary):
			return false
		var record: Dictionary = value
		var state := KarmanyBookProgressState.new()
		var player_id := StringName(String(record.get("player_id", "")))
		if not state.configure(player_id) or not state.set_level(int(record.get("level", 1))):
			return false
		coordinator._book_states[player_id] = state
	coordinator._previous_coord_by_player.clear()
	for value in data.get("previous_coords", []):
		if value is Dictionary:
			var record: Dictionary = value
			coordinator._previous_coord_by_player[StringName(String(record.get("player_id", "")))] = _array_to_coord(record.get("coord", []))
	coordinator._combat_serial = int(data.get("combat_serial", 0))
	coordinator.is_finished = bool(data.get("is_finished", false))
	coordinator.final_evaluation = null
	if not _restore_encounters(coordinator.encounter_resolver, data.get("encounters", {})):
		return false
	_restore_aeterna(coordinator.aeterna_state, data.get("aeterna", {}))
	coordinator.pvp_truce_tracker._last_pvp_round_by_pair = _restore_string_key_int_dictionary(data.get("pvp_truce", {}))
	coordinator.forge_controller._conversion_used_by_player = _restore_stringname_key_dictionary(data.get("forge_usage", {}), true)
	return true


static func _capture_encounters(resolver: KarmanyEncounterResolver) -> Dictionary:
	var encounters: Array = []
	for encounter in resolver.active_encounters:
		var data := encounter.get_karmany_data()
		if data == null:
			continue
		encounters.append({
			"encounter_id": String(encounter.encounter_id),
			"data": _resource_path(data),
			"coord": _coord_to_array(encounter.source_coord),
			"source_rank": encounter.source_rank,
			"revealed_by": String(encounter.revealed_by_player_id),
			"pending_player": String(encounter.pending_player_id),
			"status": int(encounter.status),
			"turn_ends_until_expire": encounter.owner_turn_ends_until_expire
		})
	var last_calls: Array = []
	for player_id in resolver._last_call_round_by_player.keys():
		last_calls.append({"player_id": String(player_id), "round": int(resolver._last_call_round_by_player[player_id])})
	return {
		"active": encounters,
		"last_calls": last_calls,
		"sequence": resolver._encounter_sequence
	}


static func _restore_encounters(resolver: KarmanyEncounterResolver, data: Dictionary) -> bool:
	resolver.active_encounters.clear()
	resolver._last_call_round_by_player.clear()
	resolver._encounter_sequence = int(data.get("sequence", 0))
	for value in data.get("active", []):
		if not (value is Dictionary):
			return false
		var record: Dictionary = value
		var karmany := load(String(record.get("data", ""))) as KarmanyData
		if karmany == null:
			return false
		var encounter := KarmanyEncounterState.new()
		if not encounter.configure(
			karmany,
			StringName(String(record.get("encounter_id", ""))),
			_array_to_coord(record.get("coord", [])),
			int(record.get("source_rank", KarmanyData.Rank.N1)),
			StringName(String(record.get("revealed_by", "")))
		):
			return false
		encounter.pending_player_id = StringName(String(record.get("pending_player", "")))
		encounter.status = int(record.get("status", KarmanyEncounterState.Status.AVAILABLE))
		encounter.owner_turn_ends_until_expire = int(record.get("turn_ends_until_expire", 2))
		resolver.active_encounters.append(encounter)
	for value in data.get("last_calls", []):
		if value is Dictionary:
			var record: Dictionary = value
			resolver._last_call_round_by_player[StringName(String(record.get("player_id", "")))] = int(record.get("round", 0))
	return true


static func _capture_aeterna(state: KarmanyAeternaState) -> Dictionary:
	return {
		"defeated": state.defeated,
		"defeated_by": String(state.defeated_by_player_id),
		"defeated_round": state.defeated_round,
		"attunement": _string_key_dictionary(state._sanctuary_attunement_used),
		"sync": _string_key_dictionary(state._aeterna_sync_used),
		"post_ek": _string_key_dictionary(state._post_defeat_ek_round_by_player)
	}


static func _restore_aeterna(state: KarmanyAeternaState, data: Dictionary) -> void:
	state.reset()
	state.defeated = bool(data.get("defeated", false))
	state.defeated_by_player_id = StringName(String(data.get("defeated_by", "")))
	state.defeated_round = int(data.get("defeated_round", 0))
	state._sanctuary_attunement_used = _restore_stringname_key_dictionary(data.get("attunement", {}), true)
	state._aeterna_sync_used = _restore_stringname_key_dictionary(data.get("sync", {}), true)
	state._post_defeat_ek_round_by_player = _restore_stringname_key_dictionary(data.get("post_ek", {}), false)


static func _capture_resource_array(items: Array) -> Array:
	var result: Array = []
	for value in items:
		if value is Resource:
			var path := _resource_path(value as Resource)
			if not path.is_empty():
				result.append(path)
	return result


static func _resource_path(resource: Resource) -> String:
	if resource == null:
		return ""
	return resource.resource_path


static func _coord_to_array(coord: Vector2i) -> Array:
	return [coord.x, coord.y]


static func _array_to_coord(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


static func _string_key_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source.keys():
		result[String(key)] = _json_safe(source[key])
	return result


static func _restore_string_key_int_dictionary(source_value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (source_value is Dictionary):
		return result
	var source: Dictionary = source_value
	for key in source.keys():
		result[String(key)] = int(source[key])
	return result


static func _restore_stringname_key_dictionary(source_value: Variant, bool_values: bool) -> Dictionary:
	var result: Dictionary = {}
	if not (source_value is Dictionary):
		return result
	var source: Dictionary = source_value
	for key in source.keys():
		result[StringName(String(key))] = bool(source[key]) if bool_values else int(source[key])
	return result


static func _json_safe(value: Variant) -> Variant:
	if value is StringName:
		return String(value)
	if value is Vector2i:
		return _coord_to_array(value)
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_json_safe(item))
		return result_array
	if value is Dictionary:
		var result_dict: Dictionary = {}
		for key in value.keys():
			result_dict[String(key)] = _json_safe(value[key])
		return result_dict
	return value
