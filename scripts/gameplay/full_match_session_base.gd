class_name KarmanyFullMatchSessionBase
extends RefCounted


signal state_changed(state_value: int)
signal setup_completed(summary: Dictionary)
signal full_action_resolved(
	player_id: StringName,
	action_label: String,
	success: bool
)
signal alpha_log_event(message: String)
signal result_ready(result: Dictionary)


enum MatchState {
	SETUP,
	PLAYING,
	FINISHED
}


const NO_LEGAL_ACTION_BUDGET_ID: StringName = &"phase38_no_legal_action_budget"
const MAX_FAILED_ACTIONS_PER_TURN: int = 2
const DEFAULT_WATCHDOG_TURNS: int = 96
const MAP41_STANDARD_ROUNDS: int = 8

const EVENT_COMBAT_WON_WITH_RESONANCE: StringName = &"phase38_combat_won_with_resonance"
const EVENT_ENTERED_N2: StringName = &"phase38_entered_n2"
const EVENT_ENTERED_N3: StringName = &"phase38_entered_n3"


var runtime: KarmanyMultiAiAlphaRuntime = null
var match_seed: int = 0
var match_state: MatchState = MatchState.SETUP
var configured: bool = false

var trainer_by_player: Dictionary = {}
var starting_karmany_by_player: Dictionary = {}
var setup_choices_by_player: Dictionary = {}
var completed_mission_players: Dictionary = {}
var selected_public_objectives: Array[KarmanyObjectiveData] = []

var final_result: Dictionary = {}
var alpha_log: PackedStringArray = PackedStringArray()
var statistics: Dictionary = {}

var last_error: String = ""
var verbose_console_output: bool = true

var _setup_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _action_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _auto_human_brain: KarmanyAiBrain = KarmanyAiBrain.new()
var _last_coord_by_player: Dictionary = {}
var _turn_start_coord_by_player: Dictionary = {}
var _entry_bonus_coords_by_player: Dictionary = {}
var _entry_bonus_count_by_player: Dictionary = {}
var _explored_this_turn_by_player: Dictionary = {}


func get_alpha_log() -> PackedStringArray:
	return alpha_log.duplicate()


func get_final_result() -> Dictionary:
	return final_result.duplicate(true)


func get_state_label() -> String:
	match match_state:
		MatchState.SETUP:
			return "SETUP"
		MatchState.PLAYING:
			return "PLAYING"
		MatchState.FINISHED:
			return "FINISHED"
	return "?"


func has_explored_this_turn(player_id: StringName) -> bool:
	return bool(_explored_this_turn_by_player.get(player_id, false))


func get_entry_bonus_status(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> StringName:
	if player == null:
		return &"invalid"
	var start_value: Variant = _turn_start_coord_by_player.get(
		player.player_id,
		player.current_coord
	)
	if start_value is Vector2i and target_coord == start_value:
		return &"turn_start"
	if int(_entry_bonus_count_by_player.get(player.player_id, 0)) >= 2:
		return &"limit"
	var used_value: Variant = _entry_bonus_coords_by_player.get(player.player_id, {})
	if used_value is Dictionary and (used_value as Dictionary).has(target_coord):
		return &"already_used"
	var tile := runtime.get_public_tile_data(target_coord) if runtime != null else null
	if tile == null:
		return &"no_public_tile"
	if tile.entry_effects.is_empty():
		if not tile.entry_bonus_text.strip_edges().is_empty():
			return &"text_only"
		return &"no_bonus"
	return &"eligible"


func _initialize_turn_rule_trackers() -> void:
	_turn_start_coord_by_player.clear()
	_entry_bonus_coords_by_player.clear()
	_entry_bonus_count_by_player.clear()
	_explored_this_turn_by_player.clear()
	if runtime == null or runtime.local_session == null:
		return
	for player in runtime.local_session.players:
		_reset_turn_rule_trackers(player)


func _reset_turn_rule_trackers(player: KarmanyPlayerState) -> void:
	if player == null:
		return
	_turn_start_coord_by_player[player.player_id] = player.current_coord
	_entry_bonus_coords_by_player[player.player_id] = {}
	_entry_bonus_count_by_player[player.player_id] = 0
	_explored_this_turn_by_player[player.player_id] = false


func _derive_seed(base_value: int, salt: int) -> int:
	var value: int = absi(base_value)
	if value == 0:
		value = 1
	return value + salt


func _coord_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]


func _log(message: String) -> void:
	alpha_log.append(message)

	if verbose_console_output:
		print("FASE 38: ", message)

	alpha_log_event.emit(message)


func _fail(message: String) -> bool:
	last_error = message
	push_error("FASE 38 ERROR: %s" % message)
	return false
