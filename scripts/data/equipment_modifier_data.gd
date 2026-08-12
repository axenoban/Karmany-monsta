class_name KarmanyEquipmentModifierData
extends Resource


enum ModifierType {
	COMBAT_POWER
}


@export_group("Identity")
@export var modifier_id: StringName = &""

@export_group("Modifier")
@export var modifier_type: ModifierType = ModifierType.COMBAT_POWER
@export_range(-99, 99, 1) var amount: int = 0
@export var target_tags: PackedStringArray = PackedStringArray()
@export var trigger_id: StringName = &""
@export var automatic_in_combat: bool = false

@export_group("Rules")
@export_multiline var rules_text: String = ""


func is_valid_definition() -> bool:
	if modifier_id == &"":
		return false
	if amount == 0:
		return false
	if target_tags.is_empty():
		return false
	return true


func matches_target_tags(candidate_tags: PackedStringArray) -> bool:
	if target_tags.has("any_pve"):
		return true

	for tag in candidate_tags:
		if target_tags.has(tag):
			return true

	return false
