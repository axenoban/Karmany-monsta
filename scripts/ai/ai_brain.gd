class_name KarmanyAiBrain
extends RefCounted


var profile: KarmanyAiProfile = KarmanyAiProfile.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func configure(profile_type: int, seed: int = 0) -> bool:
	if not profile.configure(profile_type):
		return false
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed
	return true


func choose_action(
	candidates: Array[KarmanyAiActionCandidate]
) -> KarmanyAiActionCandidate:
	var best_score: float = -INF
	var best_candidates: Array[KarmanyAiActionCandidate] = []

	for candidate in candidates:
		if candidate == null or not candidate.is_valid():
			continue
		var candidate_score: float = profile.score(candidate)
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

	# Los empates se resuelven con RNG para que una IA no recorra siempre
	# exactamente el mismo camino cuando varias opciones son equivalentes.
	return best_candidates[rng.randi_range(0, best_candidates.size() - 1)]


func score_action(candidate: KarmanyAiActionCandidate) -> float:
	return profile.score(candidate)
