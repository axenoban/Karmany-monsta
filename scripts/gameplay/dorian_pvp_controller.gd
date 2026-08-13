class_name KarmanyDorianPvpController
extends RefCounted


const SOURCE_ID: StringName = &"E-03"
const FIRST_PVP_POWER_BONUS: int = 3

var _used_round_by_player: Dictionary = {}


func clear() -> void:
	_used_round_by_player.clear()


func has_used_special_pvp(
	player_id: StringName,
	round_number: int
) -> bool:
	return int(_used_round_by_player.get(player_id, -1)) == round_number


func can_initiate(
	attacker: KarmanyPlayerState,
	defender: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	legacy_points: KarmanyLegacyPointsController
) -> bool:
	if attacker == null or defender == null or attacker == defender:
		return false
	if board_state == null or turn_manager == null or legacy_points == null:
		return false
	if not turn_manager.is_running or turn_manager.current_round < 2:
		return false
	if turn_manager.get_active_player() != attacker:
		return false
	if has_used_special_pvp(attacker.player_id, turn_manager.current_round):
		return false
	if legacy_points.get_total(defender.player_id) < legacy_points.get_total(attacker.player_id):
		return false
	return (
		attacker.current_coord == defender.current_coord
		or board_state.are_existing_coords_adjacent(
			attacker.current_coord,
			defender.current_coord
		)
	)


func build_authorization(
	attacker: KarmanyPlayerState,
	defender: KarmanyPlayerState,
	board_state: KarmanyBoardState,
	turn_manager: KarmanyTurnManager,
	legacy_points: KarmanyLegacyPointsController
) -> KarmanyPvpAuthorizationContext:
	if not can_initiate(
		attacker,
		defender,
		board_state,
		turn_manager,
		legacy_points
	):
		return null
	var authorization := KarmanyPvpAuthorizationContext.new()
	authorization.source_id = SOURCE_ID
	authorization.range_mode = KarmanyPvpAuthorizationContext.RangeMode.SAME_OR_ADJACENT
	return authorization


func get_power_bonus(
	attacker: KarmanyPlayerState,
	round_number: int
) -> int:
	if attacker == null or round_number < 2:
		return 0
	if has_used_special_pvp(attacker.player_id, round_number):
		return 0
	return FIRST_PVP_POWER_BONUS


func mark_special_pvp_used(
	player_id: StringName,
	round_number: int
) -> void:
	if player_id == &"" or round_number < 2:
		return
	_used_round_by_player[player_id] = round_number
