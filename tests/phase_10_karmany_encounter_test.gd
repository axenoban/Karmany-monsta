extends Node


const FLORAVIA: KarmanyData = preload("res://data/karmanys/k_05_floravia.tres")
const BRUMAK: KarmanyData = preload("res://data/karmanys/k_10_brumak.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 10 ENCOUNTER / BOND TEST")
	print("================================")

	var test_passed: bool = true

	test_passed = _test_call_and_payment_bond() and test_passed
	test_passed = _test_insufficient_payment_is_safe() and test_passed
	test_passed = _test_defeat_route_delegates_combat() and test_passed
	test_passed = _test_failed_combat_and_expiration() and test_passed
	test_passed = _test_condition_route() and test_passed

	print("")
	print("================================")
	if test_passed:
		print("FASE 10 OK - Encuentros, Llamar y Vincular validados.")
	else:
		push_error("FASE 10 ERROR - Revisar encuentros o vinculo.")
	print("================================")


func _test_call_and_payment_bond() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	var ok: bool = _expect(manager.setup_players(players), "No se pudieron preparar jugadores.")
	ok = _expect(manager.start_match(), "No se pudo iniciar partida.") and ok

	var resolver := KarmanyEncounterResolver.new()
	ok = _expect(resolver.configure(manager), "No se pudo configurar resolver.") and ok

	var decoy := _make_test_karmany(&"TEST-N1-A", KarmanyData.Rank.N1)
	var candidates: Array[KarmanyData] = []
	candidates.append(FLORAVIA)
	candidates.append(decoy)

	var call_result := resolver.call_karmany(
		p1,
		Vector2i.ZERO,
		KarmanyData.Rank.N1,
		candidates,
		0,
		true,
		false
	)

	ok = _expect(call_result.is_success(), "Llamar Floravia debe funcionar.") and ok
	ok = _expect(call_result.action_consumed, "Llamar debe consumir 1 accion.") and ok
	ok = _expect(manager.actions_remaining == 1, "Debe quedar 1 accion tras Llamar.") and ok
	ok = _expect(call_result.encounter != null, "Debe existir encuentro visible.") and ok
	ok = _expect(call_result.encounter.is_available(), "Floravia debe quedar disponible.") and ok
	ok = _expect(call_result.returned_candidate == decoy, "El Karmany no elegido debe devolverse al mazo.") and ok
	ok = _expect(resolver.has_called_this_round(p1.player_id), "Debe registrarse Llamar en la ronda.") and ok

	var second_call := resolver.call_karmany(
		p1,
		Vector2i.ZERO,
		KarmanyData.Rank.N1,
		candidates,
		0,
		true,
		false
	)
	ok = _expect(
		second_call.status == KarmanyEncounterResult.Status.CALL_LIMIT_REACHED,
		"Llamar dos veces en la misma ronda debe rechazarse."
	) and ok
	ok = _expect(manager.actions_remaining == 1, "Llamar rechazado no debe consumir accion.") and ok

	var payment := resolver.attempt_payment_bond(call_result.encounter, p1)
	ok = _expect(payment.is_success(), "Vincular Floravia por pago debe funcionar.") and ok
	ok = _expect(payment.action_consumed, "Vincular por pago debe consumir 1 accion.") and ok
	ok = _expect(manager.actions_remaining == 0, "Las dos acciones del turno deben quedar consumidas.") and ok
	ok = _expect(p1.mn == 0, "Floravia debe cobrar 2 MN.") and ok
	ok = _expect(p1.ek == 0, "Floravia debe cobrar 1 EK.") and ok
	ok = _expect(call_result.encounter.status == KarmanyEncounterState.Status.LINKED, "El encuentro debe quedar LINKED.") and ok
	ok = _expect(payment.linked_karmany != null and payment.linked_karmany.is_linked(), "Runtime Karmany debe quedar vinculado.") and ok
	ok = _expect(payment.linked_karmany.owner_player_id == p1.player_id, "El propietario debe ser player_1.") and ok
	ok = _expect(p1.karmany_roster.get_count() == 1, "Floravia debe incorporarse al roster.") and ok

	print("Llamar + Vincular por pago: ", "OK" if ok else "ERROR")
	return ok


func _test_insufficient_payment_is_safe() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()

	var resolver := KarmanyEncounterResolver.new()
	resolver.configure(manager)

	var decoy := _make_test_karmany(&"TEST-N2-A", KarmanyData.Rank.N2)
	var candidates: Array[KarmanyData] = []
	candidates.append(BRUMAK)
	candidates.append(decoy)

	var call_result := resolver.call_karmany(
		p1,
		Vector2i.ZERO,
		KarmanyData.Rank.N2,
		candidates,
		0
	)
	var before_ek: int = p1.ek
	var payment := resolver.attempt_payment_bond(call_result.encounter, p1)

	var ok: bool = true
	ok = _expect(
		payment.status == KarmanyEncounterResult.Status.INSUFFICIENT_RESOURCES,
		"Brumak debe rechazar pago con solo 1 EK."
	) and ok
	ok = _expect(p1.ek == before_ek, "Pago insuficiente no debe descontar recursos.") and ok
	ok = _expect(manager.actions_remaining == 1, "Pago insuficiente no debe consumir la segunda accion.") and ok
	ok = _expect(call_result.encounter.is_available(), "Brumak debe seguir visible tras pago insuficiente.") and ok
	ok = _expect(p1.karmany_roster.get_count() == 0, "No debe incorporarse Brumak.") and ok

	print("Pago insuficiente atomico: ", "OK" if ok else "ERROR")
	return ok


func _test_defeat_route_delegates_combat() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()

	var resolver := KarmanyEncounterResolver.new()
	resolver.configure(manager)

	var decoy := _make_test_karmany(&"TEST-N2-B", KarmanyData.Rank.N2)
	var candidates: Array[KarmanyData] = []
	candidates.append(BRUMAK)
	candidates.append(decoy)

	var call_result := resolver.call_karmany(
		p1,
		Vector2i.ZERO,
		KarmanyData.Rank.N2,
		candidates,
		0
	)
	var begin_result := resolver.begin_defeat_bond_attempt(
		call_result.encounter,
		p1
	)

	var ok: bool = true
	ok = _expect(begin_result.is_pending_combat(), "Derrota debe quedar PENDING_COMBAT.") and ok
	ok = _expect(begin_result.action_consumed, "Intento por Defensa debe consumir la accion Vincular.") and ok
	ok = _expect(begin_result.defense_target == 12, "Brumak debe entregar Defensa 12 al futuro CombatResolver.") and ok
	ok = _expect(begin_result.requires_instinct_roll, "Combate contra Karmany no vinculado debe requerir Instinto.") and ok
	ok = _expect(manager.actions_remaining == 0, "Llamar + Vincular deben consumir 2 acciones.") and ok
	ok = _expect(p1.karmany_roster.get_count() == 0, "PENDING_COMBAT aun no incorpora Karmany.") and ok

	var combat_result := resolver.complete_defeat_bond(
		call_result.encounter,
		p1,
		true
	)
	ok = _expect(combat_result.is_success(), "Victoria externa debe completar el vinculo.") and ok
	ok = _expect(call_result.encounter.status == KarmanyEncounterState.Status.LINKED, "Brumak debe quedar LINKED.") and ok
	ok = _expect(p1.karmany_roster.get_count() == 1, "Brumak debe entrar al roster tras victoria.") and ok

	print("Ruta por Defensa delegada a Fase 11: ", "OK" if ok else "ERROR")
	return ok


func _test_failed_combat_and_expiration() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()

	var resolver := KarmanyEncounterResolver.new()
	resolver.configure(manager)

	var decoy := _make_test_karmany(&"TEST-N2-C", KarmanyData.Rank.N2)
	var candidates: Array[KarmanyData] = []
	candidates.append(BRUMAK)
	candidates.append(decoy)

	var call_result := resolver.call_karmany(
		p1,
		Vector2i.ZERO,
		KarmanyData.Rank.N2,
		candidates,
		0
	)
	resolver.begin_defeat_bond_attempt(call_result.encounter, p1)
	var failed := resolver.complete_defeat_bond(
		call_result.encounter,
		p1,
		false
	)

	var ok: bool = true
	ok = _expect(failed.status == KarmanyEncounterResult.Status.COMBAT_FAILED, "Derrota debe informar COMBAT_FAILED.") and ok
	ok = _expect(call_result.encounter.is_available(), "Tras perder, el Karmany debe seguir visible.") and ok
	ok = _expect(not call_result.encounter.karmany_state.is_linked(), "Derrota no debe vincular Karmany.") and ok

	manager.end_turn()
	ok = _expect(call_result.encounter.status != KarmanyEncounterState.Status.EXPIRED, "No debe expirar al final del turno en que fue llamado.") and ok

	manager.spend_action()
	manager.spend_action()
	manager.end_turn()
	ok = _expect(manager.current_round == 2, "Debe comenzar ronda 2.") and ok
	ok = _expect(not resolver.has_called_this_round(p1.player_id), "Llamar debe volver a estar disponible en nueva ronda.") and ok

	manager.spend_action()
	manager.spend_action()
	manager.end_turn()
	ok = _expect(call_result.encounter.status == KarmanyEncounterState.Status.EXPIRED, "Debe expirar al final del siguiente turno de player_1.") and ok
	ok = _expect(not call_result.encounter.is_visible(), "Encuentro expirado no debe seguir visible.") and ok

	print("Derrota + duracion del Karmany visible: ", "OK" if ok else "ERROR")
	return ok


func _test_condition_route() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()

	var resolver := KarmanyEncounterResolver.new()
	resolver.configure(manager)

	var conditional := _make_condition_karmany(&"TEST-COND", KarmanyData.Rank.N1)
	var decoy := _make_test_karmany(&"TEST-N1-B", KarmanyData.Rank.N1)
	var candidates: Array[KarmanyData] = []
	candidates.append(conditional)
	candidates.append(decoy)

	var call_result := resolver.call_karmany(
		p1,
		Vector2i.ZERO,
		KarmanyData.Rank.N1,
		candidates,
		0
	)
	var wrong := resolver.attempt_condition_bond(
		call_result.encounter,
		p1,
		&"wrong_condition"
	)

	var ok: bool = true
	ok = _expect(wrong.status == KarmanyEncounterResult.Status.METHOD_NOT_ALLOWED, "Condicion incorrecta debe rechazarse.") and ok
	ok = _expect(manager.actions_remaining == 1, "Condicion incorrecta no debe gastar accion.") and ok

	var correct := resolver.attempt_condition_bond(
		call_result.encounter,
		p1,
		&"test_condition"
	)
	ok = _expect(correct.is_success(), "Condicion correcta debe vincular.") and ok
	ok = _expect(manager.actions_remaining == 0, "Vinculo por condicion debe consumir accion.") and ok
	ok = _expect(p1.karmany_roster.get_count() == 1, "Karmany por condicion debe incorporarse.") and ok

	print("Ruta de condicion preparada: ", "OK" if ok else "ERROR")
	return ok


func _make_test_karmany(
	id: StringName,
	rank: int
) -> KarmanyData:
	var data := KarmanyData.new()
	data.karmany_id = id
	data.display_name = String(id)
	data.rank = rank
	data.compatible_ranks = PackedInt32Array([rank])
	data.primary_type = KarmanyData.StrategicType.STABLE
	data.power = 5
	data.encounter_defense = 8
	data.acquisition_text = "Derrota Defensa 8"
	data.can_acquire_by_defeat = true
	return data


func _make_condition_karmany(
	id: StringName,
	rank: int
) -> KarmanyData:
	var data := KarmanyData.new()
	data.karmany_id = id
	data.display_name = String(id)
	data.rank = rank
	data.compatible_ranks = PackedInt32Array([rank])
	data.primary_type = KarmanyData.StrategicType.TACTICAL
	data.power = 5
	data.encounter_defense = -1
	data.acquisition_text = "Cumple condicion de prueba"
	data.can_acquire_by_condition = true
	data.acquisition_condition_id = &"test_condition"
	return data


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
