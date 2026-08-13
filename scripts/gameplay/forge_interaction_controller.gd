class_name KarmanyForgeInteractionController
extends RefCounted


const ACTION_ID_FORGE_FA: StringName = &"interact_forge_fa"
const FORGE_TILE_ID: StringName = &"N3-02"

var _conversion_used_by_player: Dictionary = {}


func clear() -> void:
	_conversion_used_by_player.clear()


func has_used_conversion(player_id: StringName) -> bool:
	return bool(_conversion_used_by_player.get(player_id, false))


func convert_common_to_fa(
	player: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	first_resource: int,
	second_resource: int
) -> KarmanyForgeInteractionResult:
	if player == null or board_state == null or turn_manager == null:
		return _result(KarmanyForgeInteractionResult.Status.INVALID_REQUEST, "Jugador, tablero y turno son obligatorios.")
	if not turn_manager.is_running or turn_manager.get_active_player() != player:
		return _result(KarmanyForgeInteractionResult.Status.NOT_ACTIVE_PLAYER, "Solo el jugador activo puede usar la Forja.")
	if not turn_manager.can_spend_action(1):
		return _result(KarmanyForgeInteractionResult.Status.NO_ACTIONS, "No quedan acciones para usar la Forja.")
	if board_state.is_blocked_by_beast(player.current_coord):
		return _result(KarmanyForgeInteractionResult.Status.TILE_BLOCKED, "Una Bestia bloquea la loseta actual.")
	var tile_data: KarmanyTileData = board_state.get_tile_data(player.current_coord)
	if tile_data == null or StringName(tile_data.tile_id) != FORGE_TILE_ID:
		return _result(KarmanyForgeInteractionResult.Status.NOT_AT_FORGE, "La conversion requiere N3-02 Forja Antigua.")
	if has_used_conversion(player.player_id):
		return _result(KarmanyForgeInteractionResult.Status.ALREADY_USED, "Este jugador ya uso la conversion de la Forja.")
	if not _is_common(first_resource) or not _is_common(second_resource):
		return _result(KarmanyForgeInteractionResult.Status.INVALID_RESOURCES, "FA no puede pagarse como recurso comun.")

	var costs: Dictionary = {}
	costs[first_resource] = int(costs.get(first_resource, 0)) + 1
	costs[second_resource] = int(costs.get(second_resource, 0)) + 1
	if not player.can_afford_resources(costs):
		return _result(KarmanyForgeInteractionResult.Status.INSUFFICIENT_RESOURCES, "No tienes los 2 recursos comunes elegidos.")
	if not player.spend_resources(costs):
		return _result(KarmanyForgeInteractionResult.Status.INSUFFICIENT_RESOURCES, "No se pudo pagar la conversion.")
	if not turn_manager.spend_action_for(ACTION_ID_FORGE_FA, 1):
		_refund(player, costs)
		return _result(KarmanyForgeInteractionResult.Status.NO_ACTIONS, "No se pudo consumir la accion de Forja.")
	if not player.gain_resource(KarmanyEffectData.ResourceType.FA, 1):
		_refund(player, costs)
		return _result(KarmanyForgeInteractionResult.Status.INVALID_REQUEST, "No se pudo otorgar el FA de la Forja.")

	_conversion_used_by_player[player.player_id] = true
	var result := KarmanyForgeInteractionResult.new()
	result.status = KarmanyForgeInteractionResult.Status.SUCCESS
	result.message = "Forja Antigua: 2 recursos comunes convertidos en 1 FA."
	result.action_consumed = true
	result.fa_gained = 1
	result.paid_resources = costs.duplicate()
	return result


func _is_common(resource_type: int) -> bool:
	return (
		resource_type == KarmanyEffectData.ResourceType.MN
		or resource_type == KarmanyEffectData.ResourceType.MR
		or resource_type == KarmanyEffectData.ResourceType.EK
	)


func _refund(player: KarmanyPlayerState, costs: Dictionary) -> void:
	for key in costs.keys():
		player.gain_resource(int(key), int(costs[key]))


func _result(status_value: int, text: String) -> KarmanyForgeInteractionResult:
	var result := KarmanyForgeInteractionResult.new()
	result.status = status_value
	result.message = text
	return result
