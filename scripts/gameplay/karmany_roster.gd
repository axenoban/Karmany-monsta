class_name KarmanyRoster
extends RefCounted


signal karmany_added(karmany: KarmanyRuntimeState)


var _linked_karmanys: Array[KarmanyRuntimeState] = []


func clear() -> void:
	_linked_karmanys.clear()


func get_count() -> int:
	return _linked_karmanys.size()


func can_add(karmany: KarmanyRuntimeState) -> bool:
	if karmany == null:
		return false
	if not karmany.is_linked():
		return false
	if not karmany.has_owner():
		return false
	if karmany.instance_id == &"":
		return false
	return not has_instance(karmany.instance_id)


func add_linked_karmany(karmany: KarmanyRuntimeState) -> bool:
	if not can_add(karmany):
		return false

	_linked_karmanys.append(karmany)
	karmany_added.emit(karmany)
	return true


func has_instance(instance_id: StringName) -> bool:
	return get_by_instance_id(instance_id) != null


func get_by_instance_id(
	instance_id: StringName
) -> KarmanyRuntimeState:
	for karmany in _linked_karmanys:
		if karmany.instance_id == instance_id:
			return karmany
	return null


func get_all() -> Array[KarmanyRuntimeState]:
	var result: Array[KarmanyRuntimeState] = []
	for karmany in _linked_karmanys:
		result.append(karmany)
	return result
