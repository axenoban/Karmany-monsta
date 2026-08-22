class_name KarmanyAeternaInstinctRollRequest
extends KarmanyInstinctRollRequest


func _is_supported_instinct_action(value: int) -> bool:
	if value == KarmanyAiActionCandidate.ActionType.AETERNA:
		return true
	return super._is_supported_instinct_action(value)
