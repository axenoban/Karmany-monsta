class_name KarmanyPhase29ContentCatalog
extends RefCounted


enum CoverageState {
	EXECUTABLE,
	INTEGRATION_PENDING,
	DEFERRED
}

const CATEGORIES: Array[StringName] = [
	&"trainers", &"tiles", &"karmanys", &"beasts",
	&"equipment", &"resonances", &"objectives", &"missions"
]

const CANONICAL_COUNTS: Dictionary = {
	"trainers": 8,
	"tiles": 41,
	"karmanys": 28,
	"beasts": 24,
	"equipment": 36,
	"resonances": 40,
	"objectives": 12,
	"missions": 16
}

const BASELINE_COUNTS: Dictionary = {
	"trainers": 0,
	"tiles": 9,
	"karmanys": 5,
	"beasts": 5,
	"equipment": 6,
	"resonances": 11,
	"objectives": 4,
	"missions": 5
}

const ADDED_PATHS: Dictionary = {
	"trainers": [
		"res://data/trainers/e_01_alderion.tres", "res://data/trainers/e_02_lyra.tres",
		"res://data/trainers/e_03_dorian.tres", "res://data/trainers/e_04_nara.tres",
		"res://data/trainers/e_05_maelis.tres", "res://data/trainers/e_06_kael.tres",
		"res://data/trainers/e_07_saira.tres", "res://data/trainers/e_08_oryn.tres"
	],
	"tiles": [
		"res://data/tiles/i_03_puesto_rocoso.tres", "res://data/tiles/n1_04_campamento_antiguo.tres",
		"res://data/tiles/n2_01_nido_de_bruma.tres", "res://data/tiles/n3_03_cueva_de_cristal_ancestral.tres"
	],
	"karmanys": [
		"res://data/karmanys/k_02_aquaris.tres", "res://data/karmanys/k_03_pyrox.tres",
		"res://data/karmanys/k_04_lumirra.tres", "res://data/karmanys/k_09_verdan.tres",
		"res://data/karmanys/k_25_zephyr.tres", "res://data/karmanys/k_26_umbrio.tres",
		"res://data/karmanys/k_27_gemmir.tres", "res://data/karmanys/k_28_vulkai.tres"
	],
	"beasts": [
		"res://data/beasts/b_07_terranuk.tres", "res://data/beasts/b_23_drakmaw.tres"
	],
	"equipment": [
		"res://data/equipment/eq_04_daga_de_resonancia.tres", "res://data/equipment/eq_19_pico_runico.tres",
		"res://data/equipment/eq_34_sello_del_santuario.tres"
	],
	"resonances": [
		"res://data/resonances/r_09_ruptura_runica.tres", "res://data/resonances/r_20_ultima_defensa.tres"
	],
	"objectives": [
		"res://data/objectives/op_e02_explorador_de_ruinas.tres", "res://data/objectives/op_d01_primer_vinculo.tres",
		"res://data/objectives/op_d03_libro_despierto.tres", "res://data/objectives/op_c01_cazador_de_bruma.tres"
	],
	"missions": [
		"res://data/missions/me_a2_mapa_de_legado.tres", "res://data/missions/me_l1_vinculos_del_camino.tres",
		"res://data/missions/me_l2_guardian_de_dos_ecos.tres", "res://data/missions/me_d2_duelo_preparado.tres"
	]
}

const ADDED_IDS: Dictionary = {
	"trainers": ["E-01", "E-02", "E-03", "E-04", "E-05", "E-06", "E-07", "E-08"],
	"tiles": ["I-03", "N1-04", "N2-01", "N3-03"],
	"karmanys": ["K-02", "K-03", "K-04", "K-09", "K-25", "K-26", "K-27", "K-28"],
	"beasts": ["B-07", "B-23"],
	"equipment": ["EQ-04", "EQ-19", "EQ-34"],
	"resonances": ["R-09", "R-20"],
	"objectives": ["OP-E02", "OP-D01", "OP-D03", "OP-C01"],
	"missions": ["ME-A2", "ME-L1", "ME-L2", "ME-D2"]
}

const EXECUTABLE_IDS: Dictionary = {
	"trainers": [],
	"tiles": ["I-03"],
	"karmanys": ["K-09"],
	"beasts": [],
	"equipment": [],
	"resonances": ["R-09", "R-20"],
	"objectives": ["OP-E02", "OP-D01", "OP-D03", "OP-C01"],
	"missions": ["ME-A2", "ME-L1", "ME-L2", "ME-D2"]
}


static func get_added_paths(category: StringName) -> Array[String]:
	var result: Array[String] = []
	var values: Array = ADDED_PATHS.get(String(category), [])
	for value in values:
		result.append(String(value))
	return result


static func get_added_ids(category: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var values: Array = ADDED_IDS.get(String(category), [])
	for value in values:
		result.append(StringName(String(value)))
	return result


static func get_executable_ids(category: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var values: Array = EXECUTABLE_IDS.get(String(category), [])
	for value in values:
		result.append(StringName(String(value)))
	return result


static func get_coverage_state(category: StringName, content_id: StringName) -> int:
	if get_executable_ids(category).has(content_id):
		return CoverageState.EXECUTABLE
	if get_added_ids(category).has(content_id):
		return CoverageState.INTEGRATION_PENDING
	return CoverageState.DEFERRED


static func get_expected_materialized_count(category: StringName) -> int:
	var key: String = String(category)
	return int(BASELINE_COUNTS.get(key, 0)) + get_added_paths(category).size()


static func get_remaining_canonical_count(category: StringName) -> int:
	var key: String = String(category)
	return maxi(int(CANONICAL_COUNTS.get(key, 0)) - get_expected_materialized_count(category), 0)


static func get_content_id(category: StringName, resource_value: Resource) -> StringName:
	if resource_value == null:
		return &""
	if category == &"trainers" and resource_value is KarmanyTrainerData:
		return (resource_value as KarmanyTrainerData).card_id
	if category == &"tiles" and resource_value is KarmanyTileData:
		return StringName((resource_value as KarmanyTileData).tile_id)
	if category == &"karmanys" and resource_value is KarmanyData:
		return (resource_value as KarmanyData).karmany_id
	if category == &"beasts" and resource_value is KarmanyBeastData:
		return (resource_value as KarmanyBeastData).beast_id
	if category == &"equipment" and resource_value is KarmanyEquipmentData:
		return (resource_value as KarmanyEquipmentData).equipment_id
	if category == &"resonances" and resource_value is KarmanyResonanceData:
		return (resource_value as KarmanyResonanceData).resonance_id
	if category == &"objectives" and resource_value is KarmanyObjectiveData:
		return (resource_value as KarmanyObjectiveData).objective_id
	if category == &"missions" and resource_value is KarmanyMissionData:
		return (resource_value as KarmanyMissionData).mission_id
	return &""


static func is_resource_valid(category: StringName, resource_value: Resource) -> bool:
	if resource_value == null:
		return false
	if category == &"trainers" and resource_value is KarmanyTrainerData:
		return (resource_value as KarmanyTrainerData).is_valid_definition()
	if category == &"tiles" and resource_value is KarmanyTileData:
		var tile: KarmanyTileData = resource_value as KarmanyTileData
		return not tile.tile_id.is_empty() and not tile.display_name.is_empty() and not tile.later_use_text.is_empty()
	if category == &"karmanys" and resource_value is KarmanyData:
		return (resource_value as KarmanyData).is_valid_definition()
	if category == &"beasts" and resource_value is KarmanyBeastData:
		return (resource_value as KarmanyBeastData).is_valid_definition()
	if category == &"equipment" and resource_value is KarmanyEquipmentData:
		return (resource_value as KarmanyEquipmentData).is_valid_definition()
	if category == &"resonances" and resource_value is KarmanyResonanceData:
		return (resource_value as KarmanyResonanceData).is_valid_definition()
	if category == &"objectives" and resource_value is KarmanyObjectiveData:
		return (resource_value as KarmanyObjectiveData).is_valid_definition()
	if category == &"missions" and resource_value is KarmanyMissionData:
		return (resource_value as KarmanyMissionData).is_valid_definition()
	return false


static func get_coverage_label(state_value: int) -> String:
	if state_value == CoverageState.EXECUTABLE:
		return "ejecutable"
	if state_value == CoverageState.INTEGRATION_PENDING:
		return "datos completos / integracion pendiente"
	return "diferido"
