extends Node

const EXPECTED_TOTAL: int = 205

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - CIERRE FASE 43")
	print("================================")
	var ok: bool = _run_test()
	print("")
	print("================================")
	if ok:
		print("FASE 43 OK - 205/205 identidades canonicas, 8 categorias y 0 IDs duplicados; listo para F44.")
	else:
		push_error("FASE 43 ERROR - revisar el primer fallo real antes de iniciar F44.")
	print("================================")

func _run_test() -> bool:
	var global_seen: Dictionary = {}
	var total: int = 0
	for spec in _specs():
		var category: String = spec["category"]
		var directory: String = spec["directory"]
		var id_property: String = spec["id_property"]
		var expected_ids: Array = spec["expected_ids"]
		var resources: Array[Resource] = _load_resources_recursive(directory)
		if resources.size() != expected_ids.size():
			return _fail("%s: esperados %d Resources y hay %d." % [category, expected_ids.size(), resources.size()])
		var expected_set: Dictionary = {}
		for expected_id in expected_ids:
			expected_set[String(expected_id)] = true
		var category_seen: Dictionary = {}
		for data in resources:
			if data == null:
				return _fail("%s: se cargo un Resource nulo." % category)
			var raw_id: Variant = data.get(id_property)
			var canonical_id: String = String(raw_id)
			if canonical_id.is_empty():
				return _fail("%s: Resource sin %s." % [category, id_property])
			if category_seen.has(canonical_id):
				return _fail("%s: ID duplicado dentro de la categoria: %s." % [category, canonical_id])
			if global_seen.has(canonical_id):
				return _fail("ID duplicado entre categorias: %s aparece en %s y %s." % [canonical_id, global_seen[canonical_id], category])
			if not expected_set.has(canonical_id):
				return _fail("%s: ID no canonico/no esperado: %s." % [category, canonical_id])
			category_seen[canonical_id] = true
			global_seen[canonical_id] = category
		for expected_id in expected_ids:
			if not category_seen.has(String(expected_id)):
				return _fail("%s: falta ID canonico %s." % [category, String(expected_id)])
		total += resources.size()
		print("F43 CIERRE | %s = %d/%d" % [category, resources.size(), expected_ids.size()])
	if total != EXPECTED_TOTAL:
		return _fail("Total canonico esperado %d y se encontraron %d Resources." % [EXPECTED_TOTAL, total])
	if global_seen.size() != EXPECTED_TOTAL:
		return _fail("El set global contiene %d IDs, se esperaban %d." % [global_seen.size(), EXPECTED_TOTAL])
	return true

func _load_resources_recursive(directory: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var resource := load("%s/%s" % [directory, file_name]) as Resource
		if resource != null:
			result.append(resource)
	for child_name in dir.get_directories():
		result.append_array(_load_resources_recursive("%s/%s" % [directory, child_name]))
	return result

func _specs() -> Array[Dictionary]:
	return [
		{"category":"Entrenadores","directory":"res://data/trainers","id_property":"card_id","expected_ids":["E-01","E-02","E-03","E-04","E-05","E-06","E-07","E-08"]},
		{"category":"Losetas","directory":"res://data/tiles","id_property":"tile_id","expected_ids":["I-01","I-02","I-03","I-04","N1-01","N1-02","N1-03","N1-04","N1-05","N1-06","N1-07","N1-08","N1-09","N1-10","N1-11","N1-12","N1-13","N1-14","N1-15","N1-16","N1-17","N1-18","N2-01","N2-02","N2-03","N2-04","N2-05","N2-06","N2-07","N2-08","N2-09","N2-10","N2-11","N2-12","N3-01","N3-02","N3-03","L-01","N3-04","N3-05","N3-06"]},
		{"category":"Karmany","directory":"res://data/karmanys","id_property":"karmany_id","expected_ids":["K-01","K-02","K-03","K-04","K-05","K-06","K-07","K-08","K-09","K-10","K-11","K-12","K-13","K-14","K-15","K-16","K-17","K-18","K-19","K-20","K-21","K-22","K-23","K-24","K-25","K-26","K-27","K-28"]},
		{"category":"Bestias","directory":"res://data/beasts","id_property":"beast_id","expected_ids":["B-01","B-02","B-03","B-04","B-05","B-06","B-07","B-08","B-09","B-10","B-11","B-12","B-13","B-14","B-15","B-16","B-17","B-18","B-19","B-20","B-21","B-22","B-23","B-24"]},
		{"category":"Equipo","directory":"res://data/equipment","id_property":"equipment_id","expected_ids":["EQ-01","EQ-02","EQ-03","EQ-04","EQ-05","EQ-06","EQ-07","EQ-08","EQ-09","EQ-10","EQ-11","EQ-12","EQ-13","EQ-14","EQ-15","EQ-16","EQ-17","EQ-18","EQ-19","EQ-20","EQ-21","EQ-22","EQ-23","EQ-24","EQ-25","EQ-26","EQ-27","EQ-28","EQ-29","EQ-30","EQ-31","EQ-32","EQ-33","EQ-34","EQ-35","EQ-36"]},
		{"category":"Resonancias","directory":"res://data/resonances","id_property":"resonance_id","expected_ids":["R-01","R-02","R-03","R-04","R-05","R-06","R-07","R-08","R-09","R-10","R-11","R-12","R-13","R-14","R-15","R-16","R-17","R-18","R-19","R-20","R-21","R-22","R-23","R-24","R-25","R-26","R-27","R-28","R-29","R-30","R-31","R-32","R-33","R-34","R-35","R-36","R-37","R-38","R-39","R-40"]},
		{"category":"Objetivos","directory":"res://data/objectives","id_property":"objective_id","expected_ids":["OP-E01","OP-E02","OP-E03","OP-D01","OP-D02","OP-D03","OP-C01","OP-C02","OP-C03","OP-A01","OP-A02","OP-A03"]},
		{"category":"Misiones","directory":"res://data/missions","id_property":"mission_id","expected_ids":["ME-A1","ME-A2","ME-L1","ME-L2","ME-D1","ME-D2","ME-N1","ME-N2","ME-M1","ME-M2","ME-K1","ME-K2","ME-S1","ME-S2","ME-O1","ME-O2"]}
	]

func _fail(message: String) -> bool:
	push_error("FASE 43 CIERRE TEST ERROR: %s" % message)
	return false
