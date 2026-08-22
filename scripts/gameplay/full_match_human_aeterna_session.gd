class_name KarmanyFullMatchHumanAeternaSession
extends KarmanyFullMatchHumanInstinctRollSession


var _next_human_aeterna_reward_request_id: int = 1
var _next_human_aeterna_resource_request_id: int = 1
var _next_human_aeterna_resonance_request_id: int = 1

var _pending_human_aeterna_reward_request: KarmanyAeternaRewardChoiceRequest = null
var _pending_human_aeterna_resource_request: KarmanyAeternaResourceDiscardRequest = null
var _pending_human_aeterna_resonance_request: KarmanyResonanceDiscardChoiceRequest = null
var _pending_human_aeterna_result: KarmanyAeternaResult = null
var _pending_human_aeterna_reward_drawn_ids: Array[StringName] = []
var _explicit_human_aeterna_in_progress: bool = false


func build_human_action_choice_request() -> KarmanyChoiceRequest:
	if _has_pending_human_aeterna_post_choice():
		return null
	return super.build_human_action_choice_request()


func build_human_resonance_discard_request() -> KarmanyResonanceDiscardChoiceRequest:
	if _has_pending_human_aeterna_post_choice():
		return null
	return super.build_human_resonance_discard_request()


func finish_human_turn_if_ready() -> bool:
	if _has_pending_human_aeterna_post_choice():
		return false
	return super.finish_human_turn_if_ready()


func _requires_human_instinct_roll(candidate: KarmanyAiActionCandidate) -> bool:
	if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		return true
	return super._requires_human_instinct_roll(candidate)


func _create_human_instinct_request(
	candidate: KarmanyAiActionCandidate
) -> KarmanyInstinctRollRequest:
	if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		return KarmanyAeternaInstinctRollRequest.new()
	return super._create_human_instinct_request(candidate)


func _clear_human_instinct_roll(candidate: KarmanyAiActionCandidate) -> bool:
	if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		candidate.payload["instinct_roll"] = 0
		return true
	return super._clear_human_instinct_roll(candidate)


func _apply_human_instinct_roll(
	candidate: KarmanyAiActionCandidate,
	roll_value: int
) -> bool:
	if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		if roll_value < 1 or roll_value > 6:
			return false
		candidate.payload["instinct_roll"] = roll_value
		return true
	return super._apply_human_instinct_roll(candidate, roll_value)


func _get_human_instinct_roll(candidate: KarmanyAiActionCandidate) -> int:
	if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		return int(candidate.payload.get("instinct_roll", -1))
	return super._get_human_instinct_roll(candidate)


func _complete_explicit_human_action(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> bool:
	if candidate == null or candidate.action_type != KarmanyAiActionCandidate.ActionType.AETERNA:
		return super._complete_explicit_human_action(player, candidate)
	_explicit_human_aeterna_in_progress = true
	var success: bool = super._complete_explicit_human_action(player, candidate)
	_explicit_human_aeterna_in_progress = false
	return success


func _resolve_aeterna_post_result(
	player: KarmanyPlayerState,
	aeterna_result: KarmanyAeternaResult
) -> void:
	if not _explicit_human_aeterna_in_progress:
		super._resolve_aeterna_post_result(player, aeterna_result)
		return
	if player == null or aeterna_result == null or not aeterna_result.is_resolved():
		return

	_pending_human_aeterna_result = aeterna_result
	_pending_human_aeterna_reward_drawn_ids.clear()
	if aeterna_result.is_victory() and aeterna_result.reward_choice_required:
		if not _open_human_aeterna_reward_request(player):
			_log("AETERNA HUMAN PENDING | no existe recompensa legal disponible para resolver.")
		return
	if aeterna_result.is_defeat():
		if _open_human_aeterna_resource_request(player):
			return
		if _open_human_aeterna_resonance_request(player):
			return
		_finish_human_aeterna_post_choices(player)


func get_pending_human_aeterna_reward_request() -> KarmanyAeternaRewardChoiceRequest:
	if _pending_human_aeterna_reward_request == null:
		return null
	if not _is_human_aeterna_context_current():
		_pending_human_aeterna_reward_request = null
		return null
	if not _pending_human_aeterna_reward_request.matches_state(
		runtime.local_session.turn_manager.get_active_player(),
		runtime.equipment_market
	):
		_pending_human_aeterna_reward_request = null
		return null
	return _pending_human_aeterna_reward_request


func build_human_aeterna_reward_choice_request() -> KarmanyAeternaRewardChoiceRequest:
	return get_pending_human_aeterna_reward_request()


func get_pending_human_aeterna_resource_discard_request() -> KarmanyAeternaResourceDiscardRequest:
	if _pending_human_aeterna_resource_request == null:
		return null
	if not _is_human_aeterna_context_current():
		_pending_human_aeterna_resource_request = null
		return null
	var player := runtime.local_session.turn_manager.get_active_player()
	if not _pending_human_aeterna_resource_request.matches_resources(player):
		_pending_human_aeterna_resource_request = null
		return null
	return _pending_human_aeterna_resource_request


func build_human_aeterna_resource_discard_request() -> KarmanyAeternaResourceDiscardRequest:
	return get_pending_human_aeterna_resource_discard_request()


func get_pending_human_aeterna_resonance_discard_request() -> KarmanyResonanceDiscardChoiceRequest:
	if _pending_human_aeterna_resonance_request == null:
		return null
	if not _is_human_aeterna_context_current():
		_pending_human_aeterna_resonance_request = null
		return null
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		_pending_human_aeterna_resonance_request = null
		return null
	var eligible_cards := _get_human_aeterna_resonance_discard_cards(player)
	if not _pending_human_aeterna_resonance_request.matches_cards(eligible_cards):
		_pending_human_aeterna_resonance_request = null
		return null
	return _pending_human_aeterna_resonance_request


func build_human_aeterna_resonance_discard_request() -> KarmanyResonanceDiscardChoiceRequest:
	return get_pending_human_aeterna_resonance_discard_request()


func resolve_human_aeterna_reward_choice(
	option_id: StringName,
	discard_equipment_id: StringName = &""
) -> bool:
	var request := get_pending_human_aeterna_reward_request()
	if request == null or _pending_human_aeterna_result == null:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		return false
	var hand_ids_before: Array[StringName] = _get_resonance_ids(player)
	var selection := request.resolve_option(option_id, discard_equipment_id)
	if selection.is_empty():
		return false

	var kind: int = int(selection.get("kind", KarmanyAeternaRewardChoiceRequest.RewardKind.NONE))
	var resolved: bool = false
	if kind == KarmanyAeternaRewardChoiceRequest.RewardKind.RESONANCES:
		resolved = runtime.coordinator.resolve_aeterna_resonance_reward(
			player,
			_pending_human_aeterna_result
		)
	elif kind == KarmanyAeternaRewardChoiceRequest.RewardKind.ANCESTRAL_EQUIPMENT:
		resolved = KarmanyAeternaMarketRewardService.resolve_visible_reward(
			player,
			_pending_human_aeterna_result,
			runtime.equipment_market,
			int(selection.get("market_index", -1)),
			StringName(selection.get("discard_equipment_id", ""))
		)
	if not resolved:
		return false

	_pending_human_aeterna_reward_request = null
	if kind == KarmanyAeternaRewardChoiceRequest.RewardKind.RESONANCES:
		if not _capture_human_aeterna_reward_drawn_ids(player, hand_ids_before):
			_log("AETERNA HUMAN ERROR | no se pudieron aislar las 3 Resonancias robadas de la recompensa.")
			return false
		_log("AETERNA HUMAN REWARD | %s | Resonancias: roba 3 y descarta 1 de las robadas" % String(player.player_id))
		if _open_human_aeterna_resonance_request(player):
			return true
	else:
		_log("AETERNA HUMAN REWARD | %s | Equipo ancestral %s gratis desde mercado" % [
			String(player.player_id),
			String(_pending_human_aeterna_result.ancestral_equipment_id),
		])
	return _finish_human_aeterna_post_choices(player)


func resolve_human_aeterna_resource_discard_choice(
	resource_types: Array[int]
) -> bool:
	var request := get_pending_human_aeterna_resource_discard_request()
	if request == null or _pending_human_aeterna_result == null:
		return false
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return false
	var resolved_resources := request.resolve_resources(resource_types)
	if resolved_resources.size() != request.required_count:
		return false

	for resource_type in resolved_resources:
		if not player.spend_resource(resource_type, 1):
			return false
	_pending_human_aeterna_result.basic_resources_discard_pending = 0
	_pending_human_aeterna_resource_request = null
	_log("AETERNA HUMAN DEFEAT | %s | recursos descartados=%s" % [
		String(player.player_id),
		str(resolved_resources),
	])
	if _open_human_aeterna_resonance_request(player):
		return true
	return _finish_human_aeterna_post_choices(player)


func resolve_human_aeterna_resonance_discard_choice(
	option_ids: Array[StringName]
) -> bool:
	var request := get_pending_human_aeterna_resonance_discard_request()
	if request == null or _pending_human_aeterna_result == null:
		return false
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return false
	var resonance_ids := request.resolve_options(option_ids)
	if resonance_ids.size() != request.required_count:
		return false
	if not runtime.coordinator.resolve_pending_resonance_discard(player, resonance_ids):
		return false
	_pending_human_aeterna_result.resonance_discard_pending = 0
	_pending_human_aeterna_resonance_request = null
	_log("AETERNA HUMAN | %s | Resonancia descartada=%s" % [
		String(player.player_id),
		str(resonance_ids),
	])
	return _finish_human_aeterna_post_choices(player)


func _open_human_aeterna_reward_request(player: KarmanyPlayerState) -> bool:
	if player == null or _pending_human_aeterna_result == null:
		return false
	if not _pending_human_aeterna_result.is_victory():
		return false
	var manager := runtime.local_session.turn_manager
	var allow_resonances: bool = (
		runtime.coordinator.resonance_deck.get_draw_count()
		+ runtime.coordinator.resonance_deck.get_discard_count()
	) >= 3
	var request := KarmanyAeternaRewardChoiceRequest.new()
	if not request.configure(
		_next_human_aeterna_reward_request_id,
		player,
		manager.current_round,
		manager.actions_remaining,
		runtime.equipment_market,
		allow_resonances
	):
		return false
	_next_human_aeterna_reward_request_id += 1
	_pending_human_aeterna_reward_request = request
	return true


func _open_human_aeterna_resource_request(player: KarmanyPlayerState) -> bool:
	if player == null or _pending_human_aeterna_result == null:
		return false
	var pending: int = _pending_human_aeterna_result.basic_resources_discard_pending
	if pending <= 0:
		return false
	var total_available: int = (
		player.get_resource(KarmanyEffectData.ResourceType.MN)
		+ player.get_resource(KarmanyEffectData.ResourceType.MR)
		+ player.get_resource(KarmanyEffectData.ResourceType.EK)
	)
	var required: int = mini(pending, total_available)
	if required <= 0:
		_pending_human_aeterna_result.basic_resources_discard_pending = 0
		return false
	var manager := runtime.local_session.turn_manager
	var request := KarmanyAeternaResourceDiscardRequest.new()
	if not request.configure(
		_next_human_aeterna_resource_request_id,
		player,
		manager.current_round,
		manager.actions_remaining,
		required
	):
		return false
	_next_human_aeterna_resource_request_id += 1
	_pending_human_aeterna_resource_request = request
	return true


func _open_human_aeterna_resonance_request(player: KarmanyPlayerState) -> bool:
	if player == null or _pending_human_aeterna_result == null:
		return false
	var pending: int = mini(
		_pending_human_aeterna_result.resonance_discard_pending,
		player.get_pending_resonance_discard_count()
	)
	if pending <= 0:
		_pending_human_aeterna_result.resonance_discard_pending = 0
		return false
	var eligible_cards := _get_human_aeterna_resonance_discard_cards(player)
	if eligible_cards.size() < pending:
		return false
	var manager := runtime.local_session.turn_manager
	var request := KarmanyResonanceDiscardChoiceRequest.new()
	if not request.configure(
		_next_human_aeterna_resonance_request_id,
		player.player_id,
		manager.current_round,
		pending,
		eligible_cards
	):
		return false
	_next_human_aeterna_resonance_request_id += 1
	_pending_human_aeterna_resonance_request = request
	return true


func _capture_human_aeterna_reward_drawn_ids(
	player: KarmanyPlayerState,
	hand_ids_before: Array[StringName]
) -> bool:
	_pending_human_aeterna_reward_drawn_ids.clear()
	if player == null or _pending_human_aeterna_result == null:
		return false
	var expected: int = _pending_human_aeterna_result.resonance_cards_drawn
	if expected != 3:
		return false
	var previous: Dictionary = {}
	for resonance_id in hand_ids_before:
		previous[resonance_id] = true
	for card in player.get_resonance_hand():
		if card == null or previous.has(card.resonance_id):
			continue
		_pending_human_aeterna_reward_drawn_ids.append(card.resonance_id)
	return _pending_human_aeterna_reward_drawn_ids.size() == expected


func _get_human_aeterna_resonance_discard_cards(
	player: KarmanyPlayerState
) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	if player == null:
		return result
	if _pending_human_aeterna_reward_drawn_ids.is_empty():
		for card in player.get_resonance_hand():
			if card != null:
				result.append(card)
		return result
	for resonance_id in _pending_human_aeterna_reward_drawn_ids:
		var card := player.resonance_hand.get_card_by_id(resonance_id)
		if card != null:
			result.append(card)
	return result


func _get_resonance_ids(player: KarmanyPlayerState) -> Array[StringName]:
	var result: Array[StringName] = []
	if player == null:
		return result
	for card in player.get_resonance_hand():
		if card != null:
			result.append(card.resonance_id)
	return result


func _finish_human_aeterna_post_choices(player: KarmanyPlayerState) -> bool:
	if player == null:
		return false
	_pending_human_aeterna_reward_request = null
	_pending_human_aeterna_resource_request = null
	_pending_human_aeterna_resonance_request = null
	_pending_human_aeterna_result = null
	_pending_human_aeterna_reward_drawn_ids.clear()
	var manager := runtime.local_session.turn_manager
	if manager != null and manager.get_active_player() == player and manager.actions_remaining == 0:
		return super._finish_explicit_human_turn_or_request_discard(player)
	return true


func _finish_explicit_human_turn_or_request_discard(player: KarmanyPlayerState) -> bool:
	if _has_pending_human_aeterna_post_choice():
		return true
	return super._finish_explicit_human_turn_or_request_discard(player)


func _has_pending_human_aeterna_post_choice() -> bool:
	return (
		_pending_human_aeterna_result != null
		or _pending_human_aeterna_reward_request != null
		or _pending_human_aeterna_resource_request != null
		or _pending_human_aeterna_resonance_request != null
	)


func _is_human_aeterna_context_current() -> bool:
	if _pending_human_aeterna_result == null:
		return false
	if not configured or match_state != MatchState.PLAYING or runtime == null:
		return false
	if runtime.ai_match_controller == null or runtime.local_session == null:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		return false
	var player := manager.get_active_player()
	return player != null and runtime.ai_match_controller.is_human_player(player.player_id)
