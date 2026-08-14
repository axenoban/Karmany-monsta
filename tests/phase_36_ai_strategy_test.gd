extends Node


const TEST_SEED: int = 36001
const MULTIROUND_SEEDS: Array[int] = [36001, 36017, 36103, 36211]
const MAX_ROUNDS_PER_SEED: int = 6
const STAGNATION_TURN_LIMIT: int = 3


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 36A AI STRATEGY TEST")
	print("================================")

	var ok: bool = true
	ok = _test_marginal_resource_value_all_types() and ok
	ok = _test_opportunist_i03_low_vs_high_mr() and ok
	ok = _test_interact_remains_repeatable() and ok
	ok = _test_soft_repetition_penalty() and ok
	ok = _test_profile_personalities() and ok
	ok = _test_multiround_stagnation_matrix() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 36A OK - valor marginal, repeticion suave y anti-estancamiento validados.")
	else:
		push_error("FASE 36A ERROR - revisar el primer fallo estrategico real.")
	print("================================")


func _test_marginal_resource_value_all_types() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED):
		return _fail("No se pudo configurar runtime para utilidad marginal.")
	var player := runtime.local_session.get_player_by_id(&"player_3")
	if player == null:
		return _fail("P3 no existe en runtime.")

	for resource_type in [
		KarmanyEffectData.ResourceType.MN,
		KarmanyEffectData.ResourceType.MR,
		KarmanyEffectData.ResourceType.EK,
		KarmanyEffectData.ResourceType.FA
	]:
		player.resource_inventory.set_resource(resource_type, 0)
		var low := KarmanyAiResourceUtility.estimate_resource_gain(
			resource_type, 2, player, runtime.coordinator
		)
		player.resource_inventory.set_resource(resource_type, 10)
		var high := KarmanyAiResourceUtility.estimate_resource_gain(
			resource_type, 2, player, runtime.coordinator
		)
		if float(low.get("value", 0.0)) <= float(high.get("value", 0.0)):
			return _fail("La utilidad marginal no disminuye para recurso %d." % resource_type)

	print("MN/MR/EK/FA: utilidad marginal decreciente: OK")
	return true


func _test_opportunist_i03_low_vs_high_mr() -> bool:
	var low_runtime := _runtime_with_p3_active(TEST_SEED)
	if low_runtime == null:
		return _fail("No se pudo preparar P3 activo con MR escaso.")
	var low_p3 := low_runtime.local_session.get_player_by_id(&"player_3")
	var low_controller := low_runtime.ai_match_controller.get_ai_controller(&"player_3")
	var low_candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		low_runtime.coordinator, low_p3
	)
	var low_interact := _find_action(low_candidates, KarmanyAiActionCandidate.ActionType.INTERACT)
	if low_interact == null:
		return _fail("Escenario A: Interactuar I-03 dejo de ser legal.")
	if not _has_progress_alternative(low_candidates):
		return _fail("Escenario A no posee alternativa Mover/Explorar.")
	var low_score: float = low_controller.brain.score_action(low_interact)
	var low_choice := low_controller.brain.choose_action(low_candidates)
	if low_choice == null:
		return _fail("Escenario A: Oportunista no pudo elegir accion.")

	var high_runtime := _runtime_with_p3_active(TEST_SEED)
	if high_runtime == null:
		return _fail("No se pudo preparar P3 activo con MR alto.")
	var high_p3 := high_runtime.local_session.get_player_by_id(&"player_3")
	high_p3.resource_inventory.set_resource(KarmanyEffectData.ResourceType.MR, 10)
	var high_controller := high_runtime.ai_match_controller.get_ai_controller(&"player_3")
	var high_candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		high_runtime.coordinator, high_p3
	)
	var high_interact := _find_action(high_candidates, KarmanyAiActionCandidate.ActionType.INTERACT)
	if high_interact == null:
		return _fail("Escenario B: Interactuar fue prohibido artificialmente.")
	if not _has_progress_alternative(high_candidates):
		return _fail("Escenario B no posee progreso alternativo real.")
	var high_score: float = high_controller.brain.score_action(high_interact)
	if high_score >= low_score:
		return _fail("+2 MR conserva valor igual/mayor con reserva alta.")
	var high_choice := high_controller.brain.choose_action(high_candidates)
	if high_choice == null:
		return _fail("Escenario B: Oportunista no pudo elegir accion.")
	if high_choice.action_type == KarmanyAiActionCandidate.ActionType.INTERACT:
		return _fail("Escenario B: +2 MR sigue dominando automaticamente con MR=10.")

	print("I-03: MR escaso mantiene Interactuar valido; MR alto prioriza progreso: OK")
	print("  score Interact bajo=%.3f | alto=%.3f | eleccion baja=%s | alta=%s" % [
		low_score, high_score, low_choice.debug_label, high_choice.debug_label
	])
	return true


func _test_interact_remains_repeatable() -> bool:
	var runtime := _runtime_with_p3_active(TEST_SEED + 1)
	if runtime == null:
		return _fail("No se pudo preparar repeticion legal de I-03.")
	var p3 := runtime.local_session.get_player_by_id(&"player_3")
	var mr_before: int = p3.mr

	for repetition_index in range(2):
		var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(runtime.coordinator, p3)
		var interaction := _find_action(candidates, KarmanyAiActionCandidate.ActionType.INTERACT)
		if interaction == null:
			return _fail("Interactuar dejo de ser legal en repeticion %d." % (repetition_index + 1))
		var execution := KarmanyAiActionExecutor.execute(runtime.coordinator, p3, interaction)
		if execution == null or not execution.was_executed():
			return _fail("Interactuar + Interactuar fue bloqueado por la correccion IA.")

	if p3.mr != mr_before + 4:
		return _fail("Dos interacciones legales no aplicaron +4 MR real.")
	if runtime.local_session.turn_manager.actions_remaining != 0:
		return _fail("Interactuar + Interactuar no consumio exactamente 2 acciones.")
	print("Legalidad: Interactuar + Interactuar sigue permitido cuando se fuerza: OK")
	return true


func _test_soft_repetition_penalty() -> bool:
	var brain := KarmanyAiBrain.new()
	if not brain.configure(KarmanyAiProfile.ProfileType.OPPORTUNIST, TEST_SEED):
		return _fail("No se pudo configurar cerebro para penalizacion suave.")
	var interaction := KarmanyAiActionCandidate.new()
	interaction.action_type = KarmanyAiActionCandidate.ActionType.INTERACT
	interaction.target_coord = Vector2i(-4, 2)
	interaction.option_index = 0
	interaction.debug_label = "Interactuar I-03 opcion 0"
	interaction.base_utility = 1.0
	interaction.economy_value = 3.0
	interaction.opportunity_value = 3.5

	var first_score: float = brain.score_action(interaction)
	brain.record_executed_action(interaction)
	var second_score: float = brain.score_action(interaction)
	brain.record_executed_action(interaction)
	var third_score: float = brain.score_action(interaction)
	if not (first_score > second_score and second_score > third_score):
		return _fail("La penalizacion no crece progresivamente con repeticion identica.")
	if third_score == -INF:
		return _fail("La penalizacion suave convirtio una accion legal en prohibicion.")
	print("Memoria corta: score %.2f -> %.2f -> %.2f sin prohibir accion: OK" % [
		first_score, second_score, third_score
	])
	return true


func _test_profile_personalities() -> bool:
	var explore := _candidate(KarmanyAiActionCandidate.ActionType.EXPLORE, "Explorar")
	explore.exploration_value = 3.0
	explore.progress_value = 1.0
	var pvp := _candidate(KarmanyAiActionCandidate.ActionType.PVP, "PvP")
	pvp.aggression_value = 4.0
	var interact := _candidate(KarmanyAiActionCandidate.ActionType.INTERACT, "Interactuar")
	interact.opportunity_value = 5.0
	interact.economy_value = 4.0
	var candidates: Array[KarmanyAiActionCandidate] = [explore, pvp, interact]
	var expected: Dictionary = {
		KarmanyAiProfile.ProfileType.EXPLORER: explore,
		KarmanyAiProfile.ProfileType.OPPORTUNIST: interact,
		KarmanyAiProfile.ProfileType.AGGRESSIVE: pvp
	}
	for profile_type in expected.keys():
		var brain := KarmanyAiBrain.new()
		if not brain.configure(int(profile_type), TEST_SEED + int(profile_type)):
			return _fail("No se pudo configurar perfil %d." % profile_type)
		if brain.choose_action(candidates) != expected[profile_type]:
			return _fail("La personalidad IA %d fue homogeneizada." % profile_type)
	print("Personalidades Exploradora/Oportunista/Agresiva permanecen distintas: OK")
	return true


func _test_multiround_stagnation_matrix() -> bool:
	for seed_value in MULTIROUND_SEEDS:
		var runtime := KarmanyMultiAiAlphaRuntime.new()
		if not runtime.configure_new(4, seed_value):
			return _fail("Seed %d no pudo configurar runtime." % seed_value)
		var p3 := runtime.local_session.get_player_by_id(&"player_3")
		var stagnation_streak: int = 0
		var max_stagnation_streak: int = 0
		var p3_turns: int = 0

		while (
			runtime.local_session.turn_manager.is_running
			and runtime.local_session.turn_manager.current_round <= MAX_ROUNDS_PER_SEED
		):
			var active := runtime.local_session.turn_manager.get_active_player()
			if active == null:
				return _fail("Seed %d perdio jugador activo." % seed_value)
			if runtime.ai_match_controller.is_human_player(active.player_id):
				if not runtime.simulate_human_probe_turn():
					return _fail("Seed %d no pudo cerrar turno humano probe." % seed_value)
				continue

			var inspect_p3: bool = active.player_id == &"player_3"
			var coord_before: Vector2i = active.current_coord
			var had_progress_alternative: bool = false
			if inspect_p3:
				p3_turns += 1
				var legal_before := KarmanyAiLegalActionGenerator.build_legal_actions(
					runtime.coordinator, active
				)
				had_progress_alternative = _has_progress_alternative(legal_before)

			if not runtime.ai_match_controller.run_current_ai_turn():
				return _fail("Seed %d fallo turno IA %s." % [seed_value, active.player_id])

			if inspect_p3:
				var only_same_interaction: bool = _last_turn_is_only_interaction(
					runtime.ai_match_controller
				)
				var stayed_put: bool = p3.current_coord == coord_before
				if had_progress_alternative and stayed_put and only_same_interaction:
					stagnation_streak += 1
				else:
					stagnation_streak = 0
				max_stagnation_streak = maxi(max_stagnation_streak, stagnation_streak)
				if stagnation_streak >= STAGNATION_TURN_LIMIT:
					push_error("AI STRATEGIC STAGNATION seed=%d coord=%s MR=%d" % [
						seed_value, str(p3.current_coord), p3.mr
					])
					return false

		print("Seed %d | P3 turnos=%d | max estancamiento=%d | coord=%s | MR=%d" % [
			seed_value,
			p3_turns,
			max_stagnation_streak,
			str(p3.current_coord),
			p3.mr
		])

	print("Matriz multirronda determinista sin farming indefinido evidente: OK")
	return true


func _runtime_with_p3_active(seed_value: int) -> KarmanyMultiAiAlphaRuntime:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		return null
	if not runtime.simulate_human_probe_turn():
		return null
	if runtime.local_session.turn_manager.get_active_player().player_id != &"player_2":
		return null
	if not runtime.ai_match_controller.run_current_ai_turn():
		return null
	var active := runtime.local_session.turn_manager.get_active_player()
	if active == null or active.player_id != &"player_3":
		return null
	return runtime


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


func _last_turn_is_only_interaction(controller: KarmanyMultiAiMatchController) -> bool:
	var successful: int = 0
	for diagnostic in controller.last_turn_diagnostics:
		if not bool(diagnostic.get("success", false)):
			continue
		successful += 1
		if int(diagnostic.get("action_type", -1)) != KarmanyAiActionCandidate.ActionType.INTERACT:
			return false
	return successful > 0


func _candidate(action_type: int, label: String) -> KarmanyAiActionCandidate:
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = action_type
	candidate.debug_label = label
	candidate.base_utility = 1.0
	return candidate


func _fail(message: String) -> bool:
	push_error("FASE 36A TEST ERROR: %s" % message)
	return false
