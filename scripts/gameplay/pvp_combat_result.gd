class_name KarmanyPvpCombatResult
extends RefCounted


enum Status {
	RESOLVED,
	INVALID_REQUEST,
	PVP_FORBIDDEN_ROUND_ONE,
	PVP_NOT_AUTHORIZED,
	OUT_OF_RANGE,
	NO_ACTIVE_KARMANY,
	TRUCE_BLOCKED,
	ACTION_NOT_AVAILABLE
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""

var attacker_player_id: StringName = &""
var defender_player_id: StringName = &""
var winner_player_id: StringName = &""
var loser_player_id: StringName = &""

var attacker_karmany_id: StringName = &""
var defender_karmany_id: StringName = &""

var attacker_power: int = 0
var defender_power: int = 0
var attacker_risk_adjustment: int = 0
var defender_risk_adjustment: int = 0

var was_tie: bool = false
var defender_won_tie: bool = false
var action_consumed: bool = false
var truce_applied: bool = false
var loser_retreat_required: bool = false

var reward_legacy_points_pending: int = 0
var resonance_cross_attacker_drawn: int = 0
var resonance_cross_defender_drawn: int = 0
var combat_resonances_discarded: int = 0

var attacker_post_effects: Array[KarmanyEffectResult] = []
var defender_post_effects: Array[KarmanyEffectResult] = []
var attacker_pending_consequences: PackedStringArray = PackedStringArray()
var defender_pending_consequences: PackedStringArray = PackedStringArray()


func is_resolved() -> bool:
	return status == Status.RESOLVED


func did_attacker_win() -> bool:
	return is_resolved() and winner_player_id == attacker_player_id


func did_defender_win() -> bool:
	return is_resolved() and winner_player_id == defender_player_id
