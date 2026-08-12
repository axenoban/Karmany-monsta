class_name KarmanyRoster
extends RefCounted


signal karmany_added(karmany: KarmanyRuntimeState)
signal active_karmany_changed(karmany: KarmanyRuntimeState)


var _linked_karmanys: Array[KarmanyRuntimeState] = []
var _active_instance_id: StringName = &""


func clear() -> void:
	_linked_karmanys.clear()
	_active_instance_id = &""
	active_karmany_changed.emit(null)


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

	if _active_instance_id == &"":
		_active_instance_id = karmany.instance_id
		active_karmany_changed.emit(karmany)

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


func set_active(instance_id: StringName) -> bool:
	var karmany := get_by_instance_id(instance_id)
	if karmany == null:
		return false
	if not karmany.is_linked() or not karmany.has_owner():
		return false

	_active_instance_id = instance_id
	active_karmany_changed.emit(karmany)
	return true


func get_active() -> KarmanyRuntimeState:
	if _active_instance_id == &"":
		return null
	return get_by_instance_id(_active_instance_id)


func get_active_instance_id() -> StringName:
	return _active_instance_id


func has_active() -> bool:
	return get_active() != null


func get_all() -> Array[KarmanyRuntimeState]:
	var result: Array[KarmanyRuntimeState] = []
	for karmany in _linked_karmanys:
		result.append(karmany)
	return result
