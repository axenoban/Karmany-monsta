class_name KarmanyPlayerState
extends RefCounted


var player_id: StringName = &""
var current_coord: Vector2i = Vector2i.ZERO

var mn: int = 0
var mr: int = 0
var ek: int = 0
var fa: int = 0


func setup_new_game(
	p_player_id: StringName = &"player_1",
	starting_coord: Vector2i = Vector2i.ZERO
) -> void:
	player_id = p_player_id
	current_coord = starting_coord
	mn = 2
	mr = 1
	ek = 1
	fa = 0


func set_board_position(coord: Vector2i) -> void:
	current_coord = coord


func add_resource(
	resource_type: KarmanyEffectData.ResourceType,
	amount: int
) -> void:

	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			mn += amount

		KarmanyEffectData.ResourceType.MR:
			mr += amount

		KarmanyEffectData.ResourceType.EK:
			ek += amount

		KarmanyEffectData.ResourceType.FA:
			fa += amount


func get_resource(
	resource_type: KarmanyEffectData.ResourceType
) -> int:

	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			return mn

		KarmanyEffectData.ResourceType.MR:
			return mr

		KarmanyEffectData.ResourceType.EK:
			return ek

		KarmanyEffectData.ResourceType.FA:
			return fa

	return 0
