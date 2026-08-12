class_name KarmanyPlayerState
extends RefCounted


var mn: int = 0
var mr: int = 0
var ek: int = 0
var fa: int = 0


func setup_new_game() -> void:
	mn = 2
	mr = 1
	ek = 1
	fa = 0


func add_resource(
	resource_type: KarmanyEffectData.ResourceType,
	amount: int
) -> void:

	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			mn += amount

		KarmanyEffectData.ResourceType.MR:
			mr += amount

		KarmanyEffectData.ResourceType.EK:
			ek += amount

		KarmanyEffectData.ResourceType.FA:
			fa += amount


func get_resource(
	resource_type: KarmanyEffectData.ResourceType
) -> int:

	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			return mn

		KarmanyEffectData.ResourceType.MR:
			return mr

		KarmanyEffectData.ResourceType.EK:
			return ek

		KarmanyEffectData.ResourceType.FA:
			return fa

	return 0
