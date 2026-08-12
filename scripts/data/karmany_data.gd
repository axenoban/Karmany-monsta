class_name KarmanyData
extends Resource


enum Rank {
	INITIAL,
	N1,
	N2,
	N3,
	LEGENDARY
}

enum StrategicType {
	STABLE,
	WILD,
	TACTICAL,
	DEFENSIVE,
	GATHERER,
	ANCESTRAL,
	CONTROL,
	OTHER
}

@export_group("Identity")
@export var karmany_id: StringName = &""
@export var display_name: String = ""
@export var subtitle: String = ""

@export_group("Classification")
@export var rank: Rank = Rank.N1
@export var compatible_ranks: PackedInt32Array = PackedInt32Array()
@export var primary_type: StrategicType = StrategicType.OTHER
@export var type_tags: PackedStringArray = PackedStringArray()

@export_group("Core Stats")
@export_range(0, 99, 1) var power: int = 0
@export_range(-1, 99, 1) var encounter_defense: int = -1
@export_range(0, 99, 1) var legacy_points: int = 0

@export_group("Acquisition")
@export_multiline var acquisition_text: String = ""

@export_group("Abilities")
@export var abilities: Array[KarmanyAbilityData] = []

@export_group("Affinity / Resonance")
@export var resonance_affinity_id: StringName = &""
@export var resonance_affinity_tags: PackedStringArray = PackedStringArray()

func is_valid_definition() -> bool:
	if karmany_id == &"" or display_name.is_empty():
		return false
	if power <= 0:
		return false
	if compatible_ranks.is_empty():
		return false
	for ability in abilities:
		if ability == null or not ability.is_valid_definition():
			return false
	return true

func supports_rank(candidate_rank: int) -> bool:
	for compatible_rank in compatible_ranks:
		if compatible_rank == candidate_rank:
			return true
	return false

func get_rank_label() -> String:
	match rank:
		Rank.INITIAL:
			return "Inicial"
		Rank.N1:
			return "Nivel 1"
		Rank.N2:
			return "Nivel 2"
		Rank.N3:
			return "Nivel 3"
		Rank.LEGENDARY:
			return "Legendaria"
	return "Desconocido"

func get_primary_type_label() -> String:
	match primary_type:
		StrategicType.STABLE:
			return "Estable"
		StrategicType.WILD:
			return "Salvaje"
		StrategicType.TACTICAL:
			return "Tactico"
		StrategicType.DEFENSIVE:
			return "Defensivo"
		StrategicType.GATHERER:
			return "Recolector"
		StrategicType.ANCESTRAL:
			return "Ancestral"
		StrategicType.CONTROL:
			return "Control"
		StrategicType.OTHER:
			return "Otro"
	return "Otro"
