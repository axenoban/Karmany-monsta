extends Node

const PENDING_DIR := "res://data/beasts/canonical_pending"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.3 BESTIAS")
	print("========================================")
	var ok := _test_contract_coverage()
	ok = _test_pending_runtime_exclusion() and ok
	ok = _test_canonical_runtime_hooks() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.3 OK - 24/24 Bestias con contrato runtime explicito; 2 FULLY_EXECUTABLE y 22 PARTIAL sin reglas inventadas.")
	else:
		push_error("FASE 44.3 ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_contract_coverage() -> bool:
	var all_beasts := _load_dir("res://data/beasts")
	all_beasts.append_array(_load_dir(PENDING_DIR))
	if all_beasts.size() != 24:
		return _fail("Se esperaban 24 Bestias y se cargaron %d." % all_beasts.size())
	for data in all_beasts:
		if data == null or not KarmanyBeastAbilityRuntimeService.has_contract(data.beast_id):
			return _fail("Bestia sin contrato F44.3: %s." % String(data.beast_id if data != null else &"NULL"))
		var contract := KarmanyBeastAbilityRuntimeService.get_contract(data.beast_id)
		var status := StringName(contract.get("status", &"PENDING"))
		if status == KarmanyBeastAbilityRuntimeService.STATUS_PENDING or status == KarmanyBeastAbilityRuntimeService.STATUS_DATA_ONLY:
			return _fail("%s conserva estado no resuelto %s." % [String(data.beast_id), String(status)])
		if status == KarmanyBeastAbilityRuntimeService.STATUS_PARTIAL and String(contract.get("reason", "")).is_empty():
			return _fail("%s es PARTIAL sin exclusion explicita." % String(data.beast_id))
	var counts := KarmanyBeastAbilityRuntimeService.get_contract_counts()
	if int(counts.get(KarmanyBeastAbilityRuntimeService.STATUS_FULLY, 0)) != 2:
		return _fail("Se esperaban 2 contratos FULLY_EXECUTABLE: %s." % str(counts))
	if int(counts.get(KarmanyBeastAbilityRuntimeService.STATUS_PARTIAL, 0)) != 22:
		return _fail("Se esperaban 22 contratos PARTIAL: %s." % str(counts))
	print("F44.3 CONTRACTS | 24/24 | FULLY=2 PARTIAL=22 DATA_ONLY=0 PENDING=0")
	return true


func _test_pending_runtime_exclusion() -> bool:
	var direct := KarmanyPhase37AlphaContentCatalog.load_category(&"beasts")
	if direct.size() != 7:
		return _fail("El catalogo runtime directo debe conservar 7 Bestias canonicas durante F44.3.")
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 17:
		return _fail("Se esperaban 17 Bestias materializadas aisladas.")
	for data in pending:
		if not data.special_rule_ids.has("pending_f44"):
			return _fail("%s no conserva el marcador canonical_pending." % String(data.beast_id))
		if not KarmanyBeastAbilityRuntimeService.is_runtime_excluded(data.beast_id):
			return _fail("%s fue promovida al runtime sin estructurar sus reglas." % String(data.beast_id))
	print("F44.3 EXCLUSION | 17 canonical_pending siguen fuera del catalogo directo y del resolver de encuentros.")
	return true


func _test_canonical_runtime_hooks() -> bool:
	var picorroca := load("res://data/beasts/b_02_picorroca.tres") as KarmanyBeastData
	var context := KarmanyBeastCombatContext.new()
	context.risk_authorized = true
	context.risk_roll = 4
	var token := KarmanyBeastAbilityRuntimeService.apply_combat_preflight(picorroca, context)
	if context.beast_defense_bonus != 2 or int(token.get("beast_defense_bonus", 0)) != 2:
		return _fail("B-02 no obtiene +2 Poder/defensa al usar Dado de Riesgo.")
	context = KarmanyBeastCombatContext.new()
	KarmanyBeastAbilityRuntimeService.apply_combat_preflight(picorroca, context)
	if context.beast_defense_bonus != 0:
		return _fail("B-02 aplico +2 sin usar Dado de Riesgo.")

	var terranuk := load("res://data/beasts/b_07_terranuk.tres") as KarmanyBeastData
	var stable := KarmanyData.new()
	stable.primary_type = KarmanyData.StrategicType.STABLE
	var player := KarmanyPlayerState.new()
	var applied := KarmanyBeastAbilityRuntimeService.apply_victory_specials(terranuk, stable, player)
	if player.mn != 2 or not applied.has("stable_win_plus_2_mn"):
		return _fail("B-07 no entrega +2 MN al ser derrotado por Karmany Estable.")
	var non_stable := KarmanyData.new()
	non_stable.primary_type = KarmanyData.StrategicType.WILD
	player = KarmanyPlayerState.new()
	KarmanyBeastAbilityRuntimeService.apply_victory_specials(terranuk, non_stable, player)
	if player.mn != 0:
		return _fail("B-07 entrega el bono Estable a un tipo no Estable.")

	var custodio := load("res://data/beasts/b_22_custodio_del_santuario.tres") as KarmanyBeastData
	context = KarmanyBeastCombatContext.new()
	context.book_level = 1
	if KarmanyBeastAbilityRuntimeService.validate_combat_preflight(custodio, context).is_empty():
		return _fail("B-22 permite combate con Libro I.")
	context.book_level = 2
	if not KarmanyBeastAbilityRuntimeService.validate_combat_preflight(custodio, context).is_empty():
		return _fail("B-22 bloquea incorrectamente Libro II.")

	var drakmaw := load("res://data/beasts/b_23_drakmaw.tres") as KarmanyBeastData
	context = KarmanyBeastCombatContext.new()
	KarmanyBeastAbilityRuntimeService.apply_combat_preflight(drakmaw, context)
	if not context.risk_repeat_locked or not context.risk_modify_locked:
		return _fail("B-23 no bloquea repeticion/modificacion del Dado de Riesgo.")
	print("F44.3 HOOKS | B-02 Riesgo, B-07 Estable, B-22 Libro y B-23 bloqueo de Riesgo ejecutables.")
	return true


func _load_dir(path: String) -> Array[KarmanyBeastData]:
	var result: Array[KarmanyBeastData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyBeastData
		if data != null:
			result.append(data)
	return result


func _fail(message: String) -> bool:
	push_error("F44.3: %s" % message)
	return false
