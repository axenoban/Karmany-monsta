class_name KarmanyCombatPowerModifiers
extends RefCounted


var equipment_power: int = 0
var resonance_power: int = 0
var trainer_power: int = 0
var book_power: int = 0
var other_power: int = 0


func get_total() -> int:
	return (
		equipment_power
		+ resonance_power
		+ trainer_power
		+ book_power
		+ other_power
	)


func clear() -> void:
	equipment_power = 0
	resonance_power = 0
	trainer_power = 0
	book_power = 0
	other_power = 0
