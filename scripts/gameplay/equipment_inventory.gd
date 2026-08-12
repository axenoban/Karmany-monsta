class_name KarmanyEquipmentInventory
extends RefCounted


signal equipment_added(equipment: KarmanyEquipmentData)
signal equipment_removed(equipment: KarmanyEquipmentData)


const MAX_EQUIPMENT: int = 3


var _equipped: Array[KarmanyEquipmentData] = []


func clear() -> void:
	_equipped.clear()


func get_count() -> int:
	return _equipped.size()


func is_full() -> bool:
	return get_count() >= MAX_EQUIPMENT


func has_equipment_id(equipment_id: StringName) -> bool:
	return get_equipment_by_id(equipment_id) != null


func get_equipment_by_id(
	equipment_id: StringName
) -> KarmanyEquipmentData:
	for equipment in _equipped:
		if equipment != null and equipment.equipment_id == equipment_id:
			return equipment
	return null


func get_all() -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	for equipment in _equipped:
		result.append(equipment)
	return result


func can_add(equipment: KarmanyEquipmentData) -> bool:
	if equipment == null or not equipment.is_valid_definition():
		return false
	if has_equipment_id(equipment.equipment_id):
		return false
	return not is_full()


func add_equipment(equipment: KarmanyEquipmentData) -> bool:
	if not can_add(equipment):
		return false

	_equipped.append(equipment)
	equipment_added.emit(equipment)
	return true


func remove_equipment(
	equipment_id: StringName
) -> KarmanyEquipmentData:
	for index in range(_equipped.size()):
		var equipment: KarmanyEquipmentData = _equipped[index]
		if equipment != null and equipment.equipment_id == equipment_id:
			_equipped.remove_at(index)
			equipment_removed.emit(equipment)
			return equipment
	return null


func can_replace(
	discard_equipment_id: StringName,
	new_equipment: KarmanyEquipmentData
) -> bool:
	if new_equipment == null or not new_equipment.is_valid_definition():
		return false
	if discard_equipment_id == &"":
		return false
	if not has_equipment_id(discard_equipment_id):
		return false
	if has_equipment_id(new_equipment.equipment_id):
		return false
	return true


func replace_equipment(
	discard_equipment_id: StringName,
	new_equipment: KarmanyEquipmentData
) -> KarmanyEquipmentData:
	if not can_replace(discard_equipment_id, new_equipment):
		return null

	for index in range(_equipped.size()):
		var current: KarmanyEquipmentData = _equipped[index]
		if current.equipment_id != discard_equipment_id:
			continue

		_equipped[index] = new_equipment
		equipment_removed.emit(current)
		equipment_added.emit(new_equipment)
		return current

	return null
