class_name KarmanyAiExecutionResult
extends RefCounted


var success: bool = false
var candidate: KarmanyAiActionCandidate = null
var message: String = ""
var raw_result: Variant = null
var actions_before: int = -1
var actions_after: int = -1


func was_executed() -> bool:
	return success
