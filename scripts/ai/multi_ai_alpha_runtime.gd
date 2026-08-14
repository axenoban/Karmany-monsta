class_name KarmanyMultiAiAlphaRuntime
extends RefCounted


const HUMAN_PROBE_PASS_ACTION_ID: StringName = &"phase34_human_probe_pass"
const CONTENT_SEED_KARMANY: int = 3701009
const CONTENT_SEED_RESONANCE: int = 3701701
const CONTENT_SEED_EQUIPMENT: int = 3701901
const CONTENT_SEED_MISSIONS: int = 3702301
const CONTENT_SEED_BEASTS: int = 3702901


var board_state: KarmanyBoardState = null
var content_session: KarmanyMap41ContentSession = null
var local_session: KarmanyLocalMultiplayerSession = null
var coordinator: KarmanyMatchCoordinator = null
var objectives_missions: KarmanyObjectiveMissionManager = null
var resonance_deck: KarmanyResonanceDeck = null
var equipment_market: KarmanyEquipmentMarket = null
var ai_match_controller: KarmanyMultiAiMatchController = null

var content_inventory: Dictionary = {}
var karmany_pools_by_rank: Dictionary = {}
var beast_decks_by_tier: Dictionary = {}
var mission_by_player: Dictionary = {}
var alpha_content_notes: PackedStringArray = PackedStringArray()

var match_seed: int = 0
var human_player_id: StringName = &""
var configured: bool = false

var _content_rng: RandomNumberGenerator = RandomNumberGenerator.new()


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

	var objective_cards: Array[KarmanyObjectiveData] = (
		KarmanyPhase37AlphaContentCatalog.get_runtime_objectives()
	)
	var mission_cards: Array[KarmanyMissionData] = (
		KarmanyPhase37AlphaContentCatalog.get_runtime_missions()
	)
	var resonance_cards: Array[KarmanyResonanceData] = (
		KarmanyPhase37AlphaContentCatalog.get_runtime_resonances()
	)
	var equipment_cards: Array[KarmanyEquipmentData] = (
		KarmanyPhase37AlphaContentCatalog.get_runtime_equipment()
	)
	var karmany_cards: Array[KarmanyData] = (
		KarmanyPhase37AlphaContentCatalog.get_runtime_karmanys()
	)
	var beast_cards: Array[KarmanyBeastData] = (
		KarmanyPhase37AlphaContentCatalog.get_runtime_beasts()
	)

	if objective_cards.is_empty():
		new_local_session.clear_registered_occupancy(p_board_state)
		return false
	if mission_cards.size() < player_count:
		new_local_session.clear_registered_occupancy(p_board_state)
		return false
	if resonance_cards.is_empty():
		new_local_session.clear_registered_occupancy(p_board_state)
		return false
	if equipment_cards.size() < KarmanyEquipmentMarket.MARKET_SIZE:
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	var new_objectives := KarmanyObjectiveMissionManager.new()
	if not new_objectives.configure(
		new_local_session.turn_manager,
		objective_cards
	):
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	var new_resonance_deck := KarmanyResonanceDeck.new()
	if not new_resonance_deck.setup(
		resonance_cards,
		true,
		_derive_content_seed(seed_value, CONTENT_SEED_RESONANCE)
	):
		new_local_session.clear_registered_occupancy(p_board_state)
		return false

	var new_equipment_market := KarmanyEquipmentMarket.new()
	if not new_equipment_market.setup(
		equipment_cards,
		true,
		_derive_content_seed(seed_value, CONTENT_SEED_EQUIPMENT)
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
	content_inventory = KarmanyPhase37AlphaContentCatalog.build_inventory()
	alpha_content_notes = PackedStringArray()
	_content_rng.seed = _derive_content_seed(seed_value, CONTENT_SEED_KARMANY)

	if not _assign_secret_missions(
		mission_cards,
		_derive_content_seed(seed_value, CONTENT_SEED_MISSIONS)
	):
		local_session.turn_manager.stop_match()
		local_session.clear_registered_occupancy(board_state)
		_reset_runtime_references()
		return false

	_build_karmany_pools(karmany_cards)
	_build_beast_decks(
		beast_cards,
		_derive_content_seed(seed_value, CONTENT_SEED_BEASTS)
	)
	_register_alpha_content_limitations(resonance_cards)

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


func get_content_inventory() -> Dictionary:
	return content_inventory.duplicate(true)


func get_alpha_content_notes() -> PackedStringArray:
	return alpha_content_notes.duplicate()


func get_secret_mission_for_viewer(
	viewer_player_id: StringName,
	target_player_id: StringName
) -> KarmanyMissionData:
	if objectives_missions == null:
		return null
	return objectives_missions.get_mission_for_viewer(
		viewer_player_id,
		target_player_id
	)


func get_karmany_pool_for_rank(rank_value: int) -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	var value: Variant = karmany_pools_by_rank.get(rank_value, [])
	if value is Array:
		for item in value:
			if item is KarmanyData:
				result.append(item as KarmanyData)
	return result


func get_beast_deck_for_tier(tier_value: int) -> KarmanyBeastDeck:
	return beast_decks_by_tier.get(tier_value, null) as KarmanyBeastDeck


func build_random_karmany_call_candidates(
	player: KarmanyPlayerState
) -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	if player == null or board_state == null:
		return result
	if not board_state.is_revealed(player.current_coord):
		return result
	var rank_value: int = board_state.get_structural_level(player.current_coord)
	var pool: Array[KarmanyData] = get_karmany_pool_for_rank(rank_value)
	if pool.size() < 2:
		return result

	var indices: Array[int] = []
	for index in range(pool.size()):
		indices.append(index)
	_shuffle_ints(indices, _content_rng)
	result.append(pool[indices[0]])
	result.append(pool[indices[1]])
	return result


func call_random_karmany(
	player: KarmanyPlayerState,
	selected_index: int = 0
) -> KarmanyEncounterResult:
	var candidates: Array[KarmanyData] = build_random_karmany_call_candidates(player)
	if candidates.size() != 2:
		return null
	var rank_value: int = board_state.get_structural_level(player.current_coord)
	return coordinator.call_karmany(
		player,
		candidates,
		selected_index,
		rank_value
	)


func spawn_beast_from_current_tile(
	player: KarmanyPlayerState,
	requires_immediate_combat: bool = true
) -> KarmanyBeastSpawnResult:
	if player == null or board_state == null or coordinator == null:
		return null
	var tile: KarmanyTileData = get_public_tile_data(player.current_coord)
	if tile == null:
		return null
	var tier_value: int = _beast_tier_from_public_tile(tile)
	if tier_value < 0:
		return null
	var deck: KarmanyBeastDeck = get_beast_deck_for_tier(tier_value)
	if deck == null:
		return null
	return coordinator.spawn_beast(
		player.current_coord,
		deck,
		requires_immediate_combat
	)


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
			KarmanyEffectResolver.apply_effect(
				effect,
				player,
				coordinator.effect_context
			)
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
			KarmanyEffectResolver.apply_effect(
				effect,
				player,
				coordinator.effect_context
			)
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


func _assign_secret_missions(
	mission_cards: Array[KarmanyMissionData],
	seed_value: int
) -> bool:
	mission_by_player.clear()
	var pool: Array[KarmanyMissionData] = []
	for mission in mission_cards:
		pool.append(mission)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_shuffle_missions(pool, rng)

	if pool.size() < local_session.players.size():
		return false
	for index in range(local_session.players.size()):
		var player: KarmanyPlayerState = local_session.players[index]
		var mission: KarmanyMissionData = pool[index]
		if not objectives_missions.assign_secret_mission(
			player,
			mission.trainer_id,
			mission
		):
			return false
		mission_by_player[player.player_id] = mission
	return true


func _build_karmany_pools(cards: Array[KarmanyData]) -> void:
	karmany_pools_by_rank.clear()
	for card in cards:
		if card == null or card.is_starting_karmany:
			continue
		if not karmany_pools_by_rank.has(card.rank):
			karmany_pools_by_rank[card.rank] = []
		var pool: Array = karmany_pools_by_rank[card.rank]
		pool.append(card)
		karmany_pools_by_rank[card.rank] = pool


func _build_beast_decks(
	cards: Array[KarmanyBeastData],
	seed_value: int
) -> void:
	beast_decks_by_tier.clear()
	var grouped: Dictionary = {}
	for card in cards:
		if card == null:
			continue
		if not grouped.has(card.tier):
			grouped[card.tier] = []
		var group: Array = grouped[card.tier]
		group.append(card)
		grouped[card.tier] = group

	for tier_value in grouped.keys():
		var typed_cards: Array[KarmanyBeastData] = []
		for item in grouped[tier_value]:
			if item is KarmanyBeastData:
				typed_cards.append(item as KarmanyBeastData)
		if typed_cards.is_empty():
			continue
		var deck := KarmanyBeastDeck.new()
		if deck.setup(
			typed_cards,
			true,
			_derive_content_seed(seed_value, int(tier_value) + 1)
		):
			beast_decks_by_tier[int(tier_value)] = deck


func _register_alpha_content_limitations(
	resonance_cards: Array[KarmanyResonanceData]
) -> void:
	var initial_cards_needed: int = (
		local_session.get_player_count()
		* KarmanyResonanceDeck.INITIAL_HAND_SIZE
	)
	if resonance_cards.size() < initial_cards_needed:
		alpha_content_notes.append(
			"Resonancias materializadas seguras insuficientes para repartir 5 a cada jugador 4P sin inventar duplicados; el mazo queda conectado pero no se fuerza mano inicial."
		)

	var tile_inventory: Dictionary = content_inventory.get("tiles", {})
	if int(tile_inventory.get("existing", 0)) < KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		alpha_content_notes.append(
			"ALPHA TILE POOL FALLBACK sigue siendo necesario para completar las 41 posiciones con el catalogo materializado."
		)


func _beast_tier_from_public_tile(tile: KarmanyTileData) -> int:
	for tag in tile.function_tags:
		var normalized: String = tag.to_lower()
		if normalized.contains("bestia basica"):
			return KarmanyBeastData.Tier.BASIC
		if normalized.contains("bestia media"):
			return KarmanyBeastData.Tier.MEDIUM
		if normalized.contains("bestia compleja"):
			return KarmanyBeastData.Tier.COMPLEX
		if normalized.contains("jefe"):
			return KarmanyBeastData.Tier.BOSS
	return -1


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


func _derive_content_seed(seed_value: int, salt: int) -> int:
	var base_value: int = absi(seed_value)
	if base_value == 0:
		base_value = 1
	return base_value + salt


func _shuffle_missions(
	items: Array[KarmanyMissionData],
	rng: RandomNumberGenerator
) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temporary: KarmanyMissionData = items[index]
		items[index] = items[swap_index]
		items[swap_index] = temporary


func _shuffle_ints(
	items: Array[int],
	rng: RandomNumberGenerator
) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temporary: int = items[index]
		items[index] = items[swap_index]
		items[swap_index] = temporary


func _reset_runtime_references() -> void:
	board_state = null
	content_session = null
	local_session = null
	coordinator = null
	objectives_missions = null
	resonance_deck = null
	equipment_market = null
	ai_match_controller = null
	content_inventory.clear()
	karmany_pools_by_rank.clear()
	beast_decks_by_tier.clear()
	mission_by_player.clear()
	alpha_content_notes = PackedStringArray()
	match_seed = 0
	human_player_id = &""
	configured = false
