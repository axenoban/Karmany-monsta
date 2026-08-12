extends Node


const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const EQ01: KarmanyEquipmentData = preload("res://data/equipment/eq_01_cristal_de_crecimiento.tres")
const EQ02: KarmanyEquipmentData = preload("res://data/equipment/eq_02_guante_runico.tres")
const EQ05: KarmanyEquipmentData = preload("res://data/equipment/eq_05_nucleo_luminico.tres")
const EQ08: KarmanyEquipmentData = preload("res://data/equipment/eq_08_prisma_ancestral.tres")
const EQ09: KarmanyEquipmentData = preload("res://data/equipment/eq_09_catalizador_de_aeterna.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 12 EQUIPMENT TEST")
	print("================================")

	var test_passed: bool = true
	test_passed = _test_equipment_definitions() and test_passed
	test_passed = _test_inventory_limit_and_replacement() and test_passed
	test_passed = _test_market_refill_and_recycle() and test_passed
	test_passed = _test_crafting_permissions_and_costs() and test_passed
	test_passed = _test_fourth_equipment_requires_discard() and test_passed
	test_passed = _test_combat_modifier_integration() and test_passed

	print("")
	print("================================")
	if test_passed:
		print("FASE 12 OK - Equipos, mercado, crafteo y modificadores validados.")
	else:
		push_error("FASE 12 ERROR - Revisar sistema de Equipos.")
	print("================================")


func _test_equipment_definitions() -> bool:
	var ok: bool = true

	for equipment in [EQ01, EQ02, EQ05, EQ08, EQ09]:
		ok = _expect(
			equipment.is_valid_definition(),
			"Definicion de Equipo invalida: %s" % equipment.display_name
		) and ok

	ok = _expect(EQ01.equipment_id == &"EQ-01", "EQ-01 tiene ID incorrecto.") and ok
	ok = _expect(EQ01.rarity == KarmanyEquipmentData.Rarity.BASIC, "EQ-01 debe ser Basico.") and ok
	ok = _expect(int(EQ01.cost.get(KarmanyEffectData.ResourceType.MN, 0)) == 2, "EQ-01 debe costar 2 MN.") and ok
	ok = _expect(int(EQ01.cost.get(KarmanyEffectData.ResourceType.EK, 0)) == 1, "EQ-01 debe costar 1 EK.") and ok
	ok = _expect(EQ05.rarity == KarmanyEquipmentData.Rarity.ADVANCED, "EQ-05 debe ser Avanzado.") and ok
	ok = _expect(EQ08.rarity == KarmanyEquipmentData.Rarity.ANCESTRAL, "EQ-08 debe ser Ancestral.") and ok
	ok = _expect(EQ09.rarity == KarmanyEquipmentData.Rarity.ANCESTRAL, "EQ-09 debe ser Ancestral.") and ok

	print("EquipmentData + fixtures v0.74: ", "OK" if ok else "ERROR")
	return ok


func _test_inventory_limit_and_replacement() -> bool:
	var inventory := KarmanyEquipmentInventory.new()
	var ok: bool = true

	ok = _expect(inventory.add_equipment(EQ01), "No se pudo equipar EQ-01.") and ok
	ok = _expect(inventory.add_equipment(EQ02), "No se pudo equipar EQ-02.") and ok
	ok = _expect(inventory.add_equipment(EQ05), "No se pudo equipar EQ-05.") and ok
	ok = _expect(inventory.get_count() == 3, "El limite normal debe ser 3 Equipos.") and ok
	ok = _expect(inventory.is_full(), "Con 3 Equipos el inventario debe estar lleno.") and ok
	ok = _expect(not inventory.add_equipment(EQ01), "No deben permitirse Equipos duplicados.") and ok
	ok = _expect(not inventory.add_equipment(EQ08), "No debe existir una cuarta ranura de reserva.") and ok

	var discarded := inventory.replace_equipment(&"EQ-02", EQ08)
	ok = _expect(discarded == EQ02, "Reemplazar debe devolver el Equipo descartado.") and ok
	ok = _expect(inventory.get_count() == 3, "Reemplazar debe mantener exactamente 3 Equipos.") and ok
	ok = _expect(not inventory.has_equipment_id(&"EQ-02"), "EQ-02 debe quedar descartado.") and ok
	ok = _expect(inventory.has_equipment_id(&"EQ-08"), "EQ-08 debe quedar equipado.") and ok

	print("Inventario maximo 3, sin duplicados ni reserva: ", "OK" if ok else "ERROR")
	return ok


func _test_market_refill_and_recycle() -> bool:
	var market := KarmanyEquipmentMarket.new()
	var ok: bool = _expect(
		market.setup(_standard_deck(), false, 12345),
		"No se pudo preparar el mercado."
	)

	ok = _expect(market.get_visible_count() == 4, "El mercado debe mostrar 4 Equipos.") and ok
	ok = _expect(market.get_visible_at(0) == EQ01, "Orden determinista inicial incorrecto.") and ok

	var taken := market.take_visible(0)
	ok = _expect(taken == EQ01, "Debe salir EQ-01 del mercado.") and ok
	ok = _expect(market.get_visible_count() == 4, "El mercado debe reponerse inmediatamente.") and ok
	ok = _expect(market.get_visible_at(3) == EQ09, "EQ-09 debe reponer el cuarto espacio.") and ok
	ok = _expect(market.get_draw_count() == 0, "El mazo de prueba debe quedar agotado.") and ok

	var renewed := market.discard_visible(0)
	ok = _expect(renewed != null, "Renovar una carta visible debe devolver la descartada.") and ok
	ok = _expect(market.get_visible_count() == 4, "Tras reciclar descarte deben seguir 4 visibles.") and ok
	ok = _expect(market.get_discard_count() == 0, "El descarte debe reciclarse cuando el mazo se agota.") and ok

	print("Mercado 4 visibles + reposicion + reciclado: ", "OK" if ok else "ERROR")
	return ok


func _test_crafting_permissions_and_costs() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)

	var manager := _make_turn_manager(p1, p2)
	var market := KarmanyEquipmentMarket.new()
	var ok: bool = _expect(market.setup(_standard_deck(), false, 11), "Mercado de crafteo invalido.")

	var basic_context := KarmanyEquipmentCraftContext.new()
	basic_context.source_id = &"test_basic_workshop"
	basic_context.allow_basic = true
	basic_context.action_cost = 1
	basic_context.resource_discounts = {
		KarmanyEffectData.ResourceType.MN: 1
	}

	var craft := KarmanyEquipmentCraftResolver.craft_from_market(
		p1,
		market,
		0,
		manager,
		basic_context
	)

	ok = _expect(craft.is_success(), "EQ-01 debe poder craftearse con permiso Basico.") and ok
	ok = _expect(craft.equipment == EQ01, "El Equipo creado debe ser EQ-01.") and ok
	ok = _expect(craft.action_consumed, "Crear Equipo debe consumir 1 accion en este contexto.") and ok
	ok = _expect(manager.actions_remaining == 1, "Debe quedar 1 accion tras craftear.") and ok
	ok = _expect(p1.get_equipment_count() == 1, "EQ-01 debe incorporarse al jugador.") and ok
	ok = _expect(p1.mn == 1, "Descuento legal de 1 MN debe dejar MN en 1.") and ok
	ok = _expect(p1.ek == 0, "EQ-01 debe gastar 1 EK.") and ok
	ok = _expect(market.get_visible_count() == 4, "El mercado debe reponerse tras craftear.") and ok

	var advanced_index: int = _find_market_index(market, &"EQ-05")
	ok = _expect(advanced_index >= 0, "EQ-05 debe seguir visible para probar rareza.") and ok
	var denied := KarmanyEquipmentCraftResolver.craft_from_market(
		p1,
		market,
		advanced_index,
		manager,
		basic_context
	)
	ok = _expect(
		denied.status == KarmanyEquipmentCraftResult.Status.RARITY_NOT_ALLOWED,
		"Un contexto Basico no debe crear Equipo Avanzado."
	) and ok
	ok = _expect(manager.actions_remaining == 1, "Crafteo rechazado no debe gastar accion.") and ok

	var advanced_context := KarmanyEquipmentCraftContext.new()
	advanced_context.source_id = &"test_advanced_workshop"
	advanced_context.allow_advanced = true
	advanced_context.action_cost = 1
	var insufficient := KarmanyEquipmentCraftResolver.craft_from_market(
		p1,
		market,
		advanced_index,
		manager,
		advanced_context
	)
	ok = _expect(
		insufficient.status == KarmanyEquipmentCraftResult.Status.INSUFFICIENT_RESOURCES,
		"EQ-05 debe rechazar recursos insuficientes."
	) and ok
	ok = _expect(manager.actions_remaining == 1, "Pago insuficiente no debe gastar accion.") and ok

	print("Crafteo, permiso de rareza, costo y descuentos: ", "OK" if ok else "ERROR")
	return ok


func _test_fourth_equipment_requires_discard() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i.ZERO)
	p1.mn = 10
	p1.mr = 10
	p1.ek = 10
	p1.fa = 10

	var ok: bool = true
	ok = _expect(p1.add_equipment(EQ01), "Preparacion: falta EQ-01.") and ok
	ok = _expect(p1.add_equipment(EQ02), "Preparacion: falta EQ-02.") and ok
	ok = _expect(p1.add_equipment(EQ05), "Preparacion: falta EQ-05.") and ok

	var manager := _make_turn_manager(p1, p2)
	var market := KarmanyEquipmentMarket.new()
	ok = _expect(market.setup(_ancestral_first_deck(), false, 22), "Mercado ancestral invalido.") and ok

	var context := KarmanyEquipmentCraftContext.new()
	context.source_id = &"test_ancestral_forge"
	context.allow_ancestral = true
	context.action_cost = 1

	var before_resources := p1.get_resource_snapshot()
	var requires_discard := KarmanyEquipmentCraftResolver.craft_from_market(
		p1,
		market,
		0,
		manager,
		context
	)
	ok = _expect(
		requires_discard.status == KarmanyEquipmentCraftResult.Status.REQUIRES_DISCARD,
		"El cuarto Equipo debe exigir descarte inmediato."
	) and ok
	ok = _expect(manager.actions_remaining == 2, "Elegir descarte pendiente no debe gastar accion.") and ok
	ok = _expect(p1.get_resource_snapshot() == before_resources, "Descarte pendiente no debe gastar recursos.") and ok

	var crafted := KarmanyEquipmentCraftResolver.craft_from_market(
		p1,
		market,
		0,
		manager,
		context,
		&"EQ-02"
	)
	ok = _expect(crafted.is_success(), "EQ-08 debe craftearse al elegir descarte.") and ok
	ok = _expect(crafted.discarded_equipment == EQ02, "EQ-02 debe ser el descartado.") and ok
	ok = _expect(p1.get_equipment_count() == 3, "El jugador debe seguir con exactamente 3 Equipos.") and ok
	ok = _expect(not p1.equipment_inventory.has_equipment_id(&"EQ-02"), "EQ-02 no debe quedar en reserva.") and ok
	ok = _expect(p1.equipment_inventory.has_equipment_id(&"EQ-08"), "EQ-08 debe quedar equipado.") and ok
	ok = _expect(p1.fa == 9 and p1.ek == 8, "EQ-08 debe cobrar 1 FA + 2 EK.") and ok
	ok = _expect(manager.actions_remaining == 1, "Crafteo ancestral debe consumir 1 accion.") and ok

	print("Cuarto Equipo -> descarte inmediato sin reserva: ", "OK" if ok else "ERROR")
	return ok


func _test_combat_modifier_integration() -> bool:
	var inventory := KarmanyEquipmentInventory.new()
	var ok: bool = true
	ok = _expect(inventory.add_equipment(EQ01), "No se pudo preparar EQ-01 para combate.") and ok
	ok = _expect(inventory.add_equipment(EQ08), "No se pudo preparar EQ-08 para combate.") and ok
	ok = _expect(inventory.add_equipment(EQ09), "No se pudo preparar EQ-09 para combate.") and ok

	var beast_bonus := KarmanyEquipmentCombatRules.get_power_bonus(
		inventory,
		KarmanyCombatRequest.TargetType.BEAST
	)
	var boss_bonus := KarmanyEquipmentCombatRules.get_power_bonus(
		inventory,
		KarmanyCombatRequest.TargetType.BOSS
	)
	var legendary_bonus := KarmanyEquipmentCombatRules.get_power_bonus(
		inventory,
		KarmanyCombatRequest.TargetType.LEGENDARY
	)
	var unbound_bonus := KarmanyEquipmentCombatRules.get_power_bonus(
		inventory,
		KarmanyCombatRequest.TargetType.UNBOUND_KARMANY
	)
	var resonance_bonus := KarmanyEquipmentCombatRules.get_power_bonus(
		inventory,
		KarmanyCombatRequest.TargetType.BEAST,
		PackedStringArray(["resonance_played"])
	)

	ok = _expect(beast_bonus == 2, "EQ-01 debe aportar +2 contra Bestia.") and ok
	ok = _expect(boss_bonus == 6, "Jefe debe recibir +2 de EQ-01 y +4 de EQ-09.") and ok
	ok = _expect(legendary_bonus == 4, "Legendario debe recibir +4 de EQ-09.") and ok
	ok = _expect(unbound_bonus == 0, "Estos Equipos no deben dar bono automatico contra Karmany no vinculado.") and ok
	ok = _expect(resonance_bonus == 4, "Con Resonancia jugada, EQ-01 + EQ-08 deben sumar +4 contra Bestia.") and ok

	var request := KarmanyCombatRequest.new()
	request.attacker_player_id = &"player_1"
	request.attacker_karmany = TERRAKOR
	request.target_id = &"boss_equipment_test"
	request.target_type = KarmanyCombatRequest.TargetType.BOSS
	request.base_defense = 12
	request.uses_instinct = true
	request.instinct_roll = 3

	ok = _expect(
		KarmanyEquipmentCombatRules.apply_to_combat_modifiers(
			inventory,
			request.target_type,
			request.modifiers
		),
		"No se pudo aplicar Equipo al desglose de combate."
	) and ok

	var combat := KarmanyCombatResolver.resolve(request)
	ok = _expect(request.modifiers.equipment_power == 6, "CombatPowerModifiers debe registrar +6 de Equipo.") and ok
	ok = _expect(combat.total_power == 12, "Terrakor 6 + Equipo 6 debe dar Poder total 12.") and ok
	ok = _expect(combat.effective_defense == 12, "Instinto 3 debe mantener Defensa 12.") and ok
	ok = _expect(combat.is_victory(), "Igualar 12 contra 12 debe mantener victoria PvE.") and ok

	print("Equipos -> CombatPowerModifiers -> CombatResolver: ", "OK" if ok else "ERROR")
	return ok


func _make_turn_manager(
	p1: KarmanyPlayerState,
	p2: KarmanyPlayerState
) -> KarmanyTurnManager:
	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()
	return manager


func _standard_deck() -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	result.append(EQ01)
	result.append(EQ02)
	result.append(EQ05)
	result.append(EQ08)
	result.append(EQ09)
	return result


func _ancestral_first_deck() -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	result.append(EQ08)
	result.append(EQ09)
	result.append(EQ01)
	result.append(EQ02)
	result.append(EQ05)
	return result


func _find_market_index(
	market: KarmanyEquipmentMarket,
	equipment_id: StringName
) -> int:
	for index in range(market.get_visible_count()):
		var equipment := market.get_visible_at(index)
		if equipment != null and equipment.equipment_id == equipment_id:
			return index
	return -1


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 12 ERROR: %s" % message)
	return false
