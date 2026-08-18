extends Node


class Phase453FixtureSession:
	extends KarmanyFullMatchHumanCombatChoiceSession

	var execution_count: int = 0
	var captured_candidate: KarmanyAiActionCandidate = null

	func _execute_candidate(
		_player: KarmanyPlayerState,
		candidate: KarmanyAiActionCandidate
	) -> bool:
		execution_count += 1
		captured_candidate = candidate
		if runtime == null or runtime.local_session == null:
			return false
		return runtime.local_session.turn_manager.spend_action_for(
			&"phase45_3_fixture_combat",
			1
		)


var _failures: Array[String] = []
var _action_request_serial: int = 45300


func _ready() -> void:
	_test_request_core_none_exact_and_one_shot()
	_test_beast_action_waits_and_filters_context()
	_test_no_resonance_executes_without_legacy_auto_pick()
	_test_pvp_keeps_ai_defender_and_uses_human_attacker_choice()
	_test_legacy_compatibility_surface()

	if _failures.is_empty():
		print("FASE 45.3 OK - combate humano espera Resonancia/ninguna, aplica contexto Bestia/PvP y conserva rutas legacy/IA.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_request_core_none_exact_and_one_shot() -> void:
	var r01 := _fixture_card(&"R-01", "Impulso Luminico", 4)
	var r37 := _fixture_card(&"R-37", "Instinto de Caza", 0)
	var cards: Array[KarmanyResonanceData] = [r01, r37]
	var request := KarmanyCombatResonanceChoiceRequest.new()
	_expect(
		request.configure(
			1,
			&"player_1",
			2,
			2,
			KarmanyAiActionCandidate.ActionType.FIGHT_BEAST,
			"Bestia fixture",
			Vector2i(1, 0),
			cards,
			cards
		),
		"CORE: la solicitud rechazo Resonancias de combate validas."
	)
	var options := request.get_options()
	_expect(options.size() == 3, "CORE: deben existir Sin Resonancia + dos cartas.")
	if options.size() != 3:
		return
	_expect(bool(options[0].get("is_none", false)), "CORE: la primera opcion no es Sin Resonancia.")
	_expect(
		StringName(options[0].get("resonance_id", "forged")) == &"",
		"CORE: Sin Resonancia expuso un ID de carta."
	)
	_expect(
		not request.resolve_option(&"phase45_3_forged"),
		"CORE: un option_id inexistente fue aceptado."
	)
	_expect(not request.is_resolved(), "CORE: una opcion invalida consumio la solicitud.")
	var r37_option := _find_option_id_for_resonance(request, &"R-37")
	_expect(r37_option != &"", "CORE: no se encontro la opcion exacta R-37.")
	if r37_option == &"":
		return
	_expect(request.resolve_option(r37_option), "CORE: R-37 valida no resolvio la solicitud.")
	_expect(
		request.get_resolved_resonance_id() == &"R-37",
		"CORE: la solicitud no devolvio el ID exacto elegido."
	)
	_expect(
		not request.resolve_option(request.get_option_ids()[0]),
		"CORE: una solicitud resuelta pudo reutilizarse."
	)

	var none_request := KarmanyCombatResonanceChoiceRequest.new()
	_expect(
		none_request.configure(
			2,
			&"player_1",
			2,
			2,
			KarmanyAiActionCandidate.ActionType.FIGHT_BEAST,
			"Bestia fixture sin Resonancia",
			Vector2i.ZERO,
			cards,
			cards
		),
		"CORE: no se pudo crear solicitud para validar Sin Resonancia."
	)
	var none_id := _find_none_option_id(none_request)
	_expect(none_id != &"", "CORE: no se encontro option_id de Sin Resonancia.")
	if none_id != &"":
		_expect(none_request.resolve_option(none_id), "CORE: Sin Resonancia no fue aceptada.")
		_expect(
			none_request.get_resolved_resonance_id() == &"",
			"CORE: Sin Resonancia devolvio una carta inesperada."
		)
	print("F45.3 CORE | Sin Resonancia + carta exacta; option_id invalido no consume y resolucion es one-shot.")


func _test_beast_action_waits_and_filters_context() -> void:
	var context := _new_fixture_session(451301, "BEAST")
	if context.is_empty():
		return
	var runtime: KarmanyMultiAiAlphaRuntime = context.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session: Phase453FixtureSession = context.get("session", null) as Phase453FixtureSession
	if runtime == null or session == null:
		_failures.append("FASE 45.3 TEST ERROR: BEAST: fixture incompleto.")
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_failures.append("FASE 45.3 TEST ERROR: BEAST: no existe jugador activo.")
		return
	player.resonance_hand.clear()
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-01", "Impulso Luminico", 4)), "BEAST: no se agrego R-01.")
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-05", "Furia Controlada", 6, PackedStringArray(["pvp"]))), "BEAST: no se agrego R-05.")
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-37", "Instinto de Caza", 0, PackedStringArray(["bestia"]))), "BEAST: no se agrego R-37.")

	var candidate := _fixture_combat_candidate(KarmanyAiActionCandidate.ActionType.FIGHT_BEAST, "Bestia humana")
	candidate.payload["resonance_id"] = &"R-01"
	var action_option_id := _install_single_action_request(session, player, candidate)
	var budget_before: int = manager.actions_remaining
	_expect(action_option_id != &"", "BEAST: no se instalo ChoiceRequest de accion.")
	if action_option_id == &"":
		return
	_expect(
		session.resolve_human_action_choice(action_option_id),
		"BEAST: seleccionar la accion de combate no genero la subeleccion."
	)
	_expect(session.execution_count == 0, "BEAST: el combate se ejecuto antes de elegir Resonancia.")
	_expect(manager.actions_remaining == budget_before, "BEAST: se gasto accion antes de resolver Resonancia.")
	_expect(
		session.build_human_action_choice_request() == null,
		"BEAST: se ofrecio otra accion mientras la Resonancia estaba pendiente."
	)
	var request := session.get_pending_human_combat_resonance_request()
	_expect(request != null, "BEAST: no quedo CombatResonanceChoiceRequest pendiente.")
	if request == null:
		return
	_expect(_request_has_resonance(request, &"R-01"), "BEAST: R-01 generica no fue ofrecida.")
	_expect(_request_has_resonance(request, &"R-37"), "BEAST: R-37 exclusiva de Bestia no fue ofrecida.")
	_expect(not _request_has_resonance(request, &"R-05"), "BEAST: R-05 PvP fue ofrecida contra Bestia.")
	_expect(
		not session.resolve_human_combat_resonance_choice(&"phase45_3_forged"),
		"BEAST: option_id forjado resolvio la subeleccion."
	)
	_expect(session.execution_count == 0, "BEAST: una opcion invalida ejecuto combate.")
	_expect(
		session.get_pending_human_combat_resonance_request() == request,
		"BEAST: una opcion invalida consumio la solicitud pendiente."
	)
	var r37_option := _find_option_id_for_resonance(request, &"R-37")
	_expect(r37_option != &"", "BEAST: falta option_id de R-37.")
	if r37_option == &"":
		return
	_expect(
		session.resolve_human_combat_resonance_choice(r37_option),
		"BEAST: R-37 valida no completo la accion."
	)
	_expect(session.execution_count == 1, "BEAST: el executor no se llamo exactamente una vez.")
	_expect(manager.actions_remaining == budget_before - 1, "BEAST: la accion no consumio exactamente 1 presupuesto.")
	_expect(session.captured_candidate != null, "BEAST: no se capturo candidato ejecutado.")
	if session.captured_candidate != null:
		_expect(
			StringName(session.captured_candidate.payload.get("resonance_id", "")) == &"R-37",
			"BEAST: el candidato no recibio exactamente la Resonancia humana elegida."
		)
	_expect(
		session.get_pending_human_combat_resonance_request() == null,
		"BEAST: la solicitud resuelta siguio pendiente."
	)
	print("F45.3 BEAST | accion espera; R-01/R-37 legales, R-05 excluida; R-37 elegida llega al executor exacto.")


func _test_no_resonance_executes_without_legacy_auto_pick() -> void:
	var context := _new_fixture_session(451302, "NONE")
	if context.is_empty():
		return
	var runtime: KarmanyMultiAiAlphaRuntime = context.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session: Phase453FixtureSession = context.get("session", null) as Phase453FixtureSession
	if runtime == null or session == null:
		return
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return
	player.resonance_hand.clear()
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-01", "Impulso Luminico", 4)), "NONE: no se agrego R-01.")
	var candidate := _fixture_combat_candidate(KarmanyAiActionCandidate.ActionType.BOND_COMBAT, "Vinculo humano")
	candidate.payload["resonance_id"] = &"R-01"
	var action_option_id := _install_single_action_request(session, player, candidate)
	if action_option_id == &"":
		return
	_expect(session.resolve_human_action_choice(action_option_id), "NONE: la accion no genero subeleccion.")
	var request := session.get_pending_human_combat_resonance_request()
	_expect(request != null, "NONE: no existe solicitud pendiente.")
	if request == null:
		return
	var none_id := _find_none_option_id(request)
	_expect(none_id != &"", "NONE: no existe opcion Sin Resonancia.")
	if none_id == &"":
		return
	_expect(
		session.resolve_human_combat_resonance_choice(none_id),
		"NONE: Sin Resonancia no completo la accion."
	)
	_expect(session.execution_count == 1, "NONE: executor no se llamo una vez.")
	if session.captured_candidate != null:
		_expect(
			not session.captured_candidate.payload.has("resonance_id"),
			"NONE: sobrevivio la Resonancia automatica preconstruida del candidato."
		)
	print("F45.3 NONE | elegir Sin Resonancia elimina la auto-seleccion legacy antes de ejecutar.")


func _test_pvp_keeps_ai_defender_and_uses_human_attacker_choice() -> void:
	var context := _new_fixture_session(451303, "PVP")
	if context.is_empty():
		return
	var runtime: KarmanyMultiAiAlphaRuntime = context.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session: Phase453FixtureSession = context.get("session", null) as Phase453FixtureSession
	if runtime == null or session == null:
		return
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return
	player.resonance_hand.clear()
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-01", "Impulso Luminico", 4)), "PVP: no se agrego R-01.")
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-05", "Furia Controlada", 6, PackedStringArray(["pvp"]))), "PVP: no se agrego R-05.")
	_expect(player.resonance_hand.add_card(_fixture_card(&"R-37", "Instinto de Caza", 0, PackedStringArray(["bestia"]))), "PVP: no se agrego R-37.")
	var candidate := _fixture_combat_candidate(KarmanyAiActionCandidate.ActionType.PVP, "PvP humano")
	candidate.payload["attacker_resonance_id"] = &"R-01"
	candidate.payload["defender_resonance_id"] = &"R-01"
	var action_option_id := _install_single_action_request(session, player, candidate)
	if action_option_id == &"":
		return
	_expect(session.resolve_human_action_choice(action_option_id), "PVP: la accion no genero subeleccion.")
	var request := session.get_pending_human_combat_resonance_request()
	_expect(request != null, "PVP: no existe solicitud pendiente.")
	if request == null:
		return
	_expect(_request_has_resonance(request, &"R-01"), "PVP: R-01 generica no fue ofrecida.")
	_expect(_request_has_resonance(request, &"R-05"), "PVP: R-05 exclusiva PvP no fue ofrecida.")
	_expect(not _request_has_resonance(request, &"R-37"), "PVP: R-37 de Bestia fue ofrecida en PvP.")
	var r05_option := _find_option_id_for_resonance(request, &"R-05")
	if r05_option == &"":
		_failures.append("FASE 45.3 TEST ERROR: PVP: falta option_id R-05.")
		return
	_expect(
		session.resolve_human_combat_resonance_choice(r05_option),
		"PVP: R-05 valida no completo la accion."
	)
	if session.captured_candidate != null:
		_expect(
			StringName(session.captured_candidate.payload.get("attacker_resonance_id", "")) == &"R-05",
			"PVP: la eleccion humana no reemplazo la Resonancia automatica del atacante."
		)
		_expect(
			StringName(session.captured_candidate.payload.get("defender_resonance_id", "")) == &"R-01",
			"PVP: F45.3 altero la Resonancia legacy del defensor IA."
		)
	print("F45.3 PVP | atacante humano elige R-05; R-37 queda fuera y la seleccion legacy del defensor IA se conserva.")


func _test_legacy_compatibility_surface() -> void:
	var session := KarmanyFullMatchSession.new()
	_expect(
		session.has_method("get_pending_human_combat_resonance_request"),
		"COMPAT: FullMatchSession no heredo el nuevo punto de decision F45.3."
	)
	_expect(
		session.has_method("execute_human_combat_with_resonance"),
		"COMPAT: desaparecio execute_human_combat_with_resonance legacy."
	)
	_expect(
		session.has_method("run_automated_current_turn"),
		"COMPAT: desaparecio el flujo automatico IA/Auto-P1."
	)
	print("F45.3 COMPAT | FullMatchSession expone ChoiceRequest nuevo y conserva helper de combate + flujo automatico legacy.")


func _new_fixture_session(seed_value: int, label: String) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("FASE 45.3 TEST ERROR: %s: no se pudo configurar runtime minimo." % label)
		return {}
	var session := Phase453FixtureSession.new()
	session.runtime = runtime
	session.match_seed = runtime.match_seed
	session.match_state = KarmanyFullMatchSessionBase.MatchState.PLAYING
	session.configured = true
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		_failures.append("FASE 45.3 TEST ERROR: %s: P1 humano no esta activo." % label)
		return {}
	return {"runtime": runtime, "session": session}


func _install_single_action_request(
	session: Phase453FixtureSession,
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> StringName:
	if session == null or player == null or candidate == null:
		return &""
	var manager := session.runtime.local_session.turn_manager
	var candidates: Array[KarmanyAiActionCandidate] = [candidate]
	var request := KarmanyChoiceRequest.new()
	_action_request_serial += 1
	if not request.configure(
		_action_request_serial,
		player.player_id,
		manager.current_round,
		manager.actions_remaining,
		candidates
	):
		return &""
	session._pending_human_choice_request = request
	var ids := request.get_option_ids()
	return ids[0] if not ids.is_empty() else &""


func _fixture_combat_candidate(action_type: int, label: String) -> KarmanyAiActionCandidate:
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = action_type
	candidate.target_coord = Vector2i(1, 0)
	candidate.debug_label = label
	return candidate


func _fixture_card(
	resonance_id: StringName,
	display_name: String,
	power: int,
	tags: PackedStringArray = PackedStringArray()
) -> KarmanyResonanceData:
	var card := KarmanyResonanceData.new()
	card.resonance_id = resonance_id
	card.display_name = display_name
	card.printed_power = power
	card.use_windows = PackedStringArray(["combat"])
	card.rules_text = "Fixture F45.3."
	card.tags = tags
	return card


func _find_none_option_id(request: KarmanyCombatResonanceChoiceRequest) -> StringName:
	if request == null:
		return &""
	for option in request.get_options():
		if bool(option.get("is_none", false)):
			return StringName(option.get("option_id", ""))
	return &""


func _find_option_id_for_resonance(
	request: KarmanyCombatResonanceChoiceRequest,
	resonance_id: StringName
) -> StringName:
	if request == null:
		return &""
	for option in request.get_options():
		if StringName(option.get("resonance_id", "")) == resonance_id:
			return StringName(option.get("option_id", ""))
	return &""


func _request_has_resonance(
	request: KarmanyCombatResonanceChoiceRequest,
	resonance_id: StringName
) -> bool:
	return _find_option_id_for_resonance(request, resonance_id) != &""


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 45.3 TEST ERROR: %s" % message)
