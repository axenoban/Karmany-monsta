class_name KarmanyLegacyPointsAwardResult
extends RefCounted


enum Status {
	APPLIED,
	INVALID_REQUEST,
	DUPLICATE,
	ALREADY_CONSUMED,
	NO_POINTS
}


var status: Status = Status.INVALID_REQUEST
var entry: KarmanyLegacyPointsEntry = null
var total_after: int = 0
var message: String = ""


func was_applied() -> bool:
	return status == Status.APPLIED and entry != null
