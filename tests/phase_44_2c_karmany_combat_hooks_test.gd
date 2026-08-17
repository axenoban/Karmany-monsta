extends Node


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.2C COMBAT HOOKS")
	print("========================================")
	var ok := _test_k17_pvp_defender_bonus()
	ok = _test_k22_legendary_integration() and ok
	ok = _test_k21_shared_loss_window() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.2C OK - hooks deterministas de PvP/Legendaria integrados sin promociones falsas.")
	else:
		push_error("FASE 44.2C ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_k17_pvp_defender_bonus() -> bool:
	var orial := load("res://data/karmanys/canonical_pending/k_17_orial.tres") as KarmanyData
	var verdan := load("res://data/karmanys/k_09_verdan.tres") as KarmanyData
	if orial == null or verdan == null:
		return _fail("No se pudieron cargar K-17/K-09.")
	if KarmanyAbilityRuntimeService.get_pvp_defender_power_bonus(orial) != 2:
		return _fail("K-17 no entrega +2 Poder en defensa PvP.")
	if KarmanyAbilityRuntimeService.get_pvp_defender_power_bonus(verdan) != 0:
		return _fail("El bono defensivo PvP de K-17 se filtro a otro Karmany.")
	if KarmanyAbilityRuntimeService.get_status(&"K-17") != KarmanyAbilityRuntimeService.STATUS_FULLY:
		return _fail("K-17 no fue promovido a FULLY tras cerrar su unico hook.")
	print("F44.2C K-17 | defensa PvP +2 aislada al defensor Orial: OK")
	return true


func _test_k22_legendary_integration() -> bool:
	var runakar := load("res://data/karmanys/canonical_pending/k_22_runakar.tres") as KarmanyData
	if runakar == null:
		return _fail("No se pudo cargar K-22 Runakar.")

	var legendary_request := KarmanyCombatRequest.new()
	legendary_request.attacker_player_id = &"P1"
	legendary_request.attacker_karmany = runakar
	legendary_request.target_id = &"K-24"
	legendary_request.target_type = KarmanyCombatRequest.TargetType.LEGENDARY
	legendary_request.base_defense = 99
	legendary_request.instinct_roll = 3
	var legendary_result := KarmanyCombatResolver.resolve(legendary_request)
	if not legendary_result.is_resolved():
		return _fail("CombatResolver rechazo fixture Legendaria de K-22: %s" % legendary_result.message)
	if legendary_result.other_power != 2:
		return _fail("K-22 no expuso +2 en el desglose de Poder contra Legendaria.")
	if legendary_result.total_power != runakar.power + 2:
		return _fail("K-22 no sumo exactamente +2 al Poder total contra Legendaria.")

	var beast_request := KarmanyCombatRequest.new()
	beast_request.attacker_player_id = &"P1"
	beast_request.attacker_karmany = runakar
	beast_request.target_id = &"B-FIXTURE"
	beast_request.target_type = KarmanyCombatRequest.TargetType.BEAST
	beast_request.base_defense = 99
	beast_request.instinct_roll = 3
	var beast_result := KarmanyCombatResolver.resolve(beast_request)
	if not beast_result.is_resolved():
		return _fail("CombatResolver rechazo fixture Beast de control para K-22.")
	if beast_result.other_power != 0 or beast_result.total_power != runakar.power:
		return _fail("La rama generica Legendaria de K-22 duplico o filtro bono a BEAST.")
	if KarmanyAbilityRuntimeService.get_status(&"K-22") != KarmanyAbilityRuntimeService.STATUS_FULLY:
		return _fail("K-22 no quedo FULLY tras cubrir Complex/Boss/Legendaria.")
	print("F44.2C K-22 | Legendaria +2 en CombatResolver; rama Beast no se duplica: OK")
	return true


func _test_k21_shared_loss_window() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var celestia := load("res://data/karmanys/canonical_pending/k_21_celestia.tres") as KarmanyData
	if celestia == null:
		return _fail("No se pudo cargar K-21 Celestia.")
	var basic := KarmanyBeastData.new()
	basic.tier = KarmanyBeastData.Tier.BASIC
	var loss_2 := PackedStringArray(["discard_2_basic_resources_choice"])

	if not KarmanyAbilityRuntimeService.commit_combat_loss(
		celestia,
		&"P1",
		3,
		4421,
		true
	):
		return _fail("K-21 no registro una primera derrota PvP valida.")
	if KarmanyAbilityRuntimeService.commit_combat_loss(
		celestia,
		&"P1",
		3,
		4421,
		true
	):
		return _fail("K-21 permitio consumir dos veces la primera derrota de la ronda.")

	var same_round := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		celestia,
		basic,
		&"P1",
		3,
		4421,
		loss_2
	)
	if int(same_round.get("effective_amount", -1)) != 2:
		return _fail("K-21 protegió una derrota Beast posterior al PvP de la misma ronda.")

	var next_round := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		celestia,
		basic,
		&"P1",
		4,
		4421,
		loss_2
	)
	if int(next_round.get("effective_amount", -1)) != 0:
		return _fail("K-21 no reabrio su ventana de primera derrota en la ronda siguiente.")
	if KarmanyAbilityRuntimeService.get_status(&"K-21") != KarmanyAbilityRuntimeService.STATUS_PARTIAL:
		return _fail("K-21 fue promovido antes de cubrir Aeterna y Karmany sin vincular.")
	print("F44.2C K-21 | derrota PvP consume la misma ventana de primera derrota de la ronda: OK")
	return true


func _fail(message: String) -> bool:
	push_error("F44.2C: %s" % message)
	return false
