class_name KarmanyResourceInventory
extends RefCounted


signal resource_changed(
	resource_type: int,
	previous_amount: int,
	current_amount: int
)


const STARTING_MN: int = 2
const STARTING_MR: int = 1
const STARTING_EK: int = 1
const STARTING_FA: int = 0


var _amounts: Dictionary = {}


func _init() -> void:
	_amounts = {
		KarmanyEffectData.ResourceType.MN: 0,
		KarmanyEffectData.ResourceType.MR: 0,
		KarmanyEffectData.ResourceType.EK: 0,
		KarmanyEffectData.ResourceType.FA: 0
	}


func reset_to_starting_resources() -> void:
	set_resource(
		KarmanyEffectData.ResourceType.MN,
		STARTING_MN
	)
	set_resource(
		KarmanyEffectData.ResourceType.MR,
		STARTING_MR
	)
	set_resource(
		KarmanyEffectData.ResourceType.EK,
		STARTING_EK
	)
	set_resource(
		KarmanyEffectData.ResourceType.FA,
		STARTING_FA
	)


func is_valid_resource_type(resource_type: int) -> bool:
	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			return true
		KarmanyEffectData.ResourceType.MR:
			return true
		KarmanyEffectData.ResourceType.EK:
			return true
		KarmanyEffectData.ResourceType.FA:
			return true

	return false


func get_resource(resource_type: int) -> int:
	if not is_valid_resource_type(resource_type):
		return 0

	return int(
		_amounts.get(
			resource_type,
			0
		)
	)


func set_resource(
	resource_type: int,
	amount: int
) -> bool:
	if not is_valid_resource_type(resource_type):
		return false

	if amount < 0:
		return false

	var previous_amount: int = get_resource(resource_type)

	_amounts[resource_type] = amount

	if previous_amount != amount:
		resource_changed.emit(
			resource_type,
			previous_amount,
			amount
		)

	return true


func adjust_resource(
	resource_type: int,
	delta: int
) -> int:
	if not is_valid_resource_type(resource_type):
		return 0

	if delta == 0:
		return 0

	var previous_amount: int = get_resource(resource_type)
	var new_amount: int = maxi(
		0,
		previous_amount + delta
	)

	set_resource(
		resource_type,
		new_amount
	)

	return new_amount - previous_amount


func gain_resource(
	resource_type: int,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if not is_valid_resource_type(resource_type):
		return false

	set_resource(
		resource_type,
		get_resource(resource_type) + amount
	)

	return true


func can_spend_resource(
	resource_type: int,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if not is_valid_resource_type(resource_type):
		return false

	return get_resource(resource_type) >= amount


func spend_resource(
	resource_type: int,
	amount: int
) -> bool:
	if not can_spend_resource(
		resource_type,
		amount
	):
		return false

	return set_resource(
		resource_type,
		get_resource(resource_type) - amount
	)


func can_afford(costs: Dictionary) -> bool:
	for resource_key in costs.keys():
		var resource_type: int = int(resource_key)
		var required_amount: int = int(
			costs[resource_key]
		)

		if not is_valid_resource_type(resource_type):
			return false

		if required_amount < 0:
			return false

		if get_resource(resource_type) < required_amount:
			return false

	return true


func spend_cost(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false

	for resource_key in costs.keys():
		var resource_type: int = int(resource_key)
		var required_amount: int = int(
			costs[resource_key]
		)

		if required_amount <= 0:
			continue

		set_resource(
			resource_type,
			get_resource(resource_type) - required_amount
		)

	return true


func get_snapshot() -> Dictionary:
	return {
		KarmanyEffectData.ResourceType.MN: get_resource(
			KarmanyEffectData.ResourceType.MN
		),
		KarmanyEffectData.ResourceType.MR: get_resource(
			KarmanyEffectData.ResourceType.MR
		),
		KarmanyEffectData.ResourceType.EK: get_resource(
			KarmanyEffectData.ResourceType.EK
		),
		KarmanyEffectData.ResourceType.FA: get_resource(
			KarmanyEffectData.ResourceType.FA
		)
	}


func get_debug_summary() -> String:
	return (
		"MN: %s | MR: %s | EK: %s | FA: %s"
		% [
			get_resource(KarmanyEffectData.ResourceType.MN),
			get_resource(KarmanyEffectData.ResourceType.MR),
			get_resource(KarmanyEffectData.ResourceType.EK),
			get_resource(KarmanyEffectData.ResourceType.FA)
		]
	)
