class_name KarmanyBookProgressResult
extends RefCounted


enum Status {
	SUCCESS,
	INVALID_REQUEST,
	NOT_ACTIVE_PLAYER,
	NO_ACTIONS,
	MAX_LEVEL,
	INSUFFICIENT_RESOURCES
}

var status: Status = Status.INVALID_REQUEST
var message: String = ""
var previous_level: int = 0
var new_level: int = 0
var paid_cost: Dictionary = {}
var action_consumed: bool = false
var milestone_award: KarmanyLegacyPointsAwardResult = null


func is_success() -> bool:
	return status == Status.SUCCESS
