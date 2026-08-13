extends Node

const SLICE_SCENE: PackedScene = preload("res://scenes/ui/phase_28_vertical_slice_prototype.tscn")
var slice_instance: KarmanyPhase28VerticalSliceBridge = null

func _ready() -> void:
	print("\n================================\nKARMANY MONSTA - PHASE 28 VERTICAL SLICE TEST\n================================")
	var ok: bool = await _run_slice()
	if ok:
		print("FASE 28 OK - Vertical Slice integrado, jugable y representativo validado.")
	else:
		push_error("FASE 28 ERROR - Revisar el primer fallo del Vertical Slice.")
	print("================================")

func _run_slice() -> bool:
	slice_instance = SLICE_SCENE.instantiate() as KarmanyPhase28VerticalSliceBridge
	if slice_instance == null:
		return _fail("No se pudo instanciar el slice.")
	add_child(slice_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	if not slice_instance.setup_ok:
		return _fail("Setup del slice invalido.")
	var session: KarmanyVerticalSliceSession = slice_instance.session
	if session.turn_manager.current_round != 1 or not session.is_human_turn() or session.turn_manager.actions_remaining != 2:
		return _fail("Inicio/turno/acciones incorrectos.")
	print("Inicio + tablero + entrenador + HUD + 2 acciones: OK")

	if not _two_actions(session, Callable(session, "interact_current_tile"), Callable(session, "interact_current_tile")):
		return false
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre R1/IA fallo.")

	if not session.explore_to(KarmanyPhase24FullMatchBridge.TILE_N2): return _fail("Explorar N2 fallo.")
	if not session.call_or_bond(): return _fail("Llamar Brumak fallo.")
	if not session.save_slice() or not session.load_slice(): return _fail("Guardar/Cargar fallo.")
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre R2/IA fallo.")
	print("Exploracion + encuentro + Guardar/Cargar + IA: OK")

	if not session.call_or_bond(): return _fail("Vincular Brumak fallo.")
	var active: KarmanyRuntimeState = session.human_player.get_active_karmany()
	if active == null or active.karmany_data == null or active.karmany_data.karmany_id != &"K-10":
		return _fail("Brumak no quedo activo.")
	if not session.craft_slice_equipment(): return _fail("Craftear EQ-01 fallo.")
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre R3/IA fallo.")
	print("Karmany + Vinculo + Equipo: OK")

	if not session.explore_to(KarmanyPhase24FullMatchBridge.TILE_EK): return _fail("Explorar encuentro Bestia fallo.")
	if not session.slice_match.board_prototype.board_state.has_beast(session.human_player.current_coord): return _fail("Garravol no aparecio.")
	if not session.fight_current_beast(): return _fail("Combate Garravol fallo.")
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre R4/IA fallo.")
	print("Resonancia + Bestia + Combate + PL: OK")

	if not session.explore_to(KarmanyPhase24FullMatchBridge.TILE_MR): return _fail("Explorar tercera loseta fallo.")
	if not session.interact_current_tile(0): return _fail("Interactuar N1-02 fallo.")
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre R5/IA fallo.")

	if not session.move_to(KarmanyPhase24FullMatchBridge.P1_START): return _fail("Mover centro R6 fallo.")
	if not session.explore_to(KarmanyPhase24FullMatchBridge.TILE_N3): return _fail("Explorar quinta coordenada fallo.")
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre R6/IA fallo.")

	if not session.move_to(KarmanyPhase24FullMatchBridge.P1_START): return _fail("Mover centro R7 fallo.")
	if not session.interact_current_tile(0): return _fail("Segunda accion R7 fallo.")
	if not session.end_human_turn_and_run_ai(): return _fail("Cierre final R7 fallo.")

	var mission: KarmanyMissionAssignment = session.objectives_missions.get_mission_assignment(session.human_player.player_id)
	var objective: KarmanyObjectiveState = session.objectives_missions.get_objective_state(&"OP-E01")
	if mission == null or not mission.is_completed(): return _fail("Mision no completada.")
	if objective == null or objective.claimed_by_player_id != session.human_player.player_id: return _fail("Objetivo no reclamado.")
	if session.turn_manager.is_running or not session.coordinator.is_finished: return _fail("Partida no termino en ronda 7.")
	if session.legacy_points.get_total(session.human_player.player_id) <= 0: return _fail("Sin PL al final.")
	if session.get_metrics_summary().is_empty(): return _fail("Metricas F27 no disponibles.")
	print("Mision + Objetivo + PL + cierre representativo: OK")
	return true

func _two_actions(session: KarmanyVerticalSliceSession, first_action: Callable, second_action: Callable) -> bool:
	if not first_action.call() or not second_action.call():
		return _fail("Dos acciones representativas fallaron.")
	return session.turn_manager.actions_remaining == 0

func _fail(message: String) -> bool:
	push_error("FASE 28 ERROR: %s" % message)
	return false
