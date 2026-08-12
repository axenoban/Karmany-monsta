class_name KarmanyMovementRules
extends RefCounted


const ACTION_ID_MOVE: StringName = &"move"


enum MoveValidation {
	OK,
	MATCH_NOT_RUNNING,
	INVALID_PLAYER,
	NOT_ACTIVE_PLAYER,
	NO_ACTION_AVAILABLE,
	INVALID_ORIGIN,
	INVALID_TARGET,
	SAME_TILE,
	TARGET_HIDDEN,
	NOT_ADJACENT,
	TARGET_BLOCKED_BY_BEAST,
	ORIGIN_BLOCKED_BY_BEAST
}


static func validate_move(
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> int:
	if board_state == null or turn_manager == null:
		return MoveValidation.MATCH_NOT_RUNNING

	if not turn_manager.is_running:
		return MoveValidation.MATCH_NOT_RUNNING

	if player == null or player.player_id == &"":
		return MoveValidation.INVALID_PLAYER

	if turn_manager.get_active_player() != player:
		return MoveValidation.NOT_ACTIVE_PLAYER

	if not turn_manager.can_spend_action(1):
		return MoveValidation.NO_ACTION_AVAILABLE

	var origin_coord := player.current_coord

	if not board_state.has_coord(origin_coord):
		return MoveValidation.INVALID_ORIGIN

	if board_state.is_blocked_by_beast(origin_coord):
		return MoveValidation.ORIGIN_BLOCKED_BY_BEAST

	if not board_state.has_coord(target_coord):
		return MoveValidation.INVALID_TARGET

	if target_coord == origin_coord:
		return MoveValidation.SAME_TILE

	if not board_state.is_revealed(target_coord):
		return MoveValidation.TARGET_HIDDEN

	if not board_state.are_existing_coords_adjacent(
		origin_coord,
		target_coord
	):
		return MoveValidation.NOT_ADJACENT

	if board_state.is_blocked_by_beast(target_coord):
		return MoveValidation.TARGET_BLOCKED_BY_BEAST

	return MoveValidation.OK


static func is_move_valid(
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	return validate_move(
		board_state,
		turn_manager,
		player,
		target_coord
	) == MoveValidation.OK


static func get_validation_message(validation: int) -> String:
	match validation:
		MoveValidation.OK:
			return "Movimiento legal."
		MoveValidation.MATCH_NOT_RUNNING:
			return "La partida no esta activa."
		MoveValidation.INVALID_PLAYER:
			return "El jugador no es valido."
		MoveValidation.NOT_ACTIVE_PLAYER:
			return "No es el turno de este jugador."
		MoveValidation.NO_ACTION_AVAILABLE:
			return "No quedan acciones disponibles."
		MoveValidation.INVALID_ORIGIN:
			return "La posicion actual no existe en el tablero."
		MoveValidation.INVALID_TARGET:
			return "La loseta destino no existe en el tablero."
		MoveValidation.SAME_TILE:
			return "El destino es la loseta actual."
		MoveValidation.TARGET_HIDDEN:
			return "Mover no puede entrar en una loseta oculta; debe usarse Explorar."
		MoveValidation.NOT_ADJACENT:
			return "La loseta destino no es adyacente."
		MoveValidation.TARGET_BLOCKED_BY_BEAST:
			return "La loseta esta bloqueada por una Bestia; debes declarar Combate para entrar."
		MoveValidation.ORIGIN_BLOCKED_BY_BEAST:
			return "Hay una Bestia sin resolver en tu loseta; debes resolver ese combate antes de moverte."

	return "Movimiento invalido."
