class_name KarmanyFullMatchHumanInstinctRollSession
extends KarmanyFullMatchHumanCombatChoiceSession


var _next_human_instinct_request_id: int = 1
var _pending_human_instinct_request: KarmanyInstinctRollRequest = null
var _pending_human_instinct_candidate: KarmanyAiActionCandidate = null
var _last_human_instinct_result: Dictionary = {}


func build_human_action_choice_request() -> KarmanyChoiceRequest:
	if get_pending_human_instinct_roll_request() != null:
		return null
	return super.build_human_action_choice_request()


func get_pending_human_instinct_roll_request() -> KarmanyInstinctRollRequest:
	if _pending_human_instinct_request == null:
		return null
	if not _is_human_instinct_request_current(_pending_human_instinct_request):
		_pending_human_instinct_request = null
		_pending_human_instinct_candidate = null
		return null
	return _pending_human_instinct_request


func build_human_instinct_roll_request() -> KarmanyInstinctRollRequest:
	return get_pending_human_instinct_roll_request()


func get_last_human_instinct_roll_result() -> Dictionary:
	return _last_human_instinct_result.duplicate(true)


func _begin_human_combat_decision(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> bool:
	if not _requires_human_instinct_roll(candidate):
		return super._begin_human_combat_decision(player, candidate)
	if player == null or runtime == null or runtime.local_session == null:
		return false
	if get_pending_human_instinct_roll_request() != null:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or manager.get_active_player() != player:
		return false

	# El candidato pudo haber sido construido para IA/legacy con tirada y
	# Resonancia ya elegidas. En el flujo humano explicito ambas decisiones se
	# neutralizan al declarar el combate. Instinto se resuelve primero y solo
	# despues se abre la seleccion de Resonancia de F45.3.
	_clear_human_combat_resonance(candidate)
	if not _prepare_human_instinct_target(player, candidate):
		return false
	if not _clear_human_instinct_roll(candidate):
		return false

	var request := KarmanyInstinctRollRequest.new()
	if not request.configure(
		_next_human_instinct_request_id,
		player.player_id,
		manager.current_round,
		manager.actions_remaining,
		candidate.action_type,
		candidate.debug_label,
		candidate.target_coord
	):
		return false
	_next_human_instinct_request_id += 1
	_pending_human_instinct_candidate = candidate
	_pending_human_instinct_request = request
	return true


func resolve_human_instinct_roll() -> bool:
	var request := get_pending_human_instinct_roll_request()
	if request == null or _pending_human_instinct_candidate == null:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_pending_human_instinct_request = null
		_pending_human_instinct_candidate = null
		return false

	# El jugador dispara la tirada, pero nunca elige su resultado. La fuente
	# aleatoria sigue siendo el RNG determinista de la partida.
	var roll_value: int = _action_rng.randi_range(1, 6)
	if not request.resolve_roll(roll_value):
		return false
	var candidate: KarmanyAiActionCandidate = _pending_human_instinct_candidate
	if not _apply_human_instinct_roll(candidate, roll_value):
		return false

	_last_human_instinct_result = request.get_result()
	_pending_human_instinct_request = null
	_pending_human_instinct_candidate = null
	_log("INSTINTO HUMAN | %s | d6=%d | Defensa %+d" % [
		String(player.player_id),
		roll_value,
		int(_last_human_instinct_result.get("defense_adjustment", 0))
	])

	# Secuencia canonica v0.74: declarar -> Instinto -> Resonancia -> resolver.
	return super._begin_human_combat_decision(player, candidate)


func _requires_human_instinct_roll(candidate: KarmanyAiActionCandidate) -> bool:
	if candidate == null:
		return false
	match candidate.action_type:
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
			return true
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
			return true
	# PvP no usa Dado de Instinto en v0.74. Aeterna conserva su flujo actual
	# hasta F45.5 para no mezclar aqui decisiones del climax.
	return false


func _prepare_human_instinct_target(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> bool:
	if player == null or candidate == null:
		return false
	if candidate.action_type != KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
		return true
	if not bool(candidate.payload.get("spawn_if_missing", false)):
		return true
	if runtime == null or runtime.board_state == null:
		return false
	if runtime.board_state.has_beast(candidate.target_coord):
		candidate.payload["spawn_if_missing"] = false
		return true
	if candidate.target_coord != player.current_coord:
		return false
	var spawn_result := runtime.spawn_beast_from_current_tile(player, false)
	if spawn_result == null or not spawn_result.is_spawned():
		return false
	candidate.payload["spawn_if_missing"] = false
	return true


func _clear_human_instinct_roll(candidate: KarmanyAiActionCandidate) -> bool:
	if candidate == null:
		return false
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
		var context_value: Variant = candidate.payload.get("combat_context", null)
		if not (context_value is KarmanyBeastCombatContext):
			return false
		var context := context_value as KarmanyBeastCombatContext
		context.instinct_roll = 0
		return true
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
		candidate.payload["instinct_roll"] = 0
		return true
	return false


func _apply_human_instinct_roll(
	candidate: KarmanyAiActionCandidate,
	roll_value: int
) -> bool:
	if candidate == null or roll_value < 1 or roll_value > 6:
		return false
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
		var context_value: Variant = candidate.payload.get("combat_context", null)
		if not (context_value is KarmanyBeastCombatContext):
			return false
		var context := context_value as KarmanyBeastCombatContext
		context.instinct_roll = roll_value
		return true
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
		candidate.payload["instinct_roll"] = roll_value
		return true
	return false


func _get_human_instinct_roll(candidate: KarmanyAiActionCandidate) -> int:
	if candidate == null:
		return -1
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
		var context_value: Variant = candidate.payload.get("combat_context", null)
		if context_value is KarmanyBeastCombatContext:
			return (context_value as KarmanyBeastCombatContext).instinct_roll
		return -1
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
		return int(candidate.payload.get("instinct_roll", -1))
	return -1


func _is_human_instinct_request_current(
	request: KarmanyInstinctRollRequest
) -> bool:
	if request == null or request.is_resolved() or _pending_human_instinct_candidate == null:
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
	var candidate: KarmanyAiActionCandidate = _pending_human_instinct_candidate
	return (
		player.player_id == request.player_id
		and manager.current_round == request.round_number
		and manager.actions_remaining == request.actions_remaining
		and candidate.action_type == request.action_type
		and candidate.debug_label == request.action_label
		and candidate.target_coord == request.target_coord
		and _get_human_instinct_roll(candidate) == 0
	)
