class_name KarmanyEquipmentData
extends Resource


enum Rarity {
	BASIC,
	ADVANCED,
	ANCESTRAL
}


@export_group("Identity")
@export var equipment_id: StringName = &""
@export var display_name: String = ""
@export var rarity: Rarity = Rarity.BASIC
@export var tags: PackedStringArray = PackedStringArray()

@export_group("Craft")
@export var cost: Dictionary = {}

@export_group("Rules")
@export_multiline var rules_text: String = ""
@export var trigger_tags: PackedStringArray = PackedStringArray()
@export var modifiers: Array[KarmanyEquipmentModifierData] = []


func is_valid_definition() -> bool:
	if equipment_id == &"" or display_name.is_empty():
		return false
	if rules_text.is_empty():
		return false
	if not is_valid_cost():
		return false

	for modifier in modifiers:
		if modifier == null or not modifier.is_valid_definition():
			return false

	return true


func is_valid_cost() -> bool:
	if cost.is_empty():
		return false

	for resource_key in cost.keys():
		var resource_type: int = int(resource_key)
		var amount: int = int(cost[resource_key])

		if (
			resource_type < KarmanyEffectData.ResourceType.MN
			or resource_type > KarmanyEffectData.ResourceType.FA
		):
			return false

		if amount <= 0:
			return false

	return true


func get_cost() -> Dictionary:
	return cost.duplicate()


func get_rarity_label() -> String:
	match rarity:
		Rarity.BASIC:
			return "Basico"
		Rarity.ADVANCED:
			return "Avanzado"
		Rarity.ANCESTRAL:
			return "Ancestral"
	return "Desconocido"
