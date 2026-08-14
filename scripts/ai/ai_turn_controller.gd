class_name KarmanyAiTurnController
extends RefCounted


var brain: KarmanyAiBrain = KarmanyAiBrain.new()
var last_turn_ended: bool = false
var last_choice_label: String = ""


func configure(profile_type: int, seed: int = 0) -> bool:
	last_turn_ended = false
	last_choice_label = ""
	return brain.configure(profile_type, seed)


func choose_current_action(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState,
	special_candidates: Array[KarmanyAiActionCandidate] = []
) -> KarmanyAiActionCandidate:
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		coordinator,
		player,
		special_candidates
	)
	return brain.choose_action(candidates)


func execute_one_action(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState,
	special_candidates: Array[KarmanyAiActionCandidate] = []
) -> KarmanyAiExecutionResult:
	var candidate := choose_current_action(coordinator, player, special_candidates)
	if candidate == null:
		var empty := KarmanyAiExecutionResult.new()
		empty.message = "La IA no encontro acciones legales."
		return empty
	last_choice_label = candidate.debug_label
	var execution := KarmanyAiActionExecutor.execute(coordinator, player, candidate)
	if execution != null and execution.was_executed():
		brain.record_executed_action(candidate)
	return execution


func play_turn(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState,
	special_candidate_provider: Callable = Callable(),
	auto_end_turn: bool = true
) -> Array[KarmanyAiExecutionResult]:
	var executions: Array[KarmanyAiExecutionResult] = []
	last_turn_ended = false
	if coordinator == null or player == null or coordinator.turn_manager == null:
		return executions
	if coordinator.turn_manager.get_active_player() != player:
		return executions

	var safety: int = KarmanyTurnManager.ACTIONS_PER_TURN + 1
	while coordinator.turn_manager.get_active_player() == player:
		if coordinator.turn_manager.actions_remaining <= 0:
			break
		if safety <= 0:
			break
		safety -= 1

		var special_candidates: Array[KarmanyAiActionCandidate] = []
		if special_candidate_provider.is_valid():
			var provided: Variant = special_candidate_provider.call(coordinator, player)
			if provided is Array:
				for value in provided:
					if value is KarmanyAiActionCandidate:
						special_candidates.append(value as KarmanyAiActionCandidate)

		# Se regeneran las acciones tras cada decision. La segunda accion del
		# turno puede ser distinta porque la primera altero posicion/recursos.
		var execution := execute_one_action(coordinator, player, special_candidates)
		executions.append(execution)
		if not execution.was_executed():
			break

	if auto_end_turn and coordinator.turn_manager.get_active_player() == player:
		if coordinator.turn_manager.actions_remaining == 0:
			if _resolve_pending_resonance_discards(coordinator, player):
				last_turn_ended = coordinator.end_turn()

	return executions


func _resolve_pending_resonance_discards(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState
) -> bool:
	if player.resonance_hand.get_pending_discard_count() == 0:
		player.request_end_turn_resonance_discard()
	var pending: int = player.resonance_hand.get_pending_discard_count()
	if pending <= 0:
		return true

	var selected: Array[StringName] = []
	while selected.size() < pending:
		var best_card: KarmanyResonanceData = null
		for card in player.get_resonance_hand():
			if card == null or selected.has(card.resonance_id):
				continue
			if best_card == null:
				best_card = card
				continue
			if card.printed_power < best_card.printed_power:
				best_card = card
			elif (
				card.printed_power == best_card.printed_power
				and String(card.resonance_id) < String(best_card.resonance_id)
			):
				best_card = card
		if best_card == null:
			return false
		selected.append(best_card.resonance_id)

	return coordinator.resolve_pending_resonance_discard(player, selected)
