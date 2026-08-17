extends Node


const LOSS_2_ID: StringName = &"discard_2_basic_resources_choice"
const LOSS_3_ID: StringName = &"discard_3_basic_resources_choice"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.2B MITIGACION")
	print("========================================")
	var ok := _test_k07_once_per_round()
	ok = _test_k12_beast_tiers() and ok
	ok = _test_k21_first_combat_loss() and ok
	ok = _test_player_scope_isolated() and ok
	ok = _test_choice_resolver_preserves_player_choice() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.2B OK - K-07/K-12/K-21 mitigan perdidas canonicas sin elegir recursos por el jugador.")
	else:
		push_error("FASE 44.2B ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_k07_once_per_round() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var rocerno := load("res://data/karmanys/canonical_pending/k_07_rocerno.tres") as KarmanyData
	var terranuk := load("res://data/beasts/b_07_terranuk.tres") as KarmanyBeastData
	if rocerno == null or terranuk == null:
		return _fail("No se pudieron cargar K-07/B-07.")

	var first := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		rocerno, terranuk, &"P1", 2, 4402, _loss_2()
	)
	if int(first.get("original_amount", -1)) != 2 or int(first.get("effective_amount", -1)) != 0:
		return _fail("K-07 no redujo en 2 la primera perdida de la ronda.")
	KarmanyAbilityRuntimeService.commit_beast_defeat_resource_policy(first, true)

	var second := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		rocerno, terranuk, &"P1", 2, 4402, _loss_2()
	)
	if int(second.get("effective_amount", -1)) != 2:
		return _fail("K-07 se activo dos veces en la misma ronda.")

	var next_round := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		rocerno, terranuk, &"P1", 3, 4402, _loss_2()
	)
	if int(next_round.get("effective_amount", -1)) != 0:
		return _fail("K-07 no se reactivo en una ronda nueva.")
	print("F44.2B K-07 | primera perdida -2, segunda normal, nueva ronda reactiva: OK")
	return true


func _test_k12_beast_tiers() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var nimbara := load("res://data/karmanys/canonical_pending/k_12_nimbara.tres") as KarmanyData
	var basic := KarmanyBeastData.new()
	basic.tier = KarmanyBeastData.Tier.BASIC
	var medium := KarmanyBeastData.new()
	medium.tier = KarmanyBeastData.Tier.MEDIUM
	var complex := KarmanyBeastData.new()
	complex.tier = KarmanyBeastData.Tier.COMPLEX
	var boss := KarmanyBeastData.new()
	boss.tier = KarmanyBeastData.Tier.BOSS
	if nimbara == null:
		return _fail("No se pudo cargar K-12.")

	var medium_policy := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		nimbara, medium, &"P1", 2, 4412, _loss_2()
	)
	var complex_policy := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		nimbara, complex, &"P1", 2, 4412, _loss_3()
	)
	var basic_policy := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		nimbara, basic, &"P1", 2, 4412, _loss_2()
	)
	var boss_policy := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		nimbara, boss, &"P1", 2, 4412, _loss_3()
	)
	if int(medium_policy.get("effective_amount", -1)) != 0:
		return _fail("K-12 no redujo en 2 contra Bestia media.")
	if int(complex_policy.get("effective_amount", -1)) != 1:
		return _fail("K-12 no redujo 3 -> 1 contra Bestia compleja.")
	if int(basic_policy.get("effective_amount", -1)) != 2:
		return _fail("K-12 se aplico incorrectamente contra Bestia basica.")
	if int(boss_policy.get("effective_amount", -1)) != 3:
		return _fail("K-12 se aplico incorrectamente contra Jefe; el maestro solo dice media o compleja.")
	print("F44.2B K-12 | media/compleja -2; basica/jefe sin bono: OK")
	return true


func _test_k21_first_combat_loss() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var celestia := load("res://data/karmanys/canonical_pending/k_21_celestia.tres") as KarmanyData
	var basic := KarmanyBeastData.new()
	basic.tier = KarmanyBeastData.Tier.BASIC
	if celestia == null:
		return _fail("No se pudo cargar K-21.")

	# La regla dice primera derrota de combate, no primera perdida de recursos.
	# Una derrota sin perdida consume correctamente la ventana de esa ronda.
	var first_loss := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		celestia, basic, &"P1", 4, 4421, PackedStringArray()
	)
	if String(first_loss.get("usage_key", "")).is_empty():
		return _fail("K-21 no registro la primera derrota sin recursos.")
	KarmanyAbilityRuntimeService.commit_beast_defeat_resource_policy(first_loss, true)

	var second_loss := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		celestia, basic, &"P1", 4, 4421, _loss_2()
	)
	if int(second_loss.get("effective_amount", -1)) != 2:
		return _fail("K-21 protegio una segunda derrota de la misma ronda.")

	var next_round := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		celestia, basic, &"P1", 5, 4421, _loss_3()
	)
	if int(next_round.get("effective_amount", -1)) != 0:
		return _fail("K-21 no anulo la perdida en la primera derrota de la nueva ronda.")
	print("F44.2B K-21 | primera derrota por ronda consume ventana aunque no haya recursos: OK")
	return true


func _test_player_scope_isolated() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var rocerno := load("res://data/karmanys/canonical_pending/k_07_rocerno.tres") as KarmanyData
	var medium := KarmanyBeastData.new()
	medium.tier = KarmanyBeastData.Tier.MEDIUM
	if rocerno == null:
		return _fail("No se pudo cargar K-07 para scope multijugador.")
	var p1 := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		rocerno, medium, &"P1", 2, 4499, _loss_2()
	)
	KarmanyAbilityRuntimeService.commit_beast_defeat_resource_policy(p1, true)
	var p2 := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		rocerno, medium, &"P2", 2, 4499, _loss_2()
	)
	if int(p2.get("effective_amount", -1)) != 0:
		return _fail("El limite de K-07 se compartio entre jugadores.")
	print("F44.2B SCOPE | limites por ronda aislados por partida + jugador + Karmany: OK")
	return true


func _test_choice_resolver_preserves_player_choice() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var rocerno := load("res://data/karmanys/canonical_pending/k_07_rocerno.tres") as KarmanyData
	var custodio := load("res://data/beasts/b_22_custodio_del_santuario.tres") as KarmanyBeastData
	if rocerno == null or custodio == null:
		return _fail("No se pudieron cargar K-07/B-22 para resolver eleccion.")

	var policy := KarmanyAbilityRuntimeService.apply_beast_defeat_resource_policy(
		rocerno, custodio, &"P1", 2, 4477, _loss_3()
	)
	if int(policy.get("effective_amount", -1)) != 1:
		return _fail("Fixture K-07/B-22 no produjo perdida efectiva de 1 recurso.")

	var combat := KarmanyCombatResult.new()
	combat.status = KarmanyCombatResult.Status.RESOLVED
	combat.outcome = KarmanyCombatResult.Outcome.DEFEAT
	var beast_result := KarmanyBeastCombatResult.new()
	beast_result.status = KarmanyBeastCombatResult.Status.RESOLVED
	beast_result.combat_result = combat
	beast_result.defeat_consequence_ids = _loss_3()
	if not KarmanyCombatConsequenceResolver.apply_beast_basic_resource_loss_policy(beast_result, policy):
		return _fail("No se pudo estructurar la consecuencia reducida.")
	if beast_result.basic_resource_loss_pending != 1:
		return _fail("La consecuencia estructurada no conserva la cantidad efectiva 1.")

	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"P1")
	var mr_before: int = player.mr
	if KarmanyCombatConsequenceResolver.resolve_beast_basic_resource_loss_choice(player, beast_result, []):
		return _fail("El resolver acepto una eleccion vacia en lugar de esperar al jugador.")
	if player.mr != mr_before:
		return _fail("El resolver modifico recursos sin una eleccion valida.")
	if not KarmanyCombatConsequenceResolver.resolve_beast_basic_resource_loss_choice(
		player,
		beast_result,
		[KarmanyEffectData.ResourceType.MR]
	):
		return _fail("El resolver rechazo la eleccion valida del jugador.")
	if player.mr != mr_before - 1:
		return _fail("La eleccion MR no desconto exactamente 1 MR.")
	if beast_result.defeat_consequence_ids.has(String(LOSS_3_ID)):
		return _fail("La consecuencia resuelta siguio pendiente despues del pago.")
	print("F44.2B CHOICE | mitigacion cambia cantidad; MN/MR/EK sigue siendo decision del jugador: OK")
	return true


func _loss_2() -> PackedStringArray:
	return PackedStringArray([String(LOSS_2_ID)])


func _loss_3() -> PackedStringArray:
	return PackedStringArray([String(LOSS_3_ID)])


func _fail(message: String) -> bool:
	push_error("F44.2B: %s" % message)
	return false
