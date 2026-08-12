class_name KarmanyRuntimeState
extends RefCounted


enum BondState {
	UNBOUND,
	LINKED
}

var instance_id: StringName = &""
var karmany_data: KarmanyData = null
var owner_player_id: StringName = &""
var bond_state: BondState = BondState.UNBOUND

func configure(
	p_karmany_data: KarmanyData,
	p_instance_id: StringName
) -> bool:
	if p_karmany_data == null:
		return false
	if not p_karmany_data.is_valid_definition():
		return false
	if p_instance_id == &"":
		return false

	karmany_data = p_karmany_data
	instance_id = p_instance_id
	owner_player_id = &""
	bond_state = BondState.UNBOUND
	return true

func set_owner_player_id(player_id: StringName) -> void:
	owner_player_id = player_id

func set_bond_state(value: int) -> bool:
	if value != BondState.UNBOUND and value != BondState.LINKED:
		return false
	bond_state = value
	return true

func is_linked() -> bool:
	return bond_state == BondState.LINKED

func has_owner() -> bool:
	return owner_player_id != &""
