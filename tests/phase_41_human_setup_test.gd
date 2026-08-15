extends Node


const TEST_SEED: int = 41041


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 41 HUMAN SETUP TEST")
	print("================================")

	var ok: bool = _run_test()
	print("")
	print("================================")
	if ok:
		print("FASE 41 OK - setup humano privado, eleccion 1 de 3 y entrada a Ronda 1 validados.")
	else:
		push_error("FASE 41 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _run_test() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED, &"player_1"):
		return _fail("No se pudo configurar runtime 4P MAP41.")

	var flow := KarmanyHumanSetupFlow.new()
	if not flow.configure(runtime):
		return _fail("No se pudo entrar a SETUP F41: %s" % flow.last_error)
	if flow.setup_state != KarmanyHumanSetupFlow.SetupState.AWAITING_STARTING_KARMANY:
		return _fail("El flujo no comienza en SETUP antes de PLAYING.")
	if runtime.local_session.turn_manager.is_running:
		return _fail("TurnManager sigue activo mientras P1 decide el setup.")
	if runtime.local_session.turn_manager.actions_remaining != 0:
		return _fail("SETUP conserva acciones consumibles cuando deberia tener presupuesto 0.")
	if runtime.local_session.turn_manager.spend_action_for(&"phase41_forbidden_probe", 1):
		return _fail("Fue posible consumir una accion durante SETUP.")

	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	if p1 == null:
		return _fail("P1 no existe.")
	if p1.has_active_karmany() or not p1.get_linked_karmanys().is_empty():
		return _fail("P1 ya tiene Karmany antes de confirmar su decision.")

	var candidates := flow.get_human_starting_candidates(&"player_1")
	if candidates.size() != 3:
		return _fail("P1 no recibio exactamente 3 candidatos.")
	var seen: Dictionary = {}
	for candidate in candidates:
		if candidate == null or not candidate.is_starting_karmany or not candidate.is_valid_definition():
			return _fail("Uno de los 3 candidatos no es un Karmany inicial valido.")
		if seen.has(candidate.karmany_id):
			return _fail("Los 3 candidatos contienen una identidad duplicada.")
		seen[candidate.karmany_id] = true
	if not flow.get_human_starting_candidates(&"player_2").is_empty():
		return _fail("Las opciones privadas de P1 son visibles usando otro viewer.")

	var public_before := flow.get_public_setup_snapshot()
	if public_before.has("candidate_ids") or public_before.has("mission_id") or public_before.has("resonance_ids"):
		return _fail("Snapshot publico expone claves privadas de setup.")
	if flow.select_starting_candidate(-1) or flow.select_starting_candidate(3):
		return _fail("Una eleccion de indice invalido fue aceptada.")
	if flow.selected_candidate_index != -1 or p1.has_active_karmany():
		return _fail("Eleccion invalida corrompio el estado pendiente.")
	if flow.confirm_starting_candidate():
		return _fail("Confirmacion sin seleccion fue aceptada.")

	var chosen_index: int = 1
	var expected: KarmanyData = candidates[chosen_index]
	if not flow.select_starting_candidate(chosen_index):
		return _fail("No se pudo seleccionar candidato indice 1.")
	if p1.has_active_karmany():
		return _fail("Seleccionar visualmente ya vinculo un Karmany antes de confirmar.")
	if not flow.confirm_starting_candidate():
		return _fail("No se pudo confirmar candidato indice 1: %s" % flow.last_error)
	if not flow.confirmed or not flow.is_ready_to_play():
		return _fail("Setup no quedo READY_TO_PLAY tras confirmar.")

	var active := p1.get_active_karmany()
	if active == null or active.karmany_data == null or active.karmany_data.karmany_id != expected.karmany_id:
		return _fail("El candidato indice 1 no se convirtio en Karmany activo de P1.")
	if p1.get_linked_karmanys().size() != 1:
		return _fail("P1 no termino con exactamente un Karmany vinculado.")
	for candidate in candidates:
		if candidate.karmany_id == expected.karmany_id:
			continue
		for state in p1.get_linked_karmanys():
			if state.karmany_data != null and state.karmany_data.karmany_id == candidate.karmany_id:
				return _fail("Uno de los dos candidatos no elegidos quedo vinculado a P1.")

	var roster_count_before: int = p1.get_linked_karmanys().size()
	if not flow.confirm_starting_candidate():
		return _fail("La segunda confirmacion idempotente fue rechazada de forma destructiva.")
	if p1.get_linked_karmanys().size() != roster_count_before:
		return _fail("Confirmar dos veces duplico el roster de P1.")

	for player in runtime.local_session.players:
		if player == null or not player.has_active_karmany():
			return _fail("Un jugador termino setup sin Karmany inicial activo.")
		var player_active := player.get_active_karmany()
		if player_active == null or player_active.karmany_data == null or not player_active.karmany_data.is_starting_karmany:
			return _fail("Un jugador recibio un Karmany no inicial durante setup.")

	var own_mission := flow.get_private_mission_for_viewer(&"player_1", &"player_1")
	if own_mission == null:
		return _fail("P1 no puede consultar su Mision Secreta despues del setup.")
	for ai_id in [&"player_2", &"player_3", &"player_4"]:
		if flow.get_private_mission_for_viewer(&"player_1", ai_id) != null:
			return _fail("P1 puede ver la Mision Secreta de %s." % String(ai_id))
		if runtime.get_secret_mission_for_viewer(&"player_1", ai_id) != null:
			return _fail("Runtime filtro la Mision Secreta de %s hacia P1." % String(ai_id))
		if not flow.get_private_resonance_hand_for_viewer(&"player_1", ai_id).is_empty():
			return _fail("P1 puede ver la mano inicial de %s." % String(ai_id))

	var own_hand := flow.get_private_resonance_hand_for_viewer(&"player_1", &"player_1")
	if own_hand.size() < KarmanyResonanceDeck.INITIAL_HAND_SIZE:
		return _fail("P1 no recibio su mano inicial de Resonancias.")
	if flow.get_public_objectives().size() != 4:
		return _fail("Setup no termino con los 4 Objetivos Publicos MAP41.")

	var full_session := flow.get_full_session()
	if full_session == null or full_session.match_state != KarmanyFullMatchSession.MatchState.SETUP:
		return _fail("FullMatchSession no permanece en SETUP antes de iniciar partida.")
	if not _verify_ai_setup_determinism(full_session, chosen_index):
		return false
	if runtime.local_session.turn_manager.is_running:
		return _fail("TurnManager se reactivo antes del boton de iniciar partida.")
	if not flow.start_playing():
		return _fail("No se pudo entrar a PLAYING: %s" % flow.last_error)
	var manager := runtime.local_session.turn_manager
	if not manager.is_running or manager.current_round != 1:
		return _fail("Ronda 1 no comenzo al salir de SETUP.")
	if manager.get_active_player() != p1:
		return _fail("Ronda 1 no comenzo con P1.")
	if manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _fail("P1 no comienza Ronda 1 con 2 acciones.")
	if full_session.match_state != KarmanyFullMatchSession.MatchState.PLAYING:
		return _fail("FullMatchSession no cambio a PLAYING.")

	print("F41 SETUP | candidatos=%s | elegido=%s | mano=%d | mision=%s" % [
		str(_candidate_ids(candidates)),
		String(expected.karmany_id),
		own_hand.size(),
		String(own_mission.mission_id)
	])
	return true


func _verify_ai_setup_determinism(
	first_session: KarmanyFullMatchSession,
	chosen_index: int
) -> bool:
	var runtime_b := KarmanyMultiAiAlphaRuntime.new()
	if not runtime_b.configure_new(4, TEST_SEED, &"player_1"):
		return _fail("Determinismo: segundo runtime no pudo configurarse.")
	var flow_b := KarmanyHumanSetupFlow.new()
	if not flow_b.configure(runtime_b):
		return _fail("Determinismo: segundo setup F41 fallo.")
	var candidates_b := flow_b.get_human_starting_candidates(&"player_1")
	if candidates_b.size() != 3:
		return _fail("Determinismo: segundo setup no produjo 3 candidatos.")
	if not flow_b.select_starting_candidate(chosen_index) or not flow_b.confirm_starting_candidate():
		return _fail("Determinismo: no pudo repetirse la misma eleccion humana.")
	var second_session := flow_b.get_full_session()
	if second_session == null:
		return _fail("Determinismo: segundo FullMatchSession inexistente.")
	for ai_id in [&"player_2", &"player_3", &"player_4"]:
		var first_data: KarmanyData = first_session.starting_karmany_by_player.get(ai_id, null) as KarmanyData
		var second_data: KarmanyData = second_session.starting_karmany_by_player.get(ai_id, null) as KarmanyData
		if first_data == null or second_data == null or first_data.karmany_id != second_data.karmany_id:
			return _fail("Determinismo: %s cambio de Karmany con misma seed y misma eleccion." % String(ai_id))
	return true


func _candidate_ids(candidates: Array[KarmanyData]) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for candidate in candidates:
		if candidate != null:
			result.append(String(candidate.karmany_id))
	return result


func _fail(message: String) -> bool:
	push_error("FASE 41 TEST ERROR: %s" % message)
	return false
