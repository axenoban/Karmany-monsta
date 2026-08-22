extends Node


var _failures: Array[String] = []


func _ready() -> void:
	_test_victory_resonance_reward_lifecycle()
	_test_defeat_resource_lifecycle()
	if _failures.is_empty():
		print("FASE 45.5 FLOW OK - consecuencias de Aeterna bloquean nuevas acciones hasta que P1 resuelve recompensa o descartes.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


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
	var ids := discard_request.get_option_ids()
	_expect(not ids.is_empty(), "VICTORY: descarte de Resonancia no tiene opciones.")
	if ids.is_empty():
		return
	var selected: Array[StringName] = [ids[0]]
	_expect(
		session.resolve_human_aeterna_resonance_discard_choice(selected),
		"VICTORY: no resolvio descarte humano de una Resonancia."
	)
	_expect(player.get_resonance_count() == hand_before + 2, "VICTORY: no conservo exactamente 2 de las 3 robadas netas.")
	_expect(not session._has_pending_human_aeterna_post_choice(), "VICTORY: quedo una consecuencia fantasma pendiente.")
	print("F45.5 FLOW VICTORY | recompensa -> roba 3 -> P1 descarta 1 -> desbloqueo.")


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
