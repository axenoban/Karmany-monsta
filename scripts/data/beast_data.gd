class_name KarmanyBeastData
extends Resource


enum Tier {
	BASIC,
	MEDIUM,
	COMPLEX,
	BOSS
}


@export_group("Identity")
@export var beast_id: StringName = &""
@export var display_name: String = ""
@export var classification: String = ""
@export var tier: Tier = Tier.BASIC

@export_group("Combat")
@export_range(1, 99, 1) var base_defense: int = 1
@export var combat_tags: PackedStringArray = PackedStringArray()
@export var special_rule_ids: PackedStringArray = PackedStringArray()

@export_group("Victory")
@export_range(0, 99, 1) var reward_legacy_points: int = 0
@export var reward_effects: Array[KarmanyEffectData] = []
@export var reward_consequence_ids: PackedStringArray = PackedStringArray()

@export_group("Defeat")
@export var defeat_effects: Array[KarmanyEffectData] = []
@export var defeat_consequence_ids: PackedStringArray = PackedStringArray()

@export_group("Rules")
@export_multiline var reward_text: String = ""
@export_multiline var defeat_text: String = ""
@export_multiline var rules_text: String = ""


func is_valid_definition() -> bool:
	if beast_id == &"" or display_name.is_empty():
		return false
	if classification.is_empty():
		return false
	if base_defense <= 0:
		return false
	if reward_legacy_points < 0:
		return false
	if reward_text.is_empty() or defeat_text.is_empty():
		return false

	for effect in reward_effects:
		if effect == null:
			return false
	for effect in defeat_effects:
		if effect == null:
			return false

	return true


func is_boss() -> bool:
	return tier == Tier.BOSS


func get_tier_label() -> String:
	match tier:
		Tier.BASIC:
			return "Basica"
		Tier.MEDIUM:
			return "Media"
		Tier.COMPLEX:
			return "Compleja"
		Tier.BOSS:
			return "Jefe"
	return "Desconocida"
