class_name KarmanyFullMatchHumanCombatChoiceSession
extends KarmanyFullMatchActionSession


const HUMAN_COMBAT_RESONANCE_R37: StringName = &"R-37"

var _next_human_combat_resonance_request_id: int = 1
var _pending_human_combat_resonance_request: KarmanyCombatResonanceChoiceRequest = null
var _pending_human_combat_candidate: KarmanyAiActionCandidate = null


func build_human_action_choice_request() -> KarmanyChoiceRequest:
	if get_pending_human_combat_resonance_request() != null:
		return null
	return super.build_human_action_choice_request()


func get_pending_human_combat_resonance_request() -> KarmanyCombatResonanceChoiceRequest:
	if _pending_human_combat_resonance_request == null:
		return null
	if not _is_human_combat_resonance_request_current(
		_pending_human_combat_resonance_request
	):
		_pending_human_combat_resonance_request = null
		_pending_human_combat_candidate = null
		return null
	return _pending_human_combat_resonance_request


func build_human_combat_resonance_choice_request() -> KarmanyCombatResonanceChoiceRequest:
	return get_pending_human_combat_resonance_request()


func resolve_human_action_choice(option_id: StringName) -> bool:
	if get_pending_human_combat_resonance_request() != null:
		return false
	var request := get_pending_human_choice_request()
	if request == null:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_pending_human_choice_request = null
		return false

	var candidate := request.resolve_option(option_id)
	if candidate == null:
		# Igual que F45.1: una opcion inexistente no consume la solicitud.
		return false

	_pending_human_choice_request = null
	if not _is_human_combat_candidate(candidate):
		return _complete_explicit_human_action(player, candidate)
	return _begin_human_combat_decision(player, candidate)


func _begin_human_combat_decision(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> bool:
	if player == null or candidate == null or not _is_human_combat_candidate(candidate):
		return false

	# Los candidatos se construyen tambien para IA/legacy y pueden traer una
	# Resonancia automatica. En el flujo humano explicito esa eleccion nunca
	# debe sobrevivir al ChoiceRequest de accion.
	_clear_human_combat_resonance(candidate)
	var selectable_cards := _get_selectable_human_combat_resonances(player, candidate)
	if selectable_cards.is_empty():
		return _complete_explicit_human_action(player, candidate)

	var manager := runtime.local_session.turn_manager
	var combat_request := KarmanyCombatResonanceChoiceRequest.new()
	if not combat_request.configure(
		_next_human_combat_resonance_request_id,
		player.player_id,
		manager.current_round,
		manager.actions_remaining,
		candidate.action_type,
		candidate.debug_label,
		candidate.target_coord,
		selectable_cards,
		player.get_resonance_hand()
	):
		return false
	_next_human_combat_resonance_request_id += 1
	_pending_human_combat_candidate = candidate
	_pending_human_combat_resonance_request = combat_request
	return true


func resolve_human_combat_resonance_choice(option_id: StringName) -> bool:
	var request := get_pending_human_combat_resonance_request()
	if request == null or _pending_human_combat_candidate == null:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_pending_human_combat_resonance_request = null
		_pending_human_combat_candidate = null
		return false
	if not request.resolve_option(option_id):
		# La UI puede corregir una seleccion invalida sin regenerar la solicitud.
		return false

	var candidate: KarmanyAiActionCandidate = _pending_human_combat_candidate
	var resonance_id: StringName = request.get_resolved_resonance_id()
	_apply_human_combat_resonance(candidate, resonance_id)
	_pending_human_combat_resonance_request = null
	_pending_human_combat_candidate = null
	return _complete_explicit_human_action(player, candidate)


func _complete_explicit_human_action(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> bool:
	if player == null or candidate == null or runtime == null or runtime.local_session == null:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or manager.get_active_player() != player:
		return false
	var success: bool = _execute_candidate(player, candidate)
	full_action_resolved.emit(player.player_id, candidate.debug_label, success)
	if not success:
		return false
	statistics["actions"] = int(statistics.get("actions", 0)) + 1
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE:
		statistics["explorations"] = int(statistics.get("explorations", 0)) + 1
	if manager.actions_remaining == 0 and manager.get_active_player() == player:
		return _finish_explicit_human_turn_or_request_discard(player)
	return true


func _get_selectable_human_combat_resonances(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	if player == null or candidate == null or not _is_human_combat_candidate(candidate):
		return result
	for card in player.get_resonance_hand():
		if card == null:
			continue
		if not KarmanyV074CanonicalRuntimeCatalog.is_resonance_automated(card.resonance_id):
			continue
		if KarmanyResonanceAbilityRuntimeService.is_runtime_excluded(card.resonance_id):
			continue
		if not card.can_use_in(KarmanyResonanceUseContext.WINDOW_COMBAT):
			continue
		# R-05 y cualquier carta marcada PvP solo se ofrecen en un PvP legal.
		if card.tags.has("pvp") and candidate.action_type != KarmanyAiActionCandidate.ActionType.PVP:
			continue
		# R-37 es exclusivamente contra Bestia. Su restriccion queda cerrada
		# aqui para la seleccion humana sin ampliar su uso a otros combates.
		if (
			card.resonance_id == HUMAN_COMBAT_RESONANCE_R37
			and candidate.action_type != KarmanyAiActionCandidate.ActionType.FIGHT_BEAST
		):
			continue
		result.append(card)
	return result


func _is_human_combat_resonance_request_current(
	request: KarmanyCombatResonanceChoiceRequest
) -> bool:
	if request == null or request.is_resolved() or _pending_human_combat_candidate == null:
		return false
	if not configured or match_state != MatchState.PLAYING or runtime == null:
		return false
	if runtime.ai_match_controller == null or runtime.local_session == null:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		return false
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return false
	var candidate: KarmanyAiActionCandidate = _pending_human_combat_candidate
	return (
		player.player_id == request.player_id
		and manager.current_round == request.round_number
		and manager.actions_remaining == request.actions_remaining
		and candidate.action_type == request.action_type
		and candidate.debug_label == request.action_label
		and candidate.target_coord == request.target_coord
		and request.matches_cards(player.get_resonance_hand())
	)


func _is_human_combat_candidate(candidate: KarmanyAiActionCandidate) -> bool:
	if candidate == null:
		return false
	match candidate.action_type:
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
			return true
		KarmanyAiActionCandidate.ActionType.PVP:
			return true
		KarmanyAiActionCandidate.ActionType.AETERNA:
			return true
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
			return true
	return false


func _clear_human_combat_resonance(candidate: KarmanyAiActionCandidate) -> void:
	if candidate == null:
		return
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.PVP:
		candidate.payload.erase("attacker_resonance_id")
		return
	candidate.payload.erase("resonance_id")


func _apply_human_combat_resonance(
	candidate: KarmanyAiActionCandidate,
	resonance_id: StringName
) -> void:
	_clear_human_combat_resonance(candidate)
	if candidate == null or resonance_id == &"":
		return
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.PVP:
		candidate.payload["attacker_resonance_id"] = resonance_id
		return
	candidate.payload["resonance_id"] = resonance_id
