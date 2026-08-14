class_name KarmanyAiBrain
extends RefCounted


const REPETITION_PENALTY_STEP: float = 1.35
const REPETITION_PENALTY_MAX: float = 5.40


var profile: KarmanyAiProfile = KarmanyAiProfile.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _last_executed_signature: String = ""
var _same_action_streak: int = 0


func configure(profile_type: int, seed_value: int = 0) -> bool:
	if not profile.configure(profile_type):
		return false
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	clear_recent_action_memory()
	return true


func choose_action(
	candidates: Array[KarmanyAiActionCandidate]
) -> KarmanyAiActionCandidate:
	var best_score: float = -INF
	var best_candidates: Array[KarmanyAiActionCandidate] = []

	for candidate in candidates:
		if candidate == null or not candidate.is_valid():
			continue
		var candidate_score: float = score_action(candidate)
		if candidate_score > best_score + 0.0001:
			best_score = candidate_score
			best_candidates.clear()
			best_candidates.append(candidate)
		elif absf(candidate_score - best_score) <= 0.0001:
			best_candidates.append(candidate)

	if best_candidates.is_empty():
		return null
	if best_candidates.size() == 1:
		return best_candidates[0]

	# RNG solo desempata utilidades equivalentes. No se usa para ocultar
	# una funcion de utilidad degenerativa.
	return best_candidates[rng.randi_range(0, best_candidates.size() - 1)]


func score_action(candidate: KarmanyAiActionCandidate) -> float:
	if candidate == null:
		return -INF
	return profile.score(candidate) - get_repetition_penalty(candidate)


func get_score_breakdown(candidate: KarmanyAiActionCandidate) -> Dictionary:
	if candidate == null:
		return {
			"base_profile_score": -INF,
			"repetition_penalty": 0.0,
			"final_score": -INF,
			"repeat_streak": _same_action_streak
		}
	var base_score: float = profile.score(candidate)
	var repetition_penalty: float = get_repetition_penalty(candidate)
	return {
		"base_profile_score": base_score,
		"repetition_penalty": repetition_penalty,
		"final_score": base_score - repetition_penalty,
		"repeat_streak": _same_action_streak,
		"signature": _candidate_signature(candidate)
	}


func get_repetition_penalty(candidate: KarmanyAiActionCandidate) -> float:
	if candidate == null or _last_executed_signature.is_empty():
		return 0.0
	if _candidate_signature(candidate) != _last_executed_signature:
		return 0.0
	return minf(
		float(_same_action_streak) * REPETITION_PENALTY_STEP,
		REPETITION_PENALTY_MAX
	)


func record_executed_action(candidate: KarmanyAiActionCandidate) -> void:
	if candidate == null:
		return
	var signature: String = _candidate_signature(candidate)
	if signature == _last_executed_signature:
		_same_action_streak += 1
	else:
		_last_executed_signature = signature
		_same_action_streak = 1


func clear_recent_action_memory() -> void:
	_last_executed_signature = ""
	_same_action_streak = 0


func get_recent_action_memory() -> Dictionary:
	return {
		"signature": _last_executed_signature,
		"same_action_streak": _same_action_streak
	}


func _candidate_signature(candidate: KarmanyAiActionCandidate) -> String:
	return "%d|%d,%d|%d" % [
		candidate.action_type,
		candidate.target_coord.x,
		candidate.target_coord.y,
		candidate.option_index
	]
