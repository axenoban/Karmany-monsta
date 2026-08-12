class_name KarmanyAbilityData
extends Resource


enum UsageLimit {
	NONE,
	ONCE_PER_TURN,
	ONCE_PER_ROUND,
	ONCE_PER_COMBAT,
	ONCE_PER_MATCH
}

@export_group("Identity")
@export var ability_id: StringName = &""
@export var display_name: String = ""

@export_group("Rules")
@export var trigger_id: StringName = &""
@export var usage_limit: UsageLimit = UsageLimit.NONE
@export_multiline var rules_text: String = ""
@export var effect_tags: PackedStringArray = PackedStringArray()

@export_group("Executable Effects")
@export var effects: Array[KarmanyEffectData] = []

func is_valid_definition() -> bool:
	return ability_id != &"" and not rules_text.is_empty()
