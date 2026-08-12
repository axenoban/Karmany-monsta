extends Node


var _round_started_events: Array[int] = []
var _round_ended_events: Array[int] = []
var _turn_started_events: Array[StringName] = []
var _turn_ended_events: Array[StringName] = []
var _action_events: Array[int] = []


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 4 TURN TEST")
	print("================================")

	var test_passed: bool = true
	var manager := KarmanyTurnManager.new()

	manager.round_started.connect(_on_round_started)
	manager.round_ended.connect(_on_round_ended)
	manager.turn_started.connect(_on_turn_started)
	manager.turn_ended.connect(_on_turn_ended)
	manager.action_spent.connect(_on_action_spent)

	var player_1 := KarmanyPlayerState.new()
	var player_2 := KarmanyPlayerState.new()
	var player_3 := KarmanyPlayerState.new()

	player_1.setup_new_game(&"player_1", Vector2i.ZERO)
	player_2.setup_new_game(&"player_2", Vector2i(1, 0))
	player_3.setup_new_game(&"player_3", Vector2i(0, 1))

	var players: Array[KarmanyPlayerState] = [
		player_1,
		player_2,
		player_3
	]

	if not manager.setup_players(players):
		test_passed = false
		push_error("FASE 4 ERROR: No se pudieron registrar 3 jugadores validos.")

	if manager.get_player_count() != 3:
		test_passed = false
		push_error("FASE 4 ERROR: El gestor no conserva los 3 jugadores.")

	if manager.get_player_by_id(&"player_2") != player_2:
		test_passed = false
		push_error("FASE 4 ERROR: No se pudo consultar player_2 por ID.")

	if not manager.start_match():
		test_passed = false
		push_error("FASE 4 ERROR: La partida no pudo comenzar.")

	if manager.current_round != 1:
		test_passed = false
		push_error("FASE 4 ERROR: La partida deberia comenzar en ronda 1.")

	if manager.get_active_player() != player_1:
		test_passed = false
		push_error("FASE 4 ERROR: player_1 deberia iniciar la partida.")

	if manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		test_passed = false
		push_error("FASE 4 ERROR: El turno no comenzo con 2 acciones.")

	if not manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: No se pudo gastar la primera accion.")

	if not manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: No se pudo gastar la segunda accion.")

	if manager.actions_remaining != 0:
		test_passed = false
		push_error("FASE 4 ERROR: Dos acciones gastadas deberian dejar 0 restantes.")

	if manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: Se permitio gastar una tercera accion ilegal.")

	if not manager.end_turn():
		test_passed = false
		push_error("FASE 4 ERROR: No se pudo finalizar el turno de player_1.")

	if manager.get_active_player() != player_2:
		test_passed = false
		push_error("FASE 4 ERROR: El turno deberia avanzar a player_2.")

	if manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 4 ERROR: player_2 no recibio 2 acciones nuevas.")

	# v0.74 exige exactamente 2 acciones salvo efecto explicito.
	if not manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: player_2 no pudo gastar su primera accion.")

	if manager.end_turn():
		test_passed = false
		push_error("FASE 4 ERROR: Se permitio finalizar turno con 1 accion pendiente.")

	if manager.get_active_player() != player_2:
		test_passed = false
		push_error("FASE 4 ERROR: Un fin de turno invalido cambio al jugador activo.")

	if manager.actions_remaining != 1:
		test_passed = false
		push_error("FASE 4 ERROR: El intento invalido altero las acciones restantes.")

	if not manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: player_2 no pudo gastar su segunda accion.")

	if not manager.end_turn():
		test_passed = false
		push_error("FASE 4 ERROR: No se pudo finalizar el turno completo de player_2.")

	if manager.get_active_player() != player_3:
		test_passed = false
		push_error("FASE 4 ERROR: El turno deberia avanzar a player_3.")

	if not manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: player_3 no pudo gastar su primera accion.")

	if not manager.spend_action():
		test_passed = false
		push_error("FASE 4 ERROR: player_3 no pudo gastar su segunda accion.")

	if not manager.end_turn():
		test_passed = false
		push_error("FASE 4 ERROR: No se pudo finalizar el turno de player_3.")

	if manager.current_round != 2:
		test_passed = false
		push_error("FASE 4 ERROR: Tras el ultimo jugador deberia comenzar ronda 2.")

	if manager.get_active_player() != player_1:
		test_passed = false
		push_error("FASE 4 ERROR: Ronda 2 deberia volver a player_1.")

	if manager.actions_remaining != 2:
		test_passed = false
		push_error("FASE 4 ERROR: El nuevo turno de player_1 deberia tener 2 acciones.")

	if _round_started_events != [1, 2]:
		test_passed = false
		push_error(
			"FASE 4 ERROR: Eventos round_started inesperados: %s."
			% _round_started_events
		)

	if _round_ended_events != [1]:
		test_passed = false
		push_error(
			"FASE 4 ERROR: Eventos round_ended inesperados: %s."
			% _round_ended_events
		)

	var expected_turn_starts: Array[StringName] = [
		&"player_1",
		&"player_2",
		&"player_3",
		&"player_1"
	]

	if _turn_started_events != expected_turn_starts:
		test_passed = false
		push_error(
			"FASE 4 ERROR: Secuencia de turnos inesperada: %s."
			% _turn_started_events
		)

	var expected_turn_ends: Array[StringName] = [
		&"player_1",
		&"player_2",
		&"player_3"
	]

	if _turn_ended_events != expected_turn_ends:
		test_passed = false
		push_error(
			"FASE 4 ERROR: Secuencia de fin de turno inesperada: %s."
			% _turn_ended_events
		)

	if _action_events != [1, 0, 1, 0, 1, 0]:
		test_passed = false
		push_error(
			"FASE 4 ERROR: Presupuesto de acciones inesperado: %s."
			% _action_events
		)

	# El juego base admite 2 a 4 jugadores: 1 jugador debe rechazarse.
	var invalid_manager := KarmanyTurnManager.new()
	var invalid_players: Array[KarmanyPlayerState] = [player_1]

	if invalid_manager.setup_players(invalid_players):
		test_passed = false
		push_error("FASE 4 ERROR: Se acepto una partida de solo 1 jugador.")

	print("")
	print("Jugadores: ", manager.get_player_count())
	print("Ronda actual: ", manager.current_round)
	print("Jugador activo: ", manager.get_active_player().player_id)
	print("Acciones disponibles: ", manager.actions_remaining)
	print("Secuencia de turnos: ", _turn_started_events)
	print("Exactamente 2 acciones por turno: OK")
	print("")
	print("================================")

	if test_passed:
		print("FASE 4 OK - Turnos, rondas y acciones validados.")
	else:
		push_error("FASE 4 ERROR - Revisar sistema de turnos.")

	print("================================")


func _on_round_started(round_number: int) -> void:
	_round_started_events.append(round_number)


func _on_round_ended(round_number: int) -> void:
	_round_ended_events.append(round_number)


func _on_turn_started(
	player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	_turn_started_events.append(player.player_id)


func _on_turn_ended(
	player: KarmanyPlayerState,
	_round_number: int
) -> void:
	_turn_ended_events.append(player.player_id)


func _on_action_spent(
	_player: KarmanyPlayerState,
	_cost: int,
	actions_remaining: int
) -> void:
	_action_events.append(actions_remaining)
