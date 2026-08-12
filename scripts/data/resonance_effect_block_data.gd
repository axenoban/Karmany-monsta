class_name KarmanyResonanceEffectBlockData
extends Resource


@export var timing_id: StringName = &"on_play"
@export var required_context_tags: PackedStringArray = PackedStringArray()
@export var effects: Array[KarmanyEffectData] = []
@export_multiline var description: String = ""


func is_valid_definition() -> bool:
	if timing_id == &"":
		return false
	if effects.is_empty():
		return false

	for effect in effects:
		if effect == null:
			return false

	return true


func matches(
	p_timing_id: StringName,
	context_tags: PackedStringArray
) -> bool:
	if timing_id != p_timing_id:
		return false

	for required_tag in required_context_tags:
		if not context_tags.has(required_tag):
			return false

	return true


func requires_effect_context() -> bool:
	for effect in effects:
		if effect == null:
			continue
		match effect.effect_type:
			KarmanyEffectData.EffectType.DRAW_CARDS:
				return true
			KarmanyEffectData.EffectType.DISCARD_CARDS:
				return true
			KarmanyEffectData.EffectType.MODIFY_STATE:
				return true
			KarmanyEffectData.EffectType.ACTIVATE_CONDITION:
				return true
			KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER:
				return true

	return false
