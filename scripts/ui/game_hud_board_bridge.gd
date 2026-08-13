extends Node


@onready var board_prototype: Node = $Board3DPrototype
@onready var hud: KarmanyGameHUD = $GameHUD


var legacy_points_controller: KarmanyLegacyPointsController = KarmanyLegacyPointsController.new()


func _ready() -> void:
	if board_prototype == null or hud == null:
		push_error("FASE 19 ERROR: No se pudo conectar tablero y HUD.")
		return

	var players: Array[KarmanyPlayerState] = []
	for player in board_prototype.turn_manager.players:
		players.append(player)

	var mode_config := KarmanyLegacyModeConfig.new()
	mode_config.configure_standard(KarmanyLegacyModeConfig.MapFormat.MAP_22)
	if not legacy_points_controller.configure(players, mode_config):
		push_error("FASE 19 ERROR: No se pudo configurar PL para el HUD.")
		return

	hud.bind_turn_manager(board_prototype.turn_manager)
	hud.bind_legacy_points_controller(legacy_points_controller)
	hud.action_requested.connect(_on_action_requested)

	board_prototype.turn_manager.action_spent.connect(_on_turn_state_changed)
	board_prototype.turn_manager.turn_started.connect(_on_turn_started)
	_sync_action_states()


func _on_action_requested(action_id: StringName) -> void:
	match action_id:
		KarmanyGameHUD.ACTION_MOVE:
			if board_prototype.try_move_selected_trainer():
				hud.set_action_context_text("Mover resuelto. Selecciona el siguiente destino si aun tienes acciones.")
			else:
				hud.set_action_context_text("Mover no se resolvio. Revisa la loseta seleccionada.")
		KarmanyGameHUD.ACTION_EXPLORE:
			if board_prototype.try_explore_selected_trainer():
				hud.set_action_context_text("Explorar resuelto. La loseta fue revelada y el Entrenador se desplazo.")
			else:
				hud.set_action_context_text("Explorar no se resolvio. Revisa la loseta seleccionada.")
		KarmanyGameHUD.ACTION_END_TURN:
			if board_prototype.turn_manager.end_turn():
				hud.set_action_context_text("Turno finalizado.")
			else:
				hud.set_action_context_text("El turno solo puede finalizar despues de gastar las 2 acciones.")
	_sync_action_states()


func _on_turn_state_changed(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	_sync_action_states()


func _on_turn_started(
	_player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	_sync_action_states()


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
		"Mover: selecciona una loseta revelada adyacente."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_EXPLORE,
		prototype_player_turn,
		"Explorar: selecciona una loseta oculta adyacente."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_INTERACT,
		false,
		"Interactuar: el motor existe por efectos, pero el sandbox visual aun no tiene selector contextual."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_COMBAT,
		false,
		"Combatir: PvE/PvP ya existen en logica; el targeting visual pertenece a la UX posterior."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_CALL_BOND,
		false,
		"Llamar/Vincular: sistema logico disponible; falta la seleccion visual del encuentro."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_IMPROVE_BOOK,
		false,
		"Mejorar Libro: se mostrara cuando el controlador de Libro quede conectado al flujo visual."
	)
	hud.set_action_state(
		KarmanyGameHUD.ACTION_END_TURN,
		manager.is_running,
		"Finalizar turno: disponible cuando quedan 0 acciones."
	)
