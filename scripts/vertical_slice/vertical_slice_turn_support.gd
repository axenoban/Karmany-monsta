class_name KarmanyVerticalSliceTurnSupport
extends RefCounted


var human_player: KarmanyPlayerState = null
var ai_player: KarmanyPlayerState = null
var coordinator: KarmanyMatchCoordinator = null
var turn_manager: KarmanyTurnManager = null
var ai_turn: KarmanyAiTurnController = KarmanyAiTurnController.new()
var ai_last_actions: PackedStringArray = PackedStringArray()


func configure(
	p_human_player: KarmanyPlayerState,
	p_ai_player: KarmanyPlayerState,
	p_coordinator: KarmanyMatchCoordinator,
	p_turn_manager: KarmanyTurnManager
) -> bool:
	if (
		p_human_player == null
		or p_ai_player == null
		or p_coordinator == null
		or p_turn_manager == null
	):
		return false
	human_player = p_human_player
	ai_player = p_ai_player
	coordinator = p_coordinator
	turn_manager = p_turn_manager
	return ai_turn.configure(KarmanyAiProfile.ProfileType.OPPORTUNIST, 2801)


func close_human_turn_and_run_ai() -> bool:
	if (
		not turn_manager.is_running
		or turn_manager.get_active_player() != human_player
		or turn_manager.actions_remaining != 0
	):
		return false
	if not _resolve_human_pending_discards():
		return false
	if not coordinator.end_turn():
		return false
	if turn_manager.is_running and turn_manager.get_active_player() == ai_player:
		return _run_ai_turn()
	return true


func _run_ai_turn() -> bool:
	ai_last_actions = PackedStringArray()
	var executions: Array[KarmanyAiExecutionResult] = (
		ai_turn.play_turn(coordinator, ai_player)
	)
	for execution in executions:
		if execution != null:
			ai_last_actions.append(execution.message)
	return (
		not turn_manager.is_running
		or turn_manager.get_active_player() != ai_player
	)


func _resolve_human_pending_discards() -> bool:
	if human_player.resonance_hand.get_pending_discard_count() == 0:
		human_player.request_end_turn_resonance_discard()
	var pending: int = human_player.resonance_hand.get_pending_discard_count()
	if pending <= 0:
		return true
	var selected: Array[StringName] = []
	for card in human_player.get_resonance_hand():
		if selected.size() >= pending:
			break
		if card != null:
			selected.append(card.resonance_id)
	return (
		selected.size() == pending
		and coordinator.resolve_pending_resonance_discard(
			human_player,
			selected
		)
	)
