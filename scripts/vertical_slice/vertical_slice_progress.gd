class_name KarmanyVerticalSliceProgress
extends RefCounted


static func get_text(session) -> String:
	if session == null or not session.configured:
		return "Sin sesion."
	var assignment: KarmanyMissionAssignment = (
		session.objectives_missions.get_mission_assignment(session.human_player.player_id)
	)
	var mission_done: bool = assignment != null and assignment.is_completed()
	var objective_state: KarmanyObjectiveState = (
		session.objectives_missions.get_objective_state(&"OP-E01")
	)
	var objective_done: bool = (
		objective_state != null
		and objective_state.claimed_by_player_id == session.human_player.player_id
	)
	return (
		"Ronda %d/7 · Acciones %d/2 · PL %d\n" % [
			session.turn_manager.current_round,
			session.turn_manager.actions_remaining,
			session.legacy_points.get_total(session.human_player.player_id)
		]
		+ "Karmany %d · Equipo %d · Resonancias %d\n" % [
			session.human_player.get_linked_karmanys().size(),
			session.human_player.get_equipment_count(),
			session.human_player.get_resonance_count()
		]
		+ "Mision %s · Objetivo %s" % [
			"OK" if mission_done else "pendiente",
			"OK" if objective_done else "pendiente"
		]
	)
