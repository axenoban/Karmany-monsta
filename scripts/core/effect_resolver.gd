class_name KarmanyEffectResolver
extends RefCounted


static func apply_effect(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState
) -> void:

	if effect == null:
		return

	match effect.effect_type:

		KarmanyEffectData.EffectType.ADD_RESOURCE:
			player.add_resource(
				effect.resource_type,
				effect.amount
			)

		KarmanyEffectData.EffectType.NONE:
			pass
