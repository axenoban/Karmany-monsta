extends Node


class Phase455ActionFixtureSession extends KarmanyFullMatchHumanAeternaSession:
	var execution_count: int = 0
	var captured_candidate: KarmanyAiActionCandidate = null

	func _execute_candidate(
		player: KarmanyPlayerState,
		candidate: KarmanyAiActionCandidate
	) -> bool:
		if player == null or candidate == null:
			return false
		if candidate.action_type != KarmanyAiActionCandidate.ActionType.AETERNA:
			return false
		if runtime == null or runtime.local_session == null:
			return false
		var manager := runtime.local_session.turn_manager
		if manager == null or manager.get_active_player() != player:
			return false
		if not manager.spend_action_for(&"phase45_5_fixture_aeterna", 1):
			return false
		execution_count += 1
		captured_candidate = candidate
		var result := KarmanyAeternaResult.new()
		result.status = KarmanyAeternaResult.Status.RESOLVED
		result.outcome = KarmanyAeternaResult.Outcome.COMBAT_VICTORY
		result.reward_choice_required = true
		_resolve_aeterna_post_result(player, result)
		return true


var _failures: Array[String] = []
var _action_request_serial: int = 455500


func _ready() -> void:
	_test_action_to_post_choice_lifecycle()
	_test_victory_resonance_reward_lifecycle()
	_test_defeat_resource_lifecycle()
	if _failures.is_empty():
		print("FASE 45.5 FLOW OK - accion Aeterna atraviesa Instinto y bloquea nuevas acciones hasta resolver recompensa o descartes.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_action_to_post_choice_lifecycle() -> void:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, 455500):
		_failures.append("ACTION FLOW: no se pudo configurar runtime minimo.")
		return
	var session := Phase455ActionFixtureSession.new()
	session.runtime = runtime
	session.match_seed = runtime.match_seed
	session.match_state = KarmanyFullMatchSessionBase.MatchState.PLAYING
	session.configured = true
	session._action_rng.seed = session._derive_seed(455500, 455077)
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		_failures.append("ACTION FLOW: P1 humano no esta activo.")
		return
	player.resonance_hand.clear()

	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.AETERNA
	candidate.target_coord = player.current_coord
	candidate.debug_label = "Combatir Aeterna Draconis"
	candidate.payload["instinct_roll"] = 6
	var option_id := _install_single_action_request(session, player, candidate)
	if option_id == &"":
		_failures.append("ACTION FLOW: no se pudo instalar ChoiceRequest de accion.")
		return
	var budget_before: int = manager.actions_remaining

	_expect(session.resolve_human_action_choice(option_id), "ACTION FLOW: declarar Aeterna no abrio Instinto.")
	_expect(session.execution_count == 0, "ACTION FLOW: ejecuto Aeterna antes de Instinto.")
	_expect(manager.actions_remaining == budget_before, "ACTION FLOW: gasto accion antes de Instinto.")
	_expect(int(candidate.payload.get("instinct_roll", -1)) == 0, "ACTION FLOW: sobrevivio la tirada automatica preconstruida.")
	_expect(session.get_pending_human_instinct_roll_request() != null, "ACTION FLOW: falta InstinctRollRequest de Aeterna.")
	_expect(session.build_human_action_choice_request() == null, "ACTION FLOW: ofrecio otra accion con Instinto pendiente.")

	_expect(session.resolve_human_instinct_roll(), "ACTION FLOW: no resolvio Instinto humano.")
	var applied_roll: int = int(candidate.payload.get("instinct_roll", 0))
	_expect(applied_roll >= 1 and applied_roll <= 6, "ACTION FLOW: no inyecto un D6 valido.")
	_expect(session.execution_count == 1, "ACTION FLOW: sin Resonancias no ejecuto exactamente una vez tras Instinto.")
	_expect(manager.actions_remaining == budget_before - 1, "ACTION FLOW: Aeterna no consumio exactamente una accion.")
	_expect(session.get_pending_human_aeterna_reward_request() != null, "ACTION FLOW: victoria fixture no abrio recompensa humana.")
	_expect(session.build_human_action_choice_request() == null, "ACTION FLOW: ofrecio nueva accion con recompensa de Aeterna pendiente.")
	if session.captured_candidate != null:
		_expect(
			int(session.captured_candidate.payload.get("instinct_roll", 0)) == applied_roll,
			"ACTION FLOW: executor no recibio la tirada humana fijada."
		)
	print("F45.5 ACTION FLOW | ChoiceRequest -> Instinto -> ejecucion -> recompensa pendiente; sin gasto prematuro.")


func _test_victory_resonance_reward_lifecycle() -> void:
	var fixture := _new_fixture(455501, "VICTORY")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as KarmanyFullMatchHumanAeternaSession
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		_failures.append("VICTORY: no existe jugador activo.")
		return

	# La recompensa dice roba 3 y conserva 2. Una carta que ya estaba en mano
	# no puede usarse como descarte para conservar las tres cartas nuevas.
	_expect(
		runtime.resonance_deck.draw_to_hand(player.resonance_hand, 1) == 1,
		"VICTORY: no pudo preparar una Resonancia previa a la recompensa."
	)
	var old_hand := player.get_resonance_hand()
	if old_hand.is_empty():
		_failures.append("VICTORY: falta Resonancia previa tras preparacion.")
		return
	var old_resonance_id: StringName = old_hand[0].resonance_id

	var result := KarmanyAeternaResult.new()
	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.COMBAT_VICTORY
	result.reward_choice_required = true

	session._explicit_human_aeterna_in_progress = true
	session._resolve_aeterna_post_result(player, result)
	session._explicit_human_aeterna_in_progress = false
	var reward_request := session.get_pending_human_aeterna_reward_request()
	_expect(reward_request != null, "VICTORY: no abrio ChoiceRequest de recompensa.")
	_expect(session.build_human_action_choice_request() == null, "VICTORY: ofrecio otra accion con recompensa pendiente.")
	if reward_request == null:
		return
	_expect(reward_request.has_resonance_option(), "VICTORY: runtime fixture no ofrece recompensa de Resonancias.")
	var hand_before: int = player.get_resonance_count()
	_expect(
		session.resolve_human_aeterna_reward_choice(KarmanyAeternaRewardChoiceRequest.OPTION_RESONANCES),
		"VICTORY: no resolvio opcion de Resonancias."
	)
	var discard_request := session.get_pending_human_aeterna_resonance_discard_request()
	_expect(discard_request != null, "VICTORY: no pidio elegir la Resonancia a descartar.")
	_expect(player.get_resonance_count() == hand_before + 3, "VICTORY: no robo exactamente 3 antes del descarte.")
	if discard_request == null:
		return
	var options := discard_request.get_options()
	_expect(options.size() == 3, "VICTORY: el descarte debe ofrecer exactamente las 3 Resonancias recien robadas.")
	for option in options:
		_expect(
			StringName(option.get("resonance_id", "")) != old_resonance_id,
			"VICTORY: permitio descartar una Resonancia previa para conservar las 3 nuevas."
		)
	var ids := discard_request.get_option_ids()
	_expect(not ids.is_empty(), "VICTORY: descarte de Resonancia no tiene opciones.")
	if ids.is_empty():
		return
	var selected: Array[StringName] = [ids[0]]
	_expect(
		session.resolve_human_aeterna_resonance_discard_choice(selected),
		"VICTORY: no resolvio descarte humano de una Resonancia nueva."
	)
	_expect(player.get_resonance_count() == hand_before + 2, "VICTORY: no conservo exactamente 2 de las 3 robadas netas.")
	_expect(
		player.resonance_hand.get_card_by_id(old_resonance_id) != null,
		"VICTORY: la Resonancia previa desaparecio durante la recompensa."
	)
	_expect(not session._has_pending_human_aeterna_post_choice(), "VICTORY: quedo una consecuencia fantasma pendiente.")
	print("F45.5 FLOW VICTORY | recompensa -> roba 3 -> P1 descarta 1 de esas 3 -> conserva 2 -> desbloqueo.")


func _test_defeat_resource_lifecycle() -> void:
	var fixture := _new_fixture(455502, "DEFEAT")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as KarmanyFullMatchHumanAeternaSession
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		_failures.append("DEFEAT: no existe jugador activo.")
		return
	player.mn = 2
	player.mr = 1
	player.ek = 0
	var result := KarmanyAeternaResult.new()
	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.COMBAT_DEFEAT
	result.basic_resources_discard_pending = 2

	session._explicit_human_aeterna_in_progress = true
	session._resolve_aeterna_post_result(player, result)
	session._explicit_human_aeterna_in_progress = false
	var request := session.get_pending_human_aeterna_resource_discard_request()
	_expect(request != null, "DEFEAT: no abrio solicitud de recursos.")
	_expect(session.finish_human_turn_if_ready() == false, "DEFEAT: permitio terminar turno con descarte pendiente.")
	if request == null:
		return
	var selected: Array[int] = [KarmanyEffectData.ResourceType.MN, KarmanyEffectData.ResourceType.MR]
	_expect(session.resolve_human_aeterna_resource_discard_choice(selected), "DEFEAT: no acepto descarte legal elegido por P1.")
	_expect(player.mn == 1 and player.mr == 0, "DEFEAT: cantidades finales no coinciden con seleccion humana.")
	_expect(not session._has_pending_human_aeterna_post_choice(), "DEFEAT: quedo consecuencia pendiente tras resolver recursos.")
	print("F45.5 FLOW DEFEAT | P1 elige recursos -> se aplican exactamente -> desbloqueo.")


func _install_single_action_request(
	session: Phase455ActionFixtureSession,
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
	if ids.size() != 1:
		return &""
	return ids[0]


func _new_fixture(seed_value: int, label: String) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("%s: no se pudo configurar runtime minimo." % label)
		return {}
	var session := KarmanyFullMatchHumanAeternaSession.new()
	session.runtime = runtime
	session.match_seed = runtime.match_seed
	session.match_state = KarmanyFullMatchSessionBase.MatchState.PLAYING
	session.configured = true
	session._action_rng.seed = session._derive_seed(seed_value, 455077)
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		_failures.append("%s: P1 humano no esta activo." % label)
		return {}
	return {"runtime": runtime, "session": session}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 45.5 FLOW TEST ERROR: %s" % message)
