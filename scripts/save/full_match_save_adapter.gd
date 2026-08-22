class_name KarmanyFullMatchSaveAdapter
extends RefCounted


const FORMAT_ID: String = "karmany_full_match_save"
const FORMAT_VERSION: int = 1

const STAGE_NONE: String = "none"
const STAGE_ACTION: String = "action"
const STAGE_INSTINCT: String = "instinct"
const STAGE_COMBAT_RESONANCE: String = "combat_resonance"
const STAGE_HAND_DISCARD: String = "hand_discard"
const STAGE_AETERNA_REWARD: String = "aeterna_reward"
const STAGE_AETERNA_RESOURCE: String = "aeterna_resource"
const STAGE_AETERNA_RESONANCE: String = "aeterna_resonance"


static func capture(session: KarmanyFullMatchSession) -> Dictionary:
	if not _is_valid_session(session):
		return {}
	var context := _build_context(session)
	if context == null:
		return {}
	var runtime_snapshot := KarmanySaveGameService.capture(context)
	if runtime_snapshot.is_empty():
		return {}
	return {
		"format": FORMAT_ID,
		"version": FORMAT_VERSION,
		"runtime": runtime_snapshot,
		"session": _capture_session_overlay(session),
	}


static func is_supported_package(package: Dictionary) -> bool:
	if String(package.get("format", "")) != FORMAT_ID:
		return false
	if int(package.get("version", 0)) != FORMAT_VERSION:
		return false
	if not (package.get("runtime", null) is Dictionary):
		return false
	if not (package.get("session", null) is Dictionary):
		return false
	return KarmanySaveGameService.is_supported_snapshot(package.get("runtime", {}))


static func restore(session: KarmanyFullMatchSession, package: Dictionary) -> bool:
	if not _is_valid_session(session) or not is_supported_package(package):
		return false
	var rollback := capture(session)
	if rollback.is_empty():
		return false
	if _restore_without_rollback(session, package):
		return true
	_restore_without_rollback(session, rollback)
	return false


static func build_fresh_session_from_package(package: Dictionary) -> Dictionary:
	if not is_supported_package(package):
		return {"ok": false, "message": "Guardado F47 incompatible."}
	var overlay: Dictionary = package.get("session", {})
	var seed_value: int = int(overlay.get("match_seed", 0))
	var human_id := StringName(String(overlay.get("human_player_id", "player_1")))
	if seed_value == 0 or human_id == &"":
		return {"ok": false, "message": "Guardado F47 sin seed/jugador humano valido."}

	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value, human_id):
		return {"ok": false, "message": "No se pudo reconstruir runtime limpio."}
	var session := KarmanyFullMatchSession.new()
	session.verbose_console_output = false
	session.forced_starting_choice_by_player = _restore_stringname_value_dictionary(
		overlay.get("forced_starting_choices", {})
	)
	if not session.configure(runtime):
		return {"ok": false, "message": "No se pudo reconstruir FullMatchSession: %s" % session.last_error}
	if not restore(session, package):
		return {"ok": false, "message": "El snapshot no pudo restaurarse sobre runtime limpio."}
	return {"ok": true, "runtime": runtime, "session": session, "message": "CONTINUAR OK"}


static func _restore_without_rollback(session: KarmanyFullMatchSession, package: Dictionary) -> bool:
	if not is_supported_package(package):
		return false
	var overlay: Dictionary = package.get("session", {})
	if int(overlay.get("match_seed", 0)) != session.match_seed:
		return false
	if StringName(String(overlay.get("human_player_id", ""))) != session.runtime.human_player_id:
		return false
	var context := _build_context(session)
	if context == null:
		return false
	if not KarmanySaveGameService.restore(context, package.get("runtime", {})):
		return false
	if not _restore_session_overlay(session, overlay):
		return false
	return _validate_restored_session(session)


static func _build_context(session: KarmanyFullMatchSession) -> KarmanySaveGameContext:
	if not _is_valid_session(session):
		return null
	var context := KarmanySaveGameContext.new()
	var players: Array[KarmanyPlayerState] = []
	for player in session.runtime.local_session.players:
		if player is KarmanyPlayerState:
			players.append(player)
	var beast_decks: Dictionary = {}
	for tier in session.runtime.beast_decks_by_tier.keys():
		var deck := session.runtime.beast_decks_by_tier.get(tier, null) as KarmanyBeastDeck
		if deck != null:
			beast_decks[tier] = deck
	if not context.configure(
		session.runtime.board_state,
		session.runtime.local_session.turn_manager,
		players,
		session.runtime.resonance_deck,
		session.runtime.equipment_market,
		session.runtime.local_session.legacy_points,
		session.runtime.objectives_missions,
		session.runtime.coordinator,
		beast_decks,
		null
	):
		return null
	return context


static func _capture_session_overlay(session: KarmanyFullMatchSession) -> Dictionary:
	return {
		"match_seed": session.match_seed,
		"human_player_id": String(session.runtime.human_player_id),
		"match_state": int(session.match_state),
		"setup_rng_state": str(session._setup_rng.state),
		"action_rng_state": str(session._action_rng.state),
		"content_rng_state": str(session.runtime._content_rng.state),
		"auto_human_brain": _capture_brain(session._auto_human_brain),
		"ai_controllers": _capture_ai_controllers(session.runtime.ai_match_controller),
		"statistics": _json_safe(session.statistics),
		"alpha_log": Array(session.alpha_log),
		"final_result": _json_safe(session.final_result),
		"completed_mission_players": _string_key_dictionary(session.completed_mission_players),
		"forced_starting_choices": _string_key_dictionary(session.forced_starting_choice_by_player),
		"trackers": _capture_full_match_trackers(session),
		"request_counters": _capture_request_counters(session),
		"pending": _capture_pending_decision(session),
	}


static func _restore_session_overlay(session: KarmanyFullMatchSession, data: Dictionary) -> bool:
	var state_value: int = int(data.get("match_state", -1))
	if state_value < KarmanyFullMatchSessionBase.MatchState.SETUP or state_value > KarmanyFullMatchSessionBase.MatchState.FINISHED:
		return false
	session.match_state = state_value
	session._setup_rng.state = _parse_rng_state(data.get("setup_rng_state", "0"))
	session._action_rng.state = _parse_rng_state(data.get("action_rng_state", "0"))
	session.runtime._content_rng.state = _parse_rng_state(data.get("content_rng_state", "0"))
	if not _restore_brain(session._auto_human_brain, data.get("auto_human_brain", {})):
		return false
	if not _restore_ai_controllers(session.runtime.ai_match_controller, data.get("ai_controllers", [])):
		return false
	session.statistics = _dictionary_copy(data.get("statistics", {}))
	session.alpha_log = PackedStringArray(data.get("alpha_log", []))
	session.final_result = _dictionary_copy(data.get("final_result", {}))
	session.completed_mission_players = _restore_stringname_key_dictionary(data.get("completed_mission_players", {}))
	session.forced_starting_choice_by_player = _restore_stringname_value_dictionary(data.get("forced_starting_choices", {}))
	if not _restore_full_match_trackers(session, data.get("trackers", {})):
		return false
	_restore_request_counters(session, data.get("request_counters", {}))
	_clear_pending_requests(session)
	if not _restore_pending_decision(session, data.get("pending", {})):
		return false
	session.configured = true
	return true


static func _capture_brain(brain: KarmanyAiBrain) -> Dictionary:
	if brain == null:
		return {}
	return {
		"profile_type": int(brain.profile.profile_type),
		"rng_state": str(brain.rng.state),
		"last_signature": brain._last_executed_signature,
		"same_action_streak": brain._same_action_streak,
	}


static func _restore_brain(brain: KarmanyAiBrain, data: Dictionary) -> bool:
	if brain == null or data.is_empty():
		return false
	if not brain.profile.configure(int(data.get("profile_type", -1))):
		return false
	brain.rng.state = _parse_rng_state(data.get("rng_state", "0"))
	brain._last_executed_signature = String(data.get("last_signature", ""))
	brain._same_action_streak = int(data.get("same_action_streak", 0))
	return brain._same_action_streak >= 0


static func _capture_ai_controllers(controller: KarmanyMultiAiMatchController) -> Array:
	var result: Array = []
	if controller == null:
		return result
	for player_id in controller.get_ai_player_ids():
		var turn_controller := controller.get_ai_controller(player_id)
		if turn_controller == null:
			continue
		result.append({
			"player_id": String(player_id),
			"brain": _capture_brain(turn_controller.brain),
			"last_turn_ended": turn_controller.last_turn_ended,
			"last_choice_label": turn_controller.last_choice_label,
		})
	return result


static func _restore_ai_controllers(controller: KarmanyMultiAiMatchController, rows: Array) -> bool:
	if controller == null:
		return false
	var restored: int = 0
	for value in rows:
		if not (value is Dictionary):
			return false
		var row: Dictionary = value
		var player_id := StringName(String(row.get("player_id", "")))
		var turn_controller := controller.get_ai_controller(player_id)
		if turn_controller == null or not _restore_brain(turn_controller.brain, row.get("brain", {})):
			return false
		turn_controller.last_turn_ended = bool(row.get("last_turn_ended", false))
		turn_controller.last_choice_label = String(row.get("last_choice_label", ""))
		restored += 1
	return restored == controller.get_ai_controller_count()


static func _capture_full_match_trackers(session: KarmanyFullMatchSession) -> Dictionary:
	return {
		"last_coord": _capture_coord_by_player(session._last_coord_by_player),
		"turn_start_coord": _capture_coord_by_player(session._turn_start_coord_by_player),
		"entry_bonus_coords": _capture_coord_set_by_player(session._entry_bonus_coords_by_player),
		"entry_bonus_count": _string_key_dictionary(session._entry_bonus_count_by_player),
		"explored_this_turn": _string_key_dictionary(session._explored_this_turn_by_player),
	}


static func _restore_full_match_trackers(session: KarmanyFullMatchSession, data: Dictionary) -> bool:
	session._last_coord_by_player = _restore_coord_by_player(data.get("last_coord", []))
	session._turn_start_coord_by_player = _restore_coord_by_player(data.get("turn_start_coord", []))
	session._entry_bonus_coords_by_player = _restore_coord_set_by_player(data.get("entry_bonus_coords", []))
	session._entry_bonus_count_by_player = _restore_stringname_key_dictionary(data.get("entry_bonus_count", {}))
	session._explored_this_turn_by_player = _restore_stringname_key_dictionary(data.get("explored_this_turn", {}))
	return true


static func _capture_request_counters(session: KarmanyFullMatchSession) -> Dictionary:
	return {
		"action": session._next_human_choice_request_id,
		"hand_discard": session._next_human_resonance_discard_request_id,
		"combat_resonance": session._next_human_combat_resonance_request_id,
		"instinct": session._next_human_instinct_request_id,
		"aeterna_reward": session._next_human_aeterna_reward_request_id,
		"aeterna_resource": session._next_human_aeterna_resource_request_id,
		"aeterna_resonance": session._next_human_aeterna_resonance_request_id,
	}


static func _restore_request_counters(session: KarmanyFullMatchSession, data: Dictionary) -> void:
	session._next_human_choice_request_id = maxi(1, int(data.get("action", 1)))
	session._next_human_resonance_discard_request_id = maxi(1, int(data.get("hand_discard", 1)))
	session._next_human_combat_resonance_request_id = maxi(1, int(data.get("combat_resonance", 1)))
	session._next_human_instinct_request_id = maxi(1, int(data.get("instinct", 1)))
	session._next_human_aeterna_reward_request_id = maxi(1, int(data.get("aeterna_reward", 1)))
	session._next_human_aeterna_resource_request_id = maxi(1, int(data.get("aeterna_resource", 1)))
	session._next_human_aeterna_resonance_request_id = maxi(1, int(data.get("aeterna_resonance", 1)))


static func _capture_pending_decision(session: KarmanyFullMatchSession) -> Dictionary:
	var aeterna_reward := session.get_pending_human_aeterna_reward_request()
	if aeterna_reward != null:
		return _capture_aeterna_pending(session, STAGE_AETERNA_REWARD, aeterna_reward.request_id)
	var aeterna_resource := session.get_pending_human_aeterna_resource_request()
	if aeterna_resource != null:
		return _capture_aeterna_pending(session, STAGE_AETERNA_RESOURCE, aeterna_resource.request_id)
	var aeterna_resonance := session.get_pending_human_aeterna_resonance_request()
	if aeterna_resonance != null:
		return _capture_aeterna_pending(session, STAGE_AETERNA_RESONANCE, aeterna_resonance.request_id)
	var instinct := session.get_pending_human_instinct_roll_request()
	if instinct != null and session._pending_human_instinct_candidate != null:
		return {
			"stage": STAGE_INSTINCT,
			"request_id": instinct.request_id,
			"candidate": _capture_candidate_descriptor(session._pending_human_instinct_candidate),
		}
	var combat := session.get_pending_human_combat_resonance_request()
	if combat != null and session._pending_human_combat_candidate != null:
		return {
			"stage": STAGE_COMBAT_RESONANCE,
			"request_id": combat.request_id,
			"candidate": _capture_candidate_descriptor(session._pending_human_combat_candidate),
			"instinct_roll": session._get_human_instinct_roll(session._pending_human_combat_candidate),
		}
	var hand_discard := session.get_pending_human_resonance_discard_request()
	if hand_discard != null:
		return {
			"stage": STAGE_HAND_DISCARD,
			"request_id": hand_discard.request_id,
			"required_count": hand_discard.required_count,
		}
	var action := session.get_pending_human_choice_request()
	if action != null:
		var descriptors: Array = []
		for option_id in action.get_option_ids():
			var candidate := action._candidate_by_option_id.get(option_id, null) as KarmanyAiActionCandidate
			if candidate != null:
				descriptors.append(_capture_candidate_descriptor(candidate))
		return {
			"stage": STAGE_ACTION,
			"request_id": action.request_id,
			"candidates": descriptors,
		}
	return {"stage": STAGE_NONE}


static func _capture_aeterna_pending(session: KarmanyFullMatchSession, stage: String, request_id: int) -> Dictionary:
	return {
		"stage": stage,
		"request_id": request_id,
		"result": _capture_aeterna_result(session._pending_human_aeterna_result),
		"reward_drawn_ids": _stringname_array_to_strings(session._pending_human_aeterna_reward_drawn_ids),
		"explicit_in_progress": session._explicit_human_aeterna_in_progress,
	}


static func _restore_pending_decision(session: KarmanyFullMatchSession, data: Dictionary) -> bool:
	var stage: String = String(data.get("stage", STAGE_NONE))
	if stage == STAGE_NONE:
		return true
	var manager := session.runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not session.runtime.ai_match_controller.is_human_player(player.player_id):
		return false
	var request_id: int = int(data.get("request_id", 0))
	if request_id <= 0:
		return false
	match stage:
		STAGE_ACTION:
			return _restore_action_request(session, player, request_id, data.get("candidates", []))
		STAGE_INSTINCT:
			return _restore_instinct_request(session, player, request_id, data.get("candidate", {}))
		STAGE_COMBAT_RESONANCE:
			return _restore_combat_resonance_request(session, player, request_id, data)
		STAGE_HAND_DISCARD:
			return _restore_hand_discard_request(session, player, request_id, int(data.get("required_count", 0)))
		STAGE_AETERNA_REWARD, STAGE_AETERNA_RESOURCE, STAGE_AETERNA_RESONANCE:
			return _restore_aeterna_pending(session, player, stage, request_id, data)
	return false


static func _restore_action_request(session: KarmanyFullMatchSession, player: KarmanyPlayerState, request_id: int, descriptors: Array) -> bool:
	var generated := _regenerate_legal_actions_without_rng_side_effects(session, player)
	if generated.size() != descriptors.size():
		return false
	for index in range(descriptors.size()):
		if not (descriptors[index] is Dictionary) or not _candidate_matches_descriptor(generated[index], descriptors[index], true):
			return false
	var request := KarmanyChoiceRequest.new()
	if not request.configure(request_id, player.player_id, session.runtime.local_session.turn_manager.current_round, session.runtime.local_session.turn_manager.actions_remaining, generated):
		return false
	session._pending_human_choice_request = request
	return true


static func _restore_instinct_request(session: KarmanyFullMatchSession, player: KarmanyPlayerState, request_id: int, descriptor: Dictionary) -> bool:
	var candidate := _find_regenerated_candidate(session, player, descriptor)
	if candidate == null:
		return false
	session._clear_human_combat_resonance(candidate)
	session._clear_human_instinct_roll(candidate)
	var request := session._create_human_instinct_request(candidate)
	if request == null:
		return false
	var manager := session.runtime.local_session.turn_manager
	if not request.configure(request_id, player.player_id, manager.current_round, manager.actions_remaining, candidate.action_type, candidate.debug_label, candidate.target_coord):
		return false
	session._pending_human_instinct_candidate = candidate
	session._pending_human_instinct_request = request
	return true


static func _restore_combat_resonance_request(session: KarmanyFullMatchSession, player: KarmanyPlayerState, request_id: int, data: Dictionary) -> bool:
	var candidate := _find_regenerated_candidate(session, player, data.get("candidate", {}))
	if candidate == null:
		return false
	session._clear_human_combat_resonance(candidate)
	var instinct_roll: int = int(data.get("instinct_roll", 0))
	if instinct_roll > 0 and not session._apply_human_instinct_roll(candidate, instinct_roll):
		return false
	var cards := session._get_selectable_human_combat_resonances(player, candidate)
	if cards.is_empty():
		return false
	var manager := session.runtime.local_session.turn_manager
	var request := KarmanyCombatResonanceChoiceRequest.new()
	if not request.configure(request_id, player.player_id, manager.current_round, manager.actions_remaining, candidate.action_type, candidate.debug_label, candidate.target_coord, cards, player.get_resonance_hand()):
		return false
	session._pending_human_combat_candidate = candidate
	session._pending_human_combat_resonance_request = request
	return true


static func _restore_hand_discard_request(session: KarmanyFullMatchSession, player: KarmanyPlayerState, request_id: int, required_count: int) -> bool:
	if required_count <= 0 or player.resonance_hand.get_pending_discard_count() != required_count:
		return false
	var request := KarmanyResonanceDiscardChoiceRequest.new()
	if not request.configure(request_id, player.player_id, session.runtime.local_session.turn_manager.current_round, required_count, player.get_resonance_hand()):
		return false
	session._pending_human_resonance_discard_request = request
	return true


static func _restore_aeterna_pending(session: KarmanyFullMatchSession, player: KarmanyPlayerState, stage: String, request_id: int, data: Dictionary) -> bool:
	var result := _restore_aeterna_result(data.get("result", {}))
	if result == null or not result.is_resolved():
		return false
	session._pending_human_aeterna_result = result
	session._pending_human_aeterna_reward_drawn_ids = _strings_to_stringname_array(data.get("reward_drawn_ids", []))
	session._explicit_human_aeterna_in_progress = bool(data.get("explicit_in_progress", false))
	match stage:
		STAGE_AETERNA_REWARD:
			session._next_human_aeterna_reward_request_id = request_id
			if not session._open_human_aeterna_reward_request(player, result):
				return false
		STAGE_AETERNA_RESOURCE:
			session._next_human_aeterna_resource_request_id = request_id
			if not session._open_human_aeterna_resource_request(player, result):
				return false
		STAGE_AETERNA_RESONANCE:
			session._next_human_aeterna_resonance_request_id = request_id
			if not session._open_human_aeterna_resonance_request(player):
				return false
		_:
			return false
	return true


static func _regenerate_legal_actions_without_rng_side_effects(session: KarmanyFullMatchSession, player: KarmanyPlayerState) -> Array[KarmanyAiActionCandidate]:
	var action_state: int = session._action_rng.state
	var content_state: int = session.runtime._content_rng.state
	var result := session.build_full_legal_actions(player)
	session._action_rng.state = action_state
	session.runtime._content_rng.state = content_state
	return result


static func _find_regenerated_candidate(session: KarmanyFullMatchSession, player: KarmanyPlayerState, descriptor: Dictionary) -> KarmanyAiActionCandidate:
	var candidates := _regenerate_legal_actions_without_rng_side_effects(session, player)
	for candidate in candidates:
		if _candidate_matches_descriptor(candidate, descriptor, true):
			return candidate
	var relaxed: Array[KarmanyAiActionCandidate] = []
	for candidate in candidates:
		if _candidate_matches_descriptor(candidate, descriptor, false):
			relaxed.append(candidate)
	return relaxed[0] if relaxed.size() == 1 else null


static func _capture_candidate_descriptor(candidate: KarmanyAiActionCandidate) -> Dictionary:
	return {
		"action_type": candidate.action_type,
		"target": [candidate.target_coord.x, candidate.target_coord.y],
		"option_index": candidate.option_index,
		"debug_label": candidate.debug_label,
	}


static func _candidate_matches_descriptor(candidate: KarmanyAiActionCandidate, descriptor: Dictionary, strict_label: bool) -> bool:
	if candidate == null:
		return false
	var target := _array_to_coord(descriptor.get("target", []))
	if candidate.action_type != int(descriptor.get("action_type", -1)):
		return false
	if candidate.target_coord != target or candidate.option_index != int(descriptor.get("option_index", -1)):
		return false
	return not strict_label or candidate.debug_label == String(descriptor.get("debug_label", ""))


static func _capture_aeterna_result(result: KarmanyAeternaResult) -> Dictionary:
	if result == null:
		return {}
	return {
		"status": int(result.status), "outcome": int(result.outcome), "message": result.message,
		"action_consumed": result.action_consumed, "fa_spent": result.fa_spent,
		"reward_choice_required": result.reward_choice_required, "reward_choice": int(result.reward_choice),
		"reward_resolved": result.reward_resolved, "ancestral_equipment_id": String(result.ancestral_equipment_id),
		"replaced_equipment_id": String(result.replaced_equipment_id), "resonance_cards_drawn": result.resonance_cards_drawn,
		"resonance_discard_pending": result.resonance_discard_pending,
		"basic_resources_discard_pending": result.basic_resources_discard_pending,
		"retreat_required": result.retreat_required, "post_defeat_ek_gained": result.post_defeat_ek_gained,
	}


static func _restore_aeterna_result(data: Dictionary) -> KarmanyAeternaResult:
	if data.is_empty():
		return null
	var result := KarmanyAeternaResult.new()
	result.status = int(data.get("status", KarmanyAeternaResult.Status.INVALID_REQUEST))
	result.outcome = int(data.get("outcome", KarmanyAeternaResult.Outcome.NONE))
	result.message = String(data.get("message", ""))
	result.action_consumed = bool(data.get("action_consumed", false))
	result.fa_spent = int(data.get("fa_spent", 0))
	result.reward_choice_required = bool(data.get("reward_choice_required", false))
	result.reward_choice = int(data.get("reward_choice", KarmanyAeternaResult.RewardChoice.NONE))
	result.reward_resolved = bool(data.get("reward_resolved", false))
	result.ancestral_equipment_id = StringName(String(data.get("ancestral_equipment_id", "")))
	result.replaced_equipment_id = StringName(String(data.get("replaced_equipment_id", "")))
	result.resonance_cards_drawn = int(data.get("resonance_cards_drawn", 0))
	result.resonance_discard_pending = int(data.get("resonance_discard_pending", 0))
	result.basic_resources_discard_pending = int(data.get("basic_resources_discard_pending", 0))
	result.retreat_required = bool(data.get("retreat_required", false))
	result.post_defeat_ek_gained = int(data.get("post_defeat_ek_gained", 0))
	return result


static func _clear_pending_requests(session: KarmanyFullMatchSession) -> void:
	session._pending_human_choice_request = null
	session._pending_human_resonance_discard_request = null
	session._pending_human_combat_resonance_request = null
	session._pending_human_combat_candidate = null
	session._pending_human_instinct_request = null
	session._pending_human_instinct_candidate = null
	session._pending_human_aeterna_reward_request = null
	session._pending_human_aeterna_resource_request = null
	session._pending_human_aeterna_resonance_request = null
	session._pending_human_aeterna_result = null
	session._pending_human_aeterna_reward_drawn_ids.clear()
	session._explicit_human_aeterna_in_progress = false


static func _validate_restored_session(session: KarmanyFullMatchSession) -> bool:
	if not _is_valid_session(session):
		return false
	var manager := session.runtime.local_session.turn_manager
	if session.match_state == KarmanyFullMatchSessionBase.MatchState.PLAYING:
		if manager == null or not manager.is_running or manager.get_active_player() == null:
			return false
	if session.match_state == KarmanyFullMatchSessionBase.MatchState.FINISHED:
		if manager != null and manager.is_running:
			return false
		if not session.runtime.coordinator.is_finished:
			return false
	return true


static func _is_valid_session(session: KarmanyFullMatchSession) -> bool:
	return (
		session != null and session.configured and session.runtime != null and session.runtime.configured
		and session.runtime.local_session != null and session.runtime.coordinator != null
	)


static func _capture_coord_by_player(source: Dictionary) -> Array:
	var result: Array = []
	for player_id in source.keys():
		var value: Variant = source[player_id]
		if value is Vector2i:
			result.append({"player_id": String(player_id), "coord": [value.x, value.y]})
	return result


static func _restore_coord_by_player(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for value in rows:
		if value is Dictionary:
			var row: Dictionary = value
			result[StringName(String(row.get("player_id", "")))] = _array_to_coord(row.get("coord", []))
	return result


static func _capture_coord_set_by_player(source: Dictionary) -> Array:
	var result: Array = []
	for player_id in source.keys():
		var coords_out: Array = []
		var set_value: Variant = source[player_id]
		if set_value is Dictionary:
			for coord in (set_value as Dictionary).keys():
				if coord is Vector2i:
					coords_out.append([coord.x, coord.y])
		result.append({"player_id": String(player_id), "coords": coords_out})
	return result


static func _restore_coord_set_by_player(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	for value in rows:
		if not (value is Dictionary):
			continue
		var row: Dictionary = value
		var coord_set: Dictionary = {}
		for coord_value in row.get("coords", []):
			coord_set[_array_to_coord(coord_value)] = true
		result[StringName(String(row.get("player_id", "")))] = coord_set
	return result


static func _string_key_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source.keys():
		result[String(key)] = _json_safe(source[key])
	return result


static func _restore_stringname_key_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (value is Dictionary):
		return result
	for key in (value as Dictionary).keys():
		result[StringName(String(key))] = (value as Dictionary)[key]
	return result


static func _restore_stringname_value_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (value is Dictionary):
		return result
	for key in (value as Dictionary).keys():
		result[StringName(String(key))] = StringName(String((value as Dictionary)[key]))
	return result


static func _stringname_array_to_strings(values: Array[StringName]) -> Array:
	var result: Array = []
	for value in values:
		result.append(String(value))
	return result


static func _strings_to_stringname_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(String(value)))
	return result


static func _array_to_coord(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


static func _parse_rng_state(value: Variant) -> int:
	return int(String(value))


static func _dictionary_copy(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


static func _json_safe(value: Variant) -> Variant:
	if value is StringName:
		return String(value)
	if value is Vector2i:
		return [value.x, value.y]
	if value is PackedStringArray:
		return Array(value)
	if value is Array:
		var out: Array = []
		for item in value:
			out.append(_json_safe(item))
		return out
	if value is Dictionary:
		var out: Dictionary = {}
		for key in value.keys():
			out[String(key)] = _json_safe(value[key])
		return out
	return value
