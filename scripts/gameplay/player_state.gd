class_name KarmanyPlayerState
extends RefCounted


var player_id: StringName = &""
var current_coord: Vector2i = Vector2i.ZERO

var resource_inventory: KarmanyResourceInventory = KarmanyResourceInventory.new()
var karmany_roster: KarmanyRoster = KarmanyRoster.new()
var equipment_inventory: KarmanyEquipmentInventory = KarmanyEquipmentInventory.new()
var resonance_hand: KarmanyResonanceHand = KarmanyResonanceHand.new()


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
	equipment_inventory.clear()
	resonance_hand.clear()


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


func set_active_karmany(instance_id: StringName) -> bool:
	return karmany_roster.set_active(instance_id)


func get_active_karmany() -> KarmanyRuntimeState:
	return karmany_roster.get_active()


func has_active_karmany() -> bool:
	return karmany_roster.has_active()


func add_equipment(equipment: KarmanyEquipmentData) -> bool:
	return equipment_inventory.add_equipment(equipment)


func replace_equipment(
	discard_equipment_id: StringName,
	new_equipment: KarmanyEquipmentData
) -> KarmanyEquipmentData:
	return equipment_inventory.replace_equipment(
		discard_equipment_id,
		new_equipment
	)


func get_equipped_equipment() -> Array[KarmanyEquipmentData]:
	return equipment_inventory.get_all()


func get_equipment_count() -> int:
	return equipment_inventory.get_count()


func get_resonance_hand() -> Array[KarmanyResonanceData]:
	return resonance_hand.get_all()


func get_resonance_count() -> int:
	return resonance_hand.get_count()


func get_pending_resonance_discard_count() -> int:
	return resonance_hand.get_pending_discard_count()


func request_end_turn_resonance_discard() -> int:
	return resonance_hand.request_end_turn_limit_discard()
