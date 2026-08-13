class_name KarmanyBookProgressState
extends RefCounted


const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 3

var player_id: StringName = &""
var level: int = MIN_LEVEL


func configure(p_player_id: StringName) -> bool:
	if p_player_id == &"":
		return false
	player_id = p_player_id
	level = MIN_LEVEL
	return true


func can_improve() -> bool:
	return level < MAX_LEVEL


func get_next_level() -> int:
	if not can_improve():
		return level
	return level + 1


func set_level(value: int) -> bool:
	if value < MIN_LEVEL or value > MAX_LEVEL:
		return false
	level = value
	return true


func get_roster_capacity() -> int:
	# Libro I: activo + 1 reserva. Libro II/III: activo + 2 reservas.
	return 2 if level == 1 else 3


func can_hold_karmany_count(count: int) -> bool:
	return count >= 0 and count <= get_roster_capacity()
