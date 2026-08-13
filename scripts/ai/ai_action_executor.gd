class_name KarmanyAiActionExecutor
extends RefCounted


static func execute(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> KarmanyAiExecutionResult:
	var result := KarmanyAiExecutionResult.new()
	result.candidate = candidate

	if coordinator == null or player == null or candidate == null:
		result.message = "Coordinador, jugador y accion IA son obligatorios."
		return result
	if not coordinator.is_configured() or coordinator.is_finished:
		result.message = "La partida no esta disponible para IA."
		return result
	if coordinator.turn_manager == null or coordinator.turn_manager.get_active_player() != player:
		result.message = "La IA solo puede actuar durante su propio turno."
		return result
	if not candidate.is_valid():
		result.message = "La accion candidata no es valida."
		return result

	result.actions_before = coordinator.turn_manager.actions_remaining
	var raw: Variant = null
	var success: bool = false

	match candidate.action_type:
		KarmanyAiActionCandidate.ActionType.MOVE:
			success = coordinator.move_player(player, candidate.target_coord)
			raw = success

		KarmanyAiActionCandidate.ActionType.EXPLORE:
			success = coordinator.explore_player(player, candidate.target_coord)
			raw = success

		KarmanyAiActionCandidate.ActionType.INTERACT:
			var interaction := coordinator.interact_effect_option(player, candidate.option_index)
			raw = interaction
			success = interaction != null and interaction.is_success()

		KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK:
			var book_result := coordinator.improve_book(player)
			raw = book_result
			success = book_result != null and book_result.is_success()

		KarmanyAiActionCandidate.ActionType.BOND_PAYMENT:
			var bond_result := coordinator.bond_visible_by_payment(player)
			raw = bond_result
			success = bond_result != null and bond_result.is_success()

		KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT:
			var craft_context_value: Variant = candidate.payload.get("craft_context", null)
			if craft_context_value is KarmanyEquipmentCraftContext:
				var visible_index: int = int(candidate.payload.get("visible_index", -1))
				var discard_id: StringName = StringName(candidate.payload.get("discard_equipment_id", ""))
				var craft_result := coordinator.craft_from_market(
					player,
					visible_index,
					craft_context_value as KarmanyEquipmentCraftContext,
					discard_id
				)
				raw = craft_result
				success = craft_result != null and craft_result.is_success()

		KarmanyAiActionCandidate.ActionType.FORGE:
			var first_resource: int = int(candidate.payload.get("first_resource", -1))
			var second_resource: int = int(candidate.payload.get("second_resource", -1))
			var forge_result := coordinator.forge_common_to_fa(
				player,
				first_resource,
				second_resource
			)
			raw = forge_result
			success = forge_result != null and forge_result.is_success()

		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
			var deck_value: Variant = candidate.payload.get("deck", null)
			var context_value: Variant = candidate.payload.get("combat_context", null)
			if deck_value is KarmanyBeastDeck and context_value is KarmanyBeastCombatContext:
				var beast_resonance_id: StringName = StringName(candidate.payload.get("resonance_id", ""))
				var book_value: Variant = candidate.payload.get("book_state", null)
				var beast_result: KarmanyBeastCombatResult
				if beast_resonance_id != &"" or book_value is KarmanyBookProgressState:
					var book_state: KarmanyBookProgressState = null
					if book_value is KarmanyBookProgressState:
						book_state = book_value as KarmanyBookProgressState
					beast_result = KarmanyBeastCombatIntegrationController.fight_with_existing_systems(
						coordinator,
						player,
						candidate.target_coord,
						deck_value as KarmanyBeastDeck,
						context_value as KarmanyBeastCombatContext,
						beast_resonance_id,
						book_state
					)
				else:
					beast_result = coordinator.fight_beast(
						player,
						candidate.target_coord,
						deck_value as KarmanyBeastDeck,
						context_value as KarmanyBeastCombatContext
					)
				raw = beast_result
				success = beast_result != null and beast_result.status == KarmanyBeastCombatResult.Status.RESOLVED

		KarmanyAiActionCandidate.ActionType.PVP:
			var defender_value: Variant = candidate.payload.get("defender", null)
			var authorization_value: Variant = candidate.payload.get("authorization", null)
			if defender_value is KarmanyPlayerState and authorization_value is KarmanyPvpAuthorizationContext:
				var attacker_resonance: StringName = StringName(candidate.payload.get("attacker_resonance_id", ""))
				var defender_resonance: StringName = StringName(candidate.payload.get("defender_resonance_id", ""))
				var trainer_bonus: int = int(candidate.payload.get("attacker_trainer_power_bonus", 0))
				var pvp_result := coordinator.resolve_pvp(
					player,
					defender_value as KarmanyPlayerState,
					authorization_value as KarmanyPvpAuthorizationContext,
					attacker_resonance,
					defender_resonance,
					trainer_bonus
				)
				raw = pvp_result
				success = pvp_result != null and pvp_result.is_resolved()

		KarmanyAiActionCandidate.ActionType.AETERNA:
			var aeterna_resonance_id: StringName = StringName(candidate.payload.get("resonance_id", ""))
			var instinct_roll: int = int(candidate.payload.get("instinct_roll", 0))
			var risk_roll: int = int(candidate.payload.get("risk_roll", 0))
			var aeterna_result := coordinator.resolve_aeterna_combat(
				player,
				aeterna_resonance_id,
				instinct_roll,
				risk_roll
			)
			raw = aeterna_result
			success = aeterna_result != null and aeterna_result.is_resolved()

	result.raw_result = raw
	result.success = success
	result.actions_after = coordinator.turn_manager.actions_remaining
	if success:
		result.message = "%s ejecutada por IA." % candidate.debug_label
	else:
		result.message = "%s fue rechazada por las reglas normales." % candidate.debug_label
	return result
