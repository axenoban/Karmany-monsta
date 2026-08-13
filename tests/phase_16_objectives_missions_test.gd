extends Node


const OP_E01: KarmanyObjectiveData = preload("res://data/objectives/op_e01_cartografo_experto.tres")
const OP_D02: KarmanyObjectiveData = preload("res://data/objectives/op_d02_forja_consistente.tres")
const OP_C03: KarmanyObjectiveData = preload("res://data/objectives/op_c03_duelista_del_eco.tres")
const OP_A03: KarmanyObjectiveData = preload("res://data/objectives/op_a03_preparacion_final.tres")

const ME_A1: KarmanyMissionData = preload("res://data/missions/me_a1_cartografo_del_primer_eco.tres")
const ME_D1: KarmanyMissionData = preload("res://data/missions/me_d1_rival_de_vael.tres")
const ME_N1: KarmanyMissionData = preload("res://data/missions/me_n1_forja_personal.tres")
const ME_K1: KarmanyMissionData = preload("res://data/missions/me_k1_cazador_del_umbral.tres")
const ME_O1: KarmanyMissionData = preload("res://data/missions/me_o1_apuesta_victoriosa.tres")

const EQ01: KarmanyEquipmentData = preload("res://data/equipment/eq_01_cristal_de_crecimiento.tres")
const EQ02: KarmanyEquipmentData = preload("res://data/equipment/eq_02_guante_runico.tres")
const EQ05: KarmanyEquipmentData = preload("res://data/equipment/eq_05_nucleo_luminico.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 16 OBJECTIVES / MISSIONS TEST")
	print("================================")

	var ok: bool = true
	ok = _test_data_fixtures() and ok
	ok = _test_secret_mission_and_immediate_reward() and ok
	ok = _test_public_objective_claims_at_turn_end() and ok
	ok = _test_end_turn_mission_timing() and ok
	ok = _test_compound_conditions() and ok
	ok = _test_ancestral_state_condition() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 16 OK - Objetivos, Misiones, condiciones y recompensas pendientes validados.")
	else:
		push_error("FASE 16 ERROR - Revisar Objetivos/Misiones.")
	print("================================")


func _test_data_fixtures() -> bool:
	var ok: bool = true
	for objective in [OP_E01, OP_D02, OP_C03, OP_A03]:
		ok = _expect(objective != null and objective.is_valid_definition(), "ObjectiveData invalido.") and ok
	ok = _expect(OP_E01.reward_legacy_points == 3, "OP-E01 debe otorgar 3 PL.") and ok
	ok = _expect(OP_D02.reward_legacy_points == 4, "OP-D02 debe otorgar 4 PL.") and ok
	ok = _expect(OP_C03.reward_legacy_points == 4, "OP-C03 debe otorgar 4 PL.") and ok
	ok = _expect(OP_A03.reward_legacy_points == 5 and OP_A03.map_41_only, "OP-A03 debe ser Ancestral de mapa 41 por 5 PL.") and ok

	for mission in [ME_A1, ME_D1, ME_N1, ME_K1, ME_O1]:
		ok = _expect(mission != null and mission.is_valid_definition(), "MissionData invalido.") and ok
		ok = _expect(mission.reward_legacy_points == 4, "Cada Mision fixture debe otorgar 4 PL.") and ok
		ok = _expect(mission.reward_effects.size() == 1, "Cada Mision debe contener +1 FA ejecutable.") and ok

	print("ObjectiveData + MissionData v0.74: ", "OK" if ok else "ERROR")
	return ok


func _test_secret_mission_and_immediate_reward() -> bool:
	var setup := _new_match([OP_E01, OP_D02, OP_C03])
	var manager: KarmanyObjectiveMissionManager = setup.manager
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var ok: bool = true

	ok = _expect(manager.assign_secret_mission(p1, &"alderion", ME_A1), "No se asigno ME-A1.") and ok
	ok = _expect(manager.get_mission_for_viewer(p1.player_id, p1.player_id) == ME_A1, "El propietario debe ver su Mision secreta.") and ok
	ok = _expect(manager.get_mission_for_viewer(p2.player_id, p1.player_id) == null, "El rival no debe ver una Mision secreta incompleta.") and ok

	manager.record_event(p1, &"tile_revealed", {"tile_id": "N1-01"})
	manager.record_event(p1, &"tile_revealed", {"tile_id": "N1-02"})
	manager.record_event(p1, &"tile_revealed", {"tile_id": "N2-01"})
	ok = _expect(not manager.get_mission_assignment(p1.player_id).is_completed(), "ME-A1 aun necesita entrar en N2+.") and ok
	ok = _expect(p1.fa == 0, "No debe entregar FA antes de completar la Mision.") and ok

	manager.record_event(p1, &"entered_n2_or_higher", {"tile_level": 2})
	var assignment := manager.get_mission_assignment(p1.player_id)
	ok = _expect(assignment.is_completed(), "ME-A1 debe completarse automaticamente.") and ok
	ok = _expect(p1.fa == 1, "Mision completada debe otorgar +1 FA inmediatamente.") and ok
	ok = _expect(manager.get_mission_for_viewer(p2.player_id, p1.player_id) == ME_A1, "Mision completada debe revelarse a los demas.") and ok
	ok = _expect(assignment.reward_legacy_points_pending == 4, "Los 4 PL deben quedar pendientes para Fase 17.") and ok
	ok = _expect(_count_pending(manager, p1.player_id, &"ME-A1") == 1, "Debe existir una sola recompensa PL pendiente de ME-A1.") and ok

	print("Mision secreta + revelado + 1 FA + 4 PL pendientes: ", "OK" if ok else "ERROR")
	return ok


func _test_public_objective_claims_at_turn_end() -> bool:
	var setup := _new_match([OP_E01, OP_D02, OP_C03])
	var manager: KarmanyObjectiveMissionManager = setup.manager
	var turn: KarmanyTurnManager = setup.turn
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var ok: bool = true

	for index in range(5):
		manager.record_event(
			p1,
			&"tile_visited",
			{"coord_key": "tile_%d" % index}
		)

	ok = _expect(not manager.get_objective_state(&"OP-E01").is_claimed(), "OP-E01 no debe reclamarse antes del fin de turno.") and ok
	turn.spend_action_for(&"test_action", 1)
	turn.spend_action_for(&"test_action", 1)
	ok = _expect(turn.end_turn(), "No se pudo terminar turno de player_1.") and ok

	var state := manager.get_objective_state(&"OP-E01")
	ok = _expect(state.is_claimed(), "OP-E01 debe reclamarse automaticamente al terminar turno.") and ok
	ok = _expect(state.claimed_by_player_id == p1.player_id, "OP-E01 debe pertenecer a player_1.") and ok
	ok = _expect(_count_pending(manager, p1.player_id, &"OP-E01") == 1, "OP-E01 debe dejar 3 PL pendientes una sola vez.") and ok

	for index in range(5):
		manager.record_event(
			p2,
			&"tile_visited",
			{"coord_key": "p2_tile_%d" % index}
		)
	turn.spend_action_for(&"test_action", 1)
	turn.spend_action_for(&"test_action", 1)
	ok = _expect(turn.end_turn(), "No se pudo terminar turno de player_2.") and ok
	ok = _expect(state.claimed_by_player_id == p1.player_id, "Objetivo Publico reclamado no debe cambiar de propietario.") and ok
	ok = _expect(_count_pending(manager, p2.player_id, &"OP-E01") == 0, "Segundo jugador no debe recibir recompensa del mismo Objetivo.") and ok

	print("Objetivo Publico: fin de turno + carrera unica: ", "OK" if ok else "ERROR")
	return ok


func _test_end_turn_mission_timing() -> bool:
	var setup := _new_match([OP_E01, OP_C03])
	var manager: KarmanyObjectiveMissionManager = setup.manager
	var turn: KarmanyTurnManager = setup.turn
	var p1: KarmanyPlayerState = setup.p1
	var ok: bool = true

	ok = _expect(manager.assign_secret_mission(p1, &"nara", ME_N1), "No se asigno ME-N1.") and ok
	ok = _expect(p1.add_equipment(EQ01), "No se equipo EQ-01.") and ok
	ok = _expect(p1.add_equipment(EQ02), "No se equipo EQ-02.") and ok
	ok = _expect(manager.set_progress_state(p1, &"book_level", 2), "No se registro Libro II.") and ok
	ok = _expect(not manager.get_mission_assignment(p1.player_id).is_completed(), "ME-N1 exige terminar turno; no debe completarse antes.") and ok
	ok = _expect(p1.fa == 0, "ME-N1 no debe dar FA antes del cierre del turno.") and ok

	turn.spend_action_for(&"test_action", 1)
	turn.spend_action_for(&"test_action", 1)
	ok = _expect(turn.end_turn(), "No se pudo cerrar turno para ME-N1.") and ok
	ok = _expect(manager.get_mission_assignment(p1.player_id).is_completed(), "ME-N1 debe completarse al final del turno.") and ok
	ok = _expect(p1.fa == 1, "ME-N1 debe otorgar +1 FA al completarse.") and ok

	print("Mision de condicion fin-de-turno: ", "OK" if ok else "ERROR")
	return ok


func _test_compound_conditions() -> bool:
	var tracker := KarmanyProgressTracker.new()
	var player_id: StringName = &"player_test"
	var ok: bool = true

	tracker.record_event(player_id, &"pvp_won", 2)
	tracker.record_event(player_id, &"beast_defeated", 2, {"beast_tier": 0})
	ok = _expect(not tracker.are_conditions_met(player_id, ME_D1.conditions), "ME-D1 no debe cumplirse si PvP y Bestia fueron en la misma ronda.") and ok
	tracker.record_event(player_id, &"beast_defeated", 3, {"beast_tier": 1})
	ok = _expect(tracker.are_conditions_met(player_id, ME_D1.conditions), "ME-D1 debe detectar logros en rondas distintas.") and ok

	var kael_tracker := KarmanyProgressTracker.new()
	kael_tracker.record_event(player_id, &"beast_defeated", 1, {"beast_tier": 0})
	kael_tracker.record_event(player_id, &"beast_defeated", 1, {"beast_tier": 0})
	ok = _expect(not kael_tracker.are_conditions_met(player_id, ME_K1.conditions), "ME-K1 requiere una Bestia Media o superior.") and ok
	kael_tracker.record_event(player_id, &"beast_defeated", 2, {"beast_tier": 1})
	ok = _expect(kael_tracker.are_conditions_met(player_id, ME_K1.conditions), "ME-K1 debe aceptar una Bestia Media o superior.") and ok

	var oryn_tracker := KarmanyProgressTracker.new()
	oryn_tracker.record_event(player_id, &"combat_won_with_risk", 1)
	ok = _expect(not oryn_tracker.are_conditions_met(player_id, ME_O1.conditions), "ME-O1 requiere 2 victorias con Riesgo.") and ok
	oryn_tracker.record_event(player_id, &"combat_won_with_risk", 2)
	ok = _expect(oryn_tracker.are_conditions_met(player_id, ME_O1.conditions), "ME-O1 debe detectar 2 victorias con Riesgo.") and ok

	print("Condiciones compuestas, filtros y rondas distintas: ", "OK" if ok else "ERROR")
	return ok


func _test_ancestral_state_condition() -> bool:
	var tracker := KarmanyProgressTracker.new()
	var player_id: StringName = &"ancestral_test"
	var ok: bool = true
	tracker.set_state_int(player_id, &"book_level", 2)
	tracker.set_state_int(player_id, &"equipment_count", 2)
	tracker.set_state_int(player_id, &"fa", 0)
	ok = _expect(not tracker.are_conditions_met(player_id, OP_A03.conditions), "OP-A03 requiere 1 FA.") and ok
	tracker.set_state_int(player_id, &"fa", 1)
	ok = _expect(tracker.are_conditions_met(player_id, OP_A03.conditions), "OP-A03 debe cumplirse con Libro II + 2 Equipos + 1 FA.") and ok

	print("Objetivo Ancestral por estado combinado: ", "OK" if ok else "ERROR")
	return ok


func _new_match(objectives: Array) -> Dictionary:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i(1, 0))

	var turn := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	turn.setup_players(players)
	turn.start_match()

	var typed_objectives: Array[KarmanyObjectiveData] = []
	for objective in objectives:
		typed_objectives.append(objective as KarmanyObjectiveData)

	var manager := KarmanyObjectiveMissionManager.new()
	manager.configure(turn, typed_objectives)
	return {
		"p1": p1,
		"p2": p2,
		"turn": turn,
		"manager": manager
	}


func _count_pending(
	manager: KarmanyObjectiveMissionManager,
	player_id: StringName,
	source_id: StringName
) -> int:
	var total: int = 0
	for reward in manager.get_pending_legacy_rewards():
		if reward.player_id == player_id and reward.source_id == source_id:
			total += 1
	return total


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 16 ERROR: %s" % message)
	return false
