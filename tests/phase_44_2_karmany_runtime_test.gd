extends Node

const PENDING_DIR := "res://data/karmanys/canonical_pending"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.2 KARMANY")
	print("========================================")
	var ok := _test_contract_coverage()
	ok = _test_pending_runtime_exclusion() and ok
	ok = _test_beast_combat_hooks() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.2 OK - 28/28 Karmany con contrato runtime explicito; 6 FULLY_EXECUTABLE y 22 PARTIAL sin promociones falsas.")
	else:
		push_error("FASE 44.2 ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_contract_coverage() -> bool:
	var expected_rows := _load_all_karmanys()
	if expected_rows.size() != 28:
		return _fail("Se esperaban 28 Karmany y se cargaron %d." % expected_rows.size())
	for data in expected_rows:
		if data == null or not KarmanyAbilityRuntimeService.has_contract(data.karmany_id):
			return _fail("Karmany sin contrato F44.2: %s." % String(data.karmany_id if data != null else &"NULL"))
		var contract := KarmanyAbilityRuntimeService.get_contract(data.karmany_id)
		var status := StringName(contract.get("status", &"PENDING"))
		if status == KarmanyAbilityRuntimeService.STATUS_PENDING or status == KarmanyAbilityRuntimeService.STATUS_DATA_ONLY:
			return _fail("%s conserva estado no resuelto %s." % [String(data.karmany_id), String(status)])
		if status == KarmanyAbilityRuntimeService.STATUS_PARTIAL and String(contract.get("reason", "")).is_empty():
			return _fail("%s es PARTIAL sin exclusion explicita." % String(data.karmany_id))
	var counts := KarmanyAbilityRuntimeService.get_contract_counts()
	if int(counts.get(KarmanyAbilityRuntimeService.STATUS_FULLY, 0)) != 6:
		return _fail("Se esperaban 6 contratos FULLY_EXECUTABLE: %s." % str(counts))
	if int(counts.get(KarmanyAbilityRuntimeService.STATUS_PARTIAL, 0)) != 22:
		return _fail("Se esperaban 22 contratos PARTIAL: %s." % str(counts))
	if KarmanyAbilityRuntimeService.get_status(&"K-17") != KarmanyAbilityRuntimeService.STATUS_FULLY:
		return _fail("K-17 debe estar FULLY tras integrar su defensa PvP.")
	if KarmanyAbilityRuntimeService.get_status(&"K-22") != KarmanyAbilityRuntimeService.STATUS_FULLY:
		return _fail("K-22 debe estar FULLY tras cubrir Bestias altas y Legendaria.")
	if KarmanyAbilityRuntimeService.get_status(&"K-21") != KarmanyAbilityRuntimeService.STATUS_PARTIAL:
		return _fail("K-21 debe seguir PARTIAL hasta cubrir todas las derrotas de combate.")
	print("F44.2 CONTRACTS | 28/28 | FULLY=6 PARTIAL=22 DATA_ONLY=0 PENDING=0")
	return true


func _test_pending_runtime_exclusion() -> bool:
	var direct := KarmanyPhase37AlphaContentCatalog.load_category(&"karmanys")
	if direct.size() != 13:
		return _fail("El catalogo runtime directo debe conservar 13 Karmany durante F44.2.")
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 15:
		return _fail("Se esperaban 15 Karmany materializados aislados.")
	for data in pending:
		if data.abilities.size() != 1 or data.abilities[0].trigger_id != &"pending_f44":
			return _fail("%s fue promovido fisicamente antes de integrar su flujo completo." % String(data.karmany_id))
	print("F44.2 EXCLUSION | 15 canonical_pending siguen fuera del catalogo directo; contrato auditable disponible.")
	return true


func _test_beast_combat_hooks() -> bool:
	KarmanyAbilityRuntimeService.clear_test_tracking()
	var basic := KarmanyBeastData.new()
	basic.tier = KarmanyBeastData.Tier.BASIC
	var medium := KarmanyBeastData.new()
	medium.tier = KarmanyBeastData.Tier.MEDIUM
	var complex := KarmanyBeastData.new()
	complex.tier = KarmanyBeastData.Tier.COMPLEX
	var tile_n1 := KarmanyTileData.new()
	tile_n1.level = KarmanyTileData.TileLevel.N1
	var tile_n2 := KarmanyTileData.new()
	tile_n2.level = KarmanyTileData.TileLevel.N2

	var terrakor := load("res://data/karmanys/k_01_terrakor.tres") as KarmanyData
	var context := KarmanyBeastCombatContext.new()
	var token := KarmanyAbilityRuntimeService.apply_beast_combat_preflight(terrakor, basic, tile_n1, 2, 9001, context)
	if context.combat_modifiers.other_power != 2:
		return _fail("K-01 no aplico +2 Poder contra Bestia.")
	KarmanyAbilityRuntimeService.commit_beast_combat(token, true)
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(terrakor, basic, tile_n1, 2, 9001, context)
	if context.combat_modifiers.other_power != 0:
		return _fail("K-01 ignoro su limite una vez por ronda.")
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(terrakor, basic, tile_n1, 3, 9001, context)
	if context.combat_modifiers.other_power != 2:
		return _fail("K-01 no se reactivo en una ronda nueva.")

	var brumak := load("res://data/karmanys/k_10_brumak.tres") as KarmanyData
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(brumak, basic, tile_n2, 2, 9001, context)
	if context.combat_modifiers.other_power != 2:
		return _fail("K-10 no aplico +2 Poder a Bestia en loseta N2.")
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(brumak, basic, tile_n1, 2, 9001, context)
	if context.combat_modifiers.other_power != 0:
		return _fail("K-10 aplico bono fuera de N2.")

	var ferrak := load("res://data/karmanys/canonical_pending/k_13_ferrak.tres") as KarmanyData
	if ferrak == null:
		return _fail("No se pudo cargar K-13 Ferrak.")
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(ferrak, medium, tile_n2, 2, 9001, context)
	if context.combat_modifiers.other_power != 2:
		return _fail("K-13 no aplico +2 Poder contra Bestia media.")
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(ferrak, basic, tile_n2, 2, 9001, context)
	if context.combat_modifiers.other_power != 0:
		return _fail("K-13 aplico bono a una Bestia no media.")

	var runakar := load("res://data/karmanys/canonical_pending/k_22_runakar.tres") as KarmanyData
	context = KarmanyBeastCombatContext.new()
	KarmanyAbilityRuntimeService.apply_beast_combat_preflight(runakar, complex, tile_n2, 2, 9001, context)
	if context.combat_modifiers.other_power != 2:
		return _fail("K-22 no cubre su rama Bestia compleja.")
	if KarmanyAbilityRuntimeService.get_status(&"K-22") != KarmanyAbilityRuntimeService.STATUS_FULLY:
		return _fail("K-22 debe quedar FULLY al cubrir Bestias altas y Legendaria/Aeterna.")

	var pyrox := load("res://data/karmanys/k_03_pyrox.tres") as KarmanyData
	context = KarmanyBeastCombatContext.new()
	var risk_token := KarmanyAbilityRuntimeService.apply_beast_combat_preflight(pyrox, basic, tile_n1, 2, 9001, context)
	if not context.risk_authorized or not bool(risk_token.get("risk_authorized", false)):
		return _fail("K-03 no autoriza el Dado de Riesgo en preflight.")
	print("F44.2 BEAST HOOKS | K-01/K-10/K-13/K-22 ejecutables; K-03 conserva su rama Riesgo PARTIAL.")
	return true


func _load_all_karmanys() -> Array[KarmanyData]:
	var result := _load_dir("res://data/karmanys")
	result.append_array(_load_dir(PENDING_DIR))
	return result


func _load_dir(path: String) -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyData
		if data != null:
			result.append(data)
	return result


func _fail(message: String) -> bool:
	push_error("F44.2: %s" % message)
	return false
