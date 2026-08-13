extends Node3D


@onready var board_prototype: Node = $Board3DPrototype
@onready var board_root_3d: Node3D = $Board3DPrototype
@onready var board_camera: Camera3D = $Board3DPrototype/Camera3D
@onready var board_tiles_root: Node3D = $Board3DPrototype/Board
@onready var hud: KarmanyGameHUD = $GameHUD


var legacy_points_controller: KarmanyLegacyPointsController = KarmanyLegacyPointsController.new()


func _ready() -> void:
	if (
		board_prototype == null
		or board_root_3d == null
		or board_camera == null
		or board_tiles_root == null
		or hud == null
	):
		push_error("FASE 19 ERROR: No se pudo conectar tablero, camara y HUD.")
		return

	# La escena compuesta debe conservar un contexto 3D explicito. El tablero
	# genera sus losetas en su propio _ready(); aqui solo garantizamos que su
	# rama 3D siga visible y que su camara sea la activa del viewport.
	board_root_3d.visible = true
	board_tiles_root.visible = true
	board_camera.make_current()
	board_camera.look_at(Vector3.ZERO, Vector3.UP)

	var manager: KarmanyTurnManager = board_prototype.turn_manager
	var players: Array[KarmanyPlayerState] = []
	for player in manager.players:
		players.append(player)

	var mode_config := KarmanyLegacyModeConfig.new()
	mode_config.configure_standard(KarmanyLegacyModeConfig.MapFormat.MAP_22)
	if not legacy_points_controller.configure(players, mode_config):
		push_error("FASE 19 ERROR: No se pudo configurar PL para el HUD.")
		return

	hud.bind_turn_manager(manager)
	hud.bind_legacy_points_controller(legacy_points_controller)
	hud.action_requested.connect(_on_action_requested)

	manager.action_spent.connect(_on_turn_state_changed)
	manager.turn_started.connect(_on_turn_started)
	_sync_action_states()
	call_deferred("_verify_visual_integration")


func _verify_visual_integration() -> void:
	var generated_tiles: int = board_tiles_root.get_child_count()
	if generated_tiles <= 0:
		push_error(
			"FASE 19 VISUAL ERROR: Board3DPrototype esta instanciado, pero no genero losetas visibles."
		)
		return

	if not board_camera.is_current():
		board_camera.make_current()

	print(
		"FASE 19 VISUAL: Board3DPrototype + GameHUD conectados; ",
		generated_tiles,
		" losetas 3D generadas y camara activa."
	)


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
			var manager: KarmanyTurnManager = board_prototype.turn_manager
			if manager.end_turn():
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
