extends Node


class Phase454FixtureSession extends KarmanyFullMatchHumanInstinctRollSession:
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
			&"phase45_4_fixture_combat",
			1
		)


var _failures: Array[String] = []
var _action_request_serial: int = 45400


func _ready() -> void:
	_test_request_core_roll_mapping_and_one_shot()
	_test_beast_sequence_instinct_before_resonance()
	_test_bond_sequence_rolls_then_executes_without_resonance()
	_test_pvp_never_opens_instinct_request()
	_test_full_match_compatibility_surface()

	if _failures.is_empty():
		print("FASE 45.4 OK - P1 declara PvE, lanza Instinto antes de Resonancia, PvP queda sin Instinto y legacy/IA conserva su ruta.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_request_core_roll_mapping_and_one_shot() -> void:
	var request := KarmanyInstinctRollRequest.new()
	_expect(
		request.configure(
			1,
			&"player_1",
			2,
			2,
			KarmanyAiActionCandidate.ActionType.FIGHT_BEAST,
			"Bestia fixture",
			Vector2i(1, 0)
		),
		"CORE: no se pudo configurar solicitud de Instinto para Bestia."
	)
	_expect(not request.resolve_roll(0), "CORE: acepto una tirada menor que 1.")
	_expect(not request.resolve_roll(7), "CORE: acepto una tirada mayor que 6.")
	_expect(not request.is_resolved(), "CORE: una tirada invalida consumio la solicitud.")
	_expect(request.resolve_roll(1), "CORE: no acepto una tirada D6 valida.")
	_expect(request.get_roll_value() == 1, "CORE: no conservo la tirada exacta.")
	_expect(request.get_defense_adjustment() == -2, "CORE: cara 1 no produjo -2 Defensa.")
	_expect(not request.resolve_roll(6), "CORE: una solicitud resuelta pudo reutilizarse.")

	var pvp_request := KarmanyInstinctRollRequest.new()
	_expect(
		not pvp_request.configure(
			2,
			&"player_1",
			2,
			2,
			KarmanyAiActionCandidate.ActionType.PVP,
			"PvP fixture",
			Vector2i.ZERO
		),
		"CORE: se permitio Dado de Instinto en PvP."
	)
	var aeterna_request := KarmanyInstinctRollRequest.new()
	_expect(
		not aeterna_request.configure(
			3,
			&"player_1",
			8,
			2,
			KarmanyAiActionCandidate.ActionType.AETERNA,
			"Aeterna fixture",
			Vector2i.ZERO
		),
		"CORE: F45.4 adelanto la solicitud humana de Aeterna reservada para F45.5."
	)
	print("F45.4 CORE | D6 1..6, ajuste canonico, one-shot; PvP/Aeterna quedan fuera de esta frontera.")


func _test_beast_sequence_instinct_before_resonance() -> void:
	var fixture := _new_fixture_session(451401, "BEAST")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as Phase454FixtureSession
	if runtime == null or session == null:
		_failures.append("FASE 45.4 TEST ERROR: BEAST: fixture incompleto.")
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_failures.append("FASE 45.4 TEST ERROR: BEAST: no existe jugador activo.")
		return
	player.resonance_hand.clear()
	_expect(
		player.resonance_hand.add_card(_fixture_card(&"R-01", "Impulso Luminico", 4)),
		"BEAST: no se agrego R-01."
	)

	var context := KarmanyBeastCombatContext.new()
	context.instinct_roll = 6
	var candidate := _fixture_combat_candidate(
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST,
		"Bestia humana"
	)
	candidate.payload["combat_context"] = context
	candidate.payload["spawn_if_missing"] = false
	candidate.payload["resonance_id"] = &"R-01"
	var action_option_id := _install_single_action_request(session, player, candidate)
	var budget_before: int = manager.actions_remaining
	_expect(action_option_id != &"", "BEAST: no se instalo ChoiceRequest de accion.")
	if action_option_id == &"":
		return

	_expect(
		session.resolve_human_action_choice(action_option_id),
		"BEAST: declarar combate no genero solicitud de Instinto."
	)
	_expect(session.execution_count == 0, "BEAST: ejecuto combate antes de lanzar Instinto.")
	_expect(manager.actions_remaining == budget_before, "BEAST: gasto accion antes de lanzar Instinto.")
	_expect(context.instinct_roll == 0, "BEAST: sobrevivio la tirada automatica preconstruida.")
	_expect(
		session.get_pending_human_combat_resonance_request() == null,
		"BEAST: ofrecio Resonancia antes de lanzar Instinto."
	)
	var instinct_request := session.get_pending_human_instinct_roll_request()
	_expect(instinct_request != null, "BEAST: no quedo InstinctRollRequest pendiente.")
	_expect(
		session.build_human_action_choice_request() == null,
		"BEAST: ofrecio otra accion mientras Instinto estaba pendiente."
	)
	if instinct_request == null:
		return

	_expect(session.resolve_human_instinct_roll(), "BEAST: la tirada humana de Instinto no resolvio.")
	_expect(
		session.get_pending_human_instinct_roll_request() == null,
		"BEAST: la solicitud de Instinto siguio pendiente tras resolver."
	)
	_expect(context.instinct_roll >= 1 and context.instinct_roll <= 6, "BEAST: el resultado no es un D6 valido.")
	var last_result := session.get_last_human_instinct_roll_result()
	_expect(
		int(last_result.get("roll", 0)) == context.instinct_roll,
		"BEAST: resultado expuesto y contexto de combate no coinciden."
	)
	_expect(
		int(last_result.get("defense_adjustment", 99)) == KarmanyCombatResolver.get_instinct_adjustment(context.instinct_roll),
		"BEAST: ajuste de Defensa expuesto no coincide con la tabla canonica."
	)
	_expect(session.execution_count == 0, "BEAST: ejecuto antes de elegir Resonancia.")
	_expect(manager.actions_remaining == budget_before, "BEAST: gasto accion antes de elegir Resonancia.")

	var resonance_request := session.get_pending_human_combat_resonance_request()
	_expect(resonance_request != null, "BEAST: no abrio Resonancia despues de Instinto.")
	if resonance_request == null:
		return
	var none_id := _find_none_option_id(resonance_request)
	_expect(none_id != &"", "BEAST: falta opcion Sin Resonancia.")
	if none_id == &"":
		return
	_expect(
		session.resolve_human_combat_resonance_choice(none_id),
		"BEAST: Sin Resonancia no completo el combate fixture."
	)
	_expect(session.execution_count == 1, "BEAST: executor no se llamo exactamente una vez.")
	_expect(manager.actions_remaining == budget_before - 1, "BEAST: no consumio exactamente una accion.")
	if session.captured_candidate != null:
		var captured_context_value: Variant = session.captured_candidate.payload.get("combat_context", null)
		_expect(captured_context_value is KarmanyBeastCombatContext, "BEAST: candidato ejecutado perdio contexto.")
		if captured_context_value is KarmanyBeastCombatContext:
			_expect(
				(captured_context_value as KarmanyBeastCombatContext).instinct_roll == context.instinct_roll,
				"BEAST: executor no recibio la tirada humana fijada."
			)
	print("F45.4 BEAST | accion -> Instinto -> Resonancia -> ejecucion; presupuesto permanece intacto hasta resolver.")


func _test_bond_sequence_rolls_then_executes_without_resonance() -> void:
	var fixture := _new_fixture_session(451402, "BOND")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as Phase454FixtureSession
	if runtime == null or session == null:
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		return
	player.resonance_hand.clear()
	var candidate := _fixture_combat_candidate(
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT,
		"Vinculo por combate humano"
	)
	candidate.payload["instinct_roll"] = 6
	var action_option_id := _install_single_action_request(session, player, candidate)
	var budget_before: int = manager.actions_remaining
	if action_option_id == &"":
		_failures.append("FASE 45.4 TEST ERROR: BOND: no se instalo accion.")
		return

	_expect(session.resolve_human_action_choice(action_option_id), "BOND: no genero solicitud de Instinto.")
	_expect(int(candidate.payload.get("instinct_roll", -1)) == 0, "BOND: no limpio tirada automatica previa.")
	_expect(session.execution_count == 0, "BOND: ejecuto antes de Instinto.")
	_expect(session.get_pending_human_instinct_roll_request() != null, "BOND: no hay Instinto pendiente.")
	_expect(session.resolve_human_instinct_roll(), "BOND: no resolvio la tirada humana.")
	var applied_roll: int = int(candidate.payload.get("instinct_roll", 0))
	_expect(applied_roll >= 1 and applied_roll <= 6, "BOND: no inyecto una tirada D6 valida.")
	_expect(
		session.get_pending_human_combat_resonance_request() == null,
		"BOND: abrio Resonancia con mano vacia."
	)
	_expect(session.execution_count == 1, "BOND: sin Resonancias no ejecuto al terminar Instinto.")
	_expect(manager.actions_remaining == budget_before - 1, "BOND: no consumio exactamente una accion.")
	print("F45.4 BOND | vinculo por combate espera Instinto y, sin Resonancias, ejecuta inmediatamente despues.")


func _test_pvp_never_opens_instinct_request() -> void:
	var fixture := _new_fixture_session(451403, "PVP")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as Phase454FixtureSession
	if runtime == null or session == null:
		return
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return
	player.resonance_hand.clear()
	_expect(
		player.resonance_hand.add_card(_fixture_card(&"R-01", "Impulso Luminico", 4)),
		"PVP: no se agrego R-01."
	)
	var candidate := _fixture_combat_candidate(KarmanyAiActionCandidate.ActionType.PVP, "PvP humano")
	candidate.payload["attacker_resonance_id"] = &"R-01"
	var action_option_id := _install_single_action_request(session, player, candidate)
	if action_option_id == &"":
		return
	_expect(session.resolve_human_action_choice(action_option_id), "PVP: no genero decision de Resonancia.")
	_expect(
		session.get_pending_human_instinct_roll_request() == null,
		"PVP: F45.4 genero Dado de Instinto donde v0.74 lo prohibe."
	)
	_expect(
		session.get_pending_human_combat_resonance_request() != null,
		"PVP: dejo de conservar la decision de Resonancia de F45.3."
	)
	print("F45.4 PVP | conserva Resonancia humana de F45.3 y nunca crea Instinto.")


func _test_full_match_compatibility_surface() -> void:
	var session := KarmanyFullMatchSession.new()
	_expect(
		session.has_method("get_pending_human_instinct_roll_request"),
		"COMPAT: FullMatchSession no heredo la solicitud de Instinto F45.4."
	)
	_expect(
		session.has_method("resolve_human_instinct_roll"),
		"COMPAT: FullMatchSession no expone la tirada humana de Instinto."
	)
	_expect(
		session.has_method("get_pending_human_combat_resonance_request"),
		"COMPAT: desaparecio la decision de Resonancia F45.3."
	)
	_expect(
		session.has_method("run_automated_current_turn"),
		"COMPAT: desaparecio el flujo automatico IA/Auto-P1."
	)
	print("F45.4 COMPAT | FullMatchSession incorpora Instinto sin retirar F45.3 ni automatizacion legacy.")


func _new_fixture_session(seed_value: int, label: String) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("FASE 45.4 TEST ERROR: %s: no se pudo configurar runtime minimo." % label)
		return {}
	var session := Phase454FixtureSession.new()
	session.runtime = runtime
	session.match_seed = runtime.match_seed
	session.match_state = KarmanyFullMatchSessionBase.MatchState.PLAYING
	session.configured = true
	session._action_rng.seed = session._derive_seed(seed_value, 454077)
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		_failures.append("FASE 45.4 TEST ERROR: %s: P1 humano no esta activo." % label)
		return {}
	return {"runtime": runtime, "session": session}


func _install_single_action_request(
	session: Phase454FixtureSession,
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
	power: int
) -> KarmanyResonanceData:
	var card := KarmanyResonanceData.new()
	card.resonance_id = resonance_id
	card.display_name = display_name
	card.printed_power = power
	card.use_windows = PackedStringArray(["combat"])
	card.rules_text = "Fixture F45.4."
	return card


func _find_none_option_id(request: KarmanyCombatResonanceChoiceRequest) -> StringName:
	if request == null:
		return &""
	for option in request.get_options():
		if bool(option.get("is_none", false)):
			return StringName(option.get("option_id", ""))
	return &""


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 45.4 TEST ERROR: %s" % message)
