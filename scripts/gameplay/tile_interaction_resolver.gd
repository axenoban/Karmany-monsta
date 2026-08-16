class_name KarmanyTileInteractionResolver
extends RefCounted


const ACTION_ID_INTERACT: StringName = &"interact_tile"


static func interact_effect_option(
	player: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	option_index: int = 0,
	effect_context: KarmanyEffectContext = null
) -> KarmanyTileInteractionResult:
	var validation := validate_effect_option(
		player,
		board_state,
		turn_manager,
		option_index,
		effect_context
	)
	if not validation.is_success():
		return validation

	var tile_data: KarmanyTileData = board_state.get_tile_data(player.current_coord)
	var effect: KarmanyEffectData = tile_data.later_use_effects[option_index]
	var effect_result: KarmanyEffectResult = KarmanyEffectResolver.apply_effect(
		effect,
		player,
		effect_context
	)
	if effect_result == null or not effect_result.was_applied():
		return _result(
			KarmanyTileInteractionResult.Status.EFFECT_FAILED,
			"El efecto de Uso posterior no pudo resolverse."
		)
	if not turn_manager.spend_action_for(ACTION_ID_INTERACT, 1):
		return _result(
			KarmanyTileInteractionResult.Status.NO_ACTIONS,
			"No se pudo consumir la accion de Interactuar."
		)

	var result := KarmanyTileInteractionResult.new()
	result.status = KarmanyTileInteractionResult.Status.SUCCESS
	result.message = "Uso posterior resuelto."
	result.tile_id = StringName(tile_data.tile_id)
	result.option_index = option_index
	result.action_consumed = true
	result.effect_result = effect_result
	return result


static func validate_interaction(
	player: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager
) -> KarmanyTileInteractionResult:
	var validation := validate_common(player, board_state, turn_manager)
	if not validation.is_success():
		return validation
	var tile_data: KarmanyTileData = board_state.get_tile_data(player.current_coord)
	if tile_data == null:
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_TILE,
			"La loseta actual no tiene datos."
		)
	if tile_data.later_use_text.strip_edges().is_empty():
		return _result(
			KarmanyTileInteractionResult.Status.NO_LATER_USE,
			"La loseta no tiene Uso posterior."
		)
	var result := KarmanyTileInteractionResult.new()
	result.status = KarmanyTileInteractionResult.Status.SUCCESS
	result.tile_id = StringName(tile_data.tile_id)
	result.message = "Interactuar disponible."
	return result


static func validate_effect_option(
	player: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	option_index: int,
	effect_context: KarmanyEffectContext = null
) -> KarmanyTileInteractionResult:
	var common := validate_common(player, board_state, turn_manager)
	if not common.is_success():
		return common
	var tile_data: KarmanyTileData = board_state.get_tile_data(player.current_coord)
	if tile_data == null:
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_TILE,
			"La loseta actual no tiene datos."
		)
	if tile_data.later_use_text.strip_edges().is_empty():
		return _result(
			KarmanyTileInteractionResult.Status.NO_LATER_USE,
			"La loseta no tiene Uso posterior."
		)
	if tile_data.later_use_effects.is_empty():
		return _result(
			KarmanyTileInteractionResult.Status.SPECIALIZED_HANDLER_REQUIRED,
			"El Uso posterior se resuelve mediante su perfil especializado."
		)
	if option_index < 0 or option_index >= tile_data.later_use_effects.size():
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_OPTION,
			"La opcion de Uso posterior no existe."
		)
	var effect: KarmanyEffectData = tile_data.later_use_effects[option_index]
	var effect_error: String = _effect_preflight_error(effect, effect_context)
	if not effect_error.is_empty():
		return _result(
			KarmanyTileInteractionResult.Status.EFFECT_FAILED,
			effect_error
		)
	var result := KarmanyTileInteractionResult.new()
	result.status = KarmanyTileInteractionResult.Status.SUCCESS
	result.tile_id = StringName(tile_data.tile_id)
	result.option_index = option_index
	result.message = "Opcion de Interactuar legal."
	return result


static func validate_common(
	player: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager
) -> KarmanyTileInteractionResult:
	if player == null or board_state == null or turn_manager == null:
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_REQUEST,
			"Jugador, tablero y turno son obligatorios."
		)
	if not turn_manager.is_running:
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_REQUEST,
			"La partida no esta activa."
		)
	if turn_manager.get_active_player() != player:
		return _result(
			KarmanyTileInteractionResult.Status.NOT_ACTIVE_PLAYER,
			"Solo el jugador activo puede Interactuar."
		)
	if not turn_manager.can_spend_action(1):
		return _result(
			KarmanyTileInteractionResult.Status.NO_ACTIONS,
			"No quedan acciones para Interactuar."
		)
	if (
		not board_state.has_coord(player.current_coord)
		or not board_state.is_revealed(player.current_coord)
	):
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_TILE,
			"La posicion actual no es una loseta revelada valida."
		)
	if board_state.is_blocked_by_beast(player.current_coord):
		return _result(
			KarmanyTileInteractionResult.Status.TILE_BLOCKED,
			"No puedes Interactuar mientras una Bestia bloquee tu loseta."
		)
	var ok := KarmanyTileInteractionResult.new()
	ok.status = KarmanyTileInteractionResult.Status.SUCCESS
	ok.message = "Contexto comun de Interactuar legal."
	return ok


static func _effect_preflight_error(
	effect: KarmanyEffectData,
	context: KarmanyEffectContext
) -> String:
	if effect == null:
		return "La opcion elegida no contiene un efecto valido."
	if effect.effect_type == KarmanyEffectData.EffectType.NONE:
		return "La opcion no contiene una operacion ejecutable."
	if (
		effect.effect_type != KarmanyEffectData.EffectType.MODIFY_STATE
		and effect.amount <= 0
	):
		return "El efecto requiere una cantidad positiva."
	match effect.effect_type:
		KarmanyEffectData.EffectType.DRAW_CARDS:
			if effect.card_source_id == &"" or context == null or not context.has_draw_cards_handler():
				return "El robo de cartas no tiene un adaptador disponible."
		KarmanyEffectData.EffectType.DISCARD_CARDS:
			if effect.card_source_id == &"" or context == null or not context.has_discard_cards_handler():
				return "El descarte de cartas no tiene un adaptador disponible."
		KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS:
			if effect.secondary_amount <= 0:
				return "El efecto de robo/descarte requiere una cantidad de descarte positiva."
			if (
				effect.card_source_id == &""
				or context == null
				or not context.has_draw_cards_handler()
				or not context.has_discard_cards_handler()
			):
				return "El robo/descarte no tiene todos sus adaptadores disponibles."
		KarmanyEffectData.EffectType.MODIFY_STATE:
			if effect.state_id == &"" or context == null or not context.has_modify_state_handler():
				return "La modificacion de estado no tiene un adaptador disponible."
		KarmanyEffectData.EffectType.ACTIVATE_CONDITION:
			if effect.condition_id == &"" or context == null or not context.has_activate_condition_handler():
				return "La condicion no tiene un adaptador disponible."
		KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER:
			if effect.encounter_id == &"" or context == null or not context.has_trigger_encounter_handler():
				return "El encuentro no tiene un adaptador disponible."
	return ""


static func _result(status_value: int, text: String) -> KarmanyTileInteractionResult:
	var result := KarmanyTileInteractionResult.new()
	result.status = status_value
	result.message = text
	return result
