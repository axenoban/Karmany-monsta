class_name KarmanyResonancePlayResult
extends RefCounted


enum Status {
	SUCCESS,
	INVALID_REQUEST,
	CARD_NOT_IN_HAND,
	WINDOW_NOT_ALLOWED,
	COMBAT_LIMIT_REACHED,
	EFFECT_CONTEXT_REQUIRED,
	HAND_ERROR,
	TRACKER_ERROR
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""
var card: KarmanyResonanceData = null
var power_applied: int = 0
var effect_results: Array[KarmanyEffectResult] = []
var trigger_ids: PackedStringArray = PackedStringArray()
var discarded_immediately: bool = false
var held_until_combat_end: bool = false


func is_success() -> bool:
	return status == Status.SUCCESS
