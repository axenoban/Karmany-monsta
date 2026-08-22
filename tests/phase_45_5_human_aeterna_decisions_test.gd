extends Node


var _failures: Array[String] = []


func _ready() -> void:
	_test_aeterna_instinct_request_boundary()
	_test_aeterna_session_instinct_adapter()
	_test_reward_request_uses_visible_ancestral_only()
	_test_free_market_reward_and_refill()
	_test_full_inventory_replacement()
	_test_defeat_resource_choice()
	_test_full_match_compatibility_surface()

	if _failures.is_empty():
		print("FASE 45.5 OK - Aeterna usa Instinto humano, recompensa visible del mercado sin coste, descartes humanos y flujo legacy/IA protegido.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_aeterna_instinct_request_boundary() -> void:
	var legacy_request := KarmanyInstinctRollRequest.new()
	_expect(
		not legacy_request.configure(
			1, &"player_1", 8, 2,
			KarmanyAiActionCandidate.ActionType.AETERNA,
			"Aeterna legacy boundary", Vector2i.ZERO
		),
		"INSTINTO: F45.4 dejo de conservar su frontera legacy para Aeterna."
	)
	var request := KarmanyAeternaInstinctRollRequest.new()
	_expect(
		request.configure(
			2, &"player_1", 8, 2,
			KarmanyAiActionCandidate.ActionType.AETERNA,
			"Combatir Aeterna Draconis", Vector2i.ZERO
		),
		"INSTINTO: F45.5 no acepta Aeterna en su solicitud especializada."
	)
	_expect(request.resolve_roll(6), "INSTINTO: no resolvio un D6 valido para Aeterna.")
	_expect(request.get_defense_adjustment() == 2, "INSTINTO: cara 6 no produjo +2 Defensa.")
	print("F45.5 INSTINTO | F45.4 permanece intacta; Aeterna obtiene request especializado.")


func _test_aeterna_session_instinct_adapter() -> void:
	var session := KarmanyFullMatchHumanAeternaSession.new()
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.AETERNA
	candidate.debug_label = "Combatir Aeterna Draconis"
	candidate.payload["instinct_roll"] = 6
	_expect(session._requires_human_instinct_roll(candidate), "ADAPTER: Aeterna no exige Instinto humano.")
	_expect(session._clear_human_instinct_roll(candidate), "ADAPTER: no limpio la tirada automatica.")
	_expect(int(candidate.payload.get("instinct_roll", -1)) == 0, "ADAPTER: sobrevivio la tirada preconstruida.")
	_expect(session._apply_human_instinct_roll(candidate, 5), "ADAPTER: no inyecto tirada humana.")
	_expect(session._get_human_instinct_roll(candidate) == 5, "ADAPTER: no expuso la tirada humana fijada.")
	var request := session._create_human_instinct_request(candidate)
	_expect(request is KarmanyAeternaInstinctRollRequest, "ADAPTER: no creo request especializado de Aeterna.")
	print("F45.5 ORDER | declarar Aeterna -> Instinto -> Resonancia -> resolver combate.")


func _test_reward_request_uses_visible_ancestral_only() -> void:
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_1")
	var market := KarmanyEquipmentMarket.new()
	var deck: Array[KarmanyEquipmentData] = [
		_equipment(&"EQ-T01", "Basico A", KarmanyEquipmentData.Rarity.BASIC),
		_equipment(&"EQ-T02", "Ancestral visible", KarmanyEquipmentData.Rarity.ANCESTRAL),
		_equipment(&"EQ-T03", "Avanzado A", KarmanyEquipmentData.Rarity.ADVANCED),
		_equipment(&"EQ-T04", "Basico B", KarmanyEquipmentData.Rarity.BASIC),
		_equipment(&"EQ-T05", "Ancestral oculto", KarmanyEquipmentData.Rarity.ANCESTRAL),
	]
	_expect(market.setup(deck, false, 45501), "REWARD REQUEST: no configuro mercado fixture.")
	var request := KarmanyAeternaRewardChoiceRequest.new()
	_expect(request.configure(1, player, 8, 1, market, true), "REWARD REQUEST: no configuro solicitud.")
	_expect(request.has_resonance_option(), "REWARD REQUEST: falta opcion de Resonancias.")
	var equipment_options := request.get_equipment_options()
	_expect(equipment_options.size() == 1, "REWARD REQUEST: ofrecio Ancestrales fuera de las 4 visibles o perdio el visible.")
	if equipment_options.size() == 1:
		_expect(
			StringName(equipment_options[0].get("equipment_id", "")) == &"EQ-T02",
			"REWARD REQUEST: la opcion visible no corresponde al Ancestral del mercado."
		)
	print("F45.5 REWARD REQUEST | solo Ancestrales dentro de las 4 cartas visibles.")


func _test_free_market_reward_and_refill() -> void:
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_1")
	var resources_before := player.get_resource_snapshot()
	var market := KarmanyEquipmentMarket.new()
	var deck: Array[KarmanyEquipmentData] = [
		_equipment(&"EQ-M01", "Basico A", KarmanyEquipmentData.Rarity.BASIC),
		_equipment(&"EQ-M02", "Ancestral premio", KarmanyEquipmentData.Rarity.ANCESTRAL),
		_equipment(&"EQ-M03", "Basico B", KarmanyEquipmentData.Rarity.BASIC),
		_equipment(&"EQ-M04", "Avanzado A", KarmanyEquipmentData.Rarity.ADVANCED),
		_equipment(&"EQ-M05", "Reposicion", KarmanyEquipmentData.Rarity.BASIC),
	]
	_expect(market.setup(deck, false, 45502), "MARKET: no configuro mercado fixture.")
	var result := _victory_result()
	_expect(
		KarmanyAeternaMarketRewardService.resolve_visible_reward(player, result, market, 1),
		"MARKET: no concedio el Ancestral visible como recompensa."
	)
	_expect(player.equipment_inventory.has_equipment_id(&"EQ-M02"), "MARKET: premio no entro al inventario.")
	_expect(player.get_resource_snapshot() == resources_before, "MARKET: la recompensa cobro recursos al jugador.")
	_expect(market.get_visible_count() == 4, "MARKET: no repuso la posicion retirada.")
	_expect(not market.contains_equipment_id(&"EQ-M02"), "MARKET: el Equipo premiado sigue dentro del suministro.")
	_expect(result.reward_resolved, "MARKET: Aeterna no marco recompensa como resuelta.")
	_expect(result.ancestral_equipment_id == &"EQ-M02", "MARKET: resultado no registro el Equipo recibido.")
	print("F45.5 MARKET | toma visible, coste 0, inventario recibe y mercado repone.")


func _test_full_inventory_replacement() -> void:
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_1")
	_expect(player.add_equipment(_equipment(&"EQ-P01", "Propio 1", KarmanyEquipmentData.Rarity.BASIC)), "FULL: no agrego equipo 1.")
	_expect(player.add_equipment(_equipment(&"EQ-P02", "Propio 2", KarmanyEquipmentData.Rarity.BASIC)), "FULL: no agrego equipo 2.")
	_expect(player.add_equipment(_equipment(&"EQ-P03", "Propio 3", KarmanyEquipmentData.Rarity.ADVANCED)), "FULL: no agrego equipo 3.")
	var market := KarmanyEquipmentMarket.new()
	var deck: Array[KarmanyEquipmentData] = [
		_equipment(&"EQ-F01", "Ancestral premio", KarmanyEquipmentData.Rarity.ANCESTRAL),
		_equipment(&"EQ-F02", "Mercado 2", KarmanyEquipmentData.Rarity.BASIC),
		_equipment(&"EQ-F03", "Mercado 3", KarmanyEquipmentData.Rarity.BASIC),
		_equipment(&"EQ-F04", "Mercado 4", KarmanyEquipmentData.Rarity.ADVANCED),
		_equipment(&"EQ-F05", "Reposicion", KarmanyEquipmentData.Rarity.BASIC),
	]
	_expect(market.setup(deck, false, 45503), "FULL: no configuro mercado.")
	var request := KarmanyAeternaRewardChoiceRequest.new()
	_expect(request.configure(2, player, 8, 1, market, true), "FULL: no configuro reward request.")
	var options := request.get_equipment_options()
	_expect(options.size() == 1, "FULL: no encontro exactamente un Ancestral visible.")
	if options.is_empty():
		return
	var option_id: StringName = StringName(options[0].get("option_id", ""))
	_expect(request.resolve_option(option_id).is_empty(), "FULL: acepto premio sin elegir Equipo a descartar.")
	_expect(not request.is_resolved(), "FULL: seleccion invalida consumio el request.")
	var selection := request.resolve_option(option_id, &"EQ-P02")
	_expect(not selection.is_empty(), "FULL: rechazo reemplazo legal elegido por jugador.")
	var result := _victory_result()
	_expect(
		KarmanyAeternaMarketRewardService.resolve_visible_reward(player, result, market, 0, &"EQ-P02"),
		"FULL: servicio no resolvio reemplazo legal."
	)
	_expect(player.get_equipment_count() == 3, "FULL: inventario dejo de respetar limite 3.")
	_expect(player.equipment_inventory.has_equipment_id(&"EQ-F01"), "FULL: Ancestral no reemplazo al elegido.")
	_expect(not player.equipment_inventory.has_equipment_id(&"EQ-P02"), "FULL: Equipo descartado sigue equipado.")
	_expect(market.get_discard_count() == 1, "FULL: Equipo reemplazado no fue al descarte del mercado.")
	print("F45.5 FULL INVENTORY | jugador elige descarte antes de recibir el Ancestral gratuito.")


func _test_defeat_resource_choice() -> void:
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_1")
	player.mn = 2
	player.mr = 1
	player.ek = 0
	var request := KarmanyAeternaResourceDiscardRequest.new()
	_expect(request.configure(1, player, 8, 1, 2), "DEFEAT: no configuro descarte de 2 recursos.")
	var invalid: Array[int] = [KarmanyEffectData.ResourceType.MR, KarmanyEffectData.ResourceType.MR]
	_expect(request.resolve_resources(invalid).is_empty(), "DEFEAT: permitio descartar mas MR de los disponibles.")
	_expect(not request.is_resolved(), "DEFEAT: seleccion invalida consumio request.")
	var valid: Array[int] = [KarmanyEffectData.ResourceType.MN, KarmanyEffectData.ResourceType.MN]
	_expect(request.resolve_resources(valid).size() == 2, "DEFEAT: rechazo dos MN disponibles elegidos por jugador.")
	print("F45.5 DEFEAT | descarte de recursos valida cantidad, tipo y duplicados disponibles.")


func _test_full_match_compatibility_surface() -> void:
	var session := KarmanyFullMatchSession.new()
	_expect(session.has_method("build_human_aeterna_reward_choice_request"), "COMPAT: FullMatchSession no expone recompensa humana de Aeterna.")
	_expect(session.has_method("resolve_human_aeterna_reward_choice"), "COMPAT: falta resolver recompensa humana.")
	_expect(session.has_method("build_human_aeterna_resource_discard_request"), "COMPAT: falta request de recursos tras derrota.")
	_expect(session.has_method("build_human_aeterna_resonance_discard_request"), "COMPAT: falta descarte de Resonancia de Aeterna.")
	_expect(session.has_method("resolve_human_instinct_roll"), "COMPAT: desaparecio F45.4 Instinto.")
	_expect(session.has_method("resolve_human_combat_resonance_choice"), "COMPAT: desaparecio F45.3 Resonancia.")
	_expect(session.has_method("run_automated_current_turn"), "COMPAT: desaparecio IA/Auto-P1 legacy.")
	print("F45.5 COMPAT | FullMatchSession conserva F45.3/F45.4 y automatizacion legacy.")


func _equipment(
	equipment_id: StringName,
	display_name: String,
	rarity: int
) -> KarmanyEquipmentData:
	var equipment := KarmanyEquipmentData.new()
	equipment.equipment_id = equipment_id
	equipment.display_name = display_name
	equipment.rarity = rarity
	equipment.cost = {KarmanyEffectData.ResourceType.MN: 1}
	equipment.rules_text = "Fixture F45.5 valido."
	return equipment


func _victory_result() -> KarmanyAeternaResult:
	var result := KarmanyAeternaResult.new()
	result.status = KarmanyAeternaResult.Status.RESOLVED
	result.outcome = KarmanyAeternaResult.Outcome.COMBAT_VICTORY
	result.reward_choice_required = true
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 45.5 TEST ERROR: %s" % message)
