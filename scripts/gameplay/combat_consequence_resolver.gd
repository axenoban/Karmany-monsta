class_name KarmanyCombatConsequenceResolver
extends RefCounted


static func has_risk_win_reward(result: KarmanyCombatResult) -> bool:
	if result == null or not result.is_victory() or result.risk_roll != 6:
		return false
	return result.pending_consequences.has(
		KarmanyCombatResolver.CONSEQUENCE_RISK_WIN_REWARD
	)


static func resolve_risk_win_basic_resources(
	player: KarmanyPlayerState,
	result: KarmanyCombatResult,
	first_resource: int,
	second_resource: int
) -> bool:
	if player == null or not has_risk_win_reward(result):
		return false
	if not _is_basic(first_resource) or not _is_basic(second_resource):
		return false
	if not player.gain_resource(first_resource, 1):
		return false
	if not player.gain_resource(second_resource, 1):
		player.spend_resource(first_resource, 1)
		return false
	_remove_consequence(result, KarmanyCombatResolver.CONSEQUENCE_RISK_WIN_REWARD)
	return true


static func resolve_risk_win_legacy_point(
	player: KarmanyPlayerState,
	result: KarmanyCombatResult,
	legacy_points: KarmanyLegacyPointsController,
	round_number: int,
	source_id: StringName
) -> KarmanyLegacyPointsAwardResult:
	if player == null or legacy_points == null or not has_risk_win_reward(result):
		return _award_error("La recompensa de Riesgo no esta disponible.")
	if source_id == &"" or round_number <= 0:
		return _award_error("Fuente y ronda son obligatorias para la recompensa de Riesgo.")
	var unique_key := StringName(
		"risk:%s:%d" % [String(player.player_id), result.get_instance_id()]
	)
	var award := legacy_points.award_points(
		player.player_id,
		KarmanyLegacyPointsEntry.SourceType.RISK_REWARD,
		source_id,
		1,
		round_number,
		unique_key,
		"Dado de Riesgo 6: eleccion de +1 PL."
	)
	if award.was_applied():
		_remove_consequence(result, KarmanyCombatResolver.CONSEQUENCE_RISK_WIN_REWARD)
	return award


static func apply_beast_basic_resource_loss_policy(
	result: KarmanyBeastCombatResult,
	policy: Dictionary
) -> bool:
	if result == null or not result.is_defeat():
		return false
	var original_amount: int = int(policy.get("original_amount", 0))
	var effective_amount: int = int(policy.get("effective_amount", original_amount))
	var reduction: int = int(policy.get("reduction", 0))
	if original_amount < 0 or effective_amount < 0 or effective_amount > original_amount:
		return false
	if reduction != original_amount - effective_amount:
		return false

	result.basic_resource_loss_original = original_amount
	result.basic_resource_loss_pending = effective_amount
	result.basic_resource_loss_reduction = reduction
	result.basic_resource_loss_consequence_id = StringName(policy.get("consequence_id", &""))
	result.basic_resource_loss_mitigation_id = StringName(policy.get("karmany_id", &""))

	if original_amount > 0 and effective_amount == 0:
		_remove_beast_consequence(result, result.basic_resource_loss_consequence_id)
	return true


static func resolve_beast_basic_resource_loss_choice(
	player: KarmanyPlayerState,
	result: KarmanyBeastCombatResult,
	selected_resources: Array
) -> bool:
	if player == null or result == null or not result.has_pending_basic_resource_loss():
		return false
	if selected_resources.size() != result.basic_resource_loss_pending:
		return false

	var costs: Dictionary = {}
	for resource_value in selected_resources:
		var resource_type: int = int(resource_value)
		if not _is_basic(resource_type):
			return false
		costs[resource_type] = int(costs.get(resource_type, 0)) + 1
	if not player.spend_resources(costs):
		return false

	result.basic_resource_loss_pending = 0
	_remove_beast_consequence(result, result.basic_resource_loss_consequence_id)
	return true


static func _is_basic(resource_type: int) -> bool:
	return (
		resource_type == KarmanyEffectData.ResourceType.MN
		or resource_type == KarmanyEffectData.ResourceType.MR
		or resource_type == KarmanyEffectData.ResourceType.EK
	)


static func _remove_consequence(result: KarmanyCombatResult, consequence: String) -> void:
	var index: int = result.pending_consequences.find(consequence)
	if index >= 0:
		result.pending_consequences.remove_at(index)


static func _remove_beast_consequence(
	result: KarmanyBeastCombatResult,
	consequence_id: StringName
) -> void:
	if result == null or consequence_id == &"":
		return
	var index: int = result.defeat_consequence_ids.find(String(consequence_id))
	if index >= 0:
		result.defeat_consequence_ids.remove_at(index)


static func _award_error(message: String) -> KarmanyLegacyPointsAwardResult:
	var result := KarmanyLegacyPointsAwardResult.new()
	result.status = KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST
	result.message = message
	return result
