extends Node

const PENDING_DIR := "res://data/equipment/canonical_pending"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.4 EQUIPOS")
	print("========================================")
	var ok := _test_contract_coverage()
	ok = _test_pending_runtime_exclusion() and ok
	ok = _test_canonical_runtime_hooks() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.4 OK - 36/36 Equipos con contrato runtime explicito; 1 FULLY_EXECUTABLE y 35 PARTIAL sin promociones falsas.")
	else:
		push_error("FASE 44.4 ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_contract_coverage() -> bool:
	var all_equipment := _load_dir("res://data/equipment")
	all_equipment.append_array(_load_dir(PENDING_DIR))
	if all_equipment.size() != 36:
		return _fail("Se esperaban 36 Equipos y se cargaron %d." % all_equipment.size())
	for data in all_equipment:
		if data == null or not KarmanyEquipmentAbilityRuntimeService.has_contract(data.equipment_id):
			return _fail("Equipo sin contrato F44.4: %s." % String(data.equipment_id if data != null else &"NULL"))
		var contract := KarmanyEquipmentAbilityRuntimeService.get_contract(data.equipment_id)
		var status := StringName(contract.get("status", &"PENDING"))
		if status == KarmanyEquipmentAbilityRuntimeService.STATUS_PENDING or status == KarmanyEquipmentAbilityRuntimeService.STATUS_DATA_ONLY:
			return _fail("%s conserva estado no resuelto %s." % [String(data.equipment_id), String(status)])
		if status == KarmanyEquipmentAbilityRuntimeService.STATUS_PARTIAL and String(contract.get("reason", "")).is_empty():
			return _fail("%s es PARTIAL sin razon explicita." % String(data.equipment_id))
	var counts := KarmanyEquipmentAbilityRuntimeService.get_contract_counts()
	if int(counts.get(KarmanyEquipmentAbilityRuntimeService.STATUS_FULLY, 0)) != 1:
		return _fail("Se esperaba 1 contrato FULLY_EXECUTABLE: %s." % str(counts))
	if int(counts.get(KarmanyEquipmentAbilityRuntimeService.STATUS_PARTIAL, 0)) != 35:
		return _fail("Se esperaban 35 contratos PARTIAL: %s." % str(counts))
	print("F44.4 CONTRACTS | 36/36 | FULLY=1 PARTIAL=35 DATA_ONLY=0 PENDING=0")
	return true


func _test_pending_runtime_exclusion() -> bool:
	var direct := _load_dir("res://data/equipment")
	if direct.size() != 9:
		return _fail("El runtime directo debe conservar exactamente 9 Equipos canonicos durante F44.4.")
	for data in direct:
		if KarmanyEquipmentAbilityRuntimeService.is_runtime_excluded(data.equipment_id):
			return _fail("%s fue excluido pese a estar en el catalogo directo." % String(data.equipment_id))
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 27:
		return _fail("Se esperaban 27 Equipos materializados aislados.")
	for data in pending:
		if not data.trigger_tags.has("pending_f44"):
			return _fail("%s no conserva el marcador canonical_pending." % String(data.equipment_id))
		if not KarmanyEquipmentAbilityRuntimeService.is_runtime_excluded(data.equipment_id):
			return _fail("%s fue promovido al runtime sin estructurar su regla." % String(data.equipment_id))
	print("F44.4 EXCLUSION | 27 canonical_pending siguen fuera del runtime directo; 9 Equipos directos auditados.")
	return true


func _test_canonical_runtime_hooks() -> bool:
	var eq01 := load("res://data/equipment/eq_01_cristal_de_crecimiento.tres") as KarmanyEquipmentData
	var inventory := KarmanyEquipmentInventory.new()
	if eq01 == null or not inventory.add_equipment(eq01):
		return _fail("EQ-01 no pudo entrar al inventario tipado.")
	var modifiers := KarmanyCombatPowerModifiers.new()
	if not KarmanyEquipmentCombatRules.apply_to_combat_modifiers(
		inventory,
		KarmanyCombatRequest.TargetType.BEAST,
		modifiers
	):
		return _fail("EQ-01 no pudo aplicar reglas de Equipo al combate.")
	if modifiers.equipment_power != 2:
		return _fail("EQ-01 debe aportar +2 Poder contra Bestias; obtuvo %d." % modifiers.equipment_power)

	var eq09 := load("res://data/equipment/eq_09_catalizador_de_aeterna.tres") as KarmanyEquipmentData
	inventory = KarmanyEquipmentInventory.new()
	if eq09 == null or not inventory.add_equipment(eq09):
		return _fail("EQ-09 no pudo entrar al inventario tipado.")
	modifiers = KarmanyCombatPowerModifiers.new()
	KarmanyEquipmentCombatRules.apply_to_combat_modifiers(
		inventory,
		KarmanyCombatRequest.TargetType.BOSS,
		modifiers
	)
	if modifiers.equipment_power != 4:
		return _fail("EQ-09 debe aportar +4 Poder contra Jefes; obtuvo %d." % modifiers.equipment_power)
	modifiers = KarmanyCombatPowerModifiers.new()
	KarmanyEquipmentCombatRules.apply_to_combat_modifiers(
		inventory,
		KarmanyCombatRequest.TargetType.BEAST,
		modifiers
	)
	if modifiers.equipment_power != 0:
		return _fail("EQ-09 aplico el bono de Jefe a una Bestia no Jefe.")
	modifiers = KarmanyCombatPowerModifiers.new()
	KarmanyEquipmentCombatRules.apply_to_combat_modifiers(
		inventory,
		KarmanyCombatRequest.TargetType.LEGENDARY,
		modifiers
	)
	if modifiers.equipment_power != 4:
		return _fail("EQ-09 perdio su modificador estructurado contra Legendarios.")

	var basic_beast := load("res://data/beasts/b_02_picorroca.tres") as KarmanyBeastData
	var boss_beast := load("res://data/beasts/b_22_custodio_del_santuario.tres") as KarmanyBeastData
	if KarmanyEquipmentAbilityRuntimeService.resolve_beast_target_type(basic_beast) != KarmanyCombatRequest.TargetType.BEAST:
		return _fail("El resolver F44.4 clasifico B-02 como Jefe.")
	if KarmanyEquipmentAbilityRuntimeService.resolve_beast_target_type(boss_beast) != KarmanyCombatRequest.TargetType.BOSS:
		return _fail("El resolver F44.4 no clasifico B-22 como Jefe.")
	print("F44.4 HOOKS | EQ-01 +2 Poder contra Bestias ejecutable; EQ-09 distingue BEAST/BOSS y mantiene +4 estructurado para Legendario.")
	return true


func _load_dir(path: String) -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyEquipmentData
		if data != null:
			result.append(data)
	return result


func _fail(message: String) -> bool:
	push_error("F44.4: %s" % message)
	return false
