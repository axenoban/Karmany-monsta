class_name KarmanyEncounterState
extends RefCounted


enum Status {
	AVAILABLE,
	PENDING_COMBAT,
	LINKED,
	EXPIRED
}


var encounter_id: StringName = &""
var karmany_state: KarmanyRuntimeState = null
var source_coord: Vector2i = Vector2i.ZERO
var source_rank: int = KarmanyData.Rank.N1
var revealed_by_player_id: StringName = &""
var pending_player_id: StringName = &""
var status: Status = Status.AVAILABLE
var owner_turn_ends_until_expire: int = 2


func configure(
	karmany_data: KarmanyData,
	p_encounter_id: StringName,
	p_source_coord: Vector2i,
	p_source_rank: int,
	p_revealed_by_player_id: StringName
) -> bool:
	if karmany_data == null:
		return false
	if not karmany_data.is_valid_definition():
		return false
	if p_encounter_id == &"":
		return false
	if p_revealed_by_player_id == &"":
		return false

	var runtime := KarmanyRuntimeState.new()
	if not runtime.configure(karmany_data, p_encounter_id):
		return false

	encounter_id = p_encounter_id
	karmany_state = runtime
	source_coord = p_source_coord
	source_rank = p_source_rank
	revealed_by_player_id = p_revealed_by_player_id
	pending_player_id = &""
	status = Status.AVAILABLE
	owner_turn_ends_until_expire = 2
	return true


func get_karmany_data() -> KarmanyData:
	if karmany_state == null:
		return null
	return karmany_state.karmany_data


func is_available() -> bool:
	return status == Status.AVAILABLE


func is_visible() -> bool:
	return (
		status == Status.AVAILABLE
		or status == Status.PENDING_COMBAT
	)


func mark_pending_combat(player_id: StringName) -> bool:
	if not is_available():
		return false
	if player_id == &"":
		return false
	pending_player_id = player_id
	status = Status.PENDING_COMBAT
	return true


func reset_after_failed_combat() -> bool:
	if status != Status.PENDING_COMBAT:
		return false
	pending_player_id = &""
	status = Status.AVAILABLE
	return true


func mark_linked() -> bool:
	if status != Status.AVAILABLE and status != Status.PENDING_COMBAT:
		return false
	pending_player_id = &""
	status = Status.LINKED
	return true


func expire() -> bool:
	if status != Status.AVAILABLE:
		return false
	status = Status.EXPIRED
	return true


func handle_revealer_turn_end(player_id: StringName) -> bool:
	if player_id != revealed_by_player_id:
		return false
	if status != Status.AVAILABLE:
		return false

	owner_turn_ends_until_expire -= 1
	if owner_turn_ends_until_expire <= 0:
		return expire()

	return false
