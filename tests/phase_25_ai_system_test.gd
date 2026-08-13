extends Node


const PHASE_24_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_24_full_match_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 25 AI TEST")
	print("================================")

	var ok: bool = true
	ok = _test_profile_preferences() and ok
	ok = await _test_hidden_information_is_not_scored() and ok
	ok = await _test_explorer_recalculates_two_actions() and ok
	ok = await _test_opportunist_uses_real_interaction() and ok
	ok = await _test_illegal_action_is_still_rejected() and ok
	ok = await _test_special_candidates_require_legal_check() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 25 OK - IA modular usa acciones legales, perfiles distintos y reevalua cada accion.")
	else:
		push_error("FASE 25 ERROR - Revisar IA modular y acciones legales.")
	print("================================")


func _test_profile_preferences() -> bool:
	var explore := _candidate(KarmanyAiActionCandidate.ActionType.EXPLORE, "Explorar")
	explore.exploration_value = 3.0
	explore.progress_value = 1.0

	var improve := _candidate(KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK, "Libro")
	improve.progress_value = 5.0

	var pvp := _candidate(KarmanyAiActionCandidate.ActionType.PVP, "PvP")
	pvp.aggression_value = 4.0

	var interact := _candidate(KarmanyAiActionCandidate.ActionType.INTERACT, "Interactuar")
	interact.opportunity_value = 5.0
	interact.economy_value = 4.0

	var candidates: Array[KarmanyAiActionCandidate] = [explore, improve, pvp, interact]
	var expected: Dictionary = {
		KarmanyAiProfile.ProfileType.EXPLORER: explore,
		KarmanyAiProfile.ProfileType.OPTIMIZER: improve,
		KarmanyAiProfile.ProfileType.AGGRESSIVE: pvp,
		KarmanyAiProfile.ProfileType.OPPORTUNIST: interact
	}

	for profile_type in expected.keys():
		var brain := KarmanyAiBrain.new()
		if not brain.configure(int(profile_type), 2501 + int(profile_type)):
			return _fail("No se pudo configurar un perfil IA.")
		var chosen := brain.choose_action(candidates)
		if chosen != expected[profile_type]:
			return _fail("Un perfil IA no priorizo su arquetipo esperado.")

	print("Perfiles Explorador / Optimizador / Agresivo / Oportunista: OK")
	return true


func _test_hidden_information_is_not_scored() -> bool:
	var prototype := await _spawn_phase_24()
	if prototype == null:
		return _fail("No se pudo instanciar Fase 24 para prueba de informacion oculta.")

	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		prototype.coordinator,
		prototype.player_1
	)
	var explore_count: int = 0
	var reference_values: Array[float] = []
	for candidate in candidates:
		if candidate.action_type != KarmanyAiActionCandidate.ActionType.EXPLORE:
			continue
		explore_count += 1
		var values: Array[float] = [
			candidate.exploration_value,
			candidate.economy_value,
			candidate.opportunity_value,
			candidate.progress_value,
			candidate.risk_value
		]
		if reference_values.is_empty():
			reference_values = values
		elif values != reference_values:
			prototype.queue_free()
			await get_tree().process_frame
			return _fail("La IA obtuvo valor distinto segun el contenido de una loseta oculta.")

	var ok: bool = explore_count >= 2
	prototype.queue_free()
	await get_tree().process_frame
	if not ok:
		return _fail("No hubo suficientes exploraciones ocultas para validar informacion imperfecta.")
	print("Losetas ocultas sin lectura privilegiada de contenido: OK")
	return true


func _test_explorer_recalculates_two_actions() -> bool:
	var prototype := await _spawn_phase_24()
	if prototype == null:
		return _fail("No se pudo instanciar Fase 24 para turno Explorador.")

	var ai := KarmanyAiTurnController.new()
	if not ai.configure(KarmanyAiProfile.ProfileType.EXPLORER, 2502):
		prototype.queue_free()
		return _fail("No se pudo configurar IA Exploradora.")

	var start_coord: Vector2i = prototype.player_1.current_coord
	var executions := ai.play_turn(
		prototype.coordinator,
		prototype.player_1,
		Callable(),
		false
	)
	var ok: bool = true
	if executions.size() != 2:
		ok = _fail("La IA Exploradora no ejecuto exactamente las 2 acciones disponibles.")
	elif not executions[0].was_executed() or not executions[1].was_executed():
		ok = _fail("Una accion elegida por la IA Exploradora fue rechazada.")
	elif executions[0].candidate.action_type != KarmanyAiActionCandidate.ActionType.EXPLORE:
		ok = _fail("El perfil Explorador no eligio Explorar cuando habia opciones legales.")
	elif prototype.turn_manager.actions_remaining != 0:
		ok = _fail("La IA no consumio exactamente las dos acciones del turno.")
	elif prototype.player_1.current_coord == start_coord:
		ok = _fail("La IA Exploradora no cambio de posicion.")
	elif not prototype.coordinator.board_state.is_revealed(prototype.player_1.current_coord):
		ok = _fail("La IA termino sobre una loseta que no quedo revelada.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("Explorador: 2 acciones adaptativas recalculadas y legales: OK")
	return ok


func _test_opportunist_uses_real_interaction() -> bool:
	var prototype := await _spawn_phase_24()
	if prototype == null:
		return _fail("No se pudo instanciar Fase 24 para turno Oportunista.")

	var ai := KarmanyAiTurnController.new()
	if not ai.configure(KarmanyAiProfile.ProfileType.OPPORTUNIST, 2503):
		prototype.queue_free()
		return _fail("No se pudo configurar IA Oportunista.")

	var ek_before: int = prototype.player_1.ek
	var execution := ai.execute_one_action(prototype.coordinator, prototype.player_1)
	var ok: bool = true
	if not execution.was_executed():
		ok = _fail("La accion Oportunista fue rechazada por el coordinador.")
	elif execution.candidate.action_type != KarmanyAiActionCandidate.ActionType.INTERACT:
		ok = _fail("El Oportunista no eligio la recompensa inmediata disponible.")
	elif prototype.player_1.ek != ek_before + 2:
		ok = _fail("Interactuar de la IA no paso por el efecto real +2 EK de I-02.")
	elif prototype.turn_manager.actions_remaining != 1:
		ok = _fail("Interactuar de la IA no consumio exactamente 1 accion.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("Oportunista: Interactuar real via MatchCoordinator (+2 EK): OK")
	return ok


func _test_illegal_action_is_still_rejected() -> bool:
	var prototype := await _spawn_phase_24()
	if prototype == null:
		return _fail("No se pudo instanciar Fase 24 para rechazo legal.")

	var hidden_target := Vector2i(1, 0)
	if prototype.coordinator.board_state.is_revealed(hidden_target):
		prototype.queue_free()
		await get_tree().process_frame
		return _fail("El destino previsto para la prueba ya estaba revelado.")

	var candidate := _candidate(KarmanyAiActionCandidate.ActionType.MOVE, "Mover ilegal a oculta")
	candidate.target_coord = hidden_target
	var actions_before: int = prototype.turn_manager.actions_remaining
	var execution := KarmanyAiActionExecutor.execute(
		prototype.coordinator,
		prototype.player_1,
		candidate
	)
	var ok: bool = true
	if execution.was_executed():
		ok = _fail("La IA pudo saltarse la regla Mover -> solo loseta revelada.")
	elif prototype.turn_manager.actions_remaining != actions_before:
		ok = _fail("Una accion ilegal de IA consumio acciones.")
	elif prototype.player_1.current_coord != Vector2i.ZERO:
		ok = _fail("Una accion ilegal de IA altero la posicion del jugador.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("Accion IA ilegal rechazada por las reglas humanas sin coste: OK")
	return ok


func _test_special_candidates_require_legal_check() -> bool:
	var prototype := await _spawn_phase_24()
	if prototype == null:
		return _fail("No se pudo instanciar Fase 24 para acciones especiales.")

	var rejected := _candidate(KarmanyAiActionCandidate.ActionType.PVP, "PvP no autorizado")
	rejected.aggression_value = 10.0
	rejected.payload["legal_check"] = func() -> bool:
		return false

	var accepted := _candidate(KarmanyAiActionCandidate.ActionType.FIGHT_BEAST, "Bestia legal simulada")
	accepted.aggression_value = 5.0
	accepted.payload["legal_check"] = func() -> bool:
		return true

	var extras: Array[KarmanyAiActionCandidate] = [rejected, accepted]
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		prototype.coordinator,
		prototype.player_1,
		extras
	)
	var has_rejected: bool = candidates.has(rejected)
	var has_accepted: bool = candidates.has(accepted)

	prototype.queue_free()
	await get_tree().process_frame
	if has_rejected or not has_accepted:
		return _fail("El filtro de acciones especiales no respeto su comprobacion legal.")
	print("Acciones especiales modulares requieren legal_check antes de entrar al arbol IA: OK")
	return true


func _spawn_phase_24() -> KarmanyPhase24FullMatchBridge:
	var prototype := PHASE_24_SCENE.instantiate() as KarmanyPhase24FullMatchBridge
	if prototype == null:
		return null
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame
	if not prototype.setup_ok:
		prototype.queue_free()
		await get_tree().process_frame
		return null
	return prototype


func _candidate(action_type: int, label: String) -> KarmanyAiActionCandidate:
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = action_type
	candidate.debug_label = label
	candidate.base_utility = 1.0
	return candidate


func _fail(message: String) -> bool:
	push_error("FASE 25 TEST ERROR: %s" % message)
	return false
