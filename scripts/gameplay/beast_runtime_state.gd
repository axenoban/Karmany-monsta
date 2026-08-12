class_name KarmanyBeastRuntimeState
extends RefCounted


var instance_id: StringName = &""
var beast_data: KarmanyBeastData = null
var coord: Vector2i = Vector2i.ZERO
var defeated: bool = false


func configure(
	p_beast_data: KarmanyBeastData,
	p_instance_id: StringName,
	p_coord: Vector2i
) -> bool:
	if p_beast_data == null or not p_beast_data.is_valid_definition():
		return false
	if p_instance_id == &"":
		return false

	beast_data = p_beast_data
	instance_id = p_instance_id
	coord = p_coord
	defeated = false
	return true


func is_blocking() -> bool:
	return beast_data != null and not defeated


func mark_defeated() -> void:
	defeated = true


func restore_blocking() -> void:
	defeated = false
