class_name KarmanyEffectResolver
extends RefCounted


static func apply_effect(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState,
	context: KarmanyEffectContext = null
) -> KarmanyEffectResult:
	if effect == null:
		return _result(
			KarmanyEffectResult.Status.INVALID_EFFECT,
			null,
			0,
			"El efecto es nulo."
		)

	if player == null:
		return _result(
			KarmanyEffectResult.Status.INVALID_EFFECT,
			effect,
			0,
			"El jugador objetivo es nulo."
		)

	match effect.effect_type:
		KarmanyEffectData.EffectType.NONE:
			return _result(
				KarmanyEffectResult.Status.NO_OP,
				effect,
				0,
				"Efecto sin operacion."
			)

		KarmanyEffectData.EffectType.ADD_RESOURCE:
			return _apply_add_resource(effect, player)

		KarmanyEffectData.EffectType.REMOVE_RESOURCE:
			return _apply_remove_resource(effect, player)

		KarmanyEffectData.EffectType.DRAW_CARDS:
			return _apply_draw_cards(effect, player, context)

		KarmanyEffectData.EffectType.MODIFY_STATE:
			return _apply_modify_state(effect, player, context)

		KarmanyEffectData.EffectType.ACTIVATE_CONDITION:
			return _apply_activate_condition(effect, player, context)

		KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER:
			return _apply_trigger_encounter(effect, player, context)

	return _result(
		KarmanyEffectResult.Status.INVALID_EFFECT,
		effect,
		0,
		"Tipo de efecto no reconocido."
	)


static func apply_effects(
	effects: Array[KarmanyEffectData],
	player: KarmanyPlayerState,
	context: KarmanyEffectContext = null
) -> Array[KarmanyEffectResult]:
	var results: Array[KarmanyEffectResult] = []

	for effect in effects:
		results.append(
			apply_effect(
				effect,
				player,
				context
			)
		)

	return results


static func count_applied(
	results: Array[KarmanyEffectResult]
) -> int:
	var applied_count: int = 0

	for result in results:
		if result != null and result.was_applied():
			applied_count += 1

	return applied_count


static func _apply_add_resource(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState
) -> KarmanyEffectResult:
	if effect.amount <= 0:
		return _invalid_amount(effect)

	player.add_resource(
		effect.resource_type,
		effect.amount
	)

	return _result(
		KarmanyEffectResult.Status.APPLIED,
		effect,
		effect.amount,
		"Recurso obtenido."
	)


static func _apply_remove_resource(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState
) -> KarmanyEffectResult:
	if effect.amount <= 0:
		return _invalid_amount(effect)

	var current_amount: int = player.get_resource(
		effect.resource_type
	)
	var removed_amount: int = mini(
		current_amount,
		effect.amount
	)

	if removed_amount > 0:
		player.add_resource(
			effect.resource_type,
			-removed_amount
		)

	return _result(
		KarmanyEffectResult.Status.APPLIED,
		effect,
		removed_amount,
		"Recurso perdido."
	)


static func _apply_draw_cards(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState,
	context: KarmanyEffectContext
) -> KarmanyEffectResult:
	if effect.amount <= 0 or effect.card_source_id == &"":
		return _result(
			KarmanyEffectResult.Status.INVALID_EFFECT,
			effect,
			0,
			"DRAW_CARDS requiere cantidad positiva y card_source_id."
		)

	if context == null:
		return _missing_context(effect)

	if not context.has_draw_cards_handler():
		return _missing_handler(
			effect,
			"draw_cards_handler"
		)

	var callback_result: Variant = context.draw_cards_handler.call(
		effect.card_source_id,
		effect.amount,
		player
	)

	if not _callback_succeeded(callback_result):
		return _failed_handler(effect, "draw_cards_handler")

	return _result(
		KarmanyEffectResult.Status.APPLIED,
		effect,
		effect.amount,
		"Robo de cartas delegado al contexto."
	)


static func _apply_modify_state(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState,
	context: KarmanyEffectContext
) -> KarmanyEffectResult:
	if effect.state_id == &"":
		return _result(
			KarmanyEffectResult.Status.INVALID_EFFECT,
			effect,
			0,
			"MODIFY_STATE requiere state_id."
		)

	if (
		effect.state_operation != KarmanyEffectData.StateOperation.SET
		and effect.amount <= 0
	):
		return _invalid_amount(effect)

	if context == null:
		return _missing_context(effect)

	if not context.has_modify_state_handler():
		return _missing_handler(
			effect,
			"modify_state_handler"
		)

	var callback_result: Variant = context.modify_state_handler.call(
		effect.state_id,
		effect.state_operation,
		effect.amount,
		player
	)

	if not _callback_succeeded(callback_result):
		return _failed_handler(effect, "modify_state_handler")

	return _result(
		KarmanyEffectResult.Status.APPLIED,
		effect,
		effect.amount,
		"Modificacion de estado delegada al contexto."
	)


static func _apply_activate_condition(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState,
	context: KarmanyEffectContext
) -> KarmanyEffectResult:
	if effect.condition_id == &"":
		return _result(
			KarmanyEffectResult.Status.INVALID_EFFECT,
			effect,
			0,
			"ACTIVATE_CONDITION requiere condition_id."
		)

	if context == null:
		return _missing_context(effect)

	if not context.has_activate_condition_handler():
		return _missing_handler(
			effect,
			"activate_condition_handler"
		)

	var callback_result: Variant = context.activate_condition_handler.call(
		effect.condition_id,
		player
	)

	if not _callback_succeeded(callback_result):
		return _failed_handler(effect, "activate_condition_handler")

	return _result(
		KarmanyEffectResult.Status.APPLIED,
		effect,
		1,
		"Condicion activada mediante el contexto."
	)


static func _apply_trigger_encounter(
	effect: KarmanyEffectData,
	player: KarmanyPlayerState,
	context: KarmanyEffectContext
) -> KarmanyEffectResult:
	if effect.encounter_id == &"":
		return _result(
			KarmanyEffectResult.Status.INVALID_EFFECT,
			effect,
			0,
			"TRIGGER_ENCOUNTER requiere encounter_id."
		)

	if context == null:
		return _missing_context(effect)

	if not context.has_trigger_encounter_handler():
		return _missing_handler(
			effect,
			"trigger_encounter_handler"
		)

	var callback_result: Variant = context.trigger_encounter_handler.call(
		effect.encounter_id,
		player
	)

	if not _callback_succeeded(callback_result):
		return _failed_handler(effect, "trigger_encounter_handler")

	return _result(
		KarmanyEffectResult.Status.APPLIED,
		effect,
		1,
		"Encuentro delegado al contexto."
	)


static func _callback_succeeded(value: Variant) -> bool:
	if value is bool:
		return bool(value)

	return true


static func _invalid_amount(
	effect: KarmanyEffectData
) -> KarmanyEffectResult:
	return _result(
		KarmanyEffectResult.Status.INVALID_EFFECT,
		effect,
		0,
		"El efecto requiere una cantidad positiva."
	)


static func _missing_context(
	effect: KarmanyEffectData
) -> KarmanyEffectResult:
	return _result(
		KarmanyEffectResult.Status.MISSING_CONTEXT,
		effect,
		0,
		"El efecto requiere KarmanyEffectContext."
	)


static func _missing_handler(
	effect: KarmanyEffectData,
	handler_name: String
) -> KarmanyEffectResult:
	return _result(
		KarmanyEffectResult.Status.MISSING_HANDLER,
		effect,
		0,
		"Falta el adaptador %s." % handler_name
	)


static func _failed_handler(
	effect: KarmanyEffectData,
	handler_name: String
) -> KarmanyEffectResult:
	return _result(
		KarmanyEffectResult.Status.FAILED,
		effect,
		0,
		"El adaptador %s rechazo el efecto." % handler_name
	)


static func _result(
	status: int,
	effect: KarmanyEffectData,
	amount_applied: int,
	message: String
) -> KarmanyEffectResult:
	return KarmanyEffectResult.new(
		status,
		effect,
		amount_applied,
		message
	)
