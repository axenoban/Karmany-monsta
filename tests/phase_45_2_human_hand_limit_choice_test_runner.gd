extends "res://tests/phase_45_2_human_hand_limit_choice_test.gd"


func _ready() -> void:
	_test_multi_discard_request_core()
	_test_explicit_human_turn_waits_for_discard_choice()
	_test_legacy_auto_discard_compatibility()

	if _failures.is_empty():
		print("FASE 45.2 OK - limite de mano humano queda pendiente hasta seleccionar Resonancias exactas; flujo legacy conserva auto-descarte.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_legacy_auto_discard_compatibility() -> void:
	# Esta regresion no necesita repetir el setup F38 completo. El comportamiento
	# legacy que se protege vive en FullMatchActionCoreSession y solo depende de
	# runtime/coordinator/turn manager/resonance deck ya configurados por F24/F37.
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, 451002):
		_failures.append("FASE 45.2 TEST ERROR: COMPAT: runtime minimo no pudo configurarse.")
		return

	var session := KarmanyFullMatchSession.new()
	session.runtime = runtime
	session.match_seed = runtime.match_seed
	session.match_state = KarmanyFullMatchSessionBase.MatchState.PLAYING
	session.configured = true

	var manager := runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		_failures.append("FASE 45.2 TEST ERROR: COMPAT: TurnManager minimo no esta activo.")
		return
	var player := manager.get_active_player()
	if player == null:
		_failures.append("FASE 45.2 TEST ERROR: COMPAT: no existe jugador activo.")
		return
	_expect(
		runtime.ai_match_controller.is_human_player(player.player_id),
		"COMPAT: el jugador activo inicial del runtime minimo no es humano."
	)

	var hand_limit: int = player.resonance_hand.get_hand_limit()
	if not _fill_hand_to_count(runtime, player, hand_limit + 1):
		_failures.append("FASE 45.2 TEST ERROR: COMPAT: no se pudo preparar overflow legacy de 1.")
		return
	var discard_before: int = runtime.resonance_deck.get_discard_count()
	var original_player_id: StringName = player.player_id
	while manager.actions_remaining > 0:
		if not manager.spend_action_for(&"phase45_2_legacy_budget", 1):
			_failures.append("FASE 45.2 TEST ERROR: COMPAT: no se pudo agotar presupuesto fixture.")
			return

	_expect(
		session.finish_human_turn_if_ready(),
		"COMPAT: finish_human_turn_if_ready dejo de resolver el descarte automatico legacy."
	)
	_expect(player.get_resonance_count() == hand_limit, "COMPAT: auto-descarte legacy no regreso al limite.")
	_expect(
		runtime.resonance_deck.get_discard_count() == discard_before + 1,
		"COMPAT: auto-descarte legacy no envio exactamente una carta al descarte."
	)
	_expect(
		manager.get_active_player() != null and manager.get_active_player().player_id != original_player_id,
		"COMPAT: finish_human_turn_if_ready no avanzo el turno."
	)
	print("F45.2 COMPAT | finish_human_turn_if_ready conserva auto-descarte legacy con fixture minimo estable.")
