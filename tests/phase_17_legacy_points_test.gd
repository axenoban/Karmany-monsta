extends Node


const B02: KarmanyBeastData = preload("res://data/beasts/b_02_picorroca.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 17 LEGACY POINTS TEST")
	print("================================")

	var ok: bool = true
	ok = _test_pending_rewards_and_ledger() and ok
	ok = _test_beast_and_pvp_adapters() and ok
	ok = _test_milestones_once_only() and ok
	ok = _test_standard_and_legacy_race_modes() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 17 OK - PL centralizados, origenes, hitos y modos validados.")
	else:
		push_error("FASE 17 ERROR - Revisar sistema central de PL.")
	print("================================")


func _test_pending_rewards_and_ledger() -> bool:
	var setup := _new_controller(false, KarmanyLegacyModeConfig.MapFormat.MAP_22)
	var controller: KarmanyLegacyPointsController = setup.controller
	var p1: KarmanyPlayerState = setup.p1
	var ok: bool = true

	var objective_reward := KarmanyLegacyRewardPending.new()
	ok = _expect(
		objective_reward.configure(
			KarmanyLegacyRewardPending.SourceType.PUBLIC_OBJECTIVE,
			&"OP-E01",
			p1.player_id,
			3,
			2
		),
		"No se pudo crear recompensa pendiente de Objetivo."
	) and ok
	var objective_award := controller.consume_pending_reward(objective_reward)
	ok = _expect(objective_award.was_applied(), "OP-E01 debe acreditar 3 PL.") and ok
	ok = _expect(objective_reward.consumed, "La recompensa de OP-E01 debe marcarse consumida.") and ok
	ok = _expect(controller.get_total(p1.player_id) == 3, "Total tras OP-E01 debe ser 3 PL.") and ok

	var repeated := controller.consume_pending_reward(objective_reward)
	ok = _expect(
		repeated.status == KarmanyLegacyPointsAwardResult.Status.ALREADY_CONSUMED,
		"Una recompensa pendiente no puede acreditarse dos veces."
	) and ok
	ok = _expect(controller.get_total(p1.player_id) == 3, "Repetir OP-E01 no debe alterar PL.") and ok

	var mission_reward := KarmanyLegacyRewardPending.new()
	mission_reward.configure(
		KarmanyLegacyRewardPending.SourceType.TRAINER_MISSION,
		&"ME-A1",
		p1.player_id,
		4,
		3
	)
	ok = _expect(controller.consume_pending_reward(mission_reward).was_applied(), "ME-A1 debe acreditar 4 PL.") and ok
	ok = _expect(controller.get_total(p1.player_id) == 7, "Objetivo + Mision deben sumar 7 PL.") and ok
	ok = _expect(controller.get_entries_for_player(p1.player_id).size() == 2, "El libro mayor debe conservar 2 entradas.") and ok
	ok = _expect(
		controller.get_points_by_source_type(
			p1.player_id,
			KarmanyLegacyPointsEntry.SourceType.PUBLIC_OBJECTIVE
		) == 3,
		"El origen Objetivo Publico debe poder auditarse."
	) and ok
	ok = _expect(
		controller.get_points_by_source_type(
			p1.player_id,
			KarmanyLegacyPointsEntry.SourceType.TRAINER_MISSION
		) == 4,
		"El origen Mision debe poder auditarse."
	) and ok

	print("Pendientes Objetivo/Mision + libro mayor + no duplicacion: ", "OK" if ok else "ERROR")
	return ok


func _test_beast_and_pvp_adapters() -> bool:
	var setup := _new_controller(false, KarmanyLegacyModeConfig.MapFormat.MAP_22)
	var controller: KarmanyLegacyPointsController = setup.controller
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var ok: bool = true

	var beast_state := KarmanyBeastRuntimeState.new()
	ok = _expect(
		beast_state.configure(B02, &"beast_phase17_001", Vector2i.ZERO),
		"No se pudo preparar Bestia de prueba."
	) and ok
	beast_state.mark_defeated()

	var combat := KarmanyCombatResult.new()
	combat.status = KarmanyCombatResult.Status.RESOLVED
	combat.outcome = KarmanyCombatResult.Outcome.VICTORY

	var beast_result := KarmanyBeastCombatResult.new()
	beast_result.status = KarmanyBeastCombatResult.Status.RESOLVED
	beast_result.beast_state = beast_state
	beast_result.combat_result = combat
	beast_result.reward_legacy_points_pending = 1

	var beast_award := controller.award_beast_result(p1.player_id, beast_result, 2)
	ok = _expect(beast_award.was_applied(), "B-02 derrotada debe acreditar 1 PL.") and ok
	ok = _expect(controller.get_total(p1.player_id) == 1, "player_1 debe tener 1 PL por Bestia.") and ok
	var duplicate_beast := controller.award_beast_result(p1.player_id, beast_result, 2)
	ok = _expect(
		duplicate_beast.status == KarmanyLegacyPointsAwardResult.Status.DUPLICATE,
		"La misma instancia de Bestia no puede puntuar dos veces."
	) and ok

	var pvp_result := KarmanyPvpCombatResult.new()
	pvp_result.status = KarmanyPvpCombatResult.Status.RESOLVED
	pvp_result.combat_id = &"pvp_phase17_001"
	pvp_result.attacker_player_id = p1.player_id
	pvp_result.defender_player_id = p2.player_id
	pvp_result.winner_player_id = p2.player_id
	pvp_result.loser_player_id = p1.player_id
	pvp_result.reward_legacy_points_pending = 2

	var pvp_award := controller.award_pvp_result(pvp_result, 3)
	ok = _expect(pvp_award.was_applied(), "PvP ganado debe acreditar 2 PL.") and ok
	ok = _expect(controller.get_total(p2.player_id) == 2, "player_2 debe tener 2 PL por PvP.") and ok
	var duplicate_pvp := controller.award_pvp_result(pvp_result, 3)
	ok = _expect(
		duplicate_pvp.status == KarmanyLegacyPointsAwardResult.Status.DUPLICATE,
		"El mismo combat_id PvP no puede puntuar dos veces."
	) and ok

	print("Bestia + PvP -> PL centralizados y protegidos contra duplicados: ", "OK" if ok else "ERROR")
	return ok


func _test_milestones_once_only() -> bool:
	var setup := _new_controller(false, KarmanyLegacyModeConfig.MapFormat.MAP_22)
	var controller: KarmanyLegacyPointsController = setup.controller
	var p1: KarmanyPlayerState = setup.p1
	var ok: bool = true

	var milestones: Array[StringName] = [
		KarmanyLegacyMilestoneCatalog.FIRST_N2_LINKED,
		KarmanyLegacyMilestoneCatalog.FIRST_N3_LINKED,
		KarmanyLegacyMilestoneCatalog.FIRST_ADVANCED_EQUIPMENT,
		KarmanyLegacyMilestoneCatalog.FIRST_ANCESTRAL_EQUIPMENT,
		KarmanyLegacyMilestoneCatalog.BOOK_III_REACHED
	]
	for milestone_id in milestones:
		ok = _expect(
			controller.award_milestone(p1.player_id, milestone_id, 4).was_applied(),
			"Cada Hito oficial debe poder acreditarse una vez."
		) and ok

	ok = _expect(controller.get_total(p1.player_id) == 9, "Los cinco Hitos deben sumar exactamente 9 PL.") and ok
	var repeated := controller.award_milestone(
		p1.player_id,
		KarmanyLegacyMilestoneCatalog.BOOK_III_REACHED,
		5
	)
	ok = _expect(
		repeated.status == KarmanyLegacyPointsAwardResult.Status.DUPLICATE,
		"Libro III no puede puntuar dos veces para el mismo jugador."
	) and ok
	ok = _expect(controller.get_total(p1.player_id) == 9, "Repetir un Hito no debe modificar el total.") and ok

	print("5 Hitos oficiales + una sola vez por jugador = 9 PL: ", "OK" if ok else "ERROR")
	return ok


func _test_standard_and_legacy_race_modes() -> bool:
	var standard := _new_controller(false, KarmanyLegacyModeConfig.MapFormat.MAP_22)
	var standard_controller: KarmanyLegacyPointsController = standard.controller
	var ok: bool = true

	ok = _expect(
		not standard_controller.evaluate_end_of_round(6).should_end_match,
		"Mapa 22 estandar no debe terminar antes de ronda 7."
	) and ok
	var standard_end := standard_controller.evaluate_end_of_round(7)
	ok = _expect(standard_end.should_end_match, "Mapa 22 estandar debe terminar al cierre de ronda 7.") and ok
	ok = _expect(
		standard_end.reason_id == KarmanyLegacyPointsController.REASON_STANDARD_ROUND_LIMIT,
		"El motivo debe registrar limite de rondas estandar."
	) and ok

	var race := _new_controller(true, KarmanyLegacyModeConfig.MapFormat.MAP_22)
	var race_controller: KarmanyLegacyPointsController = race.controller
	var race_p1: KarmanyPlayerState = race.p1
	var race_p2: KarmanyPlayerState = race.p2

	race_controller.award_points(
		race_p1.player_id,
		KarmanyLegacyPointsEntry.SourceType.OTHER,
		&"test_progress_21",
		21,
		5,
		&"test_progress_21"
	)
	ok = _expect(
		not race_controller.evaluate_end_of_round(5).should_end_match,
		"Carrera mapa 22 no termina con 21 PL."
	) and ok
	race_controller.award_points(
		race_p1.player_id,
		KarmanyLegacyPointsEntry.SourceType.OTHER,
		&"test_progress_1",
		1,
		6,
		&"test_progress_1"
	)
	race_controller.award_points(
		race_p2.player_id,
		KarmanyLegacyPointsEntry.SourceType.OTHER,
		&"test_progress_23",
		23,
		6,
		&"test_progress_23"
	)
	var race_end := race_controller.evaluate_end_of_round(6)
	ok = _expect(race_end.should_end_match, "Carrera mapa 22 debe terminar al cierre de ronda con jugador >=22 PL.") and ok
	ok = _expect(race_end.target_points == 22, "Meta oficial mapa 22 debe ser 22 PL.") and ok
	ok = _expect(race_end.target_reached_player_ids.has(race_p1.player_id), "player_1 debe constar como meta alcanzada.") and ok
	ok = _expect(race_end.leader_player_ids.size() == 1 and race_end.leader_player_ids[0] == race_p2.player_id, "Tras completar toda la ronda debe liderar quien tenga mas PL, aunque otro cruzara primero la meta.") and ok

	var race41 := _new_controller(true, KarmanyLegacyModeConfig.MapFormat.MAP_41)
	var race41_controller: KarmanyLegacyPointsController = race41.controller
	ok = _expect(race41_controller.mode_config.race_target_points == 25, "Meta oficial mapa 41 debe ser 25 PL.") and ok

	print("Modo estandar + Carrera 22/25 PL evaluados al cierre de ronda: ", "OK" if ok else "ERROR")
	return ok


func _new_controller(
	legacy_race: bool,
	map_format: int
) -> Dictionary:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i(1, 0))

	var config := KarmanyLegacyModeConfig.new()
	if legacy_race:
		config.configure_legacy_race(map_format)
	else:
		config.configure_standard(map_format)

	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	var controller := KarmanyLegacyPointsController.new()
	controller.configure(players, config)
	return {
		"p1": p1,
		"p2": p2,
		"controller": controller
	}


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 17 ERROR: %s" % message)
	return false
