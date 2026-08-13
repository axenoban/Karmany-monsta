class_name KarmanyAeternaResolver
extends RefCounted


const AETERNA_ID: StringName = &"K-24"
const BASE_DEFENSE: int = 26
const REQUIRED_BOOK_LEVEL: int = 3
const ATTEMPT_FA_COST: int = 1
const VICTORY_LEGACY_POINTS: int = 8
const SPECIAL_ACTION_COST: int = 1

const ACTION_ID_COMBAT: StringName = &"combat_aeterna"
const ACTION_ID_SYNC: StringName = &"aeterna_sync"
const ACTION_ID_POST_DEFEAT_EK: StringName = &"interact_aeterna_post_defeat"

const PREPARATION_GAIN_FA: int = 0
const PREPARATION_RESONANCES: int = 1


static func get_minimum_round(map_format: int) -> int:
	if map_format == KarmanyLegacyModeConfig.MapFormat.MAP_41:
		return 8
	return 6


static func can_attempt(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> bool:
	return _validate_attempt(player, context).status == KarmanyAeternaResult.Status.RESOLVED


static func resolve_combat(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var validation := _validate_attempt(player, context)
	if validation.status != KarmanyAeternaResult.Status.RESOLVED:
		return validation

	if context.instinct_roll < 1 or context.instinct_roll > 6:
		return _error(
			KarmanyAeternaResult.Status.INVALID_REQUEST,
			"Aeterna requiere un resultado valido del Dado de Instinto."
		)
	if context.risk_roll != 0:
		if not context.risk_authorized or context.risk_roll < 1 or context.risk_roll > 6:
			return _error(
				KarmanyAeternaResult.Status.INVALID_REQUEST,
				"Dado de Riesgo invalido o no autorizado para este intento."
			)

	var action_consumed := false
	if context.action_cost > 0:
		if not context.turn_manager.spend_action_for(ACTION_ID_COMBAT, context.action_cost):
			return _error(
				KarmanyAeternaResult.Status.ACTION_NOT_AVAILABLE,
				"No se pudo consumir la accion de Combatir contra Aeterna."
			)
		action_consumed = true

	if not player.spend_resource(KarmanyEffectData.ResourceType.FA, ATTEMPT_FA_COST):
		return _error(
			KarmanyAeternaResult.Status.FA_REQUIRED,
			"No se pudo pagar el FA del intento."
		)

	var active := player.get_active_karmany()
	var request := KarmanyCombatRequest.new()
	request.attacker_player_id = player.player_id
	request.attacker_karmany = active.karmany_data
	request.target_id = AETERNA_ID
	request.target_type = KarmanyCombatRequest.TargetType.LEGENDARY
	request.base_defense = BASE_DEFENSE
	request.uses_instinct = true
	request.instinct_roll = context.instinct_roll
	request.modifiers = context.modifiers
	request.risk_authorized = context.risk_authorized
	request.risk_roll = context.risk_roll

	var combat := KarmanyCombatResolver.resolve(request)
	var result := KarmanyAeternaResult.new()
	result.action_consumed = action_consumed
	result.fa_spent = ATTEMPT_FA_COST
	result.combat_result = combat

	if combat == null or not combat.is_resolved():
		result.status = KarmanyAeternaResult.Status.INVALID_REQUEST
		result.message = "El CombatResolver no pudo resolver el intento contra Aeterna."
		return result

	if combat.is_victory():
		var award := context.legacy_points_controller.award_points(
			player.player_id,
			KarmanyLegacyPointsEntry.SourceType.AETERNA,
			AETERNA_ID,
			VICTORY_LEGACY_POINTS,
			context.turn_manager.current_round,
			&"aeterna:defeated",
			"Aeterna Draconis derrotada."
		)
		if award == null or not award.was_applied():
			result.status = KarmanyAeternaResult.Status.INVALID_REQUEST
			result.message = "Aeterna fue derrotada, pero no pudieron registrarse sus PL."
			return result
		if not context.aeterna_state.mark_defeated(
			player.player_id,
			context.turn_manager.current_round
		):
			result.status = KarmanyAeternaResult.Status.INVALID_REQUEST
			result.message = "No pudo registrarse el estado global de Aeterna derrotada."
			return result

		result.legacy_award_result = award
		result.status = KarmanyAeternaResult.Status.RESOLVED
		result.outcome = KarmanyAeternaResult.Outcome.COMBAT_VICTORY
		result.reward_choice_required = true
		result.message = "Aeterna derrotada: 8 PL registrados y recompensa final pendiente de eleccion."
		return result

	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.COMBAT_DEFEAT
	result.basic_resources_discard_pending = 2
	result.retreat_required = true
	if player.resonance_hand.get_count() > player.resonance_hand.get_pending_discard_count():
		if player.resonance_hand.request_discard(1):
			result.resonance_discard_pending = 1
	result.message = "Derrota contra Aeterna: FA perdido; descartes y retroceso pendientes."
	return result


static func resolve_on_explore_without_requirements(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if context.aeterna_state.defeated or _meets_attempt_requirements(player, context):
		return _error(
			KarmanyAeternaResult.Status.REWARD_NOT_AVAILABLE,
			"El fallback Al explorar solo corresponde si aun no puedes enfrentar a Aeterna."
		)
	return _draw_and_request_discard(
		player,
		context,
		2,
		1,
		KarmanyAeternaResult.Outcome.SANCTUARY_EXPLORE_FALLBACK,
		"Al explorar L-01 sin requisitos: roba 2 Resonancias y descarta 1."
	)


static func resolve_on_explore_preparation(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if not _meets_attempt_requirements(player, context):
		return _error(
			KarmanyAeternaResult.Status.REWARD_NOT_AVAILABLE,
			"La preparacion Al explorar de L-01 requiere poder enfrentar a Aeterna."
		)
	return _draw_and_request_discard(
		player,
		context,
		3,
		1,
		KarmanyAeternaResult.Outcome.SANCTUARY_EXPLORE_PREPARATION,
		"Preparacion Al explorar L-01: roba 3 Resonancias y descarta 1."
	)


static func resolve_sanctuary_entry_bonus_after_attunement(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if not context.aeterna_state.has_used_sanctuary_attunement(player.player_id):
		return _error(
			KarmanyAeternaResult.Status.ATTUNEMENT_NOT_AVAILABLE,
			"Si Sintonia aun no fue usada, reemplaza esta Bonificacion de entrada."
		)
	return _draw_and_request_discard(
		player,
		context,
		1,
		1,
		KarmanyAeternaResult.Outcome.SANCTUARY_ENTRY_BONUS,
		"Bonificacion de entrada L-01: roba 1 Resonancia y descarta 1."
	)


static func resolve_sanctuary_attunement(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext,
	preparation_choice: int
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if context.aeterna_state.defeated:
		return _error(
			KarmanyAeternaResult.Status.ATTUNEMENT_NOT_AVAILABLE,
			"Sintonia del Santuario no se activa despues de derrotar a Aeterna."
		)
	if context.aeterna_state.has_used_sanctuary_attunement(player.player_id):
		return _error(
			KarmanyAeternaResult.Status.ALREADY_USED,
			"Este jugador ya uso Sintonia del Santuario."
		)
	if _meets_attempt_requirements(player, context):
		return _error(
			KarmanyAeternaResult.Status.ATTUNEMENT_NOT_AVAILABLE,
			"Sintonia del Santuario solo se ofrece al llegar sin requisitos para enfrentar a Aeterna."
		)

	var result := KarmanyAeternaResult.new()
	if preparation_choice == PREPARATION_GAIN_FA:
		if not player.gain_resource(KarmanyEffectData.ResourceType.FA, 1):
			return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No se pudo otorgar 1 FA.")
	elif preparation_choice == PREPARATION_RESONANCES:
		result = _draw_and_request_discard(
			player,
			context,
			3,
			2,
			KarmanyAeternaResult.Outcome.SANCTUARY_ATTUNEMENT,
			"Sintonia del Santuario: roba 3 Resonancias y conserva 1."
		)
		if not result.is_resolved():
			return result
	else:
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "Eleccion de Sintonia invalida.")

	if not context.aeterna_state.mark_sanctuary_attunement_used(player.player_id):
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No se pudo registrar Sintonia del Santuario.")

	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.SANCTUARY_ATTUNEMENT
	result.message = "Sintonia del Santuario resuelta sin gastar accion ni otorgar PL."
	return result


static func resolve_aeterna_sync(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if context.aeterna_state.defeated:
		return _error(KarmanyAeternaResult.Status.ALREADY_DEFEATED, "Aeterna ya fue derrotada.")
	if context.aeterna_state.has_used_aeterna_sync(player.player_id):
		return _error(KarmanyAeternaResult.Status.ALREADY_USED, "Este jugador ya uso Sintonizar con Aeterna.")
	if _available_resonances(context.resonance_deck) < 3:
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No hay 3 Resonancias disponibles para Sintonizar.")
	if not context.turn_manager.can_spend_action(SPECIAL_ACTION_COST):
		return _error(KarmanyAeternaResult.Status.ACTION_NOT_AVAILABLE, "No quedan acciones para Sintonizar.")
	if not context.turn_manager.spend_action_for(ACTION_ID_SYNC, SPECIAL_ACTION_COST):
		return _error(KarmanyAeternaResult.Status.ACTION_NOT_AVAILABLE, "No se pudo consumir la accion de Sintonizar.")

	var result := _draw_and_request_discard(
		player,
		context,
		3,
		2,
		KarmanyAeternaResult.Outcome.AETERNA_SYNC,
		"Sintonizar con Aeterna: roba 3 y conserva 1."
	)
	result.action_consumed = true
	if not result.is_resolved():
		return result
	if not context.aeterna_state.mark_aeterna_sync_used(player.player_id):
		result.status = KarmanyAeternaResult.Status.INVALID_REQUEST
		result.message = "No se pudo registrar el uso unico de Sintonizar."
		return result
	return result


static func resolve_victory_resonance_reward(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext,
	victory_result: KarmanyAeternaResult
) -> bool:
	if player == null or context == null or victory_result == null:
		return false
	if not victory_result.is_victory() or not victory_result.reward_choice_required:
		return false
	if victory_result.reward_resolved or _available_resonances(context.resonance_deck) < 3:
		return false

	var drawn := context.resonance_deck.draw_to_hand(player.resonance_hand, 3)
	if drawn != 3 or not player.resonance_hand.request_discard(1):
		return false

	victory_result.reward_choice = KarmanyAeternaResult.RewardChoice.RESONANCES
	victory_result.reward_resolved = true
	victory_result.reward_choice_required = false
	victory_result.resonance_cards_drawn = 3
	victory_result.resonance_discard_pending = 1
	return true


static func resolve_victory_equipment_reward(
	player: KarmanyPlayerState,
	victory_result: KarmanyAeternaResult,
	equipment: KarmanyEquipmentData,
	discard_equipment_id: StringName = &"",
	equipment_market: KarmanyEquipmentMarket = null
) -> bool:
	if player == null or victory_result == null or equipment == null:
		return false
	if not victory_result.is_victory() or not victory_result.reward_choice_required:
		return false
	if victory_result.reward_resolved:
		return false
	if not equipment.is_valid_definition() or equipment.rarity != KarmanyEquipmentData.Rarity.ANCESTRAL:
		return false
	if player.equipment_inventory.has_equipment_id(equipment.equipment_id):
		return false

	var replaced: KarmanyEquipmentData = null
	if player.equipment_inventory.is_full():
		if discard_equipment_id == &"" or equipment_market == null:
			return false
		var current := player.equipment_inventory.get_equipment_by_id(discard_equipment_id)
		if current == null or not equipment_market.can_accept_discard(current):
			return false
		replaced = player.replace_equipment(discard_equipment_id, equipment)
		if replaced == null or not equipment_market.add_to_discard(replaced):
			return false
	else:
		if not player.add_equipment(equipment):
			return false

	victory_result.reward_choice = KarmanyAeternaResult.RewardChoice.ANCESTRAL_EQUIPMENT
	victory_result.reward_resolved = true
	victory_result.reward_choice_required = false
	victory_result.ancestral_equipment_id = equipment.equipment_id
	if replaced != null:
		victory_result.replaced_equipment_id = replaced.equipment_id
	return true


static func collect_post_defeat_ek(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if not context.aeterna_state.defeated:
		return _error(KarmanyAeternaResult.Status.REWARD_NOT_AVAILABLE, "Aeterna aun no ha sido derrotada.")
	var round_number := context.turn_manager.current_round
	if not context.aeterna_state.can_collect_post_defeat_ek(player.player_id, round_number):
		return _error(KarmanyAeternaResult.Status.ALREADY_USED, "Ya recolectaste los 2 EK del Santuario esta ronda.")
	if not context.turn_manager.can_spend_action(SPECIAL_ACTION_COST):
		return _error(KarmanyAeternaResult.Status.ACTION_NOT_AVAILABLE, "No quedan acciones para Interactuar con el Santuario.")
	if not context.turn_manager.spend_action_for(ACTION_ID_POST_DEFEAT_EK, SPECIAL_ACTION_COST):
		return _error(KarmanyAeternaResult.Status.ACTION_NOT_AVAILABLE, "No se pudo consumir la accion del Santuario.")
	if not player.gain_resource(KarmanyEffectData.ResourceType.EK, 2):
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No se pudieron otorgar los 2 EK.")
	if not context.aeterna_state.mark_post_defeat_ek_collected(player.player_id, round_number):
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No se pudo registrar el limite por ronda del Santuario.")

	var result := KarmanyAeternaResult.new()
	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.POST_DEFEAT_EK
	result.action_consumed = true
	result.post_defeat_ek_gained = 2
	result.message = "Santuario posterior a Aeterna: +2 EK."
	return result


static func _validate_attempt(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	var base_error := _validate_sanctuary_presence(player, context)
	if base_error != null:
		return base_error
	if context.aeterna_state.defeated:
		return _error(KarmanyAeternaResult.Status.ALREADY_DEFEATED, "Aeterna solo puede ser derrotada una vez por partida.")
	if context.turn_manager.current_round < get_minimum_round(context.map_format):
		return _error(KarmanyAeternaResult.Status.TOO_EARLY, "Aeterna aun no puede ser desafiada en esta ronda.")
	if context.book_level < REQUIRED_BOOK_LEVEL:
		return _error(KarmanyAeternaResult.Status.BOOK_LEVEL_REQUIRED, "Se requiere Libro III.")
	if not player.has_active_karmany():
		return _error(KarmanyAeternaResult.Status.NO_ACTIVE_KARMANY, "Se requiere un Karmany activo.")
	if not player.can_spend_resource(KarmanyEffectData.ResourceType.FA, ATTEMPT_FA_COST):
		return _error(KarmanyAeternaResult.Status.FA_REQUIRED, "Se requiere 1 FA disponible para el intento.")
	if context.action_cost > 0 and not context.turn_manager.can_spend_action(context.action_cost):
		return _error(KarmanyAeternaResult.Status.ACTION_NOT_AVAILABLE, "No quedan acciones para Combatir.")
	var ok := KarmanyAeternaResult.new()
	ok.status = KarmanyAeternaResult.Status.RESOLVED
	return ok


static func _validate_sanctuary_presence(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> KarmanyAeternaResult:
	if player == null or context == null or not context.is_valid():
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "Contexto de Aeterna invalido.")
	if not context.turn_manager.is_running or context.turn_manager.get_active_player() != player:
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "Solo el jugador activo puede usar el Santuario.")
	if not context.legacy_points_controller.has_player(player.player_id):
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "Jugador no registrado en el controlador de PL.")
	if not context.is_player_at_sanctuary(player):
		return _error(KarmanyAeternaResult.Status.NOT_AT_SANCTUARY, "El jugador debe estar en el Santuario de Aeterna.")
	return null


static func _meets_attempt_requirements(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext
) -> bool:
	if context.aeterna_state.defeated:
		return false
	if context.turn_manager.current_round < get_minimum_round(context.map_format):
		return false
	if context.book_level < REQUIRED_BOOK_LEVEL:
		return false
	if not player.has_active_karmany():
		return false
	return player.can_spend_resource(KarmanyEffectData.ResourceType.FA, ATTEMPT_FA_COST)


static func _draw_and_request_discard(
	player: KarmanyPlayerState,
	context: KarmanyAeternaContext,
	draw_amount: int,
	discard_amount: int,
	outcome_value: int,
	message: String
) -> KarmanyAeternaResult:
	if draw_amount <= 0 or discard_amount <= 0 or discard_amount > draw_amount:
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "Parametros de Resonancia invalidos.")
	if _available_resonances(context.resonance_deck) < draw_amount:
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No hay suficientes Resonancias disponibles.")

	var result := KarmanyAeternaResult.new()
	result.resonance_cards_drawn = context.resonance_deck.draw_to_hand(player.resonance_hand, draw_amount)
	if result.resonance_cards_drawn != draw_amount:
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No se pudieron robar todas las Resonancias requeridas.")
	if not player.resonance_hand.request_discard(discard_amount):
		return _error(KarmanyAeternaResult.Status.INVALID_REQUEST, "No se pudo registrar el descarte elegido de Resonancias.")

	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = outcome_value
	result.resonance_discard_pending = discard_amount
	result.message = message
	return result


static func _available_resonances(deck: KarmanyResonanceDeck) -> int:
	if deck == null:
		return 0
	return deck.get_draw_count() + deck.get_discard_count()


static func _error(status_value: int, message: String) -> KarmanyAeternaResult:
	var result := KarmanyAeternaResult.new()
	result.status = status_value
	result.message = message
	return result
