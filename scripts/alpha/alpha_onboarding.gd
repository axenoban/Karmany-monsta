class_name KarmanyAlphaOnboarding
extends RefCounted

const TOTAL_STEPS: int = 7

static func get_step_index(session: KarmanyVerticalSliceSession) -> int:
	if session == null or not session.configured:
		return 0
	if session.coordinator.is_finished or not session.turn_manager.is_running:
		return TOTAL_STEPS
	if session.human_player.ek < 5 and session.turn_manager.current_round <= 1:
		return 1
	if not session.slice_match.board_prototype.board_state.is_revealed(KarmanyPhase24FullMatchBridge.TILE_N2):
		return 2
	if session.human_player.get_linked_karmanys().size() < 2:
		return 3
	if not session.human_player.equipment_inventory.has_equipment_id(&"EQ-01"):
		return 4
	if not session.slice_match.board_prototype.board_state.is_revealed(KarmanyPhase24FullMatchBridge.TILE_EK):
		return 5
	var mission: KarmanyMissionAssignment = session.objectives_missions.get_mission_assignment(session.human_player.player_id)
	var objective: KarmanyObjectiveState = session.objectives_missions.get_objective_state(&"OP-E01")
	if (mission != null and not mission.is_completed()) or (objective != null and objective.claimed_by_player_id == &""):
		return 6
	return 7

static func get_text(session: KarmanyVerticalSliceSession) -> String:
	if session == null or not session.configured:
		return "ALPHA GUIADO · preparando partida..."
	var step: int = get_step_index(session)
	return "ALPHA GUIADO · paso %d/%d\n%s" % [step, TOTAL_STEPS, KarmanyVerticalSliceGoal.get_text(session)]

static func get_checklist(session: KarmanyVerticalSliceSession) -> String:
	if session == null or not session.configured:
		return "[ ] Preparar partida"
	var step: int = get_step_index(session)
	var labels: Array[String] = ["Economia inicial", "Explorar N2", "Vincular Karmany", "Craftear Equipo", "Resolver Bestia", "Mision + Objetivo", "Cerrar partida"]
	var lines: Array[String] = []
	for index in range(labels.size()):
		var completed: bool = (index + 1) < step or (step == TOTAL_STEPS and session.coordinator.is_finished)
		var current: bool = (index + 1) == step and not session.coordinator.is_finished
		var marker: String = "[x]" if completed else ("[>]" if current else "[ ]")
		lines.append("%s %s" % [marker, labels[index]])
	return "\n".join(lines)

static func get_controls_hint() -> String:
	return "Selecciona loseta con clic. Verde=Mover · azul=Explorar · rojo=Bestia. Usa exactamente 2 acciones y luego Finalizar turno + IA."
