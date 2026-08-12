class_name KarmanyCombatResolver
extends RefCounted


const CONSEQUENCE_TARGET_DEFEATED: String = "target_defeated"
const CONSEQUENCE_ATTACKER_DEFEATED: String = "attacker_defeated"
const CONSEQUENCE_RISK_DISCARD_CARD: String = "risk_discard_1_card_after_combat"
const CONSEQUENCE_RISK_FILTER_RESONANCE: String = "risk_draw_1_resonance_discard_1_after_combat"
const CONSEQUENCE_RISK_WIN_REWARD: String = "risk_choose_1_pl_or_2_basic_resources_on_win"


static func resolve(
	request: KarmanyCombatRequest
) -> KarmanyCombatResult:
	var validation := _validate_request(request)
	if validation != "":
		return _invalid_result(validation)

	var result := KarmanyCombatResult.new()
	result.status = KarmanyCombatResult.Status.RESOLVED
	result.attacker_player_id = request.attacker_player_id
	result.attacker_karmany_id = request.attacker_karmany.karmany_id
	result.target_id = request.target_id
	result.target_type = request.target_type

	result.base_power = request.attacker_karmany.power
	result.equipment_power = request.modifiers.equipment_power
	result.resonance_power = request.modifiers.resonance_power
	result.trainer_power = request.modifiers.trainer_power
	result.book_power = request.modifiers.book_power
	result.other_power = request.modifiers.other_power

	result.risk_roll = request.risk_roll
	result.risk_power_adjustment = get_risk_power_adjustment(
		request.risk_roll
	)
	result.total_power = (
		result.base_power
		+ request.modifiers.get_total()
		+ result.risk_power_adjustment
	)

	result.base_defense = request.base_defense
	result.instinct_roll = request.instinct_roll
	result.instinct_adjustment = get_instinct_adjustment(
		request.instinct_roll
	)
	result.effective_defense = max(
		0,
		result.base_defense + result.instinct_adjustment
	)

	if result.total_power >= result.effective_defense:
		result.outcome = KarmanyCombatResult.Outcome.VICTORY
		result.message = "Poder total iguala o supera la Defensa efectiva."
		result.pending_consequences.append(
			CONSEQUENCE_TARGET_DEFEATED
		)
	else:
		result.outcome = KarmanyCombatResult.Outcome.DEFEAT
		result.message = "Poder total no alcanza la Defensa efectiva."
		result.pending_consequences.append(
			CONSEQUENCE_ATTACKER_DEFEATED
		)

	_append_risk_consequences(result)
	return result


static func get_instinct_adjustment(roll: int) -> int:
	match roll:
		1:
			return -2
		2:
			return -1
		3, 4:
			return 0
		5:
			return 1
		6:
			return 2
	return 0


static func get_risk_power_adjustment(roll: int) -> int:
	match roll:
		1:
			return -3
		2, 3, 4:
			return 0
		5:
			return 7
		6:
			return 10
	return 0


static func _validate_request(
	request: KarmanyCombatRequest
) -> String:
	if request == null:
		return "Solicitud de combate inexistente."
	if request.attacker_player_id == &"":
		return "El atacante requiere player_id."
	if request.attacker_karmany == null:
		return "El atacante requiere Karmany."
	if not request.attacker_karmany.is_valid_definition():
		return "Karmany atacante invalido."
	if request.target_id == &"":
		return "El objetivo requiere ID."
	if (
		request.target_type < KarmanyCombatRequest.TargetType.UNBOUND_KARMANY
		or request.target_type > KarmanyCombatRequest.TargetType.LEGENDARY
	):
		return "Tipo de objetivo invalido."
	if request.base_defense <= 0:
		return "La Defensa base debe ser mayor que cero."
	if request.modifiers == null:
		return "Falta el desglose de modificadores de Poder."

	# Fase 11 solo soporta objetivos PvE. Todos usan Instinto en v0.74.
	if not request.uses_instinct:
		return "Los combates PvE de Fase 11 requieren Dado de Instinto."
	if request.instinct_roll < 1 or request.instinct_roll > 6:
		return "El Dado de Instinto debe estar entre 1 y 6."

	if request.risk_roll != 0:
		if not request.risk_authorized:
			return "El Dado de Riesgo no esta autorizado para este combate."
		if request.risk_roll < 1 or request.risk_roll > 6:
			return "El Dado de Riesgo debe estar entre 1 y 6."

	return ""


static func _append_risk_consequences(
	result: KarmanyCombatResult
) -> void:
	match result.risk_roll:
		2:
			result.pending_consequences.append(
				CONSEQUENCE_RISK_DISCARD_CARD
			)
		4:
			result.pending_consequences.append(
				CONSEQUENCE_RISK_FILTER_RESONANCE
			)
		6:
			if result.is_victory():
				result.pending_consequences.append(
					CONSEQUENCE_RISK_WIN_REWARD
				)


static func _invalid_result(message: String) -> KarmanyCombatResult:
	var result := KarmanyCombatResult.new()
	result.status = KarmanyCombatResult.Status.INVALID_REQUEST
	result.message = message
	return result
