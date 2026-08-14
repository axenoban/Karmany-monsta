class_name KarmanyAiResourceUtility
extends RefCounted


const MIN_RESERVE_TARGET: int = 2
const SOFT_BUFFER: int = 1
const LOW_NEED_UNIT_VALUE: float = 1.55
const NEAR_TARGET_UNIT_VALUE: float = 0.70
const SURPLUS_BASE_UNIT_VALUE: float = 0.30


static func estimate_effects(
	effects: Array,
	player: KarmanyPlayerState,
	coordinator: KarmanyMatchCoordinator
) -> Dictionary:
	var total: float = 0.0
	var resource_details: Array[Dictionary] = []

	for value in effects:
		if not (value is KarmanyEffectData):
			continue
		var effect := value as KarmanyEffectData
		match effect.effect_type:
			KarmanyEffectData.EffectType.ADD_RESOURCE:
				var detail := estimate_resource_gain(
					effect.resource_type,
					maxi(effect.amount, 0),
					player,
					coordinator
				)
				total += float(detail.get("value", 0.0))
				resource_details.append(detail)
			KarmanyEffectData.EffectType.DRAW_CARDS:
				total += maxf(float(effect.amount), 0.0) * 0.8
			KarmanyEffectData.EffectType.ACTIVATE_CONDITION:
				total += 1.5
			KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER:
				total += 1.0
			KarmanyEffectData.EffectType.REMOVE_RESOURCE:
				total -= maxf(float(effect.amount), 0.0)
			KarmanyEffectData.EffectType.DISCARD_CARDS:
				total -= maxf(float(effect.amount), 0.0) * 0.8

	return {
		"value": total,
		"resource_details": resource_details
	}


static func estimate_resource_gain(
	resource_type: int,
	amount: int,
	player: KarmanyPlayerState,
	coordinator: KarmanyMatchCoordinator
) -> Dictionary:
	if player == null or amount <= 0:
		return {
			"resource_type": resource_type,
			"before": 0,
			"after": 0,
			"target": MIN_RESERVE_TARGET,
			"value": 0.0,
			"demand_sources": PackedStringArray()
		}

	var before: int = player.resource_inventory.get_resource(resource_type)
	var demand := get_resource_demand(resource_type, player, coordinator)
	var target: int = maxi(int(demand.get("target", MIN_RESERVE_TARGET)), 1)
	var total_value: float = 0.0

	for offset in range(amount):
		var stock_before_unit: int = before + offset
		total_value += _marginal_unit_value(stock_before_unit, target)

	# Crossing a known near-term threshold is more useful than merely adding
	# the same amount to an already sufficient reserve.
	var thresholds_value: Variant = demand.get("thresholds", PackedInt32Array())
	if thresholds_value is PackedInt32Array:
		var thresholds: PackedInt32Array = thresholds_value
		for threshold in thresholds:
			if before < threshold and before + amount >= threshold:
				total_value += 0.35
				break

	return {
		"resource_type": resource_type,
		"before": before,
		"after": before + amount,
		"target": target,
		"value": total_value,
		"demand_sources": demand.get("sources", PackedStringArray())
	}


static func get_resource_demand(
	resource_type: int,
	player: KarmanyPlayerState,
	coordinator: KarmanyMatchCoordinator
) -> Dictionary:
	var target: int = MIN_RESERVE_TARGET
	var thresholds: PackedInt32Array = PackedInt32Array()
	var sources: PackedStringArray = PackedStringArray()

	if coordinator != null:
		var book_state := coordinator.get_book_state(player.player_id)
		if book_state != null and book_state.can_improve():
			var book_cost: Dictionary = KarmanyBookProgressController.get_upgrade_cost(
				book_state.get_next_level()
			)
			var book_required: int = int(book_cost.get(resource_type, 0))
			if book_required > 0:
				target = maxi(target, book_required)
				thresholds.append(book_required)
				sources.append("Libro N%d" % book_state.get_next_level())

		if coordinator.equipment_market != null:
			for equipment in coordinator.equipment_market.get_visible():
				if equipment == null:
					continue
				var equipment_cost: Dictionary = equipment.get_cost()
				var equipment_required: int = int(equipment_cost.get(resource_type, 0))
				if equipment_required <= 0:
					continue
				target = maxi(target, equipment_required)
				if not thresholds.has(equipment_required):
					thresholds.append(equipment_required)
				sources.append("Equipo %s" % String(equipment.equipment_id))

	thresholds.sort()
	return {
		"target": target,
		"thresholds": thresholds,
		"sources": sources
	}


static func _marginal_unit_value(stock_before_unit: int, target: int) -> float:
	if stock_before_unit < target:
		var shortage_ratio: float = float(target - stock_before_unit) / float(maxi(target, 1))
		return LOW_NEED_UNIT_VALUE + shortage_ratio * 0.35
	if stock_before_unit < target + SOFT_BUFFER:
		return NEAR_TARGET_UNIT_VALUE

	var surplus: int = stock_before_unit - target - SOFT_BUFFER
	return maxf(
		0.08,
		SURPLUS_BASE_UNIT_VALUE / (1.0 + float(surplus) * 0.55)
	)
