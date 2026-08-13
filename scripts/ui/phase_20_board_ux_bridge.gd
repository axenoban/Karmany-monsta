extends Node3D


@onready var board_prototype: Node = $Board3DPrototype
@onready var board_branch: Node3D = $Board3DPrototype
@onready var board_camera: Camera3D = $Board3DPrototype/Camera3D
@onready var hud: KarmanyGameHUD = $GameHUD


var legacy_points_controller: KarmanyLegacyPointsController = KarmanyLegacyPointsController.new()

var _move_highlights: Array[Vector2i] = []
var _explore_highlights: Array[Vector2i] = []
var _blocked_highlights: Array[Vector2i] = []


func _ready() -> void:
	if board_prototype == null or board_branch == null or board_camera == null or hud == null:
		push_error("FASE 20 ERROR: No se pudo conectar tablero, camara y HUD.")
		return

	board_branch.visible = true
	board_camera.make_current()
	board_camera.look_at(Vector3.ZERO, Vector3.UP)

	var manager: KarmanyTurnManager = board_prototype.turn_manager
	var players: Array[KarmanyPlayerState] = []
	for player in manager.players:
		players.append(player)

	var mode_config := KarmanyLegacyModeConfig.new()
	mode_config.configure_standard(KarmanyLegacyModeConfig.MapFormat.MAP_22)
	if not legacy_points_controller.configure(players, mode_config):
		push_error("FASE 20 ERROR: No se pudo configurar PL para el HUD.")
		return

	hud.bind_turn_manager(manager)
	hud.bind_legacy_points_controller(legacy_points_controller)
	hud.action_requested.connect(_on_action_requested)

	manager.action_spent.connect(_on_turn_state_changed)
	manager.turn_started.connect(_on_turn_started)

	_bind_tile_signals()
	_sync_action_states()
	_refresh_board_ux()


func refresh_board_ux() -> void:
	_refresh_board_ux()


func get_move_highlights() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _move_highlights:
		result.append(coord)
	return result


func get_explore_highlights() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _explore_highlights:
		result.append(coord)
	return result


func get_blocked_highlights() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in _blocked_highlights:
		result.append(coord)
	return result


func get_tile_context(coord: Vector2i) -> String:
	return _build_tile_context(coord)


func _bind_tile_signals() -> void:
	for coord in board_prototype.board_state.get_coords():
		var tile: KarmanyHexTile3D = board_prototype.get_tile_view(coord)
		if tile == null:
			continue
		if not tile.tile_clicked.is_connected(_on_tile_clicked):
			tile.tile_clicked.connect(_on_tile_clicked)


func _refresh_board_ux() -> void:
	_move_highlights.clear()
	_explore_highlights.clear()
	_blocked_highlights.clear()

	for coord in board_prototype.board_state.get_coords():
		var tile: KarmanyHexTile3D = board_prototype.get_tile_view(coord)
		if tile != null:
			tile.clear_ux_hint()

	var manager: KarmanyTurnManager = board_prototype.turn_manager
	var player: KarmanyPlayerState = manager.get_active_player()
	if player == null:
		return

	# El sandbox visual solo tiene la unidad 3D de player_1. No se inventa
	# una representacion para otros jugadores dentro de esta fase.
	if player != board_prototype.player_state:
		return

	var board_state: KarmanyBoardState = board_prototype.board_state
	if board_state.is_blocked_by_beast(player.current_coord):
		_mark_hint(player.current_coord, KarmanyHexTile3D.UxHint.BLOCKED)
		_blocked_highlights.append(player.current_coord)
		return

	for coord in board_state.get_existing_neighbors(player.current_coord):
		var move_validation: int = KarmanyMovementRules.validate_move(
			board_state,
			manager,
			player,
			coord
		)
		var explore_validation: int = KarmanyExplorationRules.validate_exploration(
			board_state,
			manager,
			player,
			coord
		)

		if move_validation == KarmanyMovementRules.MoveValidation.OK:
			_move_highlights.append(coord)
			_mark_hint(coord, KarmanyHexTile3D.UxHint.MOVE)
		elif explore_validation == KarmanyExplorationRules.ExplorationValidation.OK:
			_explore_highlights.append(coord)
			_mark_hint(coord, KarmanyHexTile3D.UxHint.EXPLORE)
		elif _is_blocked_target(coord, move_validation, explore_validation):
			_blocked_highlights.append(coord)
			_mark_hint(coord, KarmanyHexTile3D.UxHint.BLOCKED)


func _mark_hint(coord: Vector2i, hint: int) -> void:
	var tile: KarmanyHexTile3D = board_prototype.get_tile_view(coord)
	if tile != null:
		tile.set_ux_hint(hint)


func _is_blocked_target(
	coord: Vector2i,
	move_validation: int,
	explore_validation: int
) -> bool:
	var board_state: KarmanyBoardState = board_prototype.board_state
	if board_state.is_blocked_by_beast(coord):
		return true
	if move_validation == KarmanyMovementRules.MoveValidation.TARGET_BLOCKED_BY_BEAST:
		return true
	return explore_validation == KarmanyExplorationRules.ExplorationValidation.TARGET_OCCUPIED


func _on_tile_clicked(tile: KarmanyHexTile3D) -> void:
	if tile == null:
		return
	hud.set_action_context_text(_build_tile_context(tile.coord))


func _build_tile_context(coord: Vector2i) -> String:
	var board_state: KarmanyBoardState = board_prototype.board_state
	var manager: KarmanyTurnManager = board_prototype.turn_manager
	var player: KarmanyPlayerState = manager.get_active_player()
	var cell: KarmanyBoardCellState = board_state.get_cell(coord)

	if cell == null:
		return "Loseta %s: coordenada no registrada." % str(coord)
	if player == null:
		return "Loseta %s: no hay jugador activo." % str(coord)

	var move_validation: int = KarmanyMovementRules.validate_move(
		board_state,
		manager,
		player,
		coord
	)
	var explore_validation: int = KarmanyExplorationRules.validate_exploration(
		board_state,
		manager,
		player,
		coord
	)

	var move_text: String = (
		"DISPONIBLE"
		if move_validation == KarmanyMovementRules.MoveValidation.OK
		else KarmanyMovementRules.get_validation_message(move_validation)
	)
	var explore_text: String = (
		"DISPONIBLE"
		if explore_validation == KarmanyExplorationRules.ExplorationValidation.OK
		else KarmanyExplorationRules.get_validation_message(explore_validation)
	)

	var header: String = "Loseta %s" % str(coord)
	if not cell.revealed:
		return "%s | Oculta | Mover: %s | Explorar: %s" % [
			header,
			move_text,
			explore_text
		]

	var identity: String = "Revelada"
	if cell.tile_data != null:
		identity = "%s (%s)" % [
			cell.tile_data.display_name,
			cell.tile_data.tile_id
		]

	var blocked_text: String = ""
	if board_state.is_blocked_by_beast(coord):
		var beast: KarmanyBeastRuntimeState = board_state.get_beast(coord)
		if beast != null and beast.beast_data != null:
			blocked_text = " | BLOQUEADA: %s" % beast.beast_data.display_name
		else:
			blocked_text = " | BLOQUEADA por Bestia"

	return "%s | %s%s | Mover: %s | Explorar: %s" % [
		header,
		identity,
		blocked_text,
		move_text,
		explore_text
	]


func _on_action_requested(action_id: StringName) -> void:
	match action_id:
		KarmanyGameHUD.ACTION_MOVE:
			_resolve_move_request()
		KarmanyGameHUD.ACTION_EXPLORE:
			_resolve_explore_request()
		KarmanyGameHUD.ACTION_END_TURN:
			_resolve_end_turn_request()
	_sync_action_states()
	_refresh_board_ux()


func _resolve_move_request() -> void:
	if board_prototype.selected_tile == null:
		hud.set_action_context_text("Mover no disponible: selecciona primero una loseta destino.")
		return

	var coord: Vector2i = board_prototype.selected_tile.coord
	var validation: int = KarmanyMovementRules.validate_move(
		board_prototype.board_state,
		board_prototype.turn_manager,
		board_prototype.player_state,
		coord
	)
	if validation != KarmanyMovementRules.MoveValidation.OK:
		hud.set_action_context_text(
			"Mover no disponible: %s" % KarmanyMovementRules.get_validation_message(validation)
		)
		return

	if board_prototype.try_move_selected_trainer():
		hud.set_action_context_text(
			"Mover resuelto hacia %s. Destinos legales actualizados." % str(coord)
		)
	else:
		hud.set_action_context_text("Mover no se resolvio por una condicion tecnica del tablero.")


func _resolve_explore_request() -> void:
	if board_prototype.selected_tile == null:
		hud.set_action_context_text("Explorar no disponible: selecciona primero una loseta oculta.")
		return

	var coord: Vector2i = board_prototype.selected_tile.coord
	var validation: int = KarmanyExplorationRules.validate_exploration(
		board_prototype.board_state,
		board_prototype.turn_manager,
		board_prototype.player_state,
		coord
	)
	if validation != KarmanyExplorationRules.ExplorationValidation.OK:
		hud.set_action_context_text(
			"Explorar no disponible: %s" % KarmanyExplorationRules.get_validation_message(validation)
		)
		return

	if board_prototype.try_explore_selected_trainer():
		hud.set_action_context_text(
			"Explorar resuelto en %s. La loseta fue revelada y los destinos se actualizaron." % str(coord)
		)
	else:
		hud.set_action_context_text("Explorar no se resolvio por una condicion tecnica del tablero.")


func _resolve_end_turn_request() -> void:
	var manager: KarmanyTurnManager = board_prototype.turn_manager
	if manager.end_turn():
		hud.set_action_context_text("Turno finalizado. UX actualizada para el nuevo jugador activo.")
	else:
		hud.set_action_context_text("Finalizar turno no disponible: debes consumir las 2 acciones.")


func _on_turn_state_changed(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	_sync_action_states()
	_refresh_board_ux()


func _on_turn_started(
	_player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	_sync_action_states()
	_refresh_board_ux()


func _sync_action_states() -> void:
	var manager: KarmanyTurnManager = board_prototype.turn_manager
	var active_player: KarmanyPlayerState = manager.get_active_player()
	var prototype_player_turn: bool = (
		active_player != null
		and active_player == board_prototype.player_state
	)

	hud.set_action_state(
		KarmanyGameHUD.ACTION_MOVE,
		prototype_player_turn,
		"Mover: las losetas verdes son destinos revelados legales."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_EXPLORE,
		prototype_player_turn,
		"Explorar: las losetas azules son destinos ocultos legales."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_INTERACT,
		false,
		"Interactuar: requiere contexto de loseta; su UX llegara en una fase posterior."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_COMBAT,
		false,
		"Combatir: los bloqueos se muestran ahora, pero el targeting de combate no pertenece a Fase 20."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_CALL_BOND,
		false,
		"Llamar/Vincular: sistema logico disponible; falta su selector visual especifico."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_IMPROVE_BOOK,
		false,
		"Mejorar Libro: no se habilita hasta conectar su controlador de gameplay."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_END_TURN,
		manager.is_running,
		"Finalizar turno: disponible cuando quedan 0 acciones."
	)
