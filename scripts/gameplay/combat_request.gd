class_name KarmanyCombatRequest
extends RefCounted


enum TargetType {
	UNBOUND_KARMANY,
	BEAST,
	BOSS,
	LEGENDARY
}


var attacker_player_id: StringName = &""
var attacker_karmany: KarmanyData = null

var target_id: StringName = &""
var target_type: TargetType = TargetType.UNBOUND_KARMANY
var base_defense: int = 0

var uses_instinct: bool = true
var instinct_roll: int = 0

var modifiers: KarmanyCombatPowerModifiers = KarmanyCombatPowerModifiers.new()

var risk_authorized: bool = false
var risk_roll: int = 0
