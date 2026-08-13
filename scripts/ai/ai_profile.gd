class_name KarmanyAiProfile
extends RefCounted


enum ProfileType {
	EXPLORER,
	OPTIMIZER,
	AGGRESSIVE,
	OPPORTUNIST
}


var profile_type: int = ProfileType.EXPLORER


func configure(value: int) -> bool:
	if value < ProfileType.EXPLORER or value > ProfileType.OPPORTUNIST:
		return false
	profile_type = value
	return true


func get_display_name() -> String:
	match profile_type:
		ProfileType.EXPLORER:
			return "Explorador"
		ProfileType.OPTIMIZER:
			return "Optimizador"
		ProfileType.AGGRESSIVE:
			return "Agresivo"
		ProfileType.OPPORTUNIST:
			return "Oportunista"
	return "IA"


func score(candidate: KarmanyAiActionCandidate) -> float:
	if candidate == null or not candidate.is_valid():
		return -INF

	var total: float = candidate.base_utility

	match profile_type:
		ProfileType.EXPLORER:
			total += candidate.exploration_value * 5.0
			total += candidate.progress_value * 1.25
			total += candidate.opportunity_value * 0.50
			total += candidate.economy_value * 0.50
			total += candidate.aggression_value * 0.10
			total -= candidate.risk_value * 0.75
			if candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE:
				total += 8.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.MOVE:
				total += 2.0

		ProfileType.OPTIMIZER:
			total += candidate.progress_value * 4.0
			total += candidate.economy_value * 3.0
			total += candidate.opportunity_value * 2.0
			total += candidate.exploration_value * 0.60
			total += candidate.aggression_value * 0.40
			total -= candidate.risk_value * 0.80
			if candidate.action_type == KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK:
				total += 8.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT:
				total += 4.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_PAYMENT:
				total += 3.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.INTERACT:
				total += 2.0

		ProfileType.AGGRESSIVE:
			total += candidate.aggression_value * 5.0
			total += candidate.progress_value * 1.50
			total += candidate.opportunity_value * 1.0
			total += candidate.exploration_value * 0.50
			total += candidate.economy_value * 0.20
			total -= candidate.risk_value * 0.25
			if candidate.action_type == KarmanyAiActionCandidate.ActionType.PVP:
				total += 10.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
				total += 8.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
				total += 9.0

		ProfileType.OPPORTUNIST:
			total += candidate.opportunity_value * 5.0
			total += candidate.economy_value * 2.50
			total += candidate.progress_value * 1.50
			total += candidate.aggression_value * 1.25
			total += candidate.exploration_value * 1.0
			total -= candidate.risk_value * 0.40
			if candidate.action_type == KarmanyAiActionCandidate.ActionType.INTERACT:
				total += 3.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT:
				total += 3.0
			elif candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_PAYMENT:
				total += 3.0

	return total
