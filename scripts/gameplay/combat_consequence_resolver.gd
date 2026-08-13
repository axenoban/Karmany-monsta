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


static func _award_error(message: String) -> KarmanyLegacyPointsAwardResult:
	var result := KarmanyLegacyPointsAwardResult.new()
	result.status = KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST
	result.message = message
	return result
