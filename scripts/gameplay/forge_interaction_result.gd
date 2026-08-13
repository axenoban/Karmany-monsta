class_name KarmanyForgeInteractionResult
extends RefCounted


enum Status {
	SUCCESS,
	INVALID_REQUEST,
	NOT_ACTIVE_PLAYER,
	NO_ACTIONS,
	NOT_AT_FORGE,
	TILE_BLOCKED,
	ALREADY_USED,
	INVALID_RESOURCES,
	INSUFFICIENT_RESOURCES
}

var status: Status = Status.INVALID_REQUEST
var message: String = ""
var action_consumed: bool = false
var fa_gained: int = 0
var paid_resources: Dictionary = {}


func is_success() -> bool:
	return status == Status.SUCCESS
