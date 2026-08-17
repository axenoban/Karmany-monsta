extends Node


const EVENT_RISK_WIN: StringName = &"combat_won_with_risk"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.6 OBJETIVOS/MISIONES RUNTIME")
	print("========================================")
	var ok: bool = true
	ok = _test_canonical_runtime_conditions() and ok
	ok = _test_move_into_n2_records_entry() and ok
	ok = _test_risk_victory_events() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.6 OK - Objetivos/Misiones activos conectados a entrada N2+ y victorias reales con Dado de Riesgo.")
	else:
		push_error("FASE 44.6 ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_canonical_runtime_conditions() -> bool:
	var direct_objectives := _load_direct_resources("res://data/objectives")
	var direct_missions := _load_direct_resources("res://data/missions")
	if direct_objectives.size() != 8:
		return _fail("Se esperaban 8 Objetivos Publicos directos y hay %d." % direct_objectives.size())
	if direct_missions.size() != 9:
		return _fail("Se esperaban 9 Misiones Secretas directas y hay %d." % direct_missions.size())

	var mission_a1 := load("res://data/missions/me_a1_cartografo_del_primer_eco.tres") as KarmanyMissionData
	var mission_o1 := load("res://data/missions/me_o1_apuesta_victoriosa.tres") as KarmanyMissionData
	if mission_a1 == null or mission_o1 == null:
		return _fail("No se pudieron cargar ME-A1/ME-O1 activos.")
	if not _mission_has_event(mission_a1, KarmanyMatchCoordinator.EVENT_ENTERED_N2_OR_HIGHER):
		return _fail("ME-A1 ya no consume entered_n2_or_higher.")
	if not _mission_has_event(mission_o1, EVENT_RISK_WIN):
		return _fail("ME-O1 ya no consume combat_won_with_risk.")
	print("F44.6 CANON | 8 Objetivos + 9 Misiones directos; ME-A1/ME-O1 conservan sus condiciones runtime.")
	return true


func _test_move_into_n2_records_entry() -> bool:
	for attempt in range(12):
		var setup := _new_started_session(446100 + attempt)
		if setup.is_empty():
			continue
		var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
		var session: KarmanyFullMatchSession = setup["session"]
		var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
		if player == null or runtime.board_state == null:
			continue

		var pair := _find_unoccupied_entry_pair(runtime, KarmanyTileData.TileLevel.N2)
		if pair.is_empty():
			continue
		var origin: Vector2i = pair["origin"]
		var target: Vector2i = pair["target"]
		if not _ensure_revealed(runtime, origin) or not _ensure_revealed(runtime, target):
			continue
		if not runtime._relocate_player(player, origin):
			continue

		var tracker := runtime.objectives_missions.progress_tracker
		var before: int = tracker.get_event_count(
			player.player_id,
			KarmanyMatchCoordinator.EVENT_ENTERED_N2_OR_HIGHER
		)
		var candidate := KarmanyAiActionCandidate.new()
		candidate.action_type = KarmanyAiActionCandidate.ActionType.MOVE
		candidate.target_coord = target
		candidate.debug_label = "F44.6 MOVE real hacia N2"
		if not session._execute_candidate(player, candidate):
			continue
		if player.current_coord != target:
			return _fail("MOVE F44.6 no termino en la loseta N2 objetivo.")
		var after: int = tracker.get_event_count(
			player.player_id,
			KarmanyMatchCoordinator.EVENT_ENTERED_N2_OR_HIGHER
		)
		if after != before + 1:
			return _fail("Mover hacia N2 debe producir exactamente 1 entered_n2_or_higher; antes=%d despues=%d." % [before, after])
		print("F44.6 ENTRY | MOVE real %s -> %s produce exactamente 1 entered_n2_or_higher." % [str(origin), str(target)])
		return true
	return _fail("No se encontro fixture legal N2 para validar Mover tras 12 seeds.")


func _test_risk_victory_events() -> bool:
	var setup := _new_started_session(446900)
	if setup.is_empty():
		return false
	var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
	var session: KarmanyFullMatchSession = setup["session"]
	var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if player == null:
		return _fail("No existe jugador activo para validar Riesgo.")
	var tracker := runtime.objectives_missions.progress_tracker
	var before: int = tracker.get_event_count(player.player_id, EVENT_RISK_WIN)

	var beast_candidate := KarmanyAiActionCandidate.new()
	beast_candidate.action_type = KarmanyAiActionCandidate.ActionType.FIGHT_BEAST
	beast_candidate.debug_label = "F44.6 Bestia Riesgo"

	var beast_victory := _beast_execution(KarmanyCombatResult.Outcome.VICTORY, 4)
	session._record_risk_victory_if_needed(player, beast_candidate, beast_victory)
	if tracker.get_event_count(player.player_id, EVENT_RISK_WIN) != before + 1:
		return _fail("Victoria contra Bestia con risk_roll=4 no registro combat_won_with_risk.")

	var no_risk_victory := _beast_execution(KarmanyCombatResult.Outcome.VICTORY, 0)
	session._record_risk_victory_if_needed(player, beast_candidate, no_risk_victory)
	if tracker.get_event_count(player.player_id, EVENT_RISK_WIN) != before + 1:
		return _fail("Victoria sin Dado de Riesgo genero progreso incorrecto.")

	var risk_defeat := _beast_execution(KarmanyCombatResult.Outcome.DEFEAT, 6)
	session._record_risk_victory_if_needed(player, beast_candidate, risk_defeat)
	if tracker.get_event_count(player.player_id, EVENT_RISK_WIN) != before + 1:
		return _fail("Derrota con Dado de Riesgo genero progreso incorrecto.")

	var aeterna_candidate := KarmanyAiActionCandidate.new()
	aeterna_candidate.action_type = KarmanyAiActionCandidate.ActionType.AETERNA
	aeterna_candidate.debug_label = "F44.6 Aeterna Riesgo"
	aeterna_candidate.payload = {"risk_roll": 5}
	var aeterna_result := KarmanyAeternaResult.new()
	aeterna_result.status = KarmanyAeternaResult.Status.RESOLVED
	aeterna_result.outcome = KarmanyAeternaResult.Outcome.COMBAT_VICTORY
	var aeterna_execution := KarmanyAiExecutionResult.new()
	aeterna_execution.success = true
	aeterna_execution.candidate = aeterna_candidate
	aeterna_execution.raw_result = aeterna_result
	session._record_risk_victory_if_needed(player, aeterna_candidate, aeterna_execution)
	if tracker.get_event_count(player.player_id, EVENT_RISK_WIN) != before + 2:
		return _fail("Victoria contra Aeterna con risk_roll=5 no registro combat_won_with_risk.")

	print("F44.6 RISK | Bestia+Aeterna victoriosas cuentan; victoria sin Riesgo y derrota con Riesgo no cuentan.")
	return true


func _beast_execution(outcome: int, risk_roll: int) -> KarmanyAiExecutionResult:
	var combat := KarmanyCombatResult.new()
	combat.status = KarmanyCombatResult.Status.RESOLVED
	combat.outcome = outcome
	combat.risk_roll = risk_roll
	var beast := KarmanyBeastCombatResult.new()
	beast.status = KarmanyBeastCombatResult.Status.RESOLVED
	beast.combat_result = combat
	var execution := KarmanyAiExecutionResult.new()
	execution.success = true
	execution.raw_result = beast
	return execution


func _find_unoccupied_entry_pair(
	runtime: KarmanyMultiAiAlphaRuntime,
	target_level: int
) -> Dictionary:
	for target in runtime.board_state.get_coords():
		if runtime.get_public_level(target) != target_level:
			continue
		if runtime.board_state.is_occupied(target) or runtime.board_state.has_beast(target):
			continue
		for origin in runtime.board_state.get_existing_neighbors(target):
			if runtime.board_state.is_occupied(origin) or runtime.board_state.has_beast(origin):
				continue
			return {"origin": origin, "target": target}
	return {}


func _ensure_revealed(runtime: KarmanyMultiAiAlphaRuntime, coord: Vector2i) -> bool:
	if runtime.board_state.is_revealed(coord):
		return true
	return runtime.content_session.reveal_into_board_state(runtime.board_state, coord)


func _mission_has_event(mission: KarmanyMissionData, event_id: StringName) -> bool:
	for condition in mission.conditions:
		if condition != null and condition.event_id == event_id:
			return true
	return false


func _load_direct_resources(path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as Resource
		if data != null:
			result.append(data)
	return result


func _new_started_session(seed_value: int) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_fail("Seed %d: no se pudo crear runtime." % seed_value)
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_fail("Seed %d: no se pudo configurar FullMatchSession: %s" % [seed_value, session.last_error])
		return {}
	if not session.start_playing():
		_fail("Seed %d: no se pudo entrar a PLAYING." % seed_value)
		return {}
	return {"runtime": runtime, "session": session}


func _fail(message: String) -> bool:
	push_error("FASE 44.6 TEST ERROR: %s" % message)
	return false
