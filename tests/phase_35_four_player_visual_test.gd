extends Node


const PHASE_35_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_35_four_player_visual_prototype.tscn"
)
const TEST_SEED: int = 34001
const VISUAL_POSITION_TOLERANCE: float = 0.05
const CAMERA_FOCUS_TOLERANCE: float = 0.05
const TEST_PASS_ACTION_ID: StringName = &"phase35_test_pass"


var _visual_action_mismatches: int = 0
var _visual_action_seen_by_player: Dictionary = {}


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 35 FOUR PLAYER VISUAL TEST")
	print("================================")

	var ok: bool = true
	ok = _test_phase_31_to_34_regression() and ok
	var sync_ok: bool = await _test_four_player_visual_sync()
	ok = sync_ok and ok
	var ai_visual_ok: bool = await _test_visible_ai_turn_sequence()
	ok = ai_visual_ok and ok

	print("")
	print("================================")
	if ok:
		print("FASE 35 OK - cuatro jugadores visibles, movimiento sincronizado y turnos IA legibles validados.")
	else:
		push_error("FASE 35 ERROR - Revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_phase_31_to_34_regression() -> bool:
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		return _fail("F31 perdio is_fully_connected().")

	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED):
		return _fail("F34 ya no configura 1 humano + 3 IA sobre mapa 41.")
	if runtime.board_state.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("F35 altero las 41 posiciones canonicas.")
	if runtime.ai_match_controller.get_ai_controller_count() != 3:
		return _fail("F35 altero la infraestructura de 3 IA de F34.")
	if not runtime.ai_match_controller.is_human_player(&"player_1"):
		return _fail("F35 altero la identificacion explicita del humano.")

	for coord in runtime.board_state.get_coords():
		var level: int = runtime.get_public_level(coord)
		if (
			level == KarmanyTileData.TileLevel.N1
			or level == KarmanyTileData.TileLevel.N2
			or level == KarmanyTileData.TileLevel.N3
		):
			if runtime.board_state.is_revealed(coord):
				continue
			if runtime.board_state.get_tile_data(coord) != null:
				return _fail("Una loseta oculta expone KarmanyTileData tras F35.")

	print("Regresion F31-F34: mapa 41, ocultamiento y 1H+3IA: OK")
	return true


func _test_four_player_visual_sync() -> bool:
	var prototype := PHASE_35_SCENE.instantiate() as KarmanyPhase35FourPlayerVisualBridge
	if prototype == null:
		return _fail("No se pudo instanciar la escena F35.")
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame
	if not prototype.setup_ok:
		prototype.queue_free()
		return _fail("La escena F35 no completo su setup.")
	prototype.set_presentation_speed_multiplier(100.0)

	var runtime := prototype.phase_34.runtime
	var manager := runtime.local_session.turn_manager
	if runtime.local_session.players.size() != 4 or prototype.phase_34.trainer_units.size() != 4:
		prototype.queue_free()
		return _fail("F35 no conserva cuatro PlayerState y cuatro TrainerUnit3D.")

	var unit_instance_ids: Dictionary = {}
	var expected_starts := KarmanyCanonicalMap41Layout.get_starting_coords()
	for index in range(4):
		var player: KarmanyPlayerState = runtime.local_session.players[index]
		var unit := prototype.get_trainer_unit(player.player_id)
		if unit == null or unit.player_state != player:
			prototype.queue_free()
			return _fail("TrainerUnit3D no apunta al PlayerState correcto para P%d." % (index + 1))
		if unit_instance_ids.has(unit.get_instance_id()):
			prototype.queue_free()
			return _fail("Dos jugadores reutilizan la misma instancia TrainerUnit3D.")
		unit_instance_ids[unit.get_instance_id()] = true
		if player.current_coord != expected_starts[index]:
			prototype.queue_free()
			return _fail("P%d no inicia en su Inicial canonica." % (index + 1))
		if prototype.get_visual_coord(player.player_id) != player.current_coord:
			prototype.queue_free()
			return _fail("Coordenada visual inicial desincronizada para P%d." % (index + 1))
		if not _unit_is_on_anchor(prototype, player.player_id, player.current_coord):
			prototype.queue_free()
			return _fail("P%d no termina visualmente sobre su UnitAnchor inicial." % (index + 1))
		var label := unit.get_node_or_null("Phase35PlayerLabel") as Label3D
		if label == null or label.text != "P%d" % (index + 1):
			prototype.queue_free()
			return _fail("P%d no posee etiqueta flotante provisional correcta." % (index + 1))

	if prototype.get_display_active_player_id() != &"player_1":
		prototype.queue_free()
		return _fail("HUD visual no identifica P1 como turno inicial.")
	if prototype.get_display_round_number() != 1 or prototype.get_display_actions_remaining() != 2:
		prototype.queue_free()
		return _fail("HUD visual no inicia en ronda 1 / acciones 2 de P1.")
	if not prototype.is_player_halo_visible(&"player_1"):
		prototype.queue_free()
		return _fail("P1 no muestra indicador visual de turno activo.")

	var participants_text: String = prototype.get_public_participants_text()
	for expected_text in ["P1 HUMANO", "P2 EXPLORADORA", "P3 OPORTUNISTA", "P4 AGRESIVA"]:
		if not participants_text.contains(expected_text):
			prototype.queue_free()
			return _fail("Panel publico no identifica %s." % expected_text)
	for private_marker in ["MN=", "EK=", "FA=", "Resonancias", "Equipos"]:
		if participants_text.contains(private_marker):
			prototype.queue_free()
			return _fail("Panel de rivales expone informacion privada: %s." % private_marker)

	var hidden_coord: Vector2i = _find_hidden_coord(runtime)
	if hidden_coord == Vector2i(999, 999):
		prototype.queue_free()
		return _fail("No se encontro una loseta oculta para verificar HUD publico.")
	var hidden_text: String = prototype.get_public_location_text_for_coord(hidden_coord)
	if not hidden_text.contains("OCULTA"):
		prototype.queue_free()
		return _fail("HUD de ubicacion no preserva la identidad oculta.")
	if runtime.get_public_tile_data(hidden_coord) != null:
		prototype.queue_free()
		return _fail("Runtime publico expone identidad antes de explorar.")

	# Una vuelta completa modifica la coordenada de P1-P4 mediante el mismo
	# generador legal + executor/coordinator usados por la IA existente.
	for expected_index in range(4):
		var active: KarmanyPlayerState = manager.get_active_player()
		var expected: KarmanyPlayerState = runtime.local_session.players[expected_index]
		if active != expected:
			prototype.queue_free()
			return _fail("TurnManager no entrego turno a P%d durante sync test." % (expected_index + 1))

		var moved_ok: bool = await _execute_one_legal_travel_and_validate(
			prototype,
			expected
		)
		if not moved_ok:
			prototype.queue_free()
			return false

		var actions_after_visual: int = manager.actions_remaining
		while manager.actions_remaining > 0:
			if not manager.spend_action_for(TEST_PASS_ACTION_ID, 1):
				prototype.queue_free()
				return _fail("No se pudo consumir presupuesto restante del test para P%d." % (expected_index + 1))
		if actions_after_visual != 1:
			prototype.queue_free()
			return _fail("La accion legal no dejo exactamente 1 accion antes de animar.")
		if not runtime.coordinator.end_turn():
			prototype.queue_free()
			return _fail("Coordinator no pudo cerrar turno de P%d." % (expected_index + 1))
		await get_tree().process_frame

	if manager.current_round != 2 or manager.get_active_player() != runtime.local_session.players[0]:
		prototype.queue_free()
		return _fail("TurnManager no regreso a P1 / ronda 2 tras P4.")
	if manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		prototype.queue_free()
		return _fail("P1 no recupero 2/2 acciones al iniciar ronda 2.")

	if prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_MOVE) < 4:
		prototype.queue_free()
		return _fail("No se registraron movimientos visuales independientes para P1-P4.")

	if not prototype.center_on_human():
		prototype.queue_free()
		return _fail("Centrar en P1 no reutiliza StrategicCameraController.")
	var camera_controller := prototype.phase_34.phase_32.phase_31.camera_controller
	var p1_unit := prototype.get_trainer_unit(&"player_1")
	var camera_target: Vector3 = camera_controller.get_target()
	var camera_xz := Vector2(camera_target.x, camera_target.z)
	var p1_xz := Vector2(p1_unit.global_position.x, p1_unit.global_position.z)
	if camera_xz.distance_to(p1_xz) > CAMERA_FOCUS_TOLERANCE:
		prototype.queue_free()
		return _fail("StrategicCameraController no enfoco al humano en el plano del tablero.")

	print("Sync visual P1-P4: PlayerState, TrainerUnit3D, UnitAnchor y acciones: OK")
	prototype.queue_free()
	await get_tree().process_frame
	return true


func _test_visible_ai_turn_sequence() -> bool:
	var prototype := PHASE_35_SCENE.instantiate() as KarmanyPhase35FourPlayerVisualBridge
	if prototype == null:
		return _fail("No se pudo instanciar probe visual IA de F35.")
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame
	if not prototype.setup_ok:
		prototype.queue_free()
		return _fail("Probe IA F35 no completo setup.")
	prototype.set_presentation_speed_multiplier(100.0)
	_visual_action_mismatches = 0
	_visual_action_seen_by_player.clear()
	prototype.visual_action_started.connect(
		_on_visual_action_started.bind(prototype)
	)

	var runtime := prototype.phase_34.runtime
	var manager := runtime.local_session.turn_manager
	if not prototype.pass_human_turn_presented():
		prototype.queue_free()
		return _fail("P1 no pudo cerrar su turno de prueba.")
	if manager.get_active_player().player_id != &"player_2":
		prototype.queue_free()
		return _fail("P1 no entrego el turno a P2.")

	var expected_ai_ids: Array[StringName] = [
		&"player_2",
		&"player_3",
		&"player_4"
	]
	for expected_id in expected_ai_ids:
		if manager.get_active_player() == null or manager.get_active_player().player_id != expected_id:
			prototype.queue_free()
			return _fail("Secuencia IA visible esperaba %s." % expected_id)
		if prototype.get_display_active_player_id() != expected_id:
			prototype.queue_free()
			return _fail("Halo/HUD no identifican %s antes de su turno." % expected_id)

		var ai_turn_ok: bool = await prototype.run_current_ai_turn_presented()
		if not ai_turn_ok:
			prototype.queue_free()
			return _fail("%s no completo su turno logico + presentacion." % expected_id)

		if runtime.ai_match_controller.last_turn_player_id != expected_id:
			prototype.queue_free()
			return _fail("El replay visual se asocio a una IA distinta de la que actuo.")
		var successful_executions: int = 0
		for execution in runtime.ai_match_controller.last_turn_executions:
			if execution != null and execution.was_executed():
				successful_executions += 1
		if successful_executions > KarmanyTurnManager.ACTIONS_PER_TURN:
			prototype.queue_free()
			return _fail("%s gasto mas de 2 acciones reales." % expected_id)
		if runtime.ai_match_controller.last_turn_decision_attempts > 6:
			prototype.queue_free()
			return _fail("%s excedio el limite preventivo de decisiones F34." % expected_id)

		for player in runtime.local_session.players:
			if prototype.get_visual_coord(player.player_id) != player.current_coord:
				prototype.queue_free()
				return _fail("Tras %s, %s quedo visualmente desincronizado." % [expected_id, player.player_id])
			if not _unit_is_on_anchor(prototype, player.player_id, player.current_coord):
				prototype.queue_free()
				return _fail("Una unidad salto a la posicion visual de otro participante.")

	if manager.current_round != 2:
		prototype.queue_free()
		return _fail("Despues de P4 no comenzo ronda 2.")
	if manager.get_active_player() == null or manager.get_active_player().player_id != &"player_1":
		prototype.queue_free()
		return _fail("Despues de P4 no regreso el control a P1.")
	if manager.actions_remaining != 2:
		prototype.queue_free()
		return _fail("P1 no recupero 2/2 acciones despues del ciclo IA.")
	if prototype.get_display_active_player_id() != &"player_1" or not prototype.is_player_halo_visible(&"player_1"):
		prototype.queue_free()
		return _fail("Representacion activa no regreso visualmente a P1.")
	if prototype.get_display_round_number() != 2 or prototype.get_display_actions_remaining() != 2:
		prototype.queue_free()
		return _fail("HUD visual no regreso a ronda 2 / acciones 2 de P1.")
	if _visual_action_mismatches != 0:
		prototype.queue_free()
		return _fail("Durante un replay IA, HUD/halo mostraron un jugador o presupuesto incorrecto.")
	for expected_id in expected_ai_ids:
		if not _visual_action_seen_by_player.has(expected_id):
			prototype.queue_free()
			return _fail("No se observo ninguna accion presentada para %s." % expected_id)

	var events := prototype.get_presentation_events()
	for expected_id in expected_ai_ids:
		if not _history_has_kind_for_player(events, expected_id, "turn_started"):
			prototype.queue_free()
			return _fail("No se registro inicio visible para %s." % expected_id)
		if not _history_has_kind_for_player(events, expected_id, "turn_finished"):
			prototype.queue_free()
			return _fail("No se registro fin visible para %s." % expected_id)

	if prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_MOVE) <= 0:
		prototype.queue_free()
		return _fail("Las IA jugaron pero ningun desplazamiento fue representado visualmente.")
	if prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_REVEAL) <= 0:
		prototype.queue_free()
		return _fail("Las IA exploraron pero no hubo feedback visual de revelacion.")

	print("Turnos IA visibles: P2 -> P3 -> P4 -> P1, feedback y halos: OK")
	prototype.queue_free()
	await get_tree().process_frame
	return true


func _execute_one_legal_travel_and_validate(
	prototype: KarmanyPhase35FourPlayerVisualBridge,
	player: KarmanyPlayerState
) -> bool:
	var runtime := prototype.phase_34.runtime
	var manager := runtime.local_session.turn_manager
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		player
	)
	var selected: KarmanyAiActionCandidate = null
	for candidate in candidates:
		if candidate == null:
			continue
		if candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE:
			selected = candidate
			break
	if selected == null:
		for candidate in candidates:
			if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.MOVE:
				selected = candidate
				break
	if selected == null:
		return _fail("%s no tiene una accion normal Mover/Explorar para el sync test." % player.player_id)

	var origin: Vector2i = player.current_coord
	var actions_before: int = manager.actions_remaining
	var other_visual_positions: Dictionary = {}
	for other_player in runtime.local_session.players:
		if other_player == null or other_player == player:
			continue
		var other_unit := prototype.get_trainer_unit(other_player.player_id)
		other_visual_positions[other_player.player_id] = other_unit.global_position

	var execution := KarmanyAiActionExecutor.execute(
		runtime.coordinator,
		player,
		selected
	)
	if execution == null or not execution.was_executed():
		return _fail("Accion normal Mover/Explorar fue rechazada para %s." % player.player_id)
	if player.current_coord == origin:
		return _fail("La accion de viaje no modifico coordenada para %s." % player.player_id)
	if manager.actions_remaining != actions_before - 1:
		return _fail("Gameplay no consumio exactamente una accion antes de la animacion.")
	var actions_after_logic: int = manager.actions_remaining

	var idle_ok: bool = await prototype.wait_for_presentation_idle()
	if not idle_ok:
		return _fail("Presentacion quedo bloqueada tras mover %s." % player.player_id)
	if manager.actions_remaining != actions_after_logic:
		return _fail("La animacion gasto o devolvio acciones de gameplay.")
	if prototype.get_visual_coord(player.player_id) != player.current_coord:
		return _fail("PlayerState y coordenada visual no coinciden para %s." % player.player_id)
	if not _unit_is_on_anchor(prototype, player.player_id, player.current_coord):
		return _fail("TrainerUnit3D no termino en UnitAnchor de %s." % player.player_id)

	for other_player_id in other_visual_positions.keys():
		var other_unit := prototype.get_trainer_unit(StringName(other_player_id))
		var before: Vector3 = other_visual_positions[other_player_id]
		if other_unit.global_position.distance_to(before) > VISUAL_POSITION_TOLERANCE:
			return _fail("Mover %s altero visualmente otra unidad %s." % [player.player_id, other_player_id])
	return true


func _unit_is_on_anchor(
	prototype: KarmanyPhase35FourPlayerVisualBridge,
	player_id: StringName,
	coord: Vector2i
) -> bool:
	var unit := prototype.get_trainer_unit(player_id)
	var tile := prototype.phase_34.phase_32.phase_31.get_tile_view(coord)
	if unit == null or tile == null:
		return false
	var anchor := tile.get_node_or_null("UnitAnchor") as Marker3D
	if anchor == null:
		return false
	# El runtime Alfa actual no permite coexistencia, por lo que el offset
	# visual en las pruebas presentes es cero y el destino debe ser el anchor.
	return unit.global_position.distance_to(anchor.global_position) <= VISUAL_POSITION_TOLERANCE


func _find_hidden_coord(runtime: KarmanyMultiAiAlphaRuntime) -> Vector2i:
	for level in [
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3
	]:
		for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
			if not runtime.board_state.is_revealed(coord):
				return coord
	return Vector2i(999, 999)


func _history_has_kind_for_player(
	events: Array[Dictionary],
	player_id: StringName,
	kind: String
) -> bool:
	for event in events:
		if StringName(event.get("player_id", "")) != player_id:
			continue
		if String(event.get("kind", "")) == kind:
			return true
	return false


func _on_visual_action_started(
	player_id: StringName,
	_action_text: String,
	prototype: KarmanyPhase35FourPlayerVisualBridge
) -> void:
	_visual_action_seen_by_player[player_id] = true
	if prototype.get_display_active_player_id() != player_id:
		_visual_action_mismatches += 1
	var visible_actions: int = prototype.get_display_actions_remaining()
	if visible_actions < 0 or visible_actions > KarmanyTurnManager.ACTIONS_PER_TURN - 1:
		_visual_action_mismatches += 1
	if not prototype.is_player_halo_visible(player_id):
		_visual_action_mismatches += 1


func _fail(message: String) -> bool:
	push_error("FASE 35 ERROR: %s" % message)
	return false
