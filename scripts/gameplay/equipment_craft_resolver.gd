class_name KarmanyEquipmentCraftResolver
extends RefCounted


static func craft_from_market(
	player: KarmanyPlayerState,
	market: KarmanyEquipmentMarket,
	visible_index: int,
	turn_manager: KarmanyTurnManager,
	context: KarmanyEquipmentCraftContext,
	discard_equipment_id: StringName = &""
) -> KarmanyEquipmentCraftResult:
	if player == null or market == null or context == null:
		return _result(
			KarmanyEquipmentCraftResult.Status.INVALID_REQUEST,
			"Jugador, mercado y contexto son obligatorios."
		)

	if not context.is_valid():
		return _result(
			KarmanyEquipmentCraftResult.Status.INVALID_REQUEST,
			"Contexto de crafteo invalido."
		)

	if context.action_cost > 0:
		if turn_manager == null or not turn_manager.is_running:
			return _result(
				KarmanyEquipmentCraftResult.Status.INVALID_REQUEST,
				"El crafteo con costo de accion requiere partida activa."
			)
		if turn_manager.get_active_player() != player:
			return _result(
				KarmanyEquipmentCraftResult.Status.NOT_ACTIVE_PLAYER,
				"Solo el jugador activo puede craftear con esta accion."
			)
		if not turn_manager.can_spend_action(context.action_cost):
			return _result(
				KarmanyEquipmentCraftResult.Status.NO_ACTIONS,
				"No quedan acciones suficientes para crear Equipo."
			)

	var equipment := market.get_visible_at(visible_index)
	if equipment == null or not equipment.is_valid_definition():
		return _result(
			KarmanyEquipmentCraftResult.Status.MARKET_ERROR,
			"No existe un Equipo valido en esa posicion del mercado."
		)

	if not context.allows_rarity(equipment.rarity):
		return _result(
			KarmanyEquipmentCraftResult.Status.RARITY_NOT_ALLOWED,
			"La fuente actual no permite crear esta rareza de Equipo."
		)

	var inventory := player.equipment_inventory
	if inventory.has_equipment_id(equipment.equipment_id):
		return _result(
			KarmanyEquipmentCraftResult.Status.DUPLICATE,
			"Un jugador no puede tener Equipos duplicados."
		)

	var replacing: bool = inventory.is_full()
	if replacing:
		if discard_equipment_id == &"":
			return _result(
				KarmanyEquipmentCraftResult.Status.REQUIRES_DISCARD,
				"Al obtener un cuarto Equipo debes descartar uno inmediatamente."
			)
		if not inventory.has_equipment_id(discard_equipment_id):
			return _result(
				KarmanyEquipmentCraftResult.Status.INVALID_DISCARD,
				"El Equipo elegido para descartar no pertenece al jugador."
			)

	var paid_cost: Dictionary = context.get_discounted_cost(
		equipment.get_cost()
	)
	if not player.can_afford_resources(paid_cost):
		return _result(
			KarmanyEquipmentCraftResult.Status.INSUFFICIENT_RESOURCES,
			"Recursos insuficientes para crear este Equipo."
		)

	if not player.spend_resources(paid_cost):
		return _result(
			KarmanyEquipmentCraftResult.Status.INSUFFICIENT_RESOURCES,
			"No se pudo pagar el costo de Equipo."
		)

	var discarded: KarmanyEquipmentData = null
	var inventory_changed: bool = false

	if replacing:
		discarded = inventory.replace_equipment(
			discard_equipment_id,
			equipment
		)
		inventory_changed = discarded != null
	else:
		inventory_changed = inventory.add_equipment(equipment)

	if not inventory_changed:
		_refund(player, paid_cost)
		return _result(
			KarmanyEquipmentCraftResult.Status.INVENTORY_ERROR,
			"No se pudo incorporar el Equipo al jugador."
		)

	var action_consumed: bool = false
	if context.action_cost > 0:
		if not turn_manager.spend_action_for(
			context.action_id,
			context.action_cost
		):
			_rollback_inventory(
				inventory,
				equipment,
				discarded
			)
			_refund(player, paid_cost)
			return _result(
				KarmanyEquipmentCraftResult.Status.NO_ACTIONS,
				"No se pudo consumir la accion de crear Equipo."
			)
		action_consumed = true

	var taken := market.take_visible(visible_index)
	if taken != equipment:
		# El mercado se valida antes de mutar; en ejecución secuencial este caso
		# no debería ocurrir. Se informa de forma explícita si el estado cambia.
		return _result(
			KarmanyEquipmentCraftResult.Status.MARKET_ERROR,
			"El mercado cambio durante la resolucion del crafteo."
		)

	var result := _result(
		KarmanyEquipmentCraftResult.Status.SUCCESS,
		"Equipo creado, equipado y mercado repuesto."
	)
	result.equipment = equipment
	result.discarded_equipment = discarded
	result.paid_cost = paid_cost
	result.action_consumed = action_consumed
	return result


static func _rollback_inventory(
	inventory: KarmanyEquipmentInventory,
	new_equipment: KarmanyEquipmentData,
	discarded: KarmanyEquipmentData
) -> void:
	if inventory == null or new_equipment == null:
		return

	if discarded != null:
		inventory.replace_equipment(
			new_equipment.equipment_id,
			discarded
		)
	else:
		inventory.remove_equipment(
			new_equipment.equipment_id
		)


static func _refund(
	player: KarmanyPlayerState,
	costs: Dictionary
) -> void:
	for resource_key in costs.keys():
		var amount: int = int(costs[resource_key])
		if amount <= 0:
			continue
		player.gain_resource(
			int(resource_key),
			amount
		)


static func _result(
	status_value: int,
	text: String
) -> KarmanyEquipmentCraftResult:
	var result := KarmanyEquipmentCraftResult.new()
	result.status = status_value
	result.message = text
	return result
