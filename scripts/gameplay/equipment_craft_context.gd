class_name KarmanyEquipmentCraftContext
extends RefCounted


var source_id: StringName = &""
var allow_basic: bool = false
var allow_advanced: bool = false
var allow_ancestral: bool = false
var action_cost: int = 1
var action_id: StringName = &"interact_craft_equipment"
var resource_discounts: Dictionary = {}


func is_valid() -> bool:
	if source_id == &"":
		return false
	if not allow_basic and not allow_advanced and not allow_ancestral:
		return false
	if action_cost < 0:
		return false
	if action_cost > 0 and action_id == &"":
		return false

	for resource_key in resource_discounts.keys():
		var resource_type: int = int(resource_key)
		var discount: int = int(resource_discounts[resource_key])
		if (
			resource_type < KarmanyEffectData.ResourceType.MN
			or resource_type > KarmanyEffectData.ResourceType.FA
		):
			return false
		if discount < 0:
			return false

	return true


func allows_rarity(rarity: int) -> bool:
	match rarity:
		KarmanyEquipmentData.Rarity.BASIC:
			return allow_basic
		KarmanyEquipmentData.Rarity.ADVANCED:
			return allow_advanced
		KarmanyEquipmentData.Rarity.ANCESTRAL:
			return allow_ancestral
	return false


func get_discounted_cost(base_cost: Dictionary) -> Dictionary:
	var result: Dictionary = {}

	for resource_key in base_cost.keys():
		var resource_type: int = int(resource_key)
		var base_amount: int = int(base_cost[resource_key])
		var discount: int = int(
			resource_discounts.get(resource_type, 0)
		)
		result[resource_type] = maxi(
			0,
			base_amount - discount
		)

	return result
