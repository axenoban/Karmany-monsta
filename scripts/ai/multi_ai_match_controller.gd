class_name KarmanyMultiAiMatchController
extends RefCounted


signal ai_turn_started(
	player_id: StringName,
	profile_name: String
)
signal ai_action_chosen(
	player_id: StringName,
	action_label: String,
	actions_remaining: int
)
signal ai_action_executed(
	player_id: StringName,
	action_label: String,
	success: bool,
	actions_remaining: int
)
signal ai_decision_diagnostic(
	player_id: StringName,
	diagnostic: Dictionary
)
signal ai_turn_finished(
	player_id: StringName,
	profile_name: String,
	round_number: int
)
signal ai_turn_blocked(
	player_id: StringName,
	reason: String
)


const MAX_DECISION_ATTEMPTS_PER_ACTION: int = 3
const AI_NO_LEGAL_ACTION_BUDGET_ID: StringName = &"ai_no_legal_action_budget"


var local_session: KarmanyLocalMultiplayerSession = null
var coordinator: KarmanyMatchCoordinator = null
var human_player_id: StringName = &""
var controller_types: Dictionary = {}
var ai_controllers: Dictionary = {}
var ai_profile_types: Dictionary = {}
var configured: bool = false

var last_turn_executions: Array[KarmanyAiExecutionResult] = []
var last_turn_diagnostics: Array[Dictionary] = []
var last_turn_player_id: StringName = &""
var last_turn_had_budget_relinquish: bool = false
var last_turn_decision_attempts: int = 0
var last_block_reason: String = ""


func configure(
	p_local_session: KarmanyLocalMultiplayerSession,
	p_coordinator: KarmanyMatchCoordinator,
	p_human_player_id: StringName,
	seed_value: int
) -> bool:
	if p_local_session == null or not p_local_session.configured:
		return false
	if p_coordinator == null or not p_coordinator.is_configured():
		return false
	if p_local_session.turn_manager == null:
		return false
	if p_coordinator.turn_manager != p_local_session.turn_manager:
		return false
	if p_human_player_id == &"":
		return false
	if p_local_session.get_player_by_id(p_human_player_id) == null:
		return false

	local_session = p_local_session
	coordinator = p_coordinator
	human_player_id = p_human_player_id
	controller_types.clear()
	ai_controllers.clear()
	ai_profile_types.clear()

	var ai_ordinal: int = 0
	for player in local_session.players:
		if player == null or player.player_id == &"":
			return false
		if player.player_id == human_player_id:
			controller_types[player.player_id] = KarmanyPlayerControllerType.Kind.HUMAN
			continue

		controller_types[player.player_id] = KarmanyPlayerControllerType.Kind.AI
		var profile_type: int = _profile_for_ai_ordinal(ai_ordinal)
		var controller := KarmanyAiTurnController.new()
		var ai_seed: int = _derive_ai_seed(seed_value, ai_ordinal)
		if not controller.configure(profile_type, ai_seed):
			return false
		ai_controllers[player.player_id] = controller
		ai_profile_types[player.player_id] = profile_type
		ai_ordinal += 1

	configured = ai_controllers.size() == local_session.get_player_count() - 1
	_clear_last_turn_state()
	return configured


func get_controller_kind(player_id: StringName) -> int:
	return int(controller_types.get(player_id, -1))


func is_human_player(player_id: StringName) -> bool:
	return configured and get_controller_kind(player_id) == KarmanyPlayerControllerType.Kind.HUMAN


func is_ai_player(player_id: StringName) -> bool:
	return configured and get_controller_kind(player_id) == KarmanyPlayerControllerType.Kind.AI


func get_ai_controller_count() -> int:
	return ai_controllers.size()


func get_ai_controller(player_id: StringName) -> KarmanyAiTurnController:
	return ai_controllers.get(player_id, null) as KarmanyAiTurnController


func get_ai_profile_type(player_id: StringName) -> int:
	return int(ai_profile_types.get(player_id, -1))


func get_ai_profile_name(player_id: StringName) -> String:
	var profile_type: int = get_ai_profile_type(player_id)
	match profile_type:
		KarmanyAiProfile.ProfileType.EXPLORER:
			return "Exploradora"
		KarmanyAiProfile.ProfileType.OPTIMIZER:
			return "Optimizadora"
		KarmanyAiProfile.ProfileType.OPPORTUNIST:
			return "Oportunista"
		KarmanyAiProfile.ProfileType.AGGRESSIVE:
			return "Agresiva"
	return ""


func get_ai_player_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	if local_session == null:
		return result
	for player in local_session.players:
		if player != null and is_ai_player(player.player_id):
			result.append(player.player_id)
	return result


func run_current_ai_turn() -> bool:
	if not configured or coordinator == null:
		return false
	var turn_manager := coordinator.turn_manager
	if turn_manager == null or not turn_manager.is_running:
		return false
	var player := turn_manager.get_active_player()
	if player == null or not is_ai_player(player.player_id):
		return false

	var controller := get_ai_controller(player.player_id)
	if controller == null:
		return false
	var turn_round: int = turn_manager.current_round

	_clear_last_turn_state()
	last_turn_player_id = player.player_id
	var profile_name: String = get_ai_profile_name(player.player_id)
	ai_turn_started.emit(player.player_id, profile_name)

	while (
		turn_manager.is_running
		and turn_manager.get_active_player() == player
		and turn_manager.actions_remaining > 0
	):
		var excluded_labels: Dictionary = {}
		var action_executed: bool = false
		var attempt_count: int = 0

		while attempt_count < MAX_DECISION_ATTEMPTS_PER_ACTION:
			attempt_count += 1
			last_turn_decision_attempts += 1

			# Se regeneran y reevalúan todas las acciones después de cada acción
			# exitosa. Recursos, posición y utilidad marginal ya pueden cambiar.
			var legal_actions := KarmanyAiLegalActionGenerator.build_legal_actions(
				coordinator,
				player
			)
			var available_actions: Array[KarmanyAiActionCandidate] = []
			for candidate in legal_actions:
				if candidate == null:
					continue
				if excluded_labels.has(candidate.debug_label):
					continue
				available_actions.append(candidate)

			if available_actions.is_empty():
				last_block_reason = "La IA no dispone de acciones legales."
				break

			var choice := controller.brain.choose_action(available_actions)
			if choice == null:
				last_block_reason = "La IA no pudo seleccionar una accion legal."
				break

			var score_breakdown: Dictionary = controller.brain.get_score_breakdown(choice)
			var resources_before: Dictionary = player.get_resource_snapshot()
			var coord_before: Vector2i = player.current_coord
			controller.last_choice_label = choice.debug_label
			ai_action_chosen.emit(
				player.player_id,
				choice.debug_label,
				turn_manager.actions_remaining
			)

			var execution := KarmanyAiActionExecutor.execute(
				coordinator,
				player,
				choice
			)
			last_turn_executions.append(execution)
			var was_executed: bool = execution != null and execution.was_executed()
			if was_executed:
				controller.brain.record_executed_action(choice)

			var diagnostic: Dictionary = {
				"action_label": choice.debug_label,
				"action_type": choice.action_type,
				"score": float(score_breakdown.get("final_score", -INF)),
				"base_profile_score": float(score_breakdown.get("base_profile_score", -INF)),
				"repetition_penalty": float(score_breakdown.get("repetition_penalty", 0.0)),
				"repeat_streak_before": int(score_breakdown.get("repeat_streak", 0)),
				"resources_before": resources_before,
				"resources_after": player.get_resource_snapshot(),
				"coord_before": coord_before,
				"coord_after": player.current_coord,
				"resource_utility": choice.payload.get("resource_utility", {}),
				"success": was_executed
			}
			last_turn_diagnostics.append(diagnostic)
			ai_decision_diagnostic.emit(player.player_id, diagnostic.duplicate(true))
			ai_action_executed.emit(
				player.player_id,
				choice.debug_label,
				was_executed,
				turn_manager.actions_remaining
			)

			if was_executed:
				action_executed = true
				break

			excluded_labels[choice.debug_label] = true
			last_block_reason = execution.message if execution != null else "Ejecucion IA nula."

		if action_executed:
			continue

		if last_block_reason.is_empty():
			last_block_reason = "La IA agoto sus intentos internos de decision."
		ai_turn_blocked.emit(player.player_id, last_block_reason)
		if not _relinquish_unusable_action_budget(player):
			return false
		break

	if (
		turn_manager.is_running
		and turn_manager.get_active_player() == player
		and turn_manager.actions_remaining == 0
	):
		# Con cero acciones play_turn no decide nada: solo resuelve descartes
		# pendientes y delega el fin de turno al coordinador/TurnManager.
		controller.play_turn(coordinator, player, Callable(), true)

	var turn_finished: bool = (
		not turn_manager.is_running
		or turn_manager.get_active_player() != player
	)
	if not turn_finished:
		return false

	ai_turn_finished.emit(player.player_id, profile_name, turn_round)
	return true


func run_ai_until_human(
	max_ai_turns: int = KarmanyTurnManager.MAX_PLAYERS - 1
) -> bool:
	if not configured or coordinator == null or max_ai_turns <= 0:
		return false
	var turn_manager := coordinator.turn_manager
	if turn_manager == null:
		return false

	var resolved_turns: int = 0
	while turn_manager.is_running:
		var active := turn_manager.get_active_player()
		if active == null:
			return false
		if is_human_player(active.player_id):
			return true
		if not is_ai_player(active.player_id):
			return false
		if resolved_turns >= max_ai_turns:
			return false
		if not run_current_ai_turn():
			return false
		resolved_turns += 1

	return coordinator.is_finished


func _relinquish_unusable_action_budget(player: KarmanyPlayerState) -> bool:
	if player == null or coordinator == null or coordinator.turn_manager == null:
		return false
	var turn_manager := coordinator.turn_manager
	last_turn_had_budget_relinquish = true

	while (
		turn_manager.is_running
		and turn_manager.get_active_player() == player
		and turn_manager.actions_remaining > 0
	):
		if not turn_manager.spend_action_for(AI_NO_LEGAL_ACTION_BUDGET_ID, 1):
			return false
	return true


func _profile_for_ai_ordinal(ai_ordinal: int) -> int:
	match ai_ordinal:
		0:
			return KarmanyAiProfile.ProfileType.EXPLORER
		1:
			return KarmanyAiProfile.ProfileType.OPPORTUNIST
		2:
			return KarmanyAiProfile.ProfileType.AGGRESSIVE
	return KarmanyAiProfile.ProfileType.OPPORTUNIST


func _derive_ai_seed(seed_value: int, ai_ordinal: int) -> int:
	var base_seed: int = absi(seed_value)
	if base_seed == 0:
		base_seed = 1
	return base_seed + (ai_ordinal + 1) * 1009


func _clear_last_turn_state() -> void:
	last_turn_executions.clear()
	last_turn_diagnostics.clear()
	last_turn_player_id = &""
	last_turn_had_budget_relinquish = false
	last_turn_decision_attempts = 0
	last_block_reason = ""
