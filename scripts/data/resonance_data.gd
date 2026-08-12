class_name KarmanyResonanceData
extends Resource


enum ResonanceType {
	ATTACK,
	DEFENSE,
	EXPLORATION,
	BOND,
	REACTION
}


@export_group("Identity")
@export var resonance_id: StringName = &""
@export var display_name: String = ""
@export var resonance_type: ResonanceType = ResonanceType.ATTACK

@export_group("Use")
@export var printed_power: int = 0
@export var use_windows: PackedStringArray = PackedStringArray()
@export var modifiers: Array[KarmanyResonanceModifierData] = []
@export var effect_blocks: Array[KarmanyResonanceEffectBlockData] = []

@export_group("Rules")
@export_multiline var rules_text: String = ""
@export var tags: PackedStringArray = PackedStringArray()


func is_valid_definition() -> bool:
	if resonance_id == &"" or display_name.is_empty():
		return false
	if use_windows.is_empty() or rules_text.is_empty():
		return false
	if printed_power < 0:
		return false

	for modifier in modifiers:
		if modifier == null or not modifier.is_valid_definition():
			return false

	for block in effect_blocks:
		if block == null or not block.is_valid_definition():
			return false

	return true


func can_use_in(window_id: StringName) -> bool:
	if window_id == &"":
		return false
	return use_windows.has(String(window_id))


func get_power_bonus(context_tags: PackedStringArray) -> int:
	var total: int = printed_power

	for modifier in modifiers:
		if modifier != null and modifier.matches(context_tags):
			total += modifier.amount

	return total


func get_matching_effect_blocks(
	timing_id: StringName,
	context_tags: PackedStringArray
) -> Array[KarmanyResonanceEffectBlockData]:
	var result: Array[KarmanyResonanceEffectBlockData] = []

	for block in effect_blocks:
		if block != null and block.matches(timing_id, context_tags):
			result.append(block)

	return result


func matching_effects_require_context(
	timing_id: StringName,
	context_tags: PackedStringArray
) -> bool:
	for block in get_matching_effect_blocks(timing_id, context_tags):
		if block.requires_effect_context():
			return true
	return false
