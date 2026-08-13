class_name KarmanyResonanceResolver
extends RefCounted


const TIMING_ON_PLAY: StringName = &"on_play"
const TRIGGER_RESONANCE_PLAYED: String = "resonance_played"
const TRIGGER_ZERO_RESONANCE_PLAYED: String = "zero_resonance_played"


static func play_from_hand(
	player: KarmanyPlayerState,
	resonance_id: StringName,
	deck: KarmanyResonanceDeck,
	context: KarmanyResonanceUseContext
) -> KarmanyResonancePlayResult:
	if player == null or deck == null or context == null:
		return _result(
			KarmanyResonancePlayResult.Status.INVALID_REQUEST,
			"Jugador, mazo y contexto son obligatorios."
		)
	if not context.is_valid():
		return _result(
			KarmanyResonancePlayResult.Status.INVALID_REQUEST,
			"Contexto de uso de Resonancia invalido."
		)

	var card := player.resonance_hand.get_card_by_id(resonance_id)
	if card == null:
		return _result(
			KarmanyResonancePlayResult.Status.CARD_NOT_IN_HAND,
			"La Resonancia no esta en la mano del jugador."
		)
	if not card.can_use_in(context.window_id):
		return _result(
			KarmanyResonancePlayResult.Status.WINDOW_NOT_ALLOWED,
			"La Resonancia no puede jugarse en esta ventana."
		)
	# Algunas cartas comparten la ventana tecnica de combate, pero su texto
	# restringe el contexto. R-05, por ejemplo, es exclusivamente PvP.
	if card.tags.has("pvp") and not context.context_tags.has("pvp"):
		return _result(
			KarmanyResonancePlayResult.Status.WINDOW_NOT_ALLOWED,
			"Esta Resonancia solo puede jugarse en un PvP legal."
		)

	if context.is_combat_window():
		if not context.usage_tracker.can_use_in_combat(
			player.player_id,
			context.combat_id
		):
			return _result(
				KarmanyResonancePlayResult.Status.COMBAT_LIMIT_REACHED,
				"Maximo 1 Resonancia por jugador por combate."
			)

	if not _can_resolve_matching_effects(
		card,
		TIMING_ON_PLAY,
		context.context_tags,
		context.effect_context
	):
		return _result(
			KarmanyResonancePlayResult.Status.EFFECT_CONTEXT_REQUIRED,
			"Faltan adaptadores para resolver el efecto inmediato de la Resonancia."
		)

	var power_bonus: int = card.get_power_bonus(
		context.context_tags
	)
	if power_bonus != 0 and context.combat_modifiers == null:
		return _result(
			KarmanyResonancePlayResult.Status.INVALID_REQUEST,
			"Una Resonancia con Poder requiere CombatPowerModifiers."
		)

	var removed := player.resonance_hand.remove_card_by_id(
		resonance_id
	)
	if removed != card:
		return _result(
			KarmanyResonancePlayResult.Status.HAND_ERROR,
			"No se pudo retirar la Resonancia de la mano."
		)

	if context.is_combat_window():
		if not context.usage_tracker.register_combat_play(
			player.player_id,
			context.combat_id,
			card
		):
			player.resonance_hand.add_card(card)
			return _result(
				KarmanyResonancePlayResult.Status.TRACKER_ERROR,
				"No se pudo registrar la Resonancia en el combate."
			)

	if power_bonus != 0:
		context.combat_modifiers.resonance_power += power_bonus

	var effect_results := resolve_effects(
		card,
		player,
		TIMING_ON_PLAY,
		context.context_tags,
		context.effect_context
	)

	var result := _result(
		KarmanyResonancePlayResult.Status.SUCCESS,
		"Resonancia jugada correctamente."
	)
	result.card = card
	result.power_applied = power_bonus
	result.effect_results = effect_results
	result.trigger_ids = PackedStringArray([
		TRIGGER_RESONANCE_PLAYED
	])
	if card.printed_power == 0:
		result.trigger_ids.append(
			TRIGGER_ZERO_RESONANCE_PLAYED
		)

	if context.is_combat_window():
		result.held_until_combat_end = true
	else:
		result.discarded_immediately = deck.discard_card(card)

	return result


static func resolve_effects(
	card: KarmanyResonanceData,
	player: KarmanyPlayerState,
	timing_id: StringName,
	context_tags: PackedStringArray,
	effect_context: KarmanyEffectContext = null
) -> Array[KarmanyEffectResult]:
	var results: Array[KarmanyEffectResult] = []
	if card == null or player == null or timing_id == &"":
		return results

	for block in card.get_matching_effect_blocks(
		timing_id,
		context_tags
	):
		var block_results := KarmanyEffectResolver.apply_effects(
			block.effects,
			player,
			effect_context
		)
		for effect_result in block_results:
			results.append(effect_result)

	return results


static func finish_combat(
	combat_id: StringName,
	usage_tracker: KarmanyResonanceUsageTracker,
	deck: KarmanyResonanceDeck
) -> int:
	if usage_tracker == null or deck == null:
		return 0
	return usage_tracker.finish_combat(
		combat_id,
		deck
	)


static func _can_resolve_matching_effects(
	card: KarmanyResonanceData,
	timing_id: StringName,
	context_tags: PackedStringArray,
	effect_context: KarmanyEffectContext
) -> bool:
	for block in card.get_matching_effect_blocks(
		timing_id,
		context_tags
	):
		for effect in block.effects:
			if not _has_required_handler(
				effect,
				effect_context
			):
				return false
	return true


static func _has_required_handler(
	effect: KarmanyEffectData,
	context: KarmanyEffectContext
) -> bool:
	if effect == null:
		return false

	match effect.effect_type:
		KarmanyEffectData.EffectType.DRAW_CARDS:
			return context != null and context.has_draw_cards_handler()
		KarmanyEffectData.EffectType.DISCARD_CARDS:
			return context != null and context.has_discard_cards_handler()
		KarmanyEffectData.EffectType.MODIFY_STATE:
			return context != null and context.has_modify_state_handler()
		KarmanyEffectData.EffectType.ACTIVATE_CONDITION:
			return context != null and context.has_activate_condition_handler()
		KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER:
			return context != null and context.has_trigger_encounter_handler()

	return true


static func _result(
	status_value: int,
	text: String
) -> KarmanyResonancePlayResult:
	var result := KarmanyResonancePlayResult.new()
	result.status = status_value
	result.message = text
	return result
