extends Node

const EXPECTED_TOTAL: int = 205

const STATUS_FULLY: String = "FULLY_EXECUTABLE"
const STATUS_PARTIAL: String = "PARTIAL"
const STATUS_DATA_ONLY: String = "DATA_ONLY"
const STATUS_PENDING: String = "PENDING"

const EXPECTED_STATUS_COUNTS: Dictionary = {
	"FULLY_EXECUTABLE": 0,
	"PARTIAL": 75,
	"DATA_ONLY": 130,
	"PENDING": 0,
}

const STRUCTURED_PROPERTIES: Array = [
	"on_explore_effects",
	"entry_effects",
	"later_use_effects",
	"abilities",
	"reward_effects",
	"defeat_effects",
	"modifiers",
	"effect_blocks",
	"conditions",
]

const TEXT_PROPERTIES: Array = [
	"rules_text",
	"passive_text",
	"active_text",
	"setup_bonus_text",
	"on_explore_text",
	"entry_bonus_text",
	"later_use_text",
	"condition_text",
	"reward_text",
	"defeat_text",
	"acquisition_text",
]

const CHOICE_HINTS: Array = [
	"elige",
	"puedes",
	"mira ",
	"mira una",
	"mira 1",
	"devuelve",
	"reordena",
	"cambia",
	"escoge",
	"selecciona",
	"descarta 1 de",
	"descarta un",
]


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.0 COBERTURA")
	print("========================================")

	var report: Dictionary = _run_audit()
	var ok: bool = bool(report.get("ok", false))

	print("")
	print("========================================")
	if ok:
		var totals: Dictionary = report.get("status_counts", {})
		print(
			"F44.0 STATUS | FULLY=%d | PARTIAL=%d | DATA_ONLY=%d | PENDING=%d"
			% [
				int(totals.get(STATUS_FULLY, 0)),
				int(totals.get(STATUS_PARTIAL, 0)),
				int(totals.get(STATUS_DATA_ONLY, 0)),
				int(totals.get(STATUS_PENDING, 0)),
			]
		)
		print(
			"F44.0 EVIDENCIA | payloads estructurados=%d | candidatos choice=%d"
			% [
				int(report.get("structured_evidence", 0)),
				int(report.get("choice_candidates", 0)),
			]
		)
		var scripts: Dictionary = report.get("script_evidence", {})
		print(
			"F44.0 INFRA | gd=%d resolver=%d controller=%d interaction=%d progress=%d ai=%d"
			% [
				int(scripts.get("gd", 0)),
				int(scripts.get("resolver", 0)),
				int(scripts.get("controller", 0)),
				int(scripts.get("interaction", 0)),
				int(scripts.get("progress", 0)),
				int(scripts.get("ai", 0)),
			]
		)
		print("FASE 44.0 OK - 205 Resources auditados; baseline logico reproducible listo para F44.1.")
	else:
		push_error("FASE 44.0 ERROR - revisar el primer fallo real antes de implementar F44.1.")
	print("========================================")


func _run_audit() -> Dictionary:
	var global_seen: Dictionary = {}
	var status_counts: Dictionary = _empty_status_counts()
	var total_resources: int = 0
	var total_direct: int = 0
	var total_pending_paths: int = 0
	var structured_evidence: int = 0
	var choice_candidates: int = 0

	for spec in _specs():
		var category: String = String(spec.get("category", ""))
		var directory: String = String(spec.get("directory", ""))
		var id_property: String = String(spec.get("id_property", ""))
		var expected_total: int = int(spec.get("total", 0))
		var expected_direct: int = int(spec.get("direct", 0))
		var expected_pending_paths: int = int(spec.get("pending_paths", 0))
		var expected_status: Dictionary = spec.get("status", {})

		var resources: Array[Resource] = _load_resources_recursive(directory)
		if resources.size() != expected_total:
			return _failure(
				"%s: esperados %d Resources y se cargaron %d."
				% [category, expected_total, resources.size()]
			)

		var category_seen: Dictionary = {}
		var category_status: Dictionary = _empty_status_counts()
		var direct_count: int = 0
		var pending_path_count: int = 0

		for data in resources:
			if data == null:
				return _failure("%s: se cargo un Resource nulo." % category)

			if not _has_property(data, id_property):
				return _failure("%s: Resource sin propiedad %s." % [category, id_property])

			var canonical_id: String = String(data.get(id_property))
			if canonical_id.is_empty():
				return _failure("%s: Resource con ID vacio." % category)
			if category_seen.has(canonical_id):
				return _failure("%s: ID duplicado %s." % [category, canonical_id])
			if global_seen.has(canonical_id):
				return _failure(
					"ID global duplicado %s entre %s y %s."
					% [canonical_id, String(global_seen[canonical_id]), category]
				)

			category_seen[canonical_id] = true
			global_seen[canonical_id] = category

			var is_pending_path: bool = data.resource_path.contains("/canonical_pending/")
			if is_pending_path:
				pending_path_count += 1
			else:
				direct_count += 1

			var status: String = _classify(category, data, is_pending_path)
			category_status[status] = int(category_status.get(status, 0)) + 1
			status_counts[status] = int(status_counts.get(status, 0)) + 1

			if is_pending_path and status != STATUS_DATA_ONLY:
				return _failure(
					"%s %s: canonical_pending fue promovido a %s sin prueba F44."
					% [category, canonical_id, status]
				)

			if _has_structured_evidence(data):
				structured_evidence += 1
			if _has_choice_hint(data):
				choice_candidates += 1

		if direct_count != expected_direct:
			return _failure(
				"%s: directos esperados %d y encontrados %d."
				% [category, expected_direct, direct_count]
			)
		if pending_path_count != expected_pending_paths:
			return _failure(
				"%s: canonical_pending esperados %d y encontrados %d."
				% [category, expected_pending_paths, pending_path_count]
			)
		if not _same_status_counts(category_status, expected_status):
			return _failure(
				"%s: clasificacion inesperada. esperado=%s real=%s"
				% [category, str(expected_status), str(category_status)]
			)

		print(
			"F44.0 | %s | total=%d direct=%d pending_path=%d | F=%d P=%d D=%d ?=%d"
			% [
				category,
				resources.size(),
				direct_count,
				pending_path_count,
				int(category_status.get(STATUS_FULLY, 0)),
				int(category_status.get(STATUS_PARTIAL, 0)),
				int(category_status.get(STATUS_DATA_ONLY, 0)),
				int(category_status.get(STATUS_PENDING, 0)),
			]
		)

		total_resources += resources.size()
		total_direct += direct_count
		total_pending_paths += pending_path_count

	if total_resources != EXPECTED_TOTAL:
		return _failure("Total esperado %d y auditado %d." % [EXPECTED_TOTAL, total_resources])
	if global_seen.size() != EXPECTED_TOTAL:
		return _failure("Set global esperado %d y real %d." % [EXPECTED_TOTAL, global_seen.size()])
	if total_direct != 80 or total_pending_paths != 125:
		return _failure(
			"Distribucion fisica inesperada: direct=%d pending=%d; esperado 80/125."
			% [total_direct, total_pending_paths]
		)
	if not _same_status_counts(status_counts, EXPECTED_STATUS_COUNTS):
		return _failure(
			"Totales logicos inesperados. esperado=%s real=%s"
			% [str(EXPECTED_STATUS_COUNTS), str(status_counts)]
		)

	var script_evidence: Dictionary = _scan_script_evidence("res://scripts")
	if int(script_evidence.get("gd", 0)) <= 0:
		return _failure("No se pudo inspeccionar infraestructura GDScript bajo res://scripts.")

	return {
		"ok": true,
		"status_counts": status_counts,
		"structured_evidence": structured_evidence,
		"choice_candidates": choice_candidates,
		"script_evidence": script_evidence,
	}


func _classify(category: String, data: Resource, is_pending_path: bool) -> String:
	if category == "Entrenadores":
		if not _has_property(data, "automation_status"):
			return STATUS_PENDING
		var automation_status: int = int(data.get("automation_status"))
		match automation_status:
			0:
				return STATUS_DATA_ONLY
			1:
				return STATUS_PARTIAL
			2:
				return STATUS_FULLY
			_:
				return STATUS_PENDING

	if is_pending_path:
		return STATUS_DATA_ONLY

	# F44.0 es una certificacion conservadora. Un Resource directo demuestra
	# integracion historica, pero no prueba por si solo todas las clausulas v0.74.
	return STATUS_PARTIAL


func _has_structured_evidence(data: Resource) -> bool:
	for property_name_variant in STRUCTURED_PROPERTIES:
		var property_name: String = String(property_name_variant)
		if not _has_property(data, property_name):
			continue
		var value: Variant = data.get(property_name)
		if value is Array and not value.is_empty():
			return true

	for trigger_property in ["interaction_profile_id", "trigger_id", "passive_id", "active_id", "setup_bonus_id"]:
		var property_name: String = String(trigger_property)
		if not _has_property(data, property_name):
			continue
		var trigger_value: String = String(data.get(property_name))
		if not trigger_value.is_empty() and trigger_value != "pending_f44":
			return true

	return false


func _has_choice_hint(data: Resource) -> bool:
	var combined_text: String = ""
	for property_name_variant in TEXT_PROPERTIES:
		var property_name: String = String(property_name_variant)
		if not _has_property(data, property_name):
			continue
		combined_text += " " + String(data.get(property_name)).to_lower()

	for hint_variant in CHOICE_HINTS:
		if combined_text.contains(String(hint_variant)):
			return true
	return false


func _has_property(data: Resource, property_name: String) -> bool:
	for property_info in data.get_property_list():
		if String(property_info.get("name", "")) == property_name:
			return true
	return false


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


func _scan_script_evidence(directory: String) -> Dictionary:
	var result: Dictionary = {
		"gd": 0,
		"resolver": 0,
		"controller": 0,
		"interaction": 0,
		"progress": 0,
		"ai": 0,
	}
	_scan_script_directory(directory, result)
	return result


func _scan_script_directory(directory: String, counters: Dictionary) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		return

	for file_name in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		var lower_name: String = file_name.to_lower()
		counters["gd"] = int(counters.get("gd", 0)) + 1
		if lower_name.contains("resolver"):
			counters["resolver"] = int(counters.get("resolver", 0)) + 1
		if lower_name.contains("controller"):
			counters["controller"] = int(counters.get("controller", 0)) + 1
		if lower_name.contains("interaction"):
			counters["interaction"] = int(counters.get("interaction", 0)) + 1
		if (
			lower_name.contains("objective")
			or lower_name.contains("mission")
			or lower_name.contains("progress")
			or lower_name.contains("tracker")
		):
			counters["progress"] = int(counters.get("progress", 0)) + 1
		if directory.contains("/ai") or lower_name.begins_with("ai_") or lower_name.contains("_ai_"):
			counters["ai"] = int(counters.get("ai", 0)) + 1

	for child_name in dir.get_directories():
		_scan_script_directory("%s/%s" % [directory, child_name], counters)


func _empty_status_counts() -> Dictionary:
	return {
		STATUS_FULLY: 0,
		STATUS_PARTIAL: 0,
		STATUS_DATA_ONLY: 0,
		STATUS_PENDING: 0,
	}


func _same_status_counts(actual: Dictionary, expected: Dictionary) -> bool:
	for status in [STATUS_FULLY, STATUS_PARTIAL, STATUS_DATA_ONLY, STATUS_PENDING]:
		if int(actual.get(status, 0)) != int(expected.get(status, 0)):
			return false
	return true


func _specs() -> Array[Dictionary]:
	return [
		{
			"category": "Entrenadores",
			"directory": "res://data/trainers",
			"id_property": "card_id",
			"total": 8,
			"direct": 8,
			"pending_paths": 0,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 3, STATUS_DATA_ONLY: 5, STATUS_PENDING: 0},
		},
		{
			"category": "Losetas",
			"directory": "res://data/tiles",
			"id_property": "tile_id",
			"total": 41,
			"direct": 13,
			"pending_paths": 28,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 13, STATUS_DATA_ONLY: 28, STATUS_PENDING: 0},
		},
		{
			"category": "Karmany",
			"directory": "res://data/karmanys",
			"id_property": "karmany_id",
			"total": 28,
			"direct": 13,
			"pending_paths": 15,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 13, STATUS_DATA_ONLY: 15, STATUS_PENDING: 0},
		},
		{
			"category": "Bestias",
			"directory": "res://data/beasts",
			"id_property": "beast_id",
			"total": 24,
			"direct": 7,
			"pending_paths": 17,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 7, STATUS_DATA_ONLY: 17, STATUS_PENDING: 0},
		},
		{
			"category": "Equipo",
			"directory": "res://data/equipment",
			"id_property": "equipment_id",
			"total": 36,
			"direct": 9,
			"pending_paths": 27,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 9, STATUS_DATA_ONLY: 27, STATUS_PENDING: 0},
		},
		{
			"category": "Resonancias",
			"directory": "res://data/resonances",
			"id_property": "resonance_id",
			"total": 40,
			"direct": 13,
			"pending_paths": 27,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 13, STATUS_DATA_ONLY: 27, STATUS_PENDING: 0},
		},
		{
			"category": "Objetivos",
			"directory": "res://data/objectives",
			"id_property": "objective_id",
			"total": 12,
			"direct": 8,
			"pending_paths": 4,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 8, STATUS_DATA_ONLY: 4, STATUS_PENDING: 0},
		},
		{
			"category": "Misiones",
			"directory": "res://data/missions",
			"id_property": "mission_id",
			"total": 16,
			"direct": 9,
			"pending_paths": 7,
			"status": {STATUS_FULLY: 0, STATUS_PARTIAL: 9, STATUS_DATA_ONLY: 7, STATUS_PENDING: 0},
		},
	]


func _failure(message: String) -> Dictionary:
	push_error("FASE 44.0 AUDIT ERROR: %s" % message)
	return {"ok": false}
