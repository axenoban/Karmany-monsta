extends Node


var _failures: Array[String] = []


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


func _test_multi_discard_request_core() -> void:
	var cards: Array[KarmanyResonanceData] = [
		_fixture_card(&"F45-2-A", "Eco A", 1),
		_fixture_card(&"F45-2-B", "Eco B", 2),
		_fixture_card(&"F45-2-C", "Eco C", 3),
		_fixture_card(&"F45-2-D", "Eco D", 4),
	]
	var request := KarmanyResonanceDiscardChoiceRequest.new()
	_expect(
		request.configure(11, &"player_1", 2, 2, cards),
		"CORE: la solicitud rechazo cuatro Resonancias validas con descarte requerido 2."
	)
	var options := request.get_options()
	_expect(options.size() == 4, "CORE: no se expusieron las cuatro opciones de descarte.")
	if options.size() != 4:
		return
	var ids := request.get_option_ids()
	_expect(ids.size() == 4, "CORE: option_ids incompletos.")
	if ids.size() != 4:
		return
	_expect(
		StringName(options[1].get("resonance_id", "")) == cards[1].resonance_id,
		"CORE: el descriptor no conserva la identidad segura de la Resonancia."
	)

	var wrong_count: Array[StringName] = [ids[0]]
	_expect(
		request.resolve_options(wrong_count).is_empty(),
		"CORE: una seleccion con cantidad incorrecta fue aceptada."
	)
	_expect(not request.is_resolved(), "CORE: cantidad incorrecta consumio la solicitud.")

	var forged: Array[StringName] = [ids[0], &"f45_2_forged"]
	_expect(
		request.resolve_options(forged).is_empty(),
		"CORE: un option_id inexistente fue aceptado."
	)
	_expect(not request.is_resolved(), "CORE: option_id inexistente consumio la solicitud.")

	var duplicated: Array[StringName] = [ids[0], ids[0]]
	_expect(
		request.resolve_options(duplicated).is_empty(),
		"CORE: una misma opcion fue seleccionada dos veces."
	)
	_expect(not request.is_resolved(), "CORE: seleccion duplicada consumio la solicitud.")

	var valid_selection: Array[StringName] = [ids[1], ids[3]]
	var resolved_ids := request.resolve_options(valid_selection)
	_expect(resolved_ids.size() == 2, "CORE: la seleccion valida no devolvio dos Resonancias.")
	if resolved_ids.size() == 2:
		_expect(
			resolved_ids[0] == cards[1].resonance_id and resolved_ids[1] == cards[3].resonance_id,
			"CORE: la seleccion valida no devolvio los IDs exactos almacenados."
		)
	_expect(request.is_resolved(), "CORE: la seleccion valida no cerro la solicitud.")
	_expect(
		request.resolve_options(valid_selection).is_empty(),
		"CORE: la solicitud resuelta pudo reutilizarse."
	)
	print("F45.2 CORE | seleccion multiple valida devuelve IDs exactos; cantidad/ID/duplicado invalidos no consumen.")


func _test_explicit_human_turn_waits_for_discard_choice() -> void:
	var context := _new_started_session(451001, "SESSION")
	if context.is_empty():
		return
	var runtime: KarmanyMultiAiAlphaRuntime = context.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session: KarmanyFullMatchSession = context.get("session", null) as KarmanyFullMatchSession
	if runtime == null or session == null:
		_failures.append("FASE 45.2 TEST ERROR: SESSION: fixture iniciado incompleto.")
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	_expect(player != null, "SESSION: no existe jugador activo.")
	if player == null:
		return
	_expect(
		runtime.ai_match_controller.is_human_player(player.player_id),
		"SESSION: el jugador activo inicial no es humano."
	)
	var hand_limit: int = player.resonance_hand.get_hand_limit()
	_expect(hand_limit == 5, "SESSION: el runtime ya no expone limite canonico de mano 5.")
	if not _fill_hand_to_count(runtime, player, hand_limit + 2):
		_failures.append("FASE 45.2 TEST ERROR: SESSION: no se pudo preparar overflow de 2 Resonancias.")
		return

	_expect(
		manager.spend_action_for(&"phase45_2_fixture_budget", 1),
		"SESSION: no se pudo reducir el presupuesto a una accion."
	)
	_expect(manager.actions_remaining == 1, "SESSION: presupuesto fixture no quedo en 1.")
	var action_request := session.build_human_action_choice_request()
	_expect(action_request != null, "SESSION: no se genero ChoiceRequest de accion con presupuesto 1.")
	if action_request == null:
		return
	var action_options := action_request.get_options()
	_expect(not action_options.is_empty(), "SESSION: no existen opciones legales para cerrar el presupuesto.")
	if action_options.is_empty():
		return
	var selected_action_id := StringName(action_options[0].get("option_id", ""))
	for option in action_options:
		if int(option.get("action_type", -1)) == KarmanyAiActionCandidate.ActionType.EXPLORE:
			selected_action_id = StringName(option.get("option_id", ""))
			break
	_expect(selected_action_id != &"", "SESSION: no se obtuvo option_id legal para la ultima accion.")
	if selected_action_id == &"":
		return
	var original_player_id: StringName = player.player_id
	var discard_before: int = runtime.resonance_deck.get_discard_count()
	_expect(
		session.resolve_human_action_choice(selected_action_id),
		"SESSION: la ultima accion humana legal no pudo ejecutarse."
	)
	_expect(manager.actions_remaining == 0, "SESSION: la ultima accion no llevo el presupuesto a 0.")
	_expect(
		manager.get_active_player() != null and manager.get_active_player().player_id == original_player_id,
		"SESSION: el turno avanzo antes de resolver el descarte humano."
	)
	_expect(
		player.get_pending_resonance_discard_count() == 2,
		"SESSION: el overflow de 2 no produjo exactamente dos descartes pendientes."
	)
	_expect(
		player.get_resonance_count() == hand_limit + 2,
		"SESSION: se auto-descartaron cartas antes de la eleccion humana."
	)
	_expect(
		session.build_human_action_choice_request() == null,
		"SESSION: se ofrecieron nuevas acciones con presupuesto agotado."
	)

	var discard_request := session.get_pending_human_resonance_discard_request()
	_expect(discard_request != null, "SESSION: no quedo solicitud humana de descarte pendiente.")
	if discard_request == null:
		return
	_expect(discard_request.required_count == 2, "SESSION: la solicitud no exige exactamente dos selecciones.")
	_expect(
		discard_request.get_option_count() == hand_limit + 2,
		"SESSION: la solicitud no representa la mano completa sin ocultar opciones."
	)
	_expect(
		session.build_human_resonance_discard_request() == discard_request,
		"SESSION: consultar el mismo estado regenero la solicitud de descarte."
	)

	var discard_option_ids := discard_request.get_option_ids()
	var invalid_selection: Array[StringName] = [discard_option_ids[0]]
	_expect(
		not session.resolve_human_resonance_discard_choice(invalid_selection),
		"SESSION: se acepto una cantidad de descartes distinta de la requerida."
	)
	_expect(
		session.get_pending_human_resonance_discard_request() == discard_request and not discard_request.is_resolved(),
		"SESSION: una seleccion invalida consumio la solicitud pendiente."
	)
	_expect(player.get_resonance_count() == hand_limit + 2, "SESSION: una seleccion invalida modifico la mano.")

	var descriptors := discard_request.get_options()
	var selected_resonance_ids: Array[StringName] = [
		StringName(descriptors[0].get("resonance_id", "")),
		StringName(descriptors[1].get("resonance_id", "")),
	]
	var valid_selection: Array[StringName] = [discard_option_ids[0], discard_option_ids[1]]
	_expect(
		session.resolve_human_resonance_discard_choice(valid_selection),
		"SESSION: la seleccion valida no resolvio descarte y cierre de turno."
	)
	_expect(player.get_resonance_count() == hand_limit, "SESSION: la mano no regreso exactamente al limite 5.")
	_expect(player.get_pending_resonance_discard_count() == 0, "SESSION: quedo descarte pendiente tras resolver.")
	_expect(
		runtime.resonance_deck.get_discard_count() == discard_before + 2,
		"SESSION: el mazo no recibio exactamente las dos Resonancias elegidas."
	)
	for resonance_id in selected_resonance_ids:
		_expect(
			not _hand_has_resonance(player, resonance_id),
			"SESSION: una Resonancia elegida sigue en la mano: %s." % String(resonance_id)
		)
	_expect(
		manager.get_active_player() != null and manager.get_active_player().player_id != original_player_id,
		"SESSION: el turno no avanzo despues de resolver el descarte requerido."
	)
	_expect(
		session.get_pending_human_resonance_discard_request() == null,
		"SESSION: la solicitud resuelta siguio pendiente."
	)
	_expect(
		not session.resolve_human_resonance_discard_choice(valid_selection),
		"SESSION: la misma seleccion pudo reutilizarse despues del cierre de turno."
	)
	print("F45.2 SESSION | ultima accion humana conserva turno; descarta 2 Resonancias elegidas y luego avanza.")


func _test_legacy_auto_discard_compatibility() -> void:
	var context := _new_started_session(451002, "COMPAT")
	if context.is_empty():
		return
	var runtime: KarmanyMultiAiAlphaRuntime = context.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session: KarmanyFullMatchSession = context.get("session", null) as KarmanyFullMatchSession
	if runtime == null or session == null:
		_failures.append("FASE 45.2 TEST ERROR: COMPAT: fixture iniciado incompleto.")
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_failures.append("FASE 45.2 TEST ERROR: COMPAT: no existe jugador activo.")
		return
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
	print("F45.2 COMPAT | finish_human_turn_if_ready conserva descarte automatico legacy para regresiones.")


func _fixture_card(resonance_id: StringName, display_name: String, power: int) -> KarmanyResonanceData:
	var card := KarmanyResonanceData.new()
	card.resonance_id = resonance_id
	card.display_name = display_name
	card.printed_power = power
	card.use_windows = PackedStringArray(["combat"])
	card.rules_text = "Fixture F45.2."
	return card


func _fill_hand_to_count(
	runtime: KarmanyMultiAiAlphaRuntime,
	player: KarmanyPlayerState,
	target_count: int
) -> bool:
	if runtime == null or player == null or target_count <= 0:
		return false
	if player.get_resonance_count() > target_count:
		return false
	while player.get_resonance_count() < target_count:
		if runtime.resonance_deck.draw_to_hand(player.resonance_hand, 1) != 1:
			return false
	return player.get_resonance_count() == target_count


func _hand_has_resonance(player: KarmanyPlayerState, resonance_id: StringName) -> bool:
	for card in player.get_resonance_hand():
		if card != null and card.resonance_id == resonance_id:
			return true
	return false


func _new_started_session(seed_value: int, label: String) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("FASE 45.2 TEST ERROR: %s: seed %d no pudo crear runtime." % [label, seed_value])
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_failures.append(
			"FASE 45.2 TEST ERROR: %s: seed %d no pudo configurar FullMatchSession: %s"
			% [label, seed_value, session.last_error]
		)
		return {}
	if not session.start_playing():
		_failures.append("FASE 45.2 TEST ERROR: %s: seed %d no pudo entrar a PLAYING." % [label, seed_value])
		return {}
	return {"runtime": runtime, "session": session}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 45.2 TEST ERROR: %s" % message)
