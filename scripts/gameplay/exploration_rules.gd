class_name KarmanyExplorationRules
extends RefCounted


const ACTION_ID_EXPLORE: StringName = &"explore"


enum ExplorationValidation {
	OK,
	MATCH_NOT_RUNNING,
	INVALID_PLAYER,
	NOT_ACTIVE_PLAYER,
	NO_ACTION_AVAILABLE,
	INVALID_ORIGIN,
	INVALID_TARGET,
	SAME_TILE,
	TARGET_ALREADY_REVEALED,
	TARGET_HAS_NO_TILE_DATA,
	TARGET_OCCUPIED,
	NOT_ADJACENT,
	ORIGIN_BLOCKED_BY_BEAST
}


static func validate_exploration(
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> int:
	if board_state == null or turn_manager == null:
		return ExplorationValidation.MATCH_NOT_RUNNING

	if not turn_manager.is_running:
		return ExplorationValidation.MATCH_NOT_RUNNING

	if player == null or player.player_id == &"":
		return ExplorationValidation.INVALID_PLAYER

	if turn_manager.get_active_player() != player:
		return ExplorationValidation.NOT_ACTIVE_PLAYER

	if not turn_manager.can_spend_action(1):
		return ExplorationValidation.NO_ACTION_AVAILABLE

	var origin_coord := player.current_coord

	if not board_state.has_coord(origin_coord):
		return ExplorationValidation.INVALID_ORIGIN

	if board_state.is_blocked_by_beast(origin_coord):
		return ExplorationValidation.ORIGIN_BLOCKED_BY_BEAST

	if not board_state.has_coord(target_coord):
		return ExplorationValidation.INVALID_TARGET

	if target_coord == origin_coord:
		return ExplorationValidation.SAME_TILE

	if board_state.is_revealed(target_coord):
		return ExplorationValidation.TARGET_ALREADY_REVEALED

	if board_state.get_tile_data(target_coord) == null:
		return ExplorationValidation.TARGET_HAS_NO_TILE_DATA

	if board_state.is_occupied(target_coord):
		return ExplorationValidation.TARGET_OCCUPIED

	if not board_state.are_existing_coords_adjacent(
		origin_coord,
		target_coord
	):
		return ExplorationValidation.NOT_ADJACENT

	return ExplorationValidation.OK


static func is_exploration_valid(
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	return validate_exploration(
		board_state,
		turn_manager,
		player,
		target_coord
	) == ExplorationValidation.OK


static func get_explorable_neighbors(
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	player: KarmanyPlayerState
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	if player == null or board_state == null:
		return result

	for coord in board_state.get_existing_neighbors(player.current_coord):
		if is_exploration_valid(
			board_state,
			turn_manager,
			player,
			coord
		):
			result.append(coord)

	return result


static func get_validation_message(validation: int) -> String:
	match validation:
		ExplorationValidation.OK:
			return "Exploracion legal."
		ExplorationValidation.MATCH_NOT_RUNNING:
			return "La partida no esta activa."
		ExplorationValidation.INVALID_PLAYER:
			return "El jugador no es valido."
		ExplorationValidation.NOT_ACTIVE_PLAYER:
			return "No es el turno de este jugador."
		ExplorationValidation.NO_ACTION_AVAILABLE:
			return "No quedan acciones disponibles."
		ExplorationValidation.INVALID_ORIGIN:
			return "La posicion actual no existe en el tablero."
		ExplorationValidation.INVALID_TARGET:
			return "La coordenada destino no existe en el tablero."
		ExplorationValidation.SAME_TILE:
			return "No puedes explorar la loseta donde ya estas."
		ExplorationValidation.TARGET_ALREADY_REVEALED:
			return "La loseta ya esta revelada; para entrar usa Mover."
		ExplorationValidation.TARGET_HAS_NO_TILE_DATA:
			return "La posicion oculta aun no tiene una loseta asignada."
		ExplorationValidation.TARGET_OCCUPIED:
			return "La loseta destino esta ocupada."
		ExplorationValidation.NOT_ADJACENT:
			return "La loseta oculta no es adyacente."
		ExplorationValidation.ORIGIN_BLOCKED_BY_BEAST:
			return "Hay una Bestia sin resolver en tu loseta; debes resolver ese combate antes de explorar."

	return "Exploracion invalida."
