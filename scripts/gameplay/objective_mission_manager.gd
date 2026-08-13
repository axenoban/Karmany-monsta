class_name KarmanyObjectiveMissionManager
extends RefCounted


signal public_objective_claimed(
	player_id: StringName,
	objective_id: StringName,
	legacy_points_pending: int
)
signal mission_completed(
	player_id: StringName,
	mission_id: StringName,
	legacy_points_pending: int
)


const EVENT_TURN_ENDED: StringName = &"turn_ended"

const STATE_EQUIPMENT_COUNT: StringName = &"equipment_count"
const STATE_LINKED_KARMANY_COUNT: StringName = &"linked_karmany_count"
const STATE_RESONANCE_COUNT: StringName = &"resonance_count"
const STATE_FA: StringName = &"fa"


var turn_manager: KarmanyTurnManager = null
var progress_tracker: KarmanyProgressTracker = KarmanyProgressTracker.new()

var _objective_states: Dictionary = {}
var _mission_assignments: Dictionary = {}
var _pending_legacy_rewards: Array[KarmanyLegacyRewardPending] = []


func configure(
	p_turn_manager: KarmanyTurnManager,
	public_objectives: Array[KarmanyObjectiveData]
) -> bool:
	if p_turn_manager == null or public_objectives.is_empty():
		return false

	var states: Dictionary = {}
	for objective in public_objectives:
		if objective == null or not objective.is_valid_definition():
			return false
		if states.has(objective.objective_id):
			return false
		var state := KarmanyObjectiveState.new()
		if not state.configure(objective):
			return false
		states[objective.objective_id] = state

	if turn_manager != null and turn_manager.turn_ended.is_connected(
		Callable(self, "_on_turn_ended")
	):
		turn_manager.turn_ended.disconnect(
			Callable(self, "_on_turn_ended")
		)

	turn_manager = p_turn_manager
	_objective_states = states
	_mission_assignments.clear()
	_pending_legacy_rewards.clear()
	progress_tracker.clear()

	turn_manager.turn_ended.connect(
		Callable(self, "_on_turn_ended")
	)
	return true


func assign_secret_mission(
	player: KarmanyPlayerState,
	trainer_id: StringName,
	mission: KarmanyMissionData
) -> bool:
	if player == null or player.player_id == &"" or trainer_id == &"":
		return false
	if turn_manager == null or turn_manager.get_player_by_id(player.player_id) != player:
		return false
	if mission == null or not mission.is_valid_definition():
		return false
	if mission.trainer_id != trainer_id:
		return false
	if _mission_assignments.has(player.player_id):
		return false

	var assignment := KarmanyMissionAssignment.new()
	if not assignment.configure(player.player_id, mission):
		return false
	_mission_assignments[player.player_id] = assignment
	_sync_player_snapshot(player)
	return true


func record_event(
	player: KarmanyPlayerState,
	event_id: StringName,
	payload: Dictionary = {},
	round_number: int = -1
) -> bool:
	if turn_manager == null or player == null or event_id == &"":
		return false
	if turn_manager.get_player_by_id(player.player_id) != player:
		return false

	var resolved_round: int = round_number
	if resolved_round <= 0:
		resolved_round = turn_manager.current_round
	if resolved_round <= 0:
		return false

	_sync_player_snapshot(player)
	if not progress_tracker.record_event(
		player.player_id,
		event_id,
		resolved_round,
		payload
	):
		return false

	if turn_manager.get_active_player() == player:
		_try_complete_mission(
			player,
			resolved_round,
			false
		)
	return true


func set_progress_state(
	player: KarmanyPlayerState,
	state_id: StringName,
	value: int
) -> bool:
	if player == null or state_id == &"":
		return false
	if turn_manager == null or turn_manager.get_player_by_id(player.player_id) != player:
		return false
	if not progress_tracker.set_state_int(
		player.player_id,
		state_id,
		value
	):
		return false

	if turn_manager.get_active_player() == player:
		_try_complete_mission(
			player,
			turn_manager.current_round,
			false
		)
	return true


func get_objective_state(
	objective_id: StringName
) -> KarmanyObjectiveState:
	return _objective_states.get(objective_id, null)


func get_public_objectives() -> Array[KarmanyObjectiveData]:
	var result: Array[KarmanyObjectiveData] = []
	for state in _objective_states.values():
		if state is KarmanyObjectiveState and state.objective_data != null:
			result.append(state.objective_data)
	return result


func get_claimed_objective_count(player_id: StringName) -> int:
	var total: int = 0
	for state in _objective_states.values():
		if state is KarmanyObjectiveState and state.claimed_by_player_id == player_id:
			total += 1
	return total


func get_mission_assignment(
	player_id: StringName
) -> KarmanyMissionAssignment:
	return _mission_assignments.get(player_id, null)


func get_mission_for_viewer(
	viewer_player_id: StringName,
	target_player_id: StringName
) -> KarmanyMissionData:
	var assignment := get_mission_assignment(target_player_id)
	if assignment == null:
		return null
	if not assignment.is_visible_to(viewer_player_id):
		return null
	return assignment.mission_data


func get_pending_legacy_rewards(
	include_consumed: bool = false
) -> Array[KarmanyLegacyRewardPending]:
	var result: Array[KarmanyLegacyRewardPending] = []
	for reward in _pending_legacy_rewards:
		if include_consumed or not reward.consumed:
			result.append(reward)
	return result


func _on_turn_ended(
	player: KarmanyPlayerState,
	round_number: int
) -> void:
	if player == null or round_number <= 0:
		return

	_sync_player_snapshot(player)
	progress_tracker.record_event(
		player.player_id,
		EVENT_TURN_ENDED,
		round_number,
		{}
	)
	_try_complete_mission(player, round_number, true)
	# Una Mision puede otorgar FA inmediatamente; refrescar antes de evaluar
	# Objetivos de fin de turno mantiene el estado real del jugador.
	_sync_player_snapshot(player)
	_claim_eligible_public_objectives(player, round_number)


func _try_complete_mission(
	player: KarmanyPlayerState,
	round_number: int,
	is_end_turn: bool
) -> bool:
	var assignment := get_mission_assignment(player.player_id)
	if assignment == null or assignment.is_completed():
		return false

	var mission := assignment.mission_data
	if mission.completion_timing == KarmanyMissionData.CompletionTiming.END_TURN and not is_end_turn:
		return false
	if not progress_tracker.are_conditions_met(
		player.player_id,
		mission.conditions
	):
		return false

	var effect_results := KarmanyEffectResolver.apply_effects(
		mission.reward_effects,
		player
	)
	for effect_result in effect_results:
		if not effect_result.was_applied():
			return false

	assignment.status = KarmanyMissionAssignment.Status.COMPLETED_REVEALED
	assignment.completed_round = round_number
	assignment.reward_legacy_points_pending = mission.reward_legacy_points
	assignment.reward_effect_results = effect_results

	_add_pending_legacy_reward(
		KarmanyLegacyRewardPending.SourceType.TRAINER_MISSION,
		mission.mission_id,
		player.player_id,
		mission.reward_legacy_points,
		round_number
	)
	mission_completed.emit(
		player.player_id,
		mission.mission_id,
		mission.reward_legacy_points
	)
	return true


func _claim_eligible_public_objectives(
	player: KarmanyPlayerState,
	round_number: int
) -> int:
	var claimed: int = 0
	for state in _objective_states.values():
		if not (state is KarmanyObjectiveState):
			continue
		if state.is_claimed():
			continue
		var objective := state.objective_data
		if not progress_tracker.are_conditions_met(
			player.player_id,
			objective.conditions
		):
			continue
		if not state.claim(player.player_id, round_number):
			continue

		_add_pending_legacy_reward(
			KarmanyLegacyRewardPending.SourceType.PUBLIC_OBJECTIVE,
			objective.objective_id,
			player.player_id,
			objective.reward_legacy_points,
			round_number
		)
		public_objective_claimed.emit(
			player.player_id,
			objective.objective_id,
			objective.reward_legacy_points
		)
		claimed += 1
	return claimed


func _sync_player_snapshot(player: KarmanyPlayerState) -> void:
	progress_tracker.set_state_int(
		player.player_id,
		STATE_EQUIPMENT_COUNT,
		player.get_equipment_count()
	)
	progress_tracker.set_state_int(
		player.player_id,
		STATE_LINKED_KARMANY_COUNT,
		player.get_linked_karmanys().size()
	)
	progress_tracker.set_state_int(
		player.player_id,
		STATE_RESONANCE_COUNT,
		player.get_resonance_count()
	)
	progress_tracker.set_state_int(
		player.player_id,
		STATE_FA,
		player.fa
	)


func _add_pending_legacy_reward(
	source_type: int,
	source_id: StringName,
	player_id: StringName,
	legacy_points: int,
	round_number: int
) -> void:
	var reward := KarmanyLegacyRewardPending.new()
	if reward.configure(
		source_type,
		source_id,
		player_id,
		legacy_points,
		round_number
	):
		_pending_legacy_rewards.append(reward)
