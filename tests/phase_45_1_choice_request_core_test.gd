extends Node


var _failures: Array[String] = []


func _ready() -> void:
	_test_choice_request_exact_one_shot()
	_test_session_uses_legal_choice_request()
	_test_legacy_auto_compatibility()

	if _failures.is_empty():
		print("FASE 45.1 OK - ChoiceRequest resuelve opciones legales exactas una sola vez y bloquea selecciones invalidas/reutilizadas.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_choice_request_exact_one_shot() -> void:
	var first := KarmanyAiActionCandidate.new()
	first.action_type = KarmanyAiActionCandidate.ActionType.MOVE
	first.target_coord = Vector2i(1, 0)
	first.debug_label = "Mover fixture"

	var second := KarmanyAiActionCandidate.new()
	second.action_type = KarmanyAiActionCandidate.ActionType.EXPLORE
	second.target_coord = Vector2i(2, 0)
	second.debug_label = "Explorar fixture"

	var candidates: Array[KarmanyAiActionCandidate] = [first, second]
	var request := KarmanyChoiceRequest.new()
	_expect(
		request.configure(7, &"player_1", 3, 2, candidates),
		"CORE: ChoiceRequest rechazo candidatos fixture validos."
	)
	var options := request.get_options()
	_expect(options.size() == 2, "CORE: ChoiceRequest no expuso las dos opciones.")
	if options.size() != 2:
		return
	var first_id := StringName(options[0].get("option_id", ""))
	var second_id := StringName(options[1].get("option_id", ""))
	_expect(first_id != &"" and second_id != &"", "CORE: option_id vacio.")
	_expect(first_id != second_id, "CORE: option_id duplicado.")
	_expect(
		request.resolve_option(&"f45_1_forged") == null,
		"CORE: una opcion inexistente fue aceptada."
	)
	_expect(not request.is_resolved(), "CORE: una opcion invalida consumio la solicitud.")
	var resolved := request.resolve_option(second_id)
	_expect(resolved == second, "CORE: option_id no devolvio la instancia exacta del candidato legal.")
	_expect(request.is_resolved(), "CORE: la seleccion valida no marco la solicitud como resuelta.")
	_expect(
		request.get_resolved_option_id() == second_id,
		"CORE: no se conservo el option_id resuelto."
	)
	_expect(
		request.resolve_option(first_id) == null,
		"CORE: una ChoiceRequest resuelta pudo reutilizarse."
	)
	print("F45.1 CORE | opcion invalida no consume; opcion valida devuelve candidato exacto y es one-shot.")


func _test_session_uses_legal_choice_request() -> void:
	var context := _new_started_session(451001)
	if context.is_empty():
		return
	var runtime: KarmanyMultiAiAlphaRuntime = context.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session: KarmanyFullMatchSession = context.get("session", null) as KarmanyFullMatchSession
	if runtime == null or session == null:
		_failures.append("SESSION: fixture iniciado incompleto.")
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	_expect(player != null, "SESSION: no existe jugador activo.")
	if player == null:
		return
	_expect(
		runtime.ai_match_controller.is_human_player(player.player_id),
		"SESSION: el primer turno fixture no pertenece al jugador humano."
	)
	var request := session.build_human_action_choice_request()
	_expect(request != null, "SESSION: no se genero ChoiceRequest desde acciones legales.")
	if request == null:
		return
	var same_request := session.build_human_action_choice_request()
	_expect(
		same_request == request,
		"SESSION: consultar dos veces el mismo estado regenero candidatos/solicitud."
	)
	var options := request.get_options()
	_expect(not options.is_empty(), "SESSION: ChoiceRequest no contiene opciones legales.")
	if options.is_empty():
		return
	_expect(
		not session.resolve_human_action_choice(&"f45_1_forged"),
		"SESSION: option_id forjado fue ejecutado."
	)
	_expect(
		session.get_pending_human_choice_request() == request and not request.is_resolved(),
		"SESSION: option_id invalido consumio la solicitud pendiente."
	)

	var selected_id := StringName(options[0].get("option_id", ""))
	for option in options:
		if int(option.get("action_type", -1)) == KarmanyAiActionCandidate.ActionType.EXPLORE:
			selected_id = StringName(option.get("option_id", ""))
			break
	var actions_before: int = int(session.statistics.get("actions", 0))
	_expect(selected_id != &"", "SESSION: no se pudo seleccionar option_id legal.")
	if selected_id == &"":
		return
	var success: bool = session.resolve_human_action_choice(selected_id)
	_expect(success, "SESSION: el candidato legal elegido no fue ejecutado por el executor existente.")
	_expect(
		session.get_pending_human_choice_request() == null,
		"SESSION: la solicitud resuelta siguio pendiente."
	)
	_expect(
		int(session.statistics.get("actions", 0)) == actions_before + 1,
		"SESSION: la ejecucion valida no actualizo statistics.actions exactamente una vez."
	)
	_expect(
		not session.resolve_human_action_choice(selected_id),
		"SESSION: se pudo reutilizar el option_id despues de resolver la solicitud."
	)
	print("F45.1 SESSION | acciones legales -> ChoiceRequest -> option_id exacto -> executor existente; replay rechazado.")


func _test_legacy_auto_compatibility() -> void:
	var session := KarmanyFullMatchSession.new()
	_expect(
		session.has_method("execute_human_special"),
		"COMPAT: desaparecio execute_human_special legacy."
	)
	_expect(
		session.has_method("run_automated_current_turn"),
		"COMPAT: desaparecio el flujo automatico usado por Auto P1/IA."
	)
	_expect(
		session.has_method("finish_human_turn_if_ready"),
		"COMPAT: desaparecio finish_human_turn_if_ready."
	)
	print("F45.1 COMPAT | execute_human_special y flujo automatico existente permanecen disponibles.")


func _new_started_session(seed_value: int) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("SESSION: seed %d no pudo crear runtime." % seed_value)
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_failures.append(
			"SESSION: seed %d no pudo configurar FullMatchSession: %s"
			% [seed_value, session.last_error]
		)
		return {}
	if not session.start_playing():
		_failures.append("SESSION: seed %d no pudo entrar a PLAYING." % seed_value)
		return {}
	return {"runtime": runtime, "session": session}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 45.1 TEST ERROR: %s" % message)
