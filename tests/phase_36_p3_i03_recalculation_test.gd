extends Node


const TEST_SEED: int = 36001


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 36A P3 I-03 RECALCULATION")
	print("================================")

	var ok: bool = _test_p3_recalculates_after_useful_interaction()
	if ok:
		print("FASE 36A P3 I-03 OK - la segunda accion usa el estado actualizado.")
	else:
		push_error("FASE 36A P3 I-03 ERROR - revisar recalculo oportunista.")
	print("================================")


func _test_p3_recalculates_after_useful_interaction() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED):
		return _fail("No se pudo configurar runtime 4P.")
	if not runtime.simulate_human_probe_turn():
		return _fail("P1 no pudo entregar turno a P2.")
	if not runtime.ai_match_controller.run_current_ai_turn():
		return _fail("P2 no pudo completar su turno.")

	var manager := runtime.local_session.turn_manager
	var p3 := manager.get_active_player()
	if p3 == null or p3.player_id != &"player_3":
		return _fail("El turno no llego a P3.")
	var current_tile: KarmanyTileData = runtime.board_state.get_tile_data(p3.current_coord)
	if current_tile == null or current_tile.tile_id != &"I-03":
		return _fail("P3 no comienza el probe sobre I-03.")
	if p3.mr != 1:
		return _fail("El probe esperaba MR inicial=1 para P3 y obtuvo %d." % p3.mr)

	var controller := runtime.ai_match_controller.get_ai_controller(p3.player_id)
	if controller == null:
		return _fail("P3 no posee KarmanyAiTurnController.")

	var first_candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		p3
	)
	var first_interaction := _find_action(
		first_candidates,
		KarmanyAiActionCandidate.ActionType.INTERACT
	)
	if first_interaction == null:
		return _fail("Interactuar I-03 no es legal con MR escaso.")
	if not _has_progress_alternative(first_candidates):
		return _fail("El probe no posee alternativa espacial real.")

	var first_choice := controller.brain.choose_action(first_candidates)
	if first_choice == null:
		return _fail("P3 no pudo elegir primera accion.")
	if first_choice.action_type != KarmanyAiActionCandidate.ActionType.INTERACT:
		return _fail("Con MR=1 el probe esperaba que I-03 siguiera siendo una oportunidad util.")
	var first_breakdown: Dictionary = controller.brain.get_score_breakdown(first_choice)

	var first_execution := controller.execute_one_action(runtime.coordinator, p3)
	if first_execution == null or not first_execution.was_executed():
		return _fail("La primera Interaccion util fue rechazada.")
	if p3.mr != 3:
		return _fail("I-03 no aplico +2 MR real: MR actual=%d." % p3.mr)
	if manager.actions_remaining != 1:
		return _fail("La primera accion no dejo exactamente 1 accion restante.")

	# Aqui se reconstruyen las acciones desde el estado POST-interaccion.
	var second_candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		p3
	)
	var repeated_interaction := _find_action(
		second_candidates,
		KarmanyAiActionCandidate.ActionType.INTERACT
	)
	if repeated_interaction == null:
		return _fail("La correccion convirtio la repeticion en ilegal.")
	if not _has_progress_alternative(second_candidates):
		return _fail("Despues de Interactuar desaparecio toda alternativa espacial.")

	var repeated_breakdown: Dictionary = controller.brain.get_score_breakdown(
		repeated_interaction
	)
	var second_choice := controller.brain.choose_action(second_candidates)
	if second_choice == null:
		return _fail("P3 no pudo elegir segunda accion.")
	if second_choice.action_type == KarmanyAiActionCandidate.ActionType.INTERACT:
		return _fail("P3 repitio automaticamente I-03 pese a MR actualizado y progreso disponible.")
	var second_breakdown: Dictionary = controller.brain.get_score_breakdown(second_choice)
	if float(repeated_breakdown.get("repetition_penalty", 0.0)) <= 0.0:
		return _fail("La repeticion identica no recibio penalizacion suave.")
	if float(repeated_breakdown.get("final_score", 0.0)) >= float(first_breakdown.get("final_score", 0.0)):
		return _fail("La utilidad de repetir I-03 no disminuyo tras acumular MR.")
	if float(second_breakdown.get("final_score", -INF)) <= float(repeated_breakdown.get("final_score", -INF)):
		return _fail("La alternativa elegida no supera realmente a la repeticion.")

	var second_execution := controller.execute_one_action(runtime.coordinator, p3)
	if second_execution == null or not second_execution.was_executed():
		return _fail("La segunda accion reevaluada no pudo ejecutarse.")
	if manager.actions_remaining != 0:
		return _fail("Las dos decisiones no consumieron exactamente el presupuesto 2/2.")

	print("P3 I-03: primera=%s score=%.3f | MR 1→3" % [
		first_choice.debug_label,
		float(first_breakdown.get("final_score", 0.0))
	])
	print("P3 I-03: repetir score=%.3f (penalizacion %.3f) | segunda=%s score=%.3f" % [
		float(repeated_breakdown.get("final_score", 0.0)),
		float(repeated_breakdown.get("repetition_penalty", 0.0)),
		second_choice.debug_label,
		float(second_breakdown.get("final_score", 0.0))
	])
	return true


func _find_action(
	candidates: Array[KarmanyAiActionCandidate],
	action_type: int
) -> KarmanyAiActionCandidate:
	for candidate in candidates:
		if candidate != null and candidate.action_type == action_type:
			return candidate
	return null


func _has_progress_alternative(candidates: Array[KarmanyAiActionCandidate]) -> bool:
	for candidate in candidates:
		if candidate == null:
			continue
		if (
			candidate.action_type == KarmanyAiActionCandidate.ActionType.MOVE
			or candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE
		):
			return true
	return false


func _fail(message: String) -> bool:
	push_error("FASE 36A P3 I-03 TEST ERROR: %s" % message)
	return false
