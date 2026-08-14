class_name KarmanyMultiAiAlphaRuntime
extends RefCounted


const HUMAN_PROBE_PASS_ACTION_ID: StringName = &"phase34_human_probe_pass"

const OP_E01: KarmanyObjectiveData = preload(
	"res://data/objectives/op_e01_cartografo_experto.tres"
)

const R01: KarmanyResonanceData = preload(
	"res://data/resonances/r_01_impulso_luminico.tres"
)
const R02: KarmanyResonanceData = preload(
	"res://data/resonances/r_02_golpe_salvaje.tres"
)
const R03: KarmanyResonanceData = preload(
	"res://data/resonances/r_03_corte_de_bruma.tres"
)
const R04: KarmanyResonanceData = preload(
	"res://data/resonances/r_04_embate_de_raiz.tres"
)
const R05: KarmanyResonanceData = preload(
	"res://data/resonances/r_05_furia_controlada.tres"
)

const EQ01: KarmanyEquipmentData = preload(
	"res://data/equipment/eq_01_cristal_de_crecimiento.tres"
)
const EQ02: KarmanyEquipmentData = preload(
	"res://data/equipment/eq_02_guante_runico.tres"
)
const EQ03: KarmanyEquipmentData = preload(
	"res://data/equipment/eq_03_baculo_de_bruma.tres"
)
const EQ05: KarmanyEquipmentData = preload(
	"res://data/equipment/eq_05_nucleo_luminico.tres"
)


var board_state: KarmanyBoardState = null
var content_session: KarmanyMap41ContentSession = null
var local_session: KarmanyLocalMultiplayerSession = null
var coordinator: KarmanyMatchCoordinator = null
var objectives_missions: KarmanyObjectiveMissionManager = null
var resonance_deck: KarmanyResonanceDeck = null
var equipment_market: KarmanyEquipmentMarket = null
var ai_match_controller: KarmanyMultiAiMatchController = null

var match_seed: int = 0
var human_player_id: StringName = &""
var configured: bool = false


func configure_new(
	player_count: int,
	seed_value: int,
	p_human_player_id: StringName = &"player_1"
) -> bool:
	var generated_board := _build_canonical_board()
	if generated_board == null:
		return false

	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return false
	var generated_content := KarmanyMap41ContentGenerator.generate(
		seed_value,
		pools,
		true
	)
	if generated_content == null:
		return false
	if not generated_content.apply_public_state(generated_board):
		return false

	return configure_existing(
		player_count,
		seed_value,
		generated_board,
		generated_content,
		p_human_player_id
	)


func configure_existing(
	player_count: int,
	seed_value: int,
	p_board_state: KarmanyBoardState,
	p_content_session: KarmanyMap41ContentSession,
	p_human_player_id: StringName = &"player_1"
) -> bool:
	if p_board_state == null or p_content_session == null:
		return false
	if not p_content_session.configured:
		return false
	if p_content_session.match_seed != seed_value:
		return false
	if not _validate_canonical_public_board(p_board_state):
		return false

	var new_local_session := KarmanyLocalMultiplayerSession.new()
	if not new_local_session.setup_local_players(player_count):
		return false
	if new_local_session.get_player_by_id(p_human_player_id) == null:
		return false
	if not new_local_session.register_initial_occupancy(p_board_state):
		return false

	var new_objectives := KarmanyObjectiveMissionManager.new()
	var objective_cards: Array[KarmanyObjectiveData] = [OP_E01]
	if not new_objectives.configure(
		new_local_session.turn_manager,
		objective_cards
	):
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	var new_resonance_deck := KarmanyResonanceDeck.new()
	var resonance_cards: Array[KarmanyResonanceData] = [
		R01,
		R02,
		R03,
		R04,
		R05
	]
	if not new_resonance_deck.setup(
		resonance_cards,
		false,
		seed_value + 1701
	):
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	var new_equipment_market := KarmanyEquipmentMarket.new()
	var equipment_cards: Array[KarmanyEquipmentData] = [
		EQ01,
		EQ02,
		EQ03,
		EQ05
	]
	if not new_equipment_market.setup(
		equipment_cards,
		false,
		seed_value + 1901
	):
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	if not new_local_session.start_match():
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	board_state = p_board_state
	content_session = p_content_session
	local_session = new_local_session
	objectives_missions = new_objectives
	resonance_deck = new_resonance_deck
	equipment_market = new_equipment_market
	match_seed = seed_value
	human_player_id = p_human_player_id

	var new_coordinator := KarmanyMatchCoordinator.new()
	if not new_coordinator.configure(
		board_state,
		local_session.turn_manager,
		local_session.legacy_points,
		objectives_missions,
		resonance_deck,
		equipment_market,
		Callable(self, "_move_executor"),
		Callable(self, "_explore_executor"),
		Callable(self, "_retreat_executor")
	):
		local_session.turn_manager.stop_match()
		local_session.clear_registered_occupancy(board_state)
		_reset_runtime_references()
		return false
	coordinator = new_coordinator

	for player in local_session.players:
		objectives_missions.record_event(
			player,
			KarmanyMatchCoordinator.EVENT_TILE_VISITED,
			{
				"coord_key": "%d,%d" % [
					player.current_coord.x,
					player.current_coord.y
				]
			}
		)

	var new_ai_match_controller := KarmanyMultiAiMatchController.new()
	if not new_ai_match_controller.configure(
		local_session,
		coordinator,
		human_player_id,
		match_seed
	):
		local_session.turn_manager.stop_match()
		local_session.clear_registered_occupancy(board_state)
		_reset_runtime_references()
		return false

	ai_match_controller = new_ai_match_controller
	configured = true
	return true


func simulate_human_probe_turn() -> bool:
	if not configured or local_session == null or coordinator == null:
		return false
	var turn_manager := local_session.turn_manager
	if turn_manager == null or not turn_manager.is_running:
		return false
	var player := turn_manager.get_active_player()
	if player == null:
		return false
	if ai_match_controller == null or not ai_match_controller.is_human_player(player.player_id):
		return false

	while turn_manager.actions_remaining > 0:
		if not turn_manager.spend_action_for(
			HUMAN_PROBE_PASS_ACTION_ID,
			1
		):
			return false

	return coordinator.end_turn()


func run_ai_until_human() -> bool:
	if ai_match_controller == null:
		return false
	return ai_match_controller.run_ai_until_human(
		KarmanyTurnManager.MAX_PLAYERS - 1
	)


func get_public_level(coord: Vector2i) -> int:
	if board_state == null:
		return -1
	return board_state.get_structural_level(coord)


func get_public_tile_data(coord: Vector2i) -> KarmanyTileData:
	if content_session == null or board_state == null:
		return null
	return content_session.get_public_tile_data(
		board_state,
		coord
	)


func get_public_ai_snapshot(coord: Vector2i) -> Dictionary:
	var result: Dictionary = {
		"coord": coord,
		"level": get_public_level(coord),
		"revealed": false
	}
	if board_state == null or not board_state.has_coord(coord):
		return result

	result["revealed"] = board_state.is_revealed(coord)
	var public_tile := get_public_tile_data(coord)
	if public_tile != null:
		result["tile_id"] = String(public_tile.tile_id)
		result["display_name"] = public_tile.display_name
	return result


func _move_executor(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	if (
		KarmanyMovementRules.validate_move(
			board_state,
			local_session.turn_manager,
			player,
			target_coord
		)
		!= KarmanyMovementRules.MoveValidation.OK
	):
		return false

	var previous_coord: Vector2i = player.current_coord
	if not _relocate_player(player, target_coord):
		return false

	if not local_session.turn_manager.spend_action_for(
		KarmanyMovementRules.ACTION_ID_MOVE,
		1
	):
		_relocate_player(player, previous_coord)
		return false

	var target_cell := board_state.get_cell(target_coord)
	if target_cell != null and target_cell.tile_data != null:
		for effect in target_cell.tile_data.entry_effects:
			KarmanyEffectResolver.apply_effect(effect, player)
	return true


func _explore_executor(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	if (
		KarmanyExplorationRules.validate_exploration(
			board_state,
			local_session.turn_manager,
			player,
			target_coord
		)
		!= KarmanyExplorationRules.ExplorationValidation.OK
	):
		return false

	var previous_coord: Vector2i = player.current_coord
	if not content_session.reveal_into_board_state(
		board_state,
		target_coord
	):
		return false

	if not _relocate_player(player, target_coord):
		_hide_revealed_coord_for_rollback(target_coord)
		return false

	if not local_session.turn_manager.spend_action_for(
		KarmanyExplorationRules.ACTION_ID_EXPLORE,
		1
	):
		_relocate_player(player, previous_coord)
		_hide_revealed_coord_for_rollback(target_coord)
		return false

	var target_cell := board_state.get_cell(target_coord)
	if target_cell != null and target_cell.tile_data != null:
		for effect in target_cell.tile_data.on_explore_effects:
			KarmanyEffectResolver.apply_effect(effect, player)
	return true


func _retreat_executor(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	return _relocate_player(
		player,
		target_coord
	)


func _relocate_player(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	if player == null or local_session == null or board_state == null:
		return false
	if not board_state.has_coord(target_coord):
		return false

	var unit_id: StringName = local_session.get_unit_id_for_player(
		player.player_id
	)
	if unit_id == &"":
		return false

	var target_occupant: StringName = board_state.get_occupying_unit_id(
		target_coord
	)
	if target_occupant != &"" and target_occupant != unit_id:
		return false

	var origin_coord: Vector2i = player.current_coord
	var origin_has_unit: bool = (
		board_state.has_coord(origin_coord)
		and board_state.get_occupying_unit_id(origin_coord) == unit_id
	)

	if origin_has_unit and origin_coord != target_coord:
		board_state.clear_unit_occupant(origin_coord)

	if not board_state.set_unit_occupant(target_coord, unit_id):
		if origin_has_unit and origin_coord != target_coord:
			board_state.set_unit_occupant(origin_coord, unit_id)
		return false

	player.set_board_position(target_coord)
	return true


func _hide_revealed_coord_for_rollback(coord: Vector2i) -> void:
	if board_state == null:
		return
	board_state.set_tile_data(coord, null)
	board_state.set_revealed(coord, false)


func _build_canonical_board() -> KarmanyBoardState:
	var result := KarmanyBoardState.new()
	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	if levels.size() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return null

	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		var level: int = int(levels[coord])
		if not result.add_cell(
			coord,
			null,
			false,
			level
		):
			return null
	return result


func _validate_canonical_public_board(
	candidate_board: KarmanyBoardState
) -> bool:
	if candidate_board == null:
		return false
	if candidate_board.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return false
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		return false

	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		if not candidate_board.has_coord(coord):
			return false
		if candidate_board.get_structural_level(coord) != int(levels[coord]):
			return false
	return true


func _reset_runtime_references() -> void:
	board_state = null
	content_session = null
	local_session = null
	coordinator = null
	objectives_missions = null
	resonance_deck = null
	equipment_market = null
	ai_match_controller = null
	match_seed = 0
	human_player_id = &""
	configured = false
