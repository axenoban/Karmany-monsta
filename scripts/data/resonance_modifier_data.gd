class_name KarmanyResonanceModifierData
extends Resource


@export var amount: int = 0
@export var required_context_tags: PackedStringArray = PackedStringArray()
@export var forbidden_context_tags: PackedStringArray = PackedStringArray()
@export_multiline var description: String = ""


func is_valid_definition() -> bool:
	return amount != 0


func matches(context_tags: PackedStringArray) -> bool:
	for required_tag in required_context_tags:
		if not context_tags.has(required_tag):
			return false

	for forbidden_tag in forbidden_context_tags:
		if context_tags.has(forbidden_tag):
			return false

	return true
