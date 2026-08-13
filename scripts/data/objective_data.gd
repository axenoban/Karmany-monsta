class_name KarmanyObjectiveData
extends Resource


enum Family {
	EXPLORATION,
	DEVELOPMENT,
	CONFRONTATION,
	ANCESTRAL
}


@export_group("Identity")
@export var objective_id: StringName = &""
@export var display_name: String = ""
@export var family: Family = Family.EXPLORATION

@export_group("Rules")
@export_multiline var condition_text: String = ""
@export var reward_legacy_points: int = 0
@export var map_41_only: bool = false
@export var conditions: Array[KarmanyProgressConditionData] = []


func is_valid_definition() -> bool:
	if objective_id == &"" or display_name.is_empty():
		return false
	if condition_text.is_empty() or reward_legacy_points <= 0:
		return false
	if conditions.is_empty():
		return false
	for condition in conditions:
		if condition == null or not condition.is_valid_definition():
			return false
	return true


func get_family_label() -> String:
	match family:
		Family.EXPLORATION:
			return "Exploracion"
		Family.DEVELOPMENT:
			return "Desarrollo"
		Family.CONFRONTATION:
			return "Confrontacion"
		Family.ANCESTRAL:
			return "Ancestral"
	return "Desconocida"
