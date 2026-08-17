class_name KarmanyPvpResolver
extends RefCounted


const TIMING_AFTER_COMBAT: StringName = &"after_combat"
const TAG_COMBAT: String = "combat"
const TAG_PVP: String = "pvp"
const TAG_COMBAT_WON: String = "combat_won"
const TAG_COMBAT_LOST: String = "combat_lost"

const CONSEQUENCE_RISK_DISCARD_CARD: String = "risk_discard_1_card_after_combat"
const CONSEQUENCE_RISK_FILTER_RESONANCE: String = "risk_draw_1_resonance_discard_1_after_combat"
const CONSEQUENCE_RISK_WIN_REWARD: String = "risk_choose_1_pl_or_2_basic_resources_on_win"


static func resolve(
	attacker: KarmanyPlayerState,
	defender: KarmanyPlayerState,
	context: KarmanyPvpCombatContext
) -> KarmanyPvpCombatResult:
	var result := KarmanyPvpCombatResult.new()

	var validation := _validate_request(attacker, defender, context)
	if validation.status != KarmanyPvpCombatResult.Status.RESOLVED:
		result.status = validation.status
		result.message = validation.message
		return result

	var attacker_active := attacker.get_active_karmany()
	var defender_active := defender.get_active_karmany()

	result.combat_id = context.combat_id
	result.attacker_player_id = attacker.player_id
	result.defender_player_id = defender.player_id
	result.attacker_karmany_id = attacker_active.karmany_data.karmany_id
	result.defender_karmany_id = defender_active.karmany_data.karmany_id

	result.attacker_risk_adjustment = KarmanyCombatResolver.get_risk_power_adjustment(
		context.attacker_risk_roll
	)
	result.defender_risk_adjustment = KarmanyCombatResolver.get_risk_power_adjustment(
		context.defender_risk_roll
	)

	result.attacker_power = (
		attacker_active.karmany_data.power
		+ context.attacker_modifiers.get_total()
		+ result.attacker_risk_adjustment
	)
	var defender_karmany_bonus: int = KarmanyAbilityRuntimeService.get_pvp_defender_power_bonus(
		defender_active.karmany_data
	)
	result.defender_power = (
		defender_active.karmany_data.power
		+ context.defender_modifiers.get_total()
		+ defender_karmany_bonus
		+ result.defender_risk_adjustment
	)

	if not context.turn_manager.spend_action_for(
		KarmanyPvpCombatContext.ACTION_ID_PVP,
		context.action_cost
	):
		result.status = KarmanyPvpCombatResult.Status.ACTION_NOT_AVAILABLE
		result.message = "No se pudo consumir la accion de Combatir para PvP."
		return result
	result.action_consumed = true

	if result.attacker_power > result.defender_power:
		result.winner_player_id = attacker.player_id
		result.loser_player_id = defender.player_id
	elif result.defender_power > result.attacker_power:
		result.winner_player_id = defender.player_id
		result.loser_player_id = attacker.player_id
	else:
		result.was_tie = true
		result.defender_won_tie = true
		result.winner_player_id = defender.player_id
		result.loser_player_id = attacker.player_id

	result.reward_legacy_points_pending = context.reward_legacy_points
	result.loser_retreat_required = true
	result.attacker_pending_consequences = _build_risk_consequences(
		context.attacker_risk_roll,
		result.winner_player_id == attacker.player_id
	)
	result.defender_pending_consequences = _build_risk_consequences(
		context.defender_risk_roll,
		result.winner_player_id == defender.player_id
	)

	_resolve_post_combat_resonance(result, attacker, defender, context)

	result.combat_resonances_discarded = KarmanyResonanceResolver.finish_combat(
		context.combat_id,
		context.resonance_usage_tracker,
		context.resonance_deck
	)

	result.resonance_cross_attacker_drawn = context.resonance_deck.draw_to_hand(
		attacker.resonance_hand,
		1
	)
	result.resonance_cross_defender_drawn = context.resonance_deck.draw_to_hand(
		defender.resonance_hand,
		1
	)

	if not context.truce_tracker.register_pvp(
		attacker.player_id,
		defender.player_id,
		context.turn_manager.current_round
	):
		result.status = KarmanyPvpCombatResult.Status.INVALID_REQUEST
		result.message = "El PvP se resolvio, pero no pudo registrarse la Tregua."
		return result

	result.truce_applied = true
	result.status = KarmanyPvpCombatResult.Status.RESOLVED
	var loser_active: KarmanyRuntimeState = attacker_active
	if result.loser_player_id == defender.player_id:
		loser_active = defender_active
	KarmanyAbilityRuntimeService.commit_combat_loss(
		loser_active.karmany_data,
		result.loser_player_id,
		context.turn_manager.current_round,
		context.turn_manager.get_instance_id(),
		true
	)
	if result.was_tie:
		result.message = "Empate de Poder: gana el defensor; Resonancia Cruzada y Tregua aplicadas."
	else:
		result.message = "PvP resuelto; Resonancia Cruzada y Tregua aplicadas."
	return result


static func _validate_request(
	attacker: KarmanyPlayerState,
	defender: KarmanyPlayerState,
	context: KarmanyPvpCombatContext
) -> KarmanyPvpCombatResult:
	if attacker == null or defender == null:
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			"Atacante y defensor son obligatorios."
		)
	if attacker.player_id == &"" or defender.player_id == &"":
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			"Ambos jugadores requieren player_id."
		)
	if attacker == defender or attacker.player_id == defender.player_id:
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			"Un jugador no puede iniciar PvP contra si mismo."
		)
	if context == null or not context.is_valid():
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			"Contexto PvP invalido."
		)
	if not context.turn_manager.is_running:
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			"La partida no esta activa."
		)
	if context.turn_manager.current_round <= 1:
		return _validation_error(
			KarmanyPvpCombatResult.Status.PVP_FORBIDDEN_ROUND_ONE,
			"PvP esta prohibido en ronda 1."
		)
	if context.turn_manager.get_active_player() != attacker:
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			"Solo el jugador activo puede iniciar este PvP."
		)
	if not context.turn_manager.can_spend_action(context.action_cost):
		return _validation_error(
			KarmanyPvpCombatResult.Status.ACTION_NOT_AVAILABLE,
			"No quedan acciones suficientes para Combatir."
		)
	if context.authorization == null or not context.authorization.is_valid():
		return _validation_error(
			KarmanyPvpCombatResult.Status.PVP_NOT_AUTHORIZED,
			"PvP requiere una loseta, carta, Entrenador o efecto que lo habilite."
		)
	if not context.authorization.is_target_in_range(
		context.board_state,
		attacker.current_coord,
		defender.current_coord
	):
		return _validation_error(
			KarmanyPvpCombatResult.Status.OUT_OF_RANGE,
			"El defensor no esta en el alcance legal de la fuente que habilita PvP."
		)

	var attacker_active := attacker.get_active_karmany()
	var defender_active := defender.get_active_karmany()
	if not _is_valid_active_karmany(attacker_active, attacker.player_id):
		return _validation_error(
			KarmanyPvpCombatResult.Status.NO_ACTIVE_KARMANY,
			"El atacante no tiene Karmany activo valido para combatir."
		)
	if not _is_valid_active_karmany(defender_active, defender.player_id):
		return _validation_error(
			KarmanyPvpCombatResult.Status.NO_ACTIVE_KARMANY,
			"No puedes iniciar PvP contra un jugador sin Karmany activo disponible."
		)
	if not context.truce_tracker.can_attack(
		attacker.player_id,
		defender.player_id,
		context.turn_manager.current_round
	):
		return _validation_error(
			KarmanyPvpCombatResult.Status.TRUCE_BLOCKED,
			"La Tregua impide que este atacante vuelva a retar al mismo defensor esta ronda."
		)

	var attacker_risk_error := _validate_risk(
		context.attacker_risk_authorized,
		context.attacker_risk_roll,
		"atacante"
	)
	if attacker_risk_error != "":
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			attacker_risk_error
		)
	var defender_risk_error := _validate_risk(
		context.defender_risk_authorized,
		context.defender_risk_roll,
		"defensor"
	)
	if defender_risk_error != "":
		return _validation_error(
			KarmanyPvpCombatResult.Status.INVALID_REQUEST,
			defender_risk_error
		)

	var ok := KarmanyPvpCombatResult.new()
	ok.status = KarmanyPvpCombatResult.Status.RESOLVED
	return ok


static func _is_valid_active_karmany(
	runtime_state: KarmanyRuntimeState,
	owner_player_id: StringName
) -> bool:
	if runtime_state == null or not runtime_state.is_linked():
		return false
	if runtime_state.owner_player_id != owner_player_id:
		return false
	if runtime_state.karmany_data == null:
		return false
	return runtime_state.karmany_data.is_valid_definition()


static func _validate_risk(
	authorized: bool,
	roll: int,
	label: String
) -> String:
	if roll == 0:
		return ""
	if not authorized:
		return "El Dado de Riesgo del %s no esta autorizado." % label
	if roll < 1 or roll > 6:
		return "El Dado de Riesgo del %s debe estar entre 1 y 6." % label
	return ""


static func _resolve_post_combat_resonance(
	result: KarmanyPvpCombatResult,
	attacker: KarmanyPlayerState,
	defender: KarmanyPlayerState,
	context: KarmanyPvpCombatContext
) -> void:
	var attacker_card := context.resonance_usage_tracker.get_card_played_by(
		attacker.player_id,
		context.combat_id
	)
	var defender_card := context.resonance_usage_tracker.get_card_played_by(
		defender.player_id,
		context.combat_id
	)
	if attacker_card != null:
		result.attacker_post_effects = KarmanyResonanceResolver.resolve_effects(
			attacker_card,
			attacker,
			TIMING_AFTER_COMBAT,
			_build_post_tags(result.winner_player_id == attacker.player_id),
			context.effect_context
		)
	if defender_card != null:
		result.defender_post_effects = KarmanyResonanceResolver.resolve_effects(
			defender_card,
			defender,
			TIMING_AFTER_COMBAT,
			_build_post_tags(result.winner_player_id == defender.player_id),
			context.effect_context
		)


static func _build_post_tags(won: bool) -> PackedStringArray:
	var tags := PackedStringArray([TAG_COMBAT, TAG_PVP])
	if won:
		tags.append(TAG_COMBAT_WON)
	else:
		tags.append(TAG_COMBAT_LOST)
	return tags


static func _build_risk_consequences(
	roll: int,
	won: bool
) -> PackedStringArray:
	var result := PackedStringArray()
	match roll:
		2:
			result.append(CONSEQUENCE_RISK_DISCARD_CARD)
		4:
			result.append(CONSEQUENCE_RISK_FILTER_RESONANCE)
		6:
			if won:
				result.append(CONSEQUENCE_RISK_WIN_REWARD)
	return result


static func _validation_error(
	status_value: int,
	message: String
) -> KarmanyPvpCombatResult:
	var result := KarmanyPvpCombatResult.new()
	result.status = status_value
	result.message = message
	return result
