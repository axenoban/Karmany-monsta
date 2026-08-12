class_name KarmanyPlayerState
extends RefCounted


var player_id: StringName = &""
var current_coord: Vector2i = Vector2i.ZERO

var resource_inventory: KarmanyResourceInventory = KarmanyResourceInventory.new()
var karmany_roster: KarmanyRoster = KarmanyRoster.new()


var mn: int:
	get:
		return resource_inventory.get_resource(
			KarmanyEffectData.ResourceType.MN
		)
	set(value):
		resource_inventory.set_resource(
			KarmanyEffectData.ResourceType.MN,
			value
		)


var mr: int:
	get:
		return resource_inventory.get_resource(
			KarmanyEffectData.ResourceType.MR
		)
	set(value):
		resource_inventory.set_resource(
			KarmanyEffectData.ResourceType.MR,
			value
		)


var ek: int:
	get:
		return resource_inventory.get_resource(
			KarmanyEffectData.ResourceType.EK
		)
	set(value):
		resource_inventory.set_resource(
			KarmanyEffectData.ResourceType.EK,
			value
		)


var fa: int:
	get:
		return resource_inventory.get_resource(
			KarmanyEffectData.ResourceType.FA
		)
	set(value):
		resource_inventory.set_resource(
			KarmanyEffectData.ResourceType.FA,
			value
		)


func setup_new_game(
	p_player_id: StringName = &"player_1",
	starting_coord: Vector2i = Vector2i.ZERO
) -> void:
	player_id = p_player_id
	current_coord = starting_coord
	resource_inventory.reset_to_starting_resources()
	karmany_roster.clear()


func set_board_position(coord: Vector2i) -> void:
	current_coord = coord


func add_resource(
	resource_type: KarmanyEffectData.ResourceType,
	amount: int
) -> void:
	resource_inventory.adjust_resource(
		resource_type,
		amount
	)


func gain_resource(
	resource_type: KarmanyEffectData.ResourceType,
	amount: int
) -> bool:
	return resource_inventory.gain_resource(
		resource_type,
		amount
	)


func get_resource(
	resource_type: KarmanyEffectData.ResourceType
) -> int:
	return resource_inventory.get_resource(
		resource_type
	)


func can_spend_resource(
	resource_type: KarmanyEffectData.ResourceType,
	amount: int
) -> bool:
	return resource_inventory.can_spend_resource(
		resource_type,
		amount
	)


func spend_resource(
	resource_type: KarmanyEffectData.ResourceType,
	amount: int
) -> bool:
	return resource_inventory.spend_resource(
		resource_type,
		amount
	)


func can_afford_resources(costs: Dictionary) -> bool:
	return resource_inventory.can_afford(costs)


func spend_resources(costs: Dictionary) -> bool:
	return resource_inventory.spend_cost(costs)


func get_resource_snapshot() -> Dictionary:
	return resource_inventory.get_snapshot()


func add_linked_karmany(karmany: KarmanyRuntimeState) -> bool:
	if karmany == null:
		return false
	if karmany.owner_player_id != player_id:
		return false
	return karmany_roster.add_linked_karmany(karmany)


func has_karmany_instance(instance_id: StringName) -> bool:
	return karmany_roster.has_instance(instance_id)


func get_linked_karmanys() -> Array[KarmanyRuntimeState]:
	return karmany_roster.get_all()
