extends Node

const DIRECT_DIR := "res://data/resonances"
const PENDING_DIR := "res://data/resonances/canonical_pending"

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.5 RESONANCIAS COMPLETAS")
	print("================================")
	var ok := _test_complete_catalog()
	ok = _test_pending_isolation() and ok
	ok = _test_canonical_corrections() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 43.5 OK - 40/40 Resonancias canonicas materializadas; R-06/R-07 corregidas y pendientes aisladas hasta F44.")
	else:
		push_error("FASE 43.5 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")

func _test_complete_catalog() -> bool:
	var resources := _load_all_resonances()
	if resources.size() != 40:
		return _fail("Se esperaban exactamente 40 Resources Resonancia y se cargaron %d." % resources.size())
	var by_id: Dictionary = {}
	for data in resources:
		if data == null or not data.is_valid_definition():
			return _fail("Existe una Resonancia nula o con definicion invalida.")
		var id := String(data.resonance_id)
		if by_id.has(id):
			return _fail("ID Resonancia duplicado: %s." % id)
		by_id[id] = data
	for definition in KarmanyV074CanonicalRuntimeCatalog.RESONANCE_DEFINITIONS:
		var id := String(definition.get("id", ""))
		if not by_id.has(id):
			return _fail("Falta identidad canonica %s." % id)
		var data := by_id[id] as KarmanyResonanceData
		if data.display_name != String(definition.get("name", "")):
			return _fail("Nombre no canonico en %s: %s." % [id, data.display_name])
		if data.resonance_type != int(definition.get("type", -1)):
			return _fail("Tipo no canonico en %s." % id)
		if data.printed_power != int(definition.get("power", -1)):
			return _fail("Valor impreso no canonico en %s." % id)
		var expected_windows: PackedStringArray = definition.get("windows", PackedStringArray())
		if data.use_windows != expected_windows:
			return _fail("Ventana de uso no canonica en %s." % id)
		var effect_text := String(definition.get("effect_text", "")).strip_edges()
		if effect_text.is_empty() or data.rules_text.find(effect_text) < 0:
			return _fail("Efecto v0.74 no esta preservado en %s." % id)
	return true

func _test_pending_isolation() -> bool:
	var direct := KarmanyPhase37AlphaContentCatalog.load_category(&"resonances")
	if direct.size() != 13:
		return _fail("El catalogo directo cambio: se esperaban 13 Resources y hay %d." % direct.size())
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 27:
		return _fail("Se esperaban exactamente 27 Resonancias pendientes F44.")
	for data in pending:
		if not data.tags.has("pending_f44"):
			return _fail("%s no esta marcada como automatizacion pendiente F44." % data.resonance_id)
		if not data.modifiers.is_empty() or not data.effect_blocks.is_empty():
			return _fail("%s contiene automatizacion ejecutable inventada antes de F44." % data.resonance_id)
	var full_pool := KarmanyV074CanonicalRuntimeCatalog.build_full_resonance_pool(_typed(direct))
	if full_pool.size() != 40:
		return _fail("El fallback canonico de Resonancias dejo de construir 40 identidades.")
	if KarmanyV074CanonicalRuntimeCatalog.AUTOMATED_RESONANCE_IDS.size() != 13:
		return _fail("La lista historica de Resonancias automatizadas cambio durante F43.5.")
	return true

func _test_canonical_corrections() -> bool:
	var direct := _load_dir(DIRECT_DIR)
	var by_id: Dictionary = {}
	for data in direct:
		by_id[String(data.resonance_id)] = data
	var r06 := by_id.get("R-06", null) as KarmanyResonanceData
	var r07 := by_id.get("R-07", null) as KarmanyResonanceData
	if r06 == null or r06.display_name != "Chispa del Libro":
		return _fail("R-06 no fue corregida a Chispa del Libro.")
	if r06.rules_text != "Si tienes Libro II o III, roba 2 Resonancias y descarta 1.":
		return _fail("R-06 no conserva el efecto exacto del maestro v0.74.")
	if r07 == null or r07.display_name != "Golpe Certero":
		return _fail("R-07 no fue corregida a Golpe Certero.")
	if r07.rules_text != "Carta segura de buen valor. Si esta carta te hace igualar exactamente la Defensa, roba 1 Resonancia.":
		return _fail("R-07 no conserva el efecto exacto del maestro v0.74.")
	return true

func _load_all_resonances() -> Array[KarmanyResonanceData]:
	var result := _load_dir(DIRECT_DIR)
	result.append_array(_load_dir(PENDING_DIR))
	return result

func _load_dir(path: String) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var value := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyResonanceData
		if value != null:
			result.append(value)
	return result

func _typed(values: Array[Resource]) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	for value in values:
		var data := value as KarmanyResonanceData
		if data != null:
			result.append(data)
	return result

func _fail(message: String) -> bool:
	push_error("FASE 43.5 ERROR: %s" % message)
	return false
