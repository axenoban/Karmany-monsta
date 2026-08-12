extends Node


const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const BRUMAK: KarmanyData = preload("res://data/karmanys/k_10_brumak.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 11 COMBAT RESOLVER TEST")
	print("================================")

	var test_passed: bool = true
	test_passed = _test_instinct_table() and test_passed
	test_passed = _test_power_formula_and_tie() and test_passed
	test_passed = _test_generic_beast_combat() and test_passed
	test_passed = _test_risk_die() and test_passed
	test_passed = _test_invalid_requests() and test_passed
	test_passed = _test_phase_10_bond_integration() and test_passed

	print("")
	print("================================")
	if test_passed:
		print("FASE 11 OK - CombatResolver PvE base validado.")
	else:
		push_error("FASE 11 ERROR - Revisar CombatResolver.")
	print("================================")


func _test_instinct_table() -> bool:
	var expected: Dictionary = {
		1: -2,
		2: -1,
		3: 0,
		4: 0,
		5: 1,
		6: 2
	}
	var ok: bool = true

	for roll in expected.keys():
		ok = _expect(
			KarmanyCombatResolver.get_instinct_adjustment(int(roll)) == int(expected[roll]),
			"Instinto incorrecto para D6=%d." % int(roll)
		) and ok

	print("Tabla Dado de Instinto -2/-1/0/0/+1/+2: ", "OK" if ok else "ERROR")
	return ok


func _test_power_formula_and_tie() -> bool:
	var request := _base_request()
	request.target_id = &"beast_formula_test"
	request.target_type = KarmanyCombatRequest.TargetType.BEAST
	request.base_defense = 14
	request.instinct_roll = 1
	request.modifiers.equipment_power = 1
	request.modifiers.resonance_power = 1
	request.modifiers.trainer_power = 1
	request.modifiers.book_power = 1
	request.modifiers.other_power = 2

	var result := KarmanyCombatResolver.resolve(request)
	var ok: bool = true
	ok = _expect(result.is_resolved(), "El combate de formula debe resolverse.") and ok
	ok = _expect(result.base_power == 6, "Terrakor debe aportar Poder base 6.") and ok
	ok = _expect(result.total_power == 12, "Poder total esperado: 12.") and ok
	ok = _expect(result.instinct_adjustment == -2, "Instinto 1 debe reducir Defensa en 2.") and ok
	ok = _expect(result.effective_defense == 12, "Defensa efectiva esperada: 12.") and ok
	ok = _expect(result.is_victory(), "Igualar Defensa efectiva debe ser victoria.") and ok
	ok = _expect(
		result.pending_consequences.has(KarmanyCombatResolver.CONSEQUENCE_TARGET_DEFEATED),
		"La victoria debe registrar consecuencia de objetivo derrotado."
	) and ok

	print("Formula completa + empate PvE = victoria: ", "OK" if ok else "ERROR")
	return ok


func _test_generic_beast_combat() -> bool:
	var request := _base_request()
	request.target_id = &"B-TEST"
	request.target_type = KarmanyCombatRequest.TargetType.BEAST
	request.base_defense = 8
	request.instinct_roll = 3
	request.modifiers.equipment_power = 2

	var victory := KarmanyCombatResolver.resolve(request)
	var ok: bool = true
	ok = _expect(victory.is_victory(), "6 + 2 debe igualar Defensa 8 y ganar.") and ok

	request.modifiers.equipment_power = 0
	request.instinct_roll = 6
	var defeat := KarmanyCombatResolver.resolve(request)
	ok = _expect(defeat.is_defeat(), "Poder 6 no debe superar Defensa efectiva 10.") and ok
	ok = _expect(defeat.effective_defense == 10, "Instinto 6 debe dejar Defensa 10.") and ok
	ok = _expect(
		defeat.pending_consequences.has(KarmanyCombatResolver.CONSEQUENCE_ATTACKER_DEFEATED),
		"La derrota debe quedar registrada como consecuencia pendiente."
	) and ok

	print("Objetivo Bestia generico sin BeastData: ", "OK" if ok else "ERROR")
	return ok


func _test_risk_die() -> bool:
	var ok: bool = true
	ok = _expect(KarmanyCombatResolver.get_risk_power_adjustment(1) == -3, "Riesgo 1 debe ser -3 Poder.") and ok
	ok = _expect(KarmanyCombatResolver.get_risk_power_adjustment(2) == 0, "Riesgo 2 no modifica Poder.") and ok
	ok = _expect(KarmanyCombatResolver.get_risk_power_adjustment(3) == 0, "Riesgo 3 no modifica Poder.") and ok
	ok = _expect(KarmanyCombatResolver.get_risk_power_adjustment(4) == 0, "Riesgo 4 no modifica Poder.") and ok
	ok = _expect(KarmanyCombatResolver.get_risk_power_adjustment(5) == 7, "Riesgo 5 debe ser +7 Poder.") and ok
	ok = _expect(KarmanyCombatResolver.get_risk_power_adjustment(6) == 10, "Riesgo 6 debe ser +10 Poder.") and ok

	var discard_request := _base_request()
	discard_request.target_id = &"risk_2_target"
	discard_request.base_defense = 20
	discard_request.instinct_roll = 3
	discard_request.risk_authorized = true
	discard_request.risk_roll = 2
	var discard_result := KarmanyCombatResolver.resolve(discard_request)
	ok = _expect(
		discard_result.pending_consequences.has(KarmanyCombatResolver.CONSEQUENCE_RISK_DISCARD_CARD),
		"Riesgo 2 debe dejar descarte de carta como consecuencia posterior."
	) and ok

	var filter_request := _base_request()
	filter_request.target_id = &"risk_4_target"
	filter_request.base_defense = 20
	filter_request.instinct_roll = 3
	filter_request.risk_authorized = true
	filter_request.risk_roll = 4
	var filter_result := KarmanyCombatResolver.resolve(filter_request)
	ok = _expect(
		filter_result.pending_consequences.has(KarmanyCombatResolver.CONSEQUENCE_RISK_FILTER_RESONANCE),
		"Riesgo 4 debe dejar filtrado de Resonancia como consecuencia posterior."
	) and ok

	var reward_request := _base_request()
	reward_request.target_id = &"risk_6_target"
	reward_request.base_defense = 12
	reward_request.instinct_roll = 3
	reward_request.risk_authorized = true
	reward_request.risk_roll = 6
	var reward_result := KarmanyCombatResolver.resolve(reward_request)
	ok = _expect(reward_result.total_power == 16, "Riesgo 6 debe llevar Terrakor 6 a Poder 16.") and ok
	ok = _expect(reward_result.is_victory(), "Riesgo 6 debe ganar el escenario de prueba.") and ok
	ok = _expect(
		reward_result.pending_consequences.has(KarmanyCombatResolver.CONSEQUENCE_RISK_WIN_REWARD),
		"Riesgo 6 victorioso debe registrar eleccion de recompensa."
	) and ok

	print("Dado de Riesgo 2.0 y consecuencias pendientes: ", "OK" if ok else "ERROR")
	return ok


func _test_invalid_requests() -> bool:
	var ok: bool = true

	var missing_instinct := _base_request()
	missing_instinct.target_id = &"missing_instinct"
	missing_instinct.base_defense = 8
	missing_instinct.instinct_roll = 0
	var invalid_instinct := KarmanyCombatResolver.resolve(missing_instinct)
	ok = _expect(
		invalid_instinct.status == KarmanyCombatResult.Status.INVALID_REQUEST,
		"Un objetivo PvE requiere D6 de Instinto 1-6."
	) and ok

	var disabled_instinct := _base_request()
	disabled_instinct.target_id = &"disabled_instinct"
	disabled_instinct.base_defense = 8
	disabled_instinct.uses_instinct = false
	disabled_instinct.instinct_roll = 0
	var invalid_disabled_instinct := KarmanyCombatResolver.resolve(disabled_instinct)
	ok = _expect(
		invalid_disabled_instinct.status == KarmanyCombatResult.Status.INVALID_REQUEST,
		"Fase 11 no debe permitir PvE sin Instinto."
	) and ok

	var unauthorized_risk := _base_request()
	unauthorized_risk.target_id = &"unauthorized_risk"
	unauthorized_risk.base_defense = 8
	unauthorized_risk.instinct_roll = 3
	unauthorized_risk.risk_roll = 5
	unauthorized_risk.risk_authorized = false
	var invalid_risk := KarmanyCombatResolver.resolve(unauthorized_risk)
	ok = _expect(
		invalid_risk.status == KarmanyCombatResult.Status.INVALID_REQUEST,
		"Riesgo sin permiso debe rechazarse."
	) and ok

	print("Validaciones PvE e Instinto obligatorias: ", "OK" if ok else "ERROR")
	return ok


func _test_phase_10_bond_integration() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	var ok: bool = _expect(manager.setup_players(players), "No se pudieron preparar jugadores para integracion.")
	ok = _expect(manager.start_match(), "No se pudo iniciar partida para integracion.") and ok

	var encounter_resolver := KarmanyEncounterResolver.new()
	ok = _expect(encounter_resolver.configure(manager), "No se pudo configurar EncounterResolver.") and ok
	var encounter := encounter_resolver.create_visible_encounter(
		BRUMAK,
		Vector2i.ZERO,
		KarmanyData.Rank.N2,
		p1.player_id
	)
	ok = _expect(encounter != null, "No se pudo crear encuentro de Brumak.") and ok

	var pending := encounter_resolver.begin_defeat_bond_attempt(encounter, p1)
	ok = _expect(pending.is_pending_combat(), "Fase 10 debe entregar PENDING_COMBAT.") and ok
	ok = _expect(pending.defense_target == 12, "Brumak debe entregar Defensa 12.") and ok
	ok = _expect(pending.requires_instinct_roll, "Brumak no vinculado debe usar Instinto.") and ok

	var combat_request := _base_request()
	combat_request.target_id = BRUMAK.karmany_id
	combat_request.target_type = KarmanyCombatRequest.TargetType.UNBOUND_KARMANY
	combat_request.base_defense = pending.defense_target
	combat_request.uses_instinct = pending.requires_instinct_roll
	combat_request.instinct_roll = 1
	combat_request.modifiers.equipment_power = 2
	combat_request.modifiers.resonance_power = 2

	var combat := KarmanyCombatResolver.resolve(combat_request)
	ok = _expect(combat.total_power == 10, "Terrakor + modificadores debe dar Poder 10.") and ok
	ok = _expect(combat.effective_defense == 10, "Brumak 12 con Instinto 1 debe quedar en Defensa 10.") and ok
	ok = _expect(combat.is_victory(), "Igualar 10 contra 10 debe derrotar a Brumak.") and ok

	var bond := encounter_resolver.complete_defeat_bond(
		encounter,
		p1,
		combat.is_victory()
	)
	ok = _expect(bond.is_success(), "Victoria de CombatResolver debe completar el vinculo de Fase 10.") and ok
	ok = _expect(p1.karmany_roster.get_count() == 1, "Brumak debe incorporarse al roster.") and ok
	ok = _expect(bond.linked_karmany != null and bond.linked_karmany.is_linked(), "Brumak debe quedar LINKED.") and ok

	print("Integracion Fase 10 PENDING_COMBAT -> Fase 11: ", "OK" if ok else "ERROR")
	return ok


func _base_request() -> KarmanyCombatRequest:
	var request := KarmanyCombatRequest.new()
	request.attacker_player_id = &"player_1"
	request.attacker_karmany = TERRAKOR
	request.target_type = KarmanyCombatRequest.TargetType.UNBOUND_KARMANY
	request.uses_instinct = true
	request.instinct_roll = 3
	return request


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 11 ERROR: %s" % message)
	return false
