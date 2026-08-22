extends Node


var _failures: Array[String] = []


func _ready() -> void:
	_test_action_request_surface()
	_test_aeterna_reward_and_followup_surface()
	_test_aeterna_defeat_resource_surface()
	if _failures.is_empty():
		print("FASE 46 CHOICE ROUTER OK - acciones y consecuencias humanas de Aeterna llegan al HUD sin ejecutar decisiones automaticas de P1.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_action_request_surface() -> void:
	var fixture := _new_fixture(460201, "ACTION")
	if fixture.is_empty():
		return
	var session := fixture.get("session", null) as KarmanyFullMatchSession
	var router := KarmanyPhase46ChoiceRouter.new()
	_expect(router.configure(session), "ACTION: router no configuro.")
	var choice := router.get_pending_choice()
	var options: Array = choice.get("options", [])
	_expect(int(choice.get("kind", -1)) == KarmanyPhase46ChoiceRouter.ChoiceKind.ACTION, "ACTION: no presento ChoiceRequest legal.")
	_expect(int(choice.get("required_count", 0)) == 1, "ACTION: cantidad requerida incorrecta.")
	_expect(not options.is_empty(), "ACTION: no hay opciones visibles.")
	for row_value in options:
		var row: Dictionary = row_value
		_expect(not String(row.get("label", "")).is_empty(), "ACTION: opcion sin etiqueta legible.")


func _test_aeterna_reward_and_followup_surface() -> void:
	var fixture := _new_fixture(460202, "AETERNA REWARD")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as KarmanyFullMatchSession
	var player := runtime.local_session.turn_manager.get_active_player()
	session._pending_human_choice_request = null
	var result := KarmanyAeternaResult.new()
	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.COMBAT_VICTORY
	result.reward_choice_required = true
	session._explicit_human_aeterna_in_progress = true
	session._resolve_aeterna_post_result(player, result)
	session._explicit_human_aeterna_in_progress = false

	var router := KarmanyPhase46ChoiceRouter.new()
	_expect(router.configure(session), "AETERNA REWARD: router no configuro.")
	var choice := router.get_pending_choice()
	_expect(int(choice.get("kind", -1)) == KarmanyPhase46ChoiceRouter.ChoiceKind.AETERNA_REWARD, "AETERNA REWARD: no priorizo recompensa pendiente.")
	var option_ids: Array[StringName] = []
	var reward_options: Array = choice.get("options", [])
	for row_value in reward_options:
		var row: Dictionary = row_value
		option_ids.append(StringName(row.get("option_id", "")))
	_expect(option_ids.has(KarmanyAeternaRewardChoiceRequest.OPTION_RESONANCES), "AETERNA REWARD: falta opcion reglamentaria de Resonancias.")
	if not option_ids.has(KarmanyAeternaRewardChoiceRequest.OPTION_RESONANCES):
		return
	var selected: Array[StringName] = [KarmanyAeternaRewardChoiceRequest.OPTION_RESONANCES]
	_expect(router.resolve_choice(KarmanyPhase46ChoiceRouter.ChoiceKind.AETERNA_REWARD, selected), "AETERNA REWARD: HUD no pudo resolver recompensa elegida.")
	var followup := router.get_pending_choice()
	var followup_options: Array = followup.get("options", [])
	_expect(int(followup.get("kind", -1)) == KarmanyPhase46ChoiceRouter.ChoiceKind.AETERNA_RESONANCE_DISCARD, "AETERNA REWARD: no mostro descarte de 1 de las 3 robadas.")
	_expect(int(followup.get("required_count", 0)) == 1, "AETERNA REWARD: descarte posterior no requiere exactamente 1.")
	_expect(followup_options.size() == 3, "AETERNA REWARD: HUD no limita opciones a las 3 Resonancias nuevas.")


func _test_aeterna_defeat_resource_surface() -> void:
	var fixture := _new_fixture(460203, "AETERNA DEFEAT")
	if fixture.is_empty():
		return
	var runtime := fixture.get("runtime", null) as KarmanyMultiAiAlphaRuntime
	var session := fixture.get("session", null) as KarmanyFullMatchSession
	var player := runtime.local_session.turn_manager.get_active_player()
	player.mn = 2
	player.mr = 1
	player.ek = 0
	session._pending_human_choice_request = null
	var result := KarmanyAeternaResult.new()
	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.COMBAT_DEFEAT
	result.basic_resources_discard_pending = 2
	session._explicit_human_aeterna_in_progress = true
	session._resolve_aeterna_post_result(player, result)
	session._explicit_human_aeterna_in_progress = false

	var router := KarmanyPhase46ChoiceRouter.new()
	_expect(router.configure(session), "AETERNA DEFEAT: router no configuro.")
	var choice := router.get_pending_choice()
	_expect(int(choice.get("kind", -1)) == KarmanyPhase46ChoiceRouter.ChoiceKind.AETERNA_RESOURCE_DISCARD, "AETERNA DEFEAT: no mostro descarte de recursos.")
	_expect(int(choice.get("required_count", 0)) == 2, "AETERNA DEFEAT: no pide exactamente dos recursos disponibles.")
	_expect(bool(choice.get("allow_repeated_options", false)), "AETERNA DEFEAT: HUD no permite elegir dos unidades del mismo recurso cuando es legal.")
	var selected: Array[StringName] = [
		StringName("aeterna_resource:%d" % KarmanyEffectData.ResourceType.MN),
		StringName("aeterna_resource:%d" % KarmanyEffectData.ResourceType.MR),
	]
	_expect(router.resolve_choice(KarmanyPhase46ChoiceRouter.ChoiceKind.AETERNA_RESOURCE_DISCARD, selected), "AETERNA DEFEAT: seleccion legal no resolvio.")
	_expect(player.mn == 1 and player.mr == 0, "AETERNA DEFEAT: el HUD no aplico exactamente la seleccion del jugador.")


func _new_fixture(seed_value: int, label: String) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("%s: runtime MAP41 no configuro." % label)
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_failures.append("%s: FullMatchSession no configuro: %s" % [label, session.last_error])
		return {}
	if not session.start_playing():
		_failures.append("%s: no inicio PLAYING." % label)
		return {}
	return {"runtime": runtime, "session": session}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 46 CHOICE ROUTER ERROR: %s" % message)
