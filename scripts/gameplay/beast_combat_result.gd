class_name KarmanyBeastCombatResult
extends RefCounted


enum Status {
	RESOLVED,
	INVALID_REQUEST,
	ACTION_NOT_AVAILABLE,
	ENTRY_FAILED
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""
var beast_state: KarmanyBeastRuntimeState = null
var combat_result: KarmanyCombatResult = null

var action_consumed: bool = false
var beast_removed: bool = false
var remains_blocking: bool = false
var entered_tile_after_victory: bool = false
var entry_bonus_allowed: bool = false
var retreat_required: bool = false
var attacker_exhaustion_pending: bool = false

var reward_legacy_points_pending: int = 0
var reward_effect_results: Array[KarmanyEffectResult] = []
var defeat_effect_results: Array[KarmanyEffectResult] = []
var reward_consequence_ids: PackedStringArray = PackedStringArray()
var defeat_consequence_ids: PackedStringArray = PackedStringArray()


func is_resolved() -> bool:
	return status == Status.RESOLVED and combat_result != null


func is_victory() -> bool:
	return is_resolved() and combat_result.is_victory()


func is_defeat() -> bool:
	return is_resolved() and combat_result.is_defeat()
