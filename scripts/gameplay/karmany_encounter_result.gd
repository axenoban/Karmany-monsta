class_name KarmanyEncounterResult
extends RefCounted


enum Status {
	SUCCESS,
	INVALID_REQUEST,
	NOT_ACTIVE_PLAYER,
	NO_ACTIONS,
	CALL_LIMIT_REACHED,
	INVALID_SOURCE,
	INVALID_CANDIDATES,
	ENCOUNTER_UNAVAILABLE,
	WRONG_POSITION,
	METHOD_NOT_ALLOWED,
	INSUFFICIENT_RESOURCES,
	PENDING_COMBAT,
	COMBAT_FAILED,
	ROSTER_REJECTED
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""
var encounter: KarmanyEncounterState = null
var returned_candidate: KarmanyData = null
var linked_karmany: KarmanyRuntimeState = null
var action_consumed: bool = false
var requires_instinct_roll: bool = false
var defense_target: int = -1


func is_success() -> bool:
	return status == Status.SUCCESS


func is_pending_combat() -> bool:
	return status == Status.PENDING_COMBAT
