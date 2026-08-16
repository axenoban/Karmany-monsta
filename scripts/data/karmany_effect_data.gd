class_name KarmanyEffectData
extends Resource


enum EffectType {
	NONE,
	ADD_RESOURCE,
	REMOVE_RESOURCE,
	DRAW_CARDS,
	MODIFY_STATE,
	ACTIVATE_CONDITION,
	TRIGGER_ENCOUNTER,
	DISCARD_CARDS,
	DRAW_DISCARD_CARDS
}


enum ResourceType {
	MN,
	MR,
	EK,
	FA
}


enum StateOperation {
	ADD,
	SET,
	REMOVE
}


@export_group("Effect")

@export var effect_type: EffectType = EffectType.NONE
@export var amount: int = 0
# Optional second quantity for compound effects. F44 currently uses it for
# DRAW_DISCARD_CARDS: amount = cards drawn, secondary_amount = cards discarded.
@export var secondary_amount: int = 0


@export_group("Resource")

@export var resource_type: ResourceType = ResourceType.MN


@export_group("Cards")

@export var card_source_id: StringName = &""


@export_group("State")

@export var state_id: StringName = &""
@export var state_operation: StateOperation = StateOperation.ADD


@export_group("Condition")

@export var condition_id: StringName = &""


@export_group("Encounter")

@export var encounter_id: StringName = &""


@export_group("Presentation")

@export_multiline var description: String = ""
