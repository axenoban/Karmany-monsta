class_name KarmanyTrainerData
extends Resource


enum AutomationStatus {
	DATA_ONLY,
	PARTIAL,
	EXECUTABLE
}

@export_group("Identity")
@export var card_id: StringName = &""
@export var trainer_id: StringName = &""
@export var display_name: String = ""
@export var title: String = ""
@export var strategic_style: String = ""
@export var difficulty_label: String = ""

@export_group("Rules v0.74")
@export_multiline var passive_text: String = ""
@export_multiline var active_text: String = ""
@export_multiline var setup_bonus_text: String = ""
@export_multiline var balance_text: String = ""
@export var passive_id: StringName = &""
@export var active_id: StringName = &""
@export var setup_bonus_id: StringName = &""

@export_group("Digital Coverage")
@export var automation_status: AutomationStatus = AutomationStatus.DATA_ONLY


func is_valid_definition() -> bool:
	return (
		card_id != &""
		and trainer_id != &""
		and not display_name.is_empty()
		and not title.is_empty()
		and not strategic_style.is_empty()
		and not passive_text.is_empty()
		and not active_text.is_empty()
		and not setup_bonus_text.is_empty()
		and passive_id != &""
		and active_id != &""
		and setup_bonus_id != &""
	)
