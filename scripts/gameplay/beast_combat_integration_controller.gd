class_name KarmanyBeastCombatIntegrationController
extends RefCounted


static func fight_with_existing_systems(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState,
	target_coord: Vector2i,
	deck: KarmanyBeastDeck,
	context: KarmanyBeastCombatContext,
	resonance_id: StringName = &"",
	book_state: KarmanyBookProgressState = null
) -> KarmanyBeastCombatResult:
	if coordinator == null or player == null or deck == null or context == null:
		return KarmanyBeastCombatResult.new()
	if coordinator.board_state == null or coordinator.turn_manager == null:
		return KarmanyBeastCombatResult.new()
	if context.combat_modifiers == null:
		context.combat_modifiers = KarmanyCombatPowerModifiers.new()

	var beast_state: KarmanyBeastRuntimeState = coordinator.board_state.get_beast(target_coord)
	if beast_state == null or beast_state.beast_data == null:
		return KarmanyBeastCombatResult.new()

	# Libro III: +2 Poder contra Bestias Complejas. La bonificacion se
	# incorpora al contenedor de modificadores ya usado por CombatResolver.
	if (
		book_state != null
		and book_state.level >= 3
		and beast_state.beast_data.tier == KarmanyBeastData.Tier.COMPLEX
	):
		context.combat_modifiers.book_power = maxi(
			context.combat_modifiers.book_power,
			2
		)

	var combat_id := StringName(
		"beast:%s:r%d:%d" % [
			String(player.player_id),
			coordinator.turn_manager.current_round,
			context.get_instance_id()
		]
	)
	var played_card: KarmanyResonanceData = null

	if resonance_id != &"":
		played_card = player.resonance_hand.get_card_by_id(resonance_id)
		if played_card == null or not played_card.can_use_in(KarmanyResonanceUseContext.WINDOW_COMBAT):
			return KarmanyBeastCombatResult.new()

		var use_context := KarmanyResonanceUseContext.new()
		use_context.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
		use_context.context_tags = PackedStringArray([
			"combat",
			"pve",
			"beast"
		])
		if beast_state.beast_data.tier == KarmanyBeastData.Tier.COMPLEX:
			use_context.context_tags.append("complex")
		use_context.combat_id = combat_id
		use_context.combat_modifiers = context.combat_modifiers
		use_context.effect_context = coordinator.effect_context
		use_context.usage_tracker = coordinator.resonance_usage_tracker

		var play_result := KarmanyResonanceResolver.play_from_hand(
			player,
			resonance_id,
			coordinator.resonance_deck,
			use_context
		)
		if not play_result.is_success():
			return KarmanyBeastCombatResult.new()
		played_card = play_result.card
		if played_card != null and played_card.tags.has("risk_authorization"):
			context.risk_authorized = true

	var result: KarmanyBeastCombatResult = coordinator.fight_beast(
		player,
		target_coord,
		deck,
		context
	)

	if played_card != null:
		var after_tags := PackedStringArray([
			"combat",
			"pve",
			"beast"
		])
		if beast_state.beast_data.tier == KarmanyBeastData.Tier.COMPLEX:
			after_tags.append("complex")
		if result.is_victory():
			after_tags.append("combat_won")
		elif result.combat_result != null and result.combat_result.is_defeat():
			after_tags.append("combat_lost")

		KarmanyResonanceResolver.resolve_effects(
			played_card,
			player,
			&"after_combat",
			after_tags,
			coordinator.effect_context
		)
		KarmanyResonanceResolver.finish_combat(
			combat_id,
			coordinator.resonance_usage_tracker,
			coordinator.resonance_deck
		)

	return result
