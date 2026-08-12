class_name KarmanyCombatResult
extends RefCounted


enum Status {
	RESOLVED,
	INVALID_REQUEST
}

enum Outcome {
	NONE,
	VICTORY,
	DEFEAT
}


var status: Status = Status.INVALID_REQUEST
var outcome: Outcome = Outcome.NONE
var message: String = ""

var attacker_player_id: StringName = &""
var attacker_karmany_id: StringName = &""
var target_id: StringName = &""
var target_type: int = -1

var base_power: int = 0
var equipment_power: int = 0
var resonance_power: int = 0
var trainer_power: int = 0
var book_power: int = 0
var other_power: int = 0
var risk_power_adjustment: int = 0
var total_power: int = 0

var base_defense: int = 0
var instinct_roll: int = 0
var instinct_adjustment: int = 0
var effective_defense: int = 0

var risk_roll: int = 0
var pending_consequences: PackedStringArray = PackedStringArray()


func is_resolved() -> bool:
	return status == Status.RESOLVED


func is_victory() -> bool:
	return is_resolved() and outcome == Outcome.VICTORY


func is_defeat() -> bool:
	return is_resolved() and outcome == Outcome.DEFEAT
