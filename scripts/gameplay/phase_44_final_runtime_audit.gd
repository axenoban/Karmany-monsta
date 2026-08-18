class_name KarmanyPhase44FinalRuntimeAudit
extends RefCounted


const STATUS_FULLY: StringName = &"FULLY_EXECUTABLE"
const STATUS_PARTIAL: StringName = &"PARTIAL"
const STATUS_DATA_ONLY: StringName = &"DATA_ONLY"
const STATUS_PENDING: StringName = &"PENDING"

const EXPECTED_TOTAL: int = 205

# F44.1A aprobo estas ocho losetas como PARTIAL aunque sus Resources
# permanezcan fisicamente bajo canonical_pending. F44.8 debe conservar
# esa promocion logica; no debe degradarlas a DATA_ONLY por su ruta.
const APPROVED_TILE_PENDING_PARTIAL_IDS = [
	"N1-06",
	"N1-10",
	"N1-11",
	"N1-16",
	"N1-18",
	"N2-03",
	"N2-07",
	"N2-11",
]

const FAMILY_ORDER = [
	"tiles",
	"karmany",
	"beasts",
	"equipment",
	"resonances",
	"objectives",
	"missions",
	"trainers",
]

const FAMILY_LABELS: Dictionary = {
	"tiles": "Losetas",
	"karmany": "Karmany",
	"beasts": "Bestias",
	"equipment": "Equipos",
	"resonances": "Resonancias",
	"objectives": "Objetivos",
	"missions": "Misiones",
	"trainers": "Entrenadores",
}

const EXPECTED_BY_FAMILY: Dictionary = {
	"tiles": {"total": 41, "fully": 0, "partial": 21, "data_only": 20, "pending": 0},
	"karmany": {"total": 28, "fully": 6, "partial": 22, "data_only": 0, "pending": 0},
	"beasts": {"total": 24, "fully": 2, "partial": 22, "data_only": 0, "pending": 0},
	"equipment": {"total": 36, "fully": 1, "partial": 35, "data_only": 0, "pending": 0},
	"resonances": {"total": 40, "fully": 5, "partial": 35, "data_only": 0, "pending": 0},
	"objectives": {"total": 12, "fully": 0, "partial": 8, "data_only": 4, "pending": 0},
	"missions": {"total": 16, "fully": 0, "partial": 9, "data_only": 7, "pending": 0},
	"trainers": {"total": 8, "fully": 0, "partial": 3, "data_only": 5, "pending": 0},
}

const EXPECTED_GLOBAL: Dictionary = {
	"total": 205,
	"fully": 14,
	"partial": 155,
	"data_only": 36,
	"pending": 0,
}


static func build_report() -> Dictionary:
	var families: Dictionary = {}
	families["tiles"] = _build_directory_family_report("res://data/tiles")
	families["karmany"] = _build_service_family_report(
		KarmanyAbilityRuntimeService.CONTRACTS.size(),
		KarmanyAbilityRuntimeService.get_contract_counts()
	)
	families["beasts"] = _build_service_family_report(
		KarmanyBeastAbilityRuntimeService.CONTRACTS.size(),
		KarmanyBeastAbilityRuntimeService.get_contract_counts()
	)
	families["equipment"] = _build_service_family_report(
		KarmanyEquipmentAbilityRuntimeService.CONTRACTS.size(),
		KarmanyEquipmentAbilityRuntimeService.get_contract_counts()
	)
	families["resonances"] = _build_service_family_report(
		KarmanyResonanceAbilityRuntimeService.CONTRACTS.size(),
		KarmanyResonanceAbilityRuntimeService.get_contract_counts()
	)
	families["objectives"] = _build_directory_family_report("res://data/objectives")
	families["missions"] = _build_directory_family_report("res://data/missions")
	families["trainers"] = _build_service_family_report(
		KarmanyTrainerAbilityRuntimeService.CONTRACTS.size(),
		KarmanyTrainerAbilityRuntimeService.get_contract_counts()
	)

	var global := _empty_counts()
	for family_value in FAMILY_ORDER:
		var family_id := String(family_value)
		var row_value: Variant = families.get(family_id, {})
		if not (row_value is Dictionary):
			continue
		var row: Dictionary = row_value
		for key in ["total", "fully", "partial", "data_only", "pending"]:
			global[key] = int(global.get(key, 0)) + int(row.get(key, 0))

	return {
		"families": families,
		"global": global,
	}


static func validate_report(report: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var families_value: Variant = report.get("families", {})
	if not (families_value is Dictionary):
		errors.append("El reporte no contiene un diccionario de familias.")
		return errors
	var families: Dictionary = families_value

	for family_value in FAMILY_ORDER:
		var family_id := String(family_value)
		var expected_value: Variant = EXPECTED_BY_FAMILY.get(family_id, {})
		var actual_value: Variant = families.get(family_id, {})
		if not (expected_value is Dictionary) or not (actual_value is Dictionary):
			errors.append("Falta fila final para %s." % family_id)
			continue
		var expected: Dictionary = expected_value
		var actual: Dictionary = actual_value
		_append_count_errors(family_id, actual, expected, errors)
		var status_sum: int = (
			int(actual.get("fully", 0))
			+ int(actual.get("partial", 0))
			+ int(actual.get("data_only", 0))
			+ int(actual.get("pending", 0))
		)
		if status_sum != int(actual.get("total", 0)):
			errors.append(
				"%s: estados=%d pero total=%d."
				% [family_id, status_sum, int(actual.get("total", 0))]
			)

	var global_value: Variant = report.get("global", {})
	if not (global_value is Dictionary):
		errors.append("El reporte no contiene agregado global.")
		return errors
	var global: Dictionary = global_value
	_append_count_errors("GLOBAL", global, EXPECTED_GLOBAL, errors)
	if int(global.get("total", 0)) != EXPECTED_TOTAL:
		errors.append(
			"GLOBAL: se esperaban %d componentes y se auditaron %d."
			% [EXPECTED_TOTAL, int(global.get("total", 0))]
		)
	if int(global.get("pending", 0)) != 0:
		errors.append(
			"GLOBAL: F44 no puede cerrar con %d componentes PENDING."
			% int(global.get("pending", 0))
		)
	return errors


static func format_family_line(family_id: String, row: Dictionary) -> String:
	return (
		"F44.8 FAMILY | %s | TOTAL=%d FULLY=%d PARTIAL=%d DATA_ONLY=%d PENDING=%d"
		% [
			String(FAMILY_LABELS.get(family_id, family_id)),
			int(row.get("total", 0)),
			int(row.get("fully", 0)),
			int(row.get("partial", 0)),
			int(row.get("data_only", 0)),
			int(row.get("pending", 0)),
		]
	)


static func format_global_line(row: Dictionary) -> String:
	return (
		"F44.8 TOTAL | TOTAL=%d FULLY=%d PARTIAL=%d DATA_ONLY=%d PENDING=%d"
		% [
			int(row.get("total", 0)),
			int(row.get("fully", 0)),
			int(row.get("partial", 0)),
			int(row.get("data_only", 0)),
			int(row.get("pending", 0)),
		]
	)


static func _build_service_family_report(total: int, counts: Dictionary) -> Dictionary:
	return {
		"total": total,
		"fully": int(counts.get(STATUS_FULLY, 0)),
		"partial": int(counts.get(STATUS_PARTIAL, 0)),
		"data_only": int(counts.get(STATUS_DATA_ONLY, 0)),
		"pending": int(counts.get(STATUS_PENDING, 0)),
	}


static func _build_directory_family_report(root_path: String) -> Dictionary:
	var row := _empty_counts()
	var tile_family: bool = root_path == "res://data/tiles"
	_count_tres_recursive(root_path, false, row, tile_family)
	return row


static func _count_tres_recursive(
	path: String,
	inside_canonical_pending: bool,
	row: Dictionary,
	tile_family: bool
) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	if dir.list_dir_begin() != OK:
		return
	var entry := dir.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			if dir.current_is_dir():
				var child_pending := inside_canonical_pending or entry == "canonical_pending"
				_count_tres_recursive(path.path_join(entry), child_pending, row, tile_family)
			elif entry.ends_with(".tres"):
				row["total"] = int(row.get("total", 0)) + 1
				var resource_path := path.path_join(entry)
				if inside_canonical_pending:
					if tile_family and _is_approved_tile_pending_partial(resource_path):
						row["partial"] = int(row.get("partial", 0)) + 1
					else:
						row["data_only"] = int(row.get("data_only", 0)) + 1
				else:
					# Los Resources directos de estas familias conservan cobertura
					# PARTIAL. En Losetas, F44.1A permite ademas ocho promociones
					# explicitas aun ubicadas bajo canonical_pending.
					row["partial"] = int(row.get("partial", 0)) + 1
		entry = dir.get_next()
	dir.list_dir_end()


static func _is_approved_tile_pending_partial(resource_path: String) -> bool:
	var data: Resource = load(resource_path) as Resource
	if data == null:
		return false
	var tile_id: String = String(data.get("tile_id"))
	return APPROVED_TILE_PENDING_PARTIAL_IDS.has(tile_id)


static func _append_count_errors(
	label: String,
	actual: Dictionary,
	expected: Dictionary,
	errors: PackedStringArray
) -> void:
	for key in ["total", "fully", "partial", "data_only", "pending"]:
		var actual_count := int(actual.get(key, -1))
		var expected_count := int(expected.get(key, -1))
		if actual_count != expected_count:
			errors.append(
				"%s: %s esperado=%d actual=%d."
				% [label, key, expected_count, actual_count]
			)


static func _empty_counts() -> Dictionary:
	return {
		"total": 0,
		"fully": 0,
		"partial": 0,
		"data_only": 0,
		"pending": 0,
	}
