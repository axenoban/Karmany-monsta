class_name KarmanyBeastEncounterResolver
extends RefCounted


static func spawn_from_deck(
	board_state: KarmanyBoardState,
	coord: Vector2i,
	deck: KarmanyBeastDeck,
	requires_immediate_combat: bool = false
) -> KarmanyBeastSpawnResult:
	var result := KarmanyBeastSpawnResult.new()
	result.coord = coord
	result.requires_immediate_combat = requires_immediate_combat

	if board_state == null or deck == null:
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.INVALID_REQUEST, "BoardState y mazo de Bestias son obligatorios.")
	if not board_state.has_coord(coord):
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.INVALID_REQUEST, "La coordenada no existe en el tablero.")
	if not board_state.is_revealed(coord):
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.TILE_NOT_REVEALED, "Una Bestia revelada debe colocarse sobre una loseta revelada.")
	if board_state.has_beast(coord):
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.TILE_ALREADY_HAS_BEAST, "La loseta ya tiene una Bestia; no se revela otra.")

	var beast_data := deck.draw_card()
	if beast_data == null:
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.DECK_EMPTY, "No quedan Bestias disponibles en ese mazo.")
	if KarmanyBeastAbilityRuntimeService.is_runtime_excluded(beast_data.beast_id):
		deck.discard_card(beast_data)
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.INVALID_REQUEST, "La Bestia %s esta excluida del runtime F44.3." % String(beast_data.beast_id))

	var beast_state := KarmanyBeastRuntimeState.new()
	var instance_id := StringName("%s@%d,%d" % [String(beast_data.beast_id), coord.x, coord.y])
	if not beast_state.configure(beast_data, instance_id, coord):
		deck.discard_card(beast_data)
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.INVALID_REQUEST, "No se pudo crear el estado runtime de la Bestia.")
	if not board_state.set_beast(coord, beast_state):
		deck.discard_card(beast_data)
		return _spawn_error(result, KarmanyBeastSpawnResult.Status.INVALID_REQUEST, "No se pudo colocar la Bestia sobre la loseta.")

	result.status = KarmanyBeastSpawnResult.Status.SPAWNED
	result.beast_state = beast_state
	result.message = "Bestia revelada y loseta bloqueada."
	return result


static func resolve_combat(
	player: KarmanyPlayerState,
	attacker_karmany: KarmanyData,
	board_state: KarmanyBoardState,
	target_coord: Vector2i,
	deck: KarmanyBeastDeck,
	context: KarmanyBeastCombatContext
) -> KarmanyBeastCombatResult:
	var result := KarmanyBeastCombatResult.new()
	var validation := _validate_combat(player, attacker_karmany, board_state, target_coord, deck, context)
	if validation != "":
		result.status = KarmanyBeastCombatResult.Status.INVALID_REQUEST
		result.message = validation
		return result

	var beast_state := board_state.get_beast(target_coord)
	var beast_data := beast_state.beast_data
	result.beast_state = beast_state
	KarmanyBeastAbilityRuntimeService.apply_combat_preflight(beast_data, context)

	var request := KarmanyCombatRequest.new()
	request.attacker_player_id = player.player_id
	request.attacker_karmany = attacker_karmany
	request.target_id = beast_data.beast_id
	request.target_type = KarmanyCombatRequest.TargetType.BOSS if beast_data.is_boss() else KarmanyCombatRequest.TargetType.BEAST
	request.base_defense = beast_data.base_defense + context.beast_defense_bonus
	request.uses_instinct = true
	request.instinct_roll = context.instinct_roll
	request.modifiers = context.combat_modifiers
	request.risk_authorized = context.risk_authorized
	request.risk_roll = context.risk_roll

	var combat_result := KarmanyCombatResolver.resolve(request)
	if not combat_result.is_resolved():
		result.status = KarmanyBeastCombatResult.Status.INVALID_REQUEST
		result.message = combat_result.message
		return result

	if context.action_cost > 0:
		if not context.turn_manager.spend_action_for(context.action_id, context.action_cost):
			result.status = KarmanyBeastCombatResult.Status.ACTION_NOT_AVAILABLE
			result.message = "No se pudo consumir la accion de Combatir."
			return result
		result.action_consumed = true

	result.combat_result = combat_result
	if combat_result.is_victory():
		return _resolve_victory(result, player, attacker_karmany, board_state, target_coord, deck, context)
	return _resolve_defeat(result, player, attacker_karmany, context)


static func _validate_combat(
	player: KarmanyPlayerState,
	attacker_karmany: KarmanyData,
	board_state: KarmanyBoardState,
	target_coord: Vector2i,
	deck: KarmanyBeastDeck,
	context: KarmanyBeastCombatContext
) -> String:
	if player == null or player.player_id == &"":
		return "Jugador invalido."
	if attacker_karmany == null or not attacker_karmany.is_valid_definition():
		return "Karmany atacante invalido."
	if board_state == null or not board_state.has_coord(target_coord):
		return "Loseta objetivo invalida."
	if not board_state.is_revealed(target_coord):
		return "La Bestia debe estar sobre una loseta revelada."
	if not board_state.has_beast(target_coord):
		return "La loseta objetivo no contiene una Bestia."
	if deck == null:
		return "Falta el mazo correspondiente de la Bestia."
	if context == null or not context.is_valid():
		return "Contexto de combate contra Bestia invalido."

	var beast_state := board_state.get_beast(target_coord)
	if beast_state == null or beast_state.beast_data == null:
		return "Estado de Bestia invalido."
	if deck.tier != beast_state.beast_data.tier:
		return "El mazo no corresponde a la categoria de la Bestia."
	var beast_rule_error := KarmanyBeastAbilityRuntimeService.validate_combat_preflight(beast_state.beast_data, context)
	if not beast_rule_error.is_empty():
		return beast_rule_error

	var origin := player.current_coord
	if origin != target_coord and not board_state.are_existing_coords_adjacent(origin, target_coord):
		return "El jugador debe estar sobre la loseta o adyacente para combatir esta Bestia."
	if context.enter_after_victory:
		if origin == target_coord:
			return "No se requiere entrada posterior si el jugador ya esta en la loseta."
		if board_state.is_occupied(target_coord):
			return "La loseta de la Bestia contiene otra unidad."
		if board_state.get_occupying_unit_id(origin) != context.moving_unit_id:
			return "La unidad indicada no ocupa la loseta de origen."
	if context.action_cost > 0:
		if not context.turn_manager.is_running:
			return "La partida no esta activa."
		if context.turn_manager.get_active_player() != player:
			return "No es el turno de este jugador."
		if not context.turn_manager.can_spend_action(context.action_cost):
			return "No quedan acciones suficientes para Combatir."
	return ""


static func _resolve_victory(
	result: KarmanyBeastCombatResult,
	player: KarmanyPlayerState,
	attacker_karmany: KarmanyData,
	board_state: KarmanyBoardState,
	target_coord: Vector2i,
	deck: KarmanyBeastDeck,
	context: KarmanyBeastCombatContext
) -> KarmanyBeastCombatResult:
	var beast_state := result.beast_state
	var beast_data := beast_state.beast_data
	var origin := player.current_coord

	if context.enter_after_victory:
		if not board_state.clear_unit_occupant(origin):
			result.status = KarmanyBeastCombatResult.Status.ENTRY_FAILED
			result.message = "No se pudo liberar la ocupacion de origen."
			return result
		if not board_state.set_unit_occupant(target_coord, context.moving_unit_id):
			board_state.set_unit_occupant(origin, context.moving_unit_id)
			result.status = KarmanyBeastCombatResult.Status.ENTRY_FAILED
			result.message = "No se pudo ocupar la loseta tras derrotar la Bestia."
			return result

	if board_state.clear_beast(target_coord) != beast_state:
		if context.enter_after_victory:
			board_state.clear_unit_occupant(target_coord)
			board_state.set_unit_occupant(origin, context.moving_unit_id)
		result.status = KarmanyBeastCombatResult.Status.ENTRY_FAILED
		result.message = "No se pudo retirar la Bestia derrotada del tablero."
		return result

	beast_state.mark_defeated()
	if not deck.discard_card(beast_data):
		beast_state.restore_blocking()
		board_state.set_beast(target_coord, beast_state)
		if context.enter_after_victory:
			board_state.clear_unit_occupant(target_coord)
			board_state.set_unit_occupant(origin, context.moving_unit_id)
		result.status = KarmanyBeastCombatResult.Status.ENTRY_FAILED
		result.message = "No se pudo enviar la Bestia derrotada al descarte correcto."
		return result

	if context.enter_after_victory:
		player.set_board_position(target_coord)
		result.entered_tile_after_victory = true
		result.entry_bonus_allowed = true
		var tile_data := board_state.get_tile_data(target_coord)
		if tile_data != null:
			result.entry_effect_results = KarmanyEffectResolver.apply_effects(tile_data.entry_effects, player, context.effect_context)

	result.status = KarmanyBeastCombatResult.Status.RESOLVED
	result.message = "Bestia derrotada; la loseta deja de estar bloqueada."
	result.beast_removed = true
	result.remains_blocking = false
	result.reward_legacy_points_pending = beast_data.reward_legacy_points
	result.reward_consequence_ids = beast_data.reward_consequence_ids.duplicate()
	result.reward_effect_results = KarmanyEffectResolver.apply_effects(beast_data.reward_effects, player, context.effect_context)
	KarmanyBeastAbilityRuntimeService.apply_victory_specials(beast_data, attacker_karmany, player)
	return result


static func _resolve_defeat(
	result: KarmanyBeastCombatResult,
	player: KarmanyPlayerState,
	attacker_karmany: KarmanyData,
	context: KarmanyBeastCombatContext
) -> KarmanyBeastCombatResult:
	var beast_data := result.beast_state.beast_data
	result.status = KarmanyBeastCombatResult.Status.RESOLVED
	result.message = "El jugador pierde; la Bestia permanece bloqueando la loseta."
	result.beast_removed = false
	result.remains_blocking = true
	result.retreat_required = true
	result.attacker_exhaustion_pending = not attacker_karmany.is_starting_karmany
	result.defeat_consequence_ids = beast_data.defeat_consequence_ids.duplicate()
	result.defeat_effect_results = KarmanyEffectResolver.apply_effects(beast_data.defeat_effects, player, context.effect_context)
	return result


static func _spawn_error(
	result: KarmanyBeastSpawnResult,
	status_value: int,
	message: String
) -> KarmanyBeastSpawnResult:
	result.status = status_value
	result.message = message
	return result
