class_name KarmanyVerticalSliceGoal
extends RefCounted


static func get_text(session: KarmanyVerticalSliceSession) -> String:
	if session == null or not session.configured:
		return "Inicializando..."
	if session.coordinator.is_finished or not session.turn_manager.is_running:
		return "Partida finalizada. Revisa el resultado por PL."
	if session.human_player.ek < 5 and session.turn_manager.current_round <= 1:
		return "Recolecta EK con Interactuar en I-02."
	if not session.slice_match.board_prototype.board_state.is_revealed(
		KarmanyPhase24FullMatchBridge.TILE_N2
	):
		return "Explora Paso de Cristal (N2) y llama a Brumak."
	var visible: Array[KarmanyEncounterState] = (
		session.coordinator.encounter_resolver.get_visible_encounters_at(
			session.human_player.current_coord
		)
	)
	if session.human_player.get_linked_karmanys().size() < 2 and not visible.is_empty():
		return "Vincula a Brumak pagando 3 EK."
	if (
		session.human_player.get_linked_karmanys().size() < 2
		and session.human_player.current_coord == KarmanyPhase24FullMatchBridge.TILE_N2
	):
		return "Usa Llamar/Vincular para generar el encuentro N2."
	if not session.human_player.equipment_inventory.has_equipment_id(&"EQ-01"):
		return "Craftea EQ-01 en Paso de Cristal."
	if not session.slice_match.board_prototype.board_state.is_revealed(
		KarmanyPhase24FullMatchBridge.TILE_EK
	):
		return "Regresa al centro y Explora Arroyo Karmico."
	if session.slice_match.board_prototype.board_state.has_beast(
		session.human_player.current_coord
	):
		return "Combate: Brumak + EQ-01 + R-04 muestran la sinergia central."
	var assignment: KarmanyMissionAssignment = (
		session.objectives_missions.get_mission_assignment(session.human_player.player_id)
	)
	if assignment != null and not assignment.is_completed():
		return "Completa la Mision: revela 3 losetas y entra en N2."
	var objective_state: KarmanyObjectiveState = (
		session.objectives_missions.get_objective_state(&"OP-E01")
	)
	if objective_state != null and objective_state.claimed_by_player_id == &"":
		return "Visita 5 losetas distintas para reclamar Cartografo Experto."
	return "Gestiona tus acciones hasta el final de ronda 7; gana quien tenga mas PL."
