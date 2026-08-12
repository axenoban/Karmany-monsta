class_name KarmanyEffectData
extends Resource


enum EffectType {
	NONE,
	ADD_RESOURCE
}


enum ResourceType {
	MN,
	MR,
	EK,
	FA
}


@export_group("Effect")

@export var effect_type: EffectType = EffectType.NONE
@export var resource_type: ResourceType = ResourceType.MN
@export var amount: int = 0


@export_group("Presentation")

@export_multiline var description: String = ""
