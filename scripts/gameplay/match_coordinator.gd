class_name KarmanyMatchCoordinator
extends RefCounted


signal integration_event(message: String)
signal match_finished(evaluation: KarmanyLegacyMatchEvaluation)


const EVENT_TILE_VISITED: StringName = &"tile_visited"
const EVENT_TILE_REVEALED: StringName = &"tile_revealed"
const EVENT_ENTERED_N2_OR_HIGHER: StringName = &"entered_n2_or_higher"
const EVENT_KARMANY_LINKED: StringName = &"karmany_linked"
const EVENT_EQUIPMENT_CREATED: StringName = &"equipment_created"
const EVENT_BEAST_DEFEATED: StringName = &"beast_defeated"
const EVENT_PVP_WON: StringName = &"pvp_won"
const STATE_BOOK_LEVEL: StringName = &"book_level"

var board_state: KarmanyBoardState = null
var turn_manager: KarmanyTurnManager = null
var legacy_points: KarmanyLegacyPointsController = null
var objectives_missions: KarmanyObjectiveMissionManager = null
var resonance_deck: KarmanyResonanceDeck = null
var equipment_market: KarmanyEquipmentMarket = null

var encounter_resolver: KarmanyEncounterResolver = KarmanyEncounterResolver.new()
var resonance_usage_tracker: KarmanyResonanceUsageTracker = KarmanyResonanceUsageTracker.new()
var resonance_effect_adapter: KarmanyResonanceEffectAdapter = KarmanyResonanceEffectAdapter.new()
var effect_context: KarmanyEffectContext = KarmanyEffectContext.new()
var pvp_truce_tracker: KarmanyPvpTruceTracker = KarmanyPvpTruceTracker.new()
var aeterna_state: KarmanyAeternaState = KarmanyAeternaState.new()
var forge_controller: KarmanyForgeInteractionController = KarmanyForgeInteractionController.new()

var final_evaluation: KarmanyLegacyMatchEvaluation = null
var is_finished: bool = false

var _book_states: Dictionary = {}
var _previous_coord_by_player: Dictionary = {}
var _move_executor: Callable = Callable()
var _explore_executor: Callable = Callable()
var _retreat_executor: Callable = Callable()
var _configured: bool = false
var _combat_serial: int = 0


func configure(
	p_board_state: KarmanyBoardState,
	p_turn_manager: KarmanyTurnManager,
	p_legacy_points: KarmanyLegacyPointsController,
	p_objectives_missions: KarmanyObjectiveMissionManager,
	p_resonance_deck: KarmanyResonanceDeck,
	p_equipment_market: KarmanyEquipmentMarket,
	move_executor: Callable,
	explore_executor: Callable,
	retreat_executor: Callable
) -> bool:
	if p_board_state == null or p_turn_manager == null:
		return false
	if p_legacy_points == null or p_objectives_missions == null:
		return false
	if p_resonance_deck == null or p_equipment_market == null:
		return false
	if not move_executor.is_valid() or not explore_executor.is_valid() or not retreat_executor.is_valid():
		return false
	if not p_turn_manager.is_running or p_turn_manager.players.is_empty():
		return false

	board_state = p_board_state
	turn_manager = p_turn_manager
	legacy_points = p_legacy_points
	objectives_missions = p_objectives_missions
	resonance_deck = p_resonance_deck
	equipment_market = p_equipment_market
	_move_executor = move_executor
	_explore_executor = explore_executor
	_retreat_executor = retreat_executor

	if not encounter_resolver.configure(turn_manager):
		return false
	if not resonance_effect_adapter.setup(resonance_deck):
		return false
	if not resonance_effect_adapter.configure_context(effect_context):
		return false

	_book_states.clear()
	_previous_coord_by_player.clear()
	for player in turn_manager.players:
		var state := KarmanyBookProgressState.new()
		if not state.configure(player.player_id):
			return false
		_book_states[player.player_id] = state
		_previous_coord_by_player[player.player_id] = player.current_coord
		objectives_missions.set_progress_state(player, STATE_BOOK_LEVEL, state.level)

	if not turn_manager.round_ended.is_connected(_on_round_ended):
		turn_manager.round_ended.connect(_on_round_ended)

	is_finished = false
	final_evaluation = null
	_configured = true
	_log("Partida integrada configurada sobre los sistemas existentes.")
	return true


func is_configured() -> bool:
	return _configured


func get_book_state(player_id: StringName) -> KarmanyBookProgressState:
	return _book_states.get(player_id, null)


func get_previous_coord(player_id: StringName) -> Vector2i:
	var value: Variant = _previous_coord_by_player.get(player_id, Vector2i.ZERO)
	return value as Vector2i


func move_player(player: KarmanyPlayerState, target_coord: Vector2i) -> bool:
	if not _can_act(player):
		return false
	var origin: Vector2i = player.current_coord
	var value: Variant = _move_executor.call(player, target_coord)
	if not (value is bool) or not bool(value):
		return false
	_previous_coord_by_player[player.player_id] = origin
	_record_visit(player, target_coord)
	_consume_pending_legacy_rewards()
	_log("%s Mover %s -> %s" % [String(player.player_id), origin, target_coord])
	return true


func explore_player(player: KarmanyPlayerState, target_coord: Vector2i) -> bool:
	if not _can_act(player):
		return false
	var origin: Vector2i = player.current_coord
	var was_revealed: bool = board_state.is_revealed(target_coord)
	var value: Variant = _explore_executor.call(player, target_coord)
	if not (value is bool) or not bool(value):
		return false
	_previous_coord_by_player[player.player_id] = origin
	if not was_revealed and board_state.is_revealed(target_coord):
		var tile_data: KarmanyTileData = board_state.get_tile_data(target_coord)
		var payload: Dictionary = {"coord_key": _coord_key(target_coord)}
		if tile_data != null:
			payload["tile_id"] = tile_data.tile_id
			payload["tile_level"] = int(tile_data.level)
		objectives_missions.record_event(player, EVENT_TILE_REVEALED, payload)
		if tile_data != null and tile_data.level >= KarmanyTileData.TileLevel.N2:
			objectives_missions.record_event(player, EVENT_ENTERED_N2_OR_HIGHER, payload)
	_record_visit(player, target_coord)
	_consume_pending_legacy_rewards()
	_log("%s Explorar %s -> %s" % [String(player.player_id), origin, target_coord])
	return true


func interact_effect_option(player: KarmanyPlayerState, option_index: int = 0) -> KarmanyTileInteractionResult:
	var result := KarmanyTileInteractionResolver.interact_effect_option(
		player, board_state, turn_manager, option_index, effect_context
	)
	if result.is_success():
		_consume_pending_legacy_rewards()
		_log("%s Interactuar en %s" % [String(player.player_id), String(result.tile_id)])
	return result


func improve_book(player: KarmanyPlayerState) -> KarmanyBookProgressResult:
	var state := get_book_state(player.player_id)
	var result := KarmanyBookProgressController.improve(player, turn_manager, state, legacy_points)
	if result.is_success():
		objectives_missions.set_progress_state(player, STATE_BOOK_LEVEL, result.new_level)
		_consume_pending_legacy_rewards()
		_log("%s mejora Libro %d -> %d" % [String(player.player_id), result.previous_level, result.new_level])
	return result


func call_karmany(
	player: KarmanyPlayerState,
	candidate_cards: Array[KarmanyData],
	selected_index: int,
	compatible_rank: int
) -> KarmanyEncounterResult:
	var result := encounter_resolver.call_karmany(
		player,
		player.current_coord,
		candidate_cards,
		selected_index,
		compatible_rank
	)
	if result.is_success():
		_log("%s llama Karmany: %s" % [String(player.player_id), result.encounter.karmany_data.display_name])
	return result


func bond_visible_by_payment(player: KarmanyPlayerState) -> KarmanyEncounterResult:
	var state := get_book_state(player.player_id)
	if state == null or not state.can_hold_karmany_count(player.get_linked_karmanys().size() + 1):
		return _encounter_error(KarmanyEncounterResult.Status.ROSTER_REJECTED, "El Libro no tiene espacio para otro Karmany.")
	var result := encounter_resolver.bond_by_payment(player, player.current_coord)
	if result.is_success() and result.linked_karmany != null:
		_on_karmany_linked(player, result.linked_karmany)
	return result


func craft_from_market(
	player: KarmanyPlayerState,
	visible_index: int,
	context: KarmanyEquipmentCraftContext,
	discard_equipment_id: StringName = &""
) -> KarmanyEquipmentCraftResult:
	var result := KarmanyEquipmentCraftResolver.craft_from_market(
		player, equipment_market, visible_index, turn_manager, context, discard_equipment_id
	)
	if result.is_success() and result.equipment != null:
		var payload: Dictionary = {
			"equipment_id": String(result.equipment.equipment_id),
			"rarity": int(result.equipment.rarity)
		}
		objectives_missions.record_event(player, EVENT_EQUIPMENT_CREATED, payload)
		if result.equipment.rarity == KarmanyEquipmentData.Rarity.ADVANCED:
			legacy_points.award_milestone(player.player_id, KarmanyLegacyMilestoneCatalog.FIRST_ADVANCED_EQUIPMENT, turn_manager.current_round)
		elif result.equipment.rarity == KarmanyEquipmentData.Rarity.ANCESTRAL:
			legacy_points.award_milestone(player.player_id, KarmanyLegacyMilestoneCatalog.FIRST_ANCESTRAL_EQUIPMENT, turn_manager.current_round)
		_consume_pending_legacy_rewards()
		_log("%s crea Equipo %s" % [String(player.player_id), result.equipment.display_name])
	return result


func forge_common_to_fa(
	player: KarmanyPlayerState,
	first_resource: int,
	second_resource: int
) -> KarmanyForgeInteractionResult:
	var result := forge_controller.convert_common_to_fa(
		player, board_state, turn_manager, first_resource, second_resource
	)
	if result.is_success():
		_consume_pending_legacy_rewards()
		_log("%s usa Forja Antigua y obtiene 1 FA" % String(player.player_id))
	return result


func spawn_beast(
	coord: Vector2i,
	deck: KarmanyBeastDeck,
	requires_immediate_combat: bool = false
) -> KarmanyBeastSpawnResult:
	var result := KarmanyBeastEncounterResolver.spawn_from_deck(
		board_state, coord, deck, requires_immediate_combat
	)
	if result.is_spawned():
		_log("Bestia %s aparece en %s" % [result.beast_state.beast_data.display_name, coord])
	return result


func fight_beast(
	player: KarmanyPlayerState,
	target_coord: Vector2i,
	deck: KarmanyBeastDeck,
	context: KarmanyBeastCombatContext
) -> KarmanyBeastCombatResult:
	var active := player.get_active_karmany()
	if active == null:
		return KarmanyBeastCombatResult.new()
	var result := KarmanyBeastEncounterResolver.resolve_combat(
		player, active.karmany_data, board_state, target_coord, deck, context
	)
	if result.is_victory():
		legacy_points.award_beast_result(player.player_id, result, turn_manager.current_round)
		var payload: Dictionary = {
			"beast_id": String(result.beast_state.beast_data.beast_id),
			"beast_tier": int(result.beast_state.beast_data.tier)
		}
		objectives_missions.record_event(player, EVENT_BEAST_DEFEATED, payload)
		_consume_pending_legacy_rewards()
		_log("%s derrota Bestia %s" % [String(player.player_id), result.beast_state.beast_data.display_name])
	return result


func resolve_pvp(
	attacker: KarmanyPlayerState,
	defender: KarmanyPlayerState,
	authorization: KarmanyPvpAuthorizationContext,
	attacker_resonance_id: StringName = &"",
	defender_resonance_id: StringName = &""
) -> KarmanyPvpCombatResult:
	_combat_serial += 1
	var combat_id := StringName("phase24_pvp_%d_r%d" % [_combat_serial, turn_manager.current_round])
	var context := KarmanyPvpCombatContext.new()
	context.turn_manager = turn_manager
	context.board_state = board_state
	context.authorization = authorization
	context.truce_tracker = pvp_truce_tracker
	context.resonance_deck = resonance_deck
	context.resonance_usage_tracker = resonance_usage_tracker
	context.effect_context = effect_context
	context.combat_id = combat_id

	_play_combat_resonance(attacker, attacker_resonance_id, combat_id, context.attacker_modifiers, PackedStringArray(["combat", "pvp"]))
	_play_combat_resonance(defender, defender_resonance_id, combat_id, context.defender_modifiers, PackedStringArray(["combat", "pvp"]))

	var result := KarmanyPvpResolver.resolve(attacker, defender, context)
	if result.is_resolved():
		legacy_points.award_pvp_result(result, turn_manager.current_round)
		var winner := turn_manager.get_player_by_id(result.winner_player_id)
		if winner != null:
			objectives_missions.record_event(winner, EVENT_PVP_WON, {"opponent_id": String(result.loser_player_id)})
		if result.loser_retreat_required:
			_apply_retreat(result.loser_player_id)
		_consume_pending_legacy_rewards()
		_log("PvP resuelto: gana %s" % String(result.winner_player_id))
	return result


func resolve_sanctuary_attunement_gain_fa(player: KarmanyPlayerState) -> KarmanyAeternaResult:
	var context := _build_aeterna_context(player, 1, KarmanyCombatPowerModifiers.new(), false, 0)
	var result := KarmanyAeternaResolver.resolve_sanctuary_attunement(
		player, context, KarmanyAeternaResolver.PREPARATION_GAIN_FA
	)
	if result.is_resolved():
		_log("%s usa Sintonia del Santuario: +1 FA" % String(player.player_id))
	return result


func resolve_aeterna_combat(
	player: KarmanyPlayerState,
	resonance_id: StringName,
	instinct_roll: int,
	risk_roll: int = 0
) -> KarmanyAeternaResult:
	_combat_serial += 1
	var combat_id := StringName("phase24_aeterna_%d_r%d" % [_combat_serial, turn_manager.current_round])
	var modifiers := KarmanyCombatPowerModifiers.new()
	var played_card: KarmanyResonanceData = null
	if resonance_id != &"":
		played_card = _play_combat_resonance(
			player, resonance_id, combat_id, modifiers, PackedStringArray(["combat", "legendary", "aeterna"])
		)
	var risk_authorized: bool = played_card != null and played_card.tags.has("risk_authorization")
	var context := _build_aeterna_context(player, instinct_roll, modifiers, risk_authorized, risk_roll)
	var result := KarmanyAeternaResolver.resolve_combat(player, context)

	if played_card != null:
		var after_tags := PackedStringArray(["combat", "legendary", "aeterna"])
		if result.is_victory():
			after_tags.append("combat_won")
		elif result.is_defeat():
			after_tags.append("combat_lost")
		KarmanyResonanceResolver.resolve_effects(played_card, player, &"after_combat", after_tags, effect_context)
		KarmanyResonanceResolver.finish_combat(combat_id, resonance_usage_tracker, resonance_deck)

	if result.is_victory():
		objectives_missions.record_event(player, &"aeterna_defeated", {"karmany_id": "K-24"})
		_consume_pending_legacy_rewards()
		_log("%s derrota Aeterna Draconis" % String(player.player_id))
	elif result.is_defeat() and result.retreat_required:
		_apply_retreat(player.player_id)
	return result


func resolve_aeterna_resonance_reward(
	player: KarmanyPlayerState,
	victory_result: KarmanyAeternaResult
) -> bool:
	var context := _build_aeterna_context(player, 1, KarmanyCombatPowerModifiers.new(), false, 0)
	return KarmanyAeternaResolver.resolve_victory_resonance_reward(player, context, victory_result)


func resolve_pending_resonance_discard(
	player: KarmanyPlayerState,
	resonance_ids: Array[StringName]
) -> bool:
	return player.resonance_hand.resolve_pending_discard(resonance_ids, resonance_deck)


func end_turn() -> bool:
	if not _configured or is_finished:
		return false
	var player := turn_manager.get_active_player()
	if player == null:
		return false
	if player.resonance_hand.get_pending_discard_count() > 0:
		return false
	var additional: int = player.request_end_turn_resonance_discard()
	if additional > 0:
		return false
	if not turn_manager.end_turn():
		return false
	_consume_pending_legacy_rewards()
	return true


func _record_visit(player: KarmanyPlayerState, coord: Vector2i) -> void:
	objectives_missions.record_event(
		player,
		EVENT_TILE_VISITED,
		{"coord_key": _coord_key(coord)}
	)


func _on_karmany_linked(player: KarmanyPlayerState, runtime: KarmanyRuntimeState) -> void:
	var data: KarmanyData = runtime.karmany_data
	objectives_missions.record_event(
		player,
		EVENT_KARMANY_LINKED,
		{"karmany_id": String(data.karmany_id), "rank": int(data.rank)}
	)
	if data.rank == KarmanyData.Rank.N2:
		legacy_points.award_milestone(player.player_id, KarmanyLegacyMilestoneCatalog.FIRST_N2_LINKED, turn_manager.current_round)
	elif data.rank == KarmanyData.Rank.N3:
		legacy_points.award_milestone(player.player_id, KarmanyLegacyMilestoneCatalog.FIRST_N3_LINKED, turn_manager.current_round)
	_consume_pending_legacy_rewards()
	_log("%s vincula %s" % [String(player.player_id), data.display_name])


func _play_combat_resonance(
	player: KarmanyPlayerState,
	resonance_id: StringName,
	combat_id: StringName,
	modifiers: KarmanyCombatPowerModifiers,
	tags: PackedStringArray
) -> KarmanyResonanceData:
	if player == null or resonance_id == &"":
		return null
	var use_context := KarmanyResonanceUseContext.new()
	use_context.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	use_context.context_tags = tags
	use_context.combat_id = combat_id
	use_context.combat_modifiers = modifiers
	use_context.effect_context = effect_context
	use_context.usage_tracker = resonance_usage_tracker
	var play_result := KarmanyResonanceResolver.play_from_hand(
		player, resonance_id, resonance_deck, use_context
	)
	if not play_result.is_success():
		return null
	return play_result.card


func _build_aeterna_context(
	player: KarmanyPlayerState,
	instinct_roll: int,
	modifiers: KarmanyCombatPowerModifiers,
	risk_authorized: bool,
	risk_roll: int
) -> KarmanyAeternaContext:
	var context := KarmanyAeternaContext.new()
	context.board_state = board_state
	context.turn_manager = turn_manager
	context.legacy_points_controller = legacy_points
	context.resonance_deck = resonance_deck
	context.aeterna_state = aeterna_state
	context.map_format = KarmanyLegacyModeConfig.MapFormat.MAP_22
	var book := get_book_state(player.player_id)
	context.book_level = book.level if book != null else 1
	context.instinct_roll = instinct_roll
	context.modifiers = modifiers
	context.risk_authorized = risk_authorized
	context.risk_roll = risk_roll
	context.action_cost = 1
	return context


func _apply_retreat(player_id: StringName) -> bool:
	var player := turn_manager.get_player_by_id(player_id)
	if player == null:
		return false
	var target: Vector2i = get_previous_coord(player_id)
	var value: Variant = _retreat_executor.call(player, target)
	if value is bool and bool(value):
		_log("%s retrocede a %s" % [String(player_id), target])
		return true
	return false


func _consume_pending_legacy_rewards() -> int:
	var consumed: int = 0
	for reward in objectives_missions.get_pending_legacy_rewards(false):
		var result := legacy_points.consume_pending_reward(reward)
		if result.was_applied():
			consumed += 1
	return consumed


func _on_round_ended(round_number: int) -> void:
	_consume_pending_legacy_rewards()
	var evaluation := legacy_points.evaluate_end_of_round(round_number)
	if evaluation.should_end_match:
		is_finished = true
		final_evaluation = evaluation
		_log("Fin de partida al cierre de ronda %d. Lider: %s con %d PL." % [round_number, str(evaluation.leader_player_ids), evaluation.leading_score])
		match_finished.emit(evaluation)


func _can_act(player: KarmanyPlayerState) -> bool:
	return (
		_configured
		and not is_finished
		and player != null
		and turn_manager.is_running
		and turn_manager.get_active_player() == player
	)


func _coord_key(coord: Vector2i) -> String:
	return "%d,%d" % [coord.x, coord.y]


func _encounter_error(status_value: int, text: String) -> KarmanyEncounterResult:
	var result := KarmanyEncounterResult.new()
	result.status = status_value
	result.message = text
	return result


func _log(message: String) -> void:
	print("FASE 24: ", message)
	integration_event.emit(message)
