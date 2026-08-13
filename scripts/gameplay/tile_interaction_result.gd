class_name KarmanyTileInteractionResult
extends RefCounted


enum Status {
	SUCCESS,
	INVALID_REQUEST,
	NOT_ACTIVE_PLAYER,
	NO_ACTIONS,
	INVALID_TILE,
	TILE_BLOCKED,
	NO_LATER_USE,
	INVALID_OPTION,
	SPECIALIZED_HANDLER_REQUIRED,
	EFFECT_FAILED
}

var status: Status = Status.INVALID_REQUEST
var message: String = ""
var tile_id: StringName = &""
var option_index: int = -1
var action_consumed: bool = false
var effect_result: KarmanyEffectResult = null


func is_success() -> bool:
	return status == Status.SUCCESS
