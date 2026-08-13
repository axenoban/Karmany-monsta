class_name KarmanyBookProgressController
extends RefCounted


const ACTION_ID_IMPROVE_BOOK: StringName = &"improve_book"


static func get_upgrade_cost(next_level: int) -> Dictionary:
	match next_level:
		2:
			return {
				KarmanyEffectData.ResourceType.MR: 2,
				KarmanyEffectData.ResourceType.EK: 3
			}
		3:
			return {
				KarmanyEffectData.ResourceType.MR: 3,
				KarmanyEffectData.ResourceType.EK: 3,
				KarmanyEffectData.ResourceType.FA: 2
			}
	return {}


static func improve(
	player: KarmanyPlayerState,
	turn_manager: KarmanyTurnManager,
	state: KarmanyBookProgressState,
	legacy_points: KarmanyLegacyPointsController = null
) -> KarmanyBookProgressResult:
	if player == null or turn_manager == null or state == null:
		return _result(KarmanyBookProgressResult.Status.INVALID_REQUEST, "Jugador, turno y Libro son obligatorios.")
	if state.player_id != player.player_id:
		return _result(KarmanyBookProgressResult.Status.INVALID_REQUEST, "El Libro no pertenece a este jugador.")
	if not turn_manager.is_running:
		return _result(KarmanyBookProgressResult.Status.INVALID_REQUEST, "La partida no esta activa.")
	if turn_manager.get_active_player() != player:
		return _result(KarmanyBookProgressResult.Status.NOT_ACTIVE_PLAYER, "Solo el jugador activo puede mejorar Libro.")
	if not state.can_improve():
		return _result(KarmanyBookProgressResult.Status.MAX_LEVEL, "El Libro ya esta en Nivel III.")
	if not turn_manager.can_spend_action(1):
		return _result(KarmanyBookProgressResult.Status.NO_ACTIONS, "No quedan acciones para mejorar Libro.")

	var next_level: int = state.get_next_level()
	var cost: Dictionary = get_upgrade_cost(next_level)
	if cost.is_empty() or not player.can_afford_resources(cost):
		return _result(KarmanyBookProgressResult.Status.INSUFFICIENT_RESOURCES, "Recursos insuficientes para mejorar Libro.")
	if not player.spend_resources(cost):
		return _result(KarmanyBookProgressResult.Status.INSUFFICIENT_RESOURCES, "No se pudo pagar el costo del Libro.")
	if not turn_manager.spend_action_for(ACTION_ID_IMPROVE_BOOK, 1):
		_refund(player, cost)
		return _result(KarmanyBookProgressResult.Status.NO_ACTIONS, "No se pudo consumir la accion de mejorar Libro.")

	var previous_level: int = state.level
	if not state.set_level(next_level):
		_refund(player, cost)
		return _result(KarmanyBookProgressResult.Status.INVALID_REQUEST, "No se pudo actualizar el nivel del Libro.")

	var result := KarmanyBookProgressResult.new()
	result.status = KarmanyBookProgressResult.Status.SUCCESS
	result.previous_level = previous_level
	result.new_level = next_level
	result.paid_cost = cost.duplicate()
	result.action_consumed = true
	result.message = "Libro mejorado a Nivel %d." % next_level

	if next_level == 3 and legacy_points != null:
		result.milestone_award = legacy_points.award_milestone(
			player.player_id,
			KarmanyLegacyMilestoneCatalog.BOOK_III_REACHED,
			turn_manager.current_round
		)
	return result


static func _refund(player: KarmanyPlayerState, costs: Dictionary) -> void:
	for resource_key in costs.keys():
		var amount: int = int(costs[resource_key])
		if amount > 0:
			player.gain_resource(int(resource_key), amount)


static func _result(status_value: int, text: String) -> KarmanyBookProgressResult:
	var result := KarmanyBookProgressResult.new()
	result.status = status_value
	result.message = text
	return result
