class_name KarmanyTileInteractionOptionData
extends Resource


@export_group("Identity")
@export var option_id: StringName = &""
@export var label: String = ""

@export_group("Executable Effects")
@export var effects: Array[KarmanyEffectData] = []


func is_valid_definition() -> bool:
	if option_id == &"" or label.strip_edges().is_empty():
		return false
	if effects.is_empty():
		return false
	for effect in effects:
		if effect == null or effect.effect_type == KarmanyEffectData.EffectType.NONE:
			return false
	return true
