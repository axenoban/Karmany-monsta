class_name KarmanyBeastSpawnResult
extends RefCounted


enum Status {
	SPAWNED,
	INVALID_REQUEST,
	TILE_NOT_REVEALED,
	TILE_ALREADY_HAS_BEAST,
	DECK_EMPTY
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""
var coord: Vector2i = Vector2i.ZERO
var beast_state: KarmanyBeastRuntimeState = null
var requires_immediate_combat: bool = false


func is_spawned() -> bool:
	return status == Status.SPAWNED
