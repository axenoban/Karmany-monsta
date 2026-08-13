extends Node


@onready var prototype: KarmanyPhase24FullMatchBridge = $Phase24FullMatchPrototype


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 24 FULL MATCH INTEGRATION TEST")
	print("================================")

	var ok: bool = true
	ok = _expect(prototype != null and prototype.setup_ok, "El setup integrado no quedo listo.") and ok
	if prototype == null or not prototype.setup_ok:
		_finish(false)
		return

	ok = _test_initial_state() and ok
	var flow_ok: bool = prototype.run_complete_match_fast()
	ok = _expect(flow_ok, "El flujo abreviado no llego legalmente al final.") and ok
	await get_tree().process_frame
	ok = _test_final_state() and ok
	ok = _test_progression_and_rewards() and ok
	ok = _test_consistency_after_finish() and ok

	_finish(ok)


func _test_initial_state() -> bool:
	var ok: bool = true
	ok = _expect(prototype.turn_manager.current_round == 1, "Debe comenzar en ronda 1.") and ok
	ok = _expect(prototype.turn_manager.actions_remaining == 2, "Cada turno debe comenzar con 2 acciones.") and ok
	ok = _expect(prototype.turn_manager.get_active_player() == prototype.player_1, "player_1 debe iniciar.") and ok
	ok = _expect(prototype.player_1.mn == 2 and prototype.player_1.mr == 1 and prototype.player_1.ek == 1 and prototype.player_1.fa == 0, "Recursos iniciales de player_1 incorrectos.") and ok
	ok = _expect(prototype.player_2.mn == 2 and prototype.player_2.mr == 1 and prototype.player_2.ek == 1 and prototype.player_2.fa == 0, "Recursos iniciales de player_2 incorrectos.") and ok
	ok = _expect(prototype.player_1.get_resonance_count() == 5 and prototype.player_2.get_resonance_count() == 5, "Cada jugador debe recibir 5 Resonancias.") and ok
	ok = _expect(prototype.equipment_market.get_visible_count() == 4, "El mercado debe iniciar con 4 Equipos visibles.") and ok
	ok = _expect(prototype.board_prototype.board_state.get_cell_count() == 7, "El sandbox integrado debe conservar 7 hexagonos.") and ok
	ok = _expect(prototype.board_prototype.board_state.get_occupying_unit_id(prototype.P1_START) != &"", "P1 debe ocupar su inicio.") and ok
	ok = _expect(prototype.board_prototype.board_state.get_occupying_unit_id(prototype.P2_START) == prototype.P2_UNIT_ID, "P2 debe ocupar su inicio logico.") and ok
	print("Setup + 2 acciones + recursos + manos + mercado + ocupacion: ", "OK" if ok else "ERROR")
	return ok


func _test_final_state() -> bool:
	var ok: bool = true
	ok = _expect(prototype.coordinator.is_finished, "MatchCoordinator debe marcar la partida finalizada.") and ok
	ok = _expect(prototype.coordinator.final_evaluation != null, "Debe existir evaluacion final.") and ok
	ok = _expect(not prototype.turn_manager.is_running, "TurnManager debe quedar detenido al cerrar la ronda final.") and ok
	ok = _expect(prototype.turn_manager.current_round == 12, "No debe abrirse una ronda fantasma despues del final.") and ok
	ok = _expect(prototype.turn_manager.actions_remaining == 0, "Una partida detenida no debe conservar acciones activas.") and ok
	if prototype.coordinator.final_evaluation != null:
		ok = _expect(prototype.coordinator.final_evaluation.should_end_match, "La evaluacion debe ordenar final de partida.") and ok
		ok = _expect(prototype.coordinator.final_evaluation.reason_id == KarmanyLegacyPointsController.REASON_LEGACY_RACE_TARGET, "El final debe provenir de Carrera de Legado.") and ok
		ok = _expect(prototype.coordinator.final_evaluation.leader_player_ids.has(prototype.player_1.player_id), "player_1 debe ser lider final del recorrido.") and ok
	ok = _expect(prototype.legacy_points.get_total(prototype.player_1.player_id) >= prototype.DEMO_RACE_TARGET, "P1 debe alcanzar la meta de PL.") and ok
	ok = _expect(prototype.coordinator.aeterna_state.defeated, "Aeterna debe quedar derrotada.") and ok
	ok = _expect(prototype.coordinator.aeterna_state.defeated_by_player_id == prototype.player_1.player_id, "Aeterna debe haber sido derrotada por P1.") and ok
	print("Final de ronda + Carrera de Legado + Aeterna + ganador: ", "OK" if ok else "ERROR")
	return ok


func _test_progression_and_rewards() -> bool:
	var ok: bool = true
	var p1_book: KarmanyBookProgressState = prototype.coordinator.get_book_state(prototype.player_1.player_id)
	ok = _expect(p1_book != null and p1_book.level == 3, "P1 debe terminar con Libro III.") and ok
	ok = _expect(prototype.player_1.get_linked_karmanys().size() == 2, "P1 debe conservar Terrakor + Brumak.") and ok
	ok = _expect(prototype.player_1.has_karmany_instance(&"phase24_starter_p1"), "El Karmany inicial de P1 debe seguir en roster.") and ok
	var has_brumak: bool = false
	for runtime in prototype.player_1.get_linked_karmanys():
		if runtime.karmany_data != null and runtime.karmany_data.karmany_id == &"K-10":
			has_brumak = true
	ok = _expect(has_brumak, "Brumak debe haber quedado vinculado.") and ok
	ok = _expect(prototype.player_1.equipment_inventory.has_equipment_id(&"EQ-02"), "EQ-02 debe haber sido crafteado.") and ok
	ok = _expect(prototype.player_1.equipment_inventory.has_equipment_id(&"EQ-09"), "EQ-09 debe haberse obtenido de Aeterna.") and ok

	var mission_p1: KarmanyMissionAssignment = prototype.objectives_missions.get_mission_assignment(prototype.player_1.player_id)
	var mission_p2: KarmanyMissionAssignment = prototype.objectives_missions.get_mission_assignment(prototype.player_2.player_id)
	ok = _expect(mission_p1 != null and mission_p1.is_completed(), "Mision de Alderion debe completarse.") and ok
	ok = _expect(mission_p2 != null and mission_p2.is_completed(), "Mision de Dorian debe completarse con Bestia+PvP en rondas distintas.") and ok
	var objective: KarmanyObjectiveState = prototype.objectives_missions.get_objective_state(&"OP-E01")
	ok = _expect(objective != null and objective.claimed_by_player_id == prototype.player_1.player_id, "OP-E01 debe ser reclamado por P1.") and ok

	ok = _expect(prototype.legacy_points.get_points_by_source_type(prototype.player_1.player_id, KarmanyLegacyPointsEntry.SourceType.AETERNA) == 8, "Aeterna debe aportar exactamente 8 PL.") and ok
	ok = _expect(prototype.legacy_points.get_points_by_source_type(prototype.player_1.player_id, KarmanyLegacyPointsEntry.SourceType.TRAINER_MISSION) == 4, "Mision P1 debe aportar 4 PL.") and ok
	ok = _expect(prototype.legacy_points.get_points_by_source_type(prototype.player_1.player_id, KarmanyLegacyPointsEntry.SourceType.MILESTONE) >= 4, "P1 debe puntuar N2 vinculado y Libro III.") and ok
	ok = _expect(prototype.legacy_points.get_points_by_source_type(prototype.player_2.player_id, KarmanyLegacyPointsEntry.SourceType.BEAST) == 1, "Bestia debe aportar 1 PL a P2.") and ok
	ok = _expect(prototype.legacy_points.get_points_by_source_type(prototype.player_2.player_id, KarmanyLegacyPointsEntry.SourceType.PVP) == 2, "PvP debe aportar 2 PL a P2.") and ok
	print("Libro + vinculo + Equipo + Misiones + Objetivo + origen de PL: ", "OK" if ok else "ERROR")
	return ok


func _test_consistency_after_finish() -> bool:
	var ok: bool = true
	ok = _expect(prototype.player_1.current_coord == prototype.TILE_AETERNA, "P1 debe terminar en el Santuario.") and ok
	ok = _expect(prototype.player_2.current_coord == prototype.P2_START, "P2 debe conservar su posicion inicial.") and ok
	ok = _expect(prototype.board_prototype.board_state.get_occupying_unit_id(prototype.TILE_AETERNA) != &"", "La ocupacion final de P1 debe coincidir con su coordenada.") and ok
	ok = _expect(prototype.board_prototype.board_state.get_occupying_unit_id(prototype.P2_START) == prototype.P2_UNIT_ID, "La ocupacion final de P2 debe ser consistente.") and ok
	ok = _expect(prototype.player_1.mn >= 0 and prototype.player_1.mr >= 0 and prototype.player_1.ek >= 0 and prototype.player_1.fa >= 0, "P1 no puede tener recursos negativos.") and ok
	ok = _expect(prototype.player_2.mn >= 0 and prototype.player_2.mr >= 0 and prototype.player_2.ek >= 0 and prototype.player_2.fa >= 0, "P2 no puede tener recursos negativos.") and ok
	ok = _expect(prototype.player_1.resonance_hand.get_pending_discard_count() == 0, "P1 no debe terminar con descarte pendiente.") and ok
	ok = _expect(prototype.player_2.resonance_hand.get_pending_discard_count() == 0, "P2 no debe terminar con descarte pendiente.") and ok
	ok = _expect(not prototype.coordinator.move_player(prototype.player_1, prototype.P1_START), "No deben aceptarse acciones despues del final.") and ok
	print("Recursos + ocupacion + descartes + bloqueo post-final: ", "OK" if ok else "ERROR")
	return ok


func _finish(ok: bool) -> void:
	print("")
	print("================================")
	if ok:
		print("FASE 24 OK - Partida integrada desde Setup hasta resultado final validada.")
	else:
		push_error("FASE 24 ERROR - Revisar integracion completa de partida.")
	print("================================")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 24 ERROR: %s" % message)
	return false
