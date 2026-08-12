class_name KarmanyEffectResult
extends RefCounted


enum Status {
	APPLIED,
	NO_OP,
	INVALID_EFFECT,
	MISSING_CONTEXT,
	MISSING_HANDLER,
	FAILED
}


var status: int = Status.INVALID_EFFECT
var effect: KarmanyEffectData = null
var amount_applied: int = 0
var message: String = ""


func _init(
	p_status: int = Status.INVALID_EFFECT,
	p_effect: KarmanyEffectData = null,
	p_amount_applied: int = 0,
	p_message: String = ""
) -> void:
	status = p_status
	effect = p_effect
	amount_applied = p_amount_applied
	message = p_message


func was_applied() -> bool:
	return status == Status.APPLIED
