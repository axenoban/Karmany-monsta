extends Node


func _ready() -> void:
	print("\n================================")
	print("KARMANY MONSTA - FASE 29 CONTENT TEST")
	print("================================")
	var ok: bool = true
	ok = _test_counts() and ok
	ok = _test_materialized_resources() and ok
	ok = _test_coverage_separation() and ok
	ok = _test_starter_roster() and ok
	ok = _test_content_samples() and ok
	if ok:
		print("FASE 29 OK - Catalogo ampliado sin introducir contenido no automatizado en pools ejecutables.")
	else:
		push_error("FASE 29 ERROR - Revisar el primer fallo del catalogo de contenido.")
	print("================================")


func _test_counts() -> bool:
	var expected_canonical: Dictionary = {
		"trainers": 8, "tiles": 41, "karmanys": 28, "beasts": 24,
		"equipment": 36, "resonances": 40, "objectives": 12, "missions": 16
	}
	for category in KarmanyPhase29ContentCatalog.CATEGORIES:
		var key: String = String(category)
		if int(KarmanyPhase29ContentCatalog.CANONICAL_COUNTS.get(key, -1)) != int(expected_canonical[key]):
			return _fail("Conteo canonico incorrecto para %s." % key)
		if KarmanyPhase29ContentCatalog.get_added_paths(category).is_empty():
			return _fail("Fase 29 no amplio la categoria %s." % key)
		if KarmanyPhase29ContentCatalog.get_expected_materialized_count(category) > int(expected_canonical[key]):
			return _fail("La cobertura materializada supera el catalogo canonico en %s." % key)
	print("Ocho categorias ampliadas + conteos canonicos: OK")
	return true


func _test_materialized_resources() -> bool:
	for category in KarmanyPhase29ContentCatalog.CATEGORIES:
		var expected_ids: Array[StringName] = KarmanyPhase29ContentCatalog.get_added_ids(category)
		var seen_ids: Dictionary = {}
		for path in KarmanyPhase29ContentCatalog.get_added_paths(category):
			if not ResourceLoader.exists(path):
				return _fail("Ruta de contenido inexistente: %s" % path)
			var resource_value: Resource = load(path)
			if not KarmanyPhase29ContentCatalog.is_resource_valid(category, resource_value):
				return _fail("Resource invalido en %s" % path)
			var content_id: StringName = KarmanyPhase29ContentCatalog.get_content_id(category, resource_value)
			if content_id == &"" or not expected_ids.has(content_id):
				return _fail("ID no esperado en %s" % path)
			if seen_ids.has(content_id):
				return _fail("ID duplicado %s en %s" % [String(content_id), String(category)])
			seen_ids[content_id] = true
		if seen_ids.size() != expected_ids.size():
			return _fail("Cantidad de IDs no coincide en %s" % String(category))
	print("Resources cargan + validan + IDs unicos: OK")
	return true


func _test_coverage_separation() -> bool:
	if KarmanyPhase29ContentCatalog.get_coverage_state(&"karmanys", &"K-09") != KarmanyPhase29ContentCatalog.CoverageState.EXECUTABLE:
		return _fail("Verdan debe ser ejecutable.")
	if KarmanyPhase29ContentCatalog.get_coverage_state(&"resonances", &"R-09") != KarmanyPhase29ContentCatalog.CoverageState.EXECUTABLE:
		return _fail("R-09 debe ser ejecutable.")
	if KarmanyPhase29ContentCatalog.get_coverage_state(&"resonances", &"R-20") != KarmanyPhase29ContentCatalog.CoverageState.INTEGRATION_PENDING:
		return _fail("R-20 debe permanecer integracion pendiente hasta cubrir todos sus contextos de combate.")
	if KarmanyPhase29ContentCatalog.get_coverage_state(&"trainers", &"E-03") != KarmanyPhase29ContentCatalog.CoverageState.INTEGRATION_PENDING:
		return _fail("E-03 debe permanecer integracion pendiente hasta automatizar toda su carta.")
	if KarmanyPhase29ContentCatalog.get_coverage_state(&"beasts", &"B-23") != KarmanyPhase29ContentCatalog.CoverageState.INTEGRATION_PENDING:
		return _fail("B-23 no debe entrar silenciosamente como Bestia completamente automatizada.")
	if KarmanyPhase29ContentCatalog.get_coverage_state(&"equipment", &"EQ-34") != KarmanyPhase29ContentCatalog.CoverageState.INTEGRATION_PENDING:
		return _fail("EQ-34 debe permanecer fuera del pool seguro hasta cablear su modificador.")
	print("Ejecutable vs integracion pendiente separados: OK")
	return true


func _test_starter_roster() -> bool:
	var starter_paths: Array[String] = [
		"res://data/karmanys/k_01_terrakor.tres", "res://data/karmanys/k_02_aquaris.tres",
		"res://data/karmanys/k_03_pyrox.tres", "res://data/karmanys/k_04_lumirra.tres",
		"res://data/karmanys/k_25_zephyr.tres", "res://data/karmanys/k_26_umbrio.tres",
		"res://data/karmanys/k_27_gemmir.tres", "res://data/karmanys/k_28_vulkai.tres"
	]
	var starter_ids: Dictionary = {}
	for path in starter_paths:
		if not ResourceLoader.exists(path):
			return _fail("Falta Karmany inicial: %s" % path)
		var data: KarmanyData = load(path) as KarmanyData
		if data == null or not data.is_valid_definition() or not data.is_starting_karmany:
			return _fail("Karmany inicial invalido: %s" % path)
		starter_ids[data.karmany_id] = true
	if starter_ids.size() != 8:
		return _fail("El set inicial debe contener 8 IDs unicos.")
	print("Ocho Karmany iniciales materializados: OK")
	return true


func _test_content_samples() -> bool:
	var tile: KarmanyTileData = load("res://data/tiles/i_03_puesto_rocoso.tres") as KarmanyTileData
	if tile == null or tile.entry_effects.size() != 1 or tile.later_use_effects.size() != 1:
		return _fail("I-03 no contiene sus efectos ejecutables de Entrada/Uso posterior.")
	if tile.entry_effects[0].resource_type != KarmanyEffectData.ResourceType.MR or tile.entry_effects[0].amount != 1:
		return _fail("Entrada I-03 debe otorgar +1 MR.")
	if tile.later_use_effects[0].resource_type != KarmanyEffectData.ResourceType.MR or tile.later_use_effects[0].amount != 2:
		return _fail("Uso posterior I-03 debe otorgar +2 MR.")

	var verdan: KarmanyData = load("res://data/karmanys/k_09_verdan.tres") as KarmanyData
	if verdan == null or verdan.power != 6 or verdan.encounter_defense != 9 or not verdan.can_acquire_by_defeat:
		return _fail("K-09 no coincide con su nucleo canonico.")

	var r09: KarmanyResonanceData = load("res://data/resonances/r_09_ruptura_runica.tres") as KarmanyResonanceData
	var r09_blocks: Array[KarmanyResonanceEffectBlockData] = r09.get_matching_effect_blocks(&"after_combat", PackedStringArray(["combat_won", "target_beast"]))
	if r09_blocks.size() != 1 or r09_blocks[0].effects.size() != 1 or r09_blocks[0].effects[0].amount != 2:
		return _fail("R-09 no expone su recompensa +2 MR tras victoria contra Bestia.")

	var r20: KarmanyResonanceData = load("res://data/resonances/r_20_ultima_defensa.tres") as KarmanyResonanceData
	var r20_blocks: Array[KarmanyResonanceEffectBlockData] = r20.get_matching_effect_blocks(&"after_combat", PackedStringArray(["combat_lost"]))
	if r20_blocks.size() != 1 or r20_blocks[0].effects.size() != 2:
		return _fail("R-20 no conserva su estructura de robo/descarte tras derrota.")

	print("Muestras I-03 + K-09 + R-09 ejecutables; R-20 materializada con cobertura pendiente: OK")
	return true


func _fail(message: String) -> bool:
	push_error("FASE 29 ERROR: %s" % message)
	return false
