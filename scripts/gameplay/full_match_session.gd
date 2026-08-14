class_name KarmanyFullMatchSession
extends KarmanyFullMatchResultSession


const GENERIC_COMBAT_RESONANCE_EXCLUSIONS = [
	"R-05", # Solo PvP legal.
	"R-37"  # Instinto de Caza: solo combate contra Bestia.
]

var universal_tile_interactions: KarmanyUniversalTileInteractionService = null


func configure(p_runtime: KarmanyMultiAiAlphaRuntime) -> bool:
	last_error = ""
	if p_runtime == null or not p_runtime.configured:
		return _fail("Runtime F37 no configurado.")
	if p_runtime.local_session == null or p_runtime.local_session.get_player_count() != 4:
		return _fail("F38 requiere exactamente 4 participantes.")
	if p_runtime.board_state == null or p_runtime.board_state.get_cell_count() != 41:
		return _fail("F38 requiere el mapa canonico de 41 posiciones.")
	if p_runtime.coordinator == null or not p_runtime.coordinator.is_configured():
		return _fail("MatchCoordinator no esta disponible.")
	var manager := p_runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		return _fail("TurnManager no esta activo.")
	if p_runtime.local_session.legacy_mode_config.standard_round_limit != MAP41_STANDARD_ROUNDS:
		return _fail("El modo principal MAP41 debe terminar en 8 rondas segun v0.74.")
	if manager.current_round != 1 or manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _fail("El upgrade F38 solo puede ejecutarse antes de consumir acciones de Ronda 1.")

	runtime = p_runtime
	match_seed = p_runtime.match_seed
	_setup_rng.seed = _derive_seed(match_seed, 380011)
	_action_rng.seed = _derive_seed(match_seed, 380077)
	if not _auto_human_brain.configure(
		KarmanyAiProfile.ProfileType.EXPLORER,
		_derive_seed(match_seed, 380131)
	):
		return _fail("No se pudo configurar el controlador Alpha legal de P1.")
	if not _apply_complete_setup():
		return false

	universal_tile_interactions = KarmanyUniversalTileInteractionService.new()
	if not universal_tile_interactions.configure(
		runtime,
		Callable(self, "_phase39_build_tile_special_candidates"),
		Callable(self, "_execute_candidate")
	):
		return _fail("F39 no pudo configurar la fuente universal de Interactuar.")
	runtime.coordinator.set_meta(
		KarmanyUniversalTileInteractionService.META_KEY,
		universal_tile_interactions
	)

	runtime.coordinator._move_executor = Callable(self, "_full_move_executor")
	runtime.coordinator._explore_executor = Callable(self, "_full_explore_executor")
	_initialize_turn_rule_trackers()
	_connect_runtime_observers()
	match_state = MatchState.SETUP
	configured = true
	_log("SETUP COMPLETE | seed=%d | mapa=41 | jugadores=4" % match_seed)
	_log("FASE 39 | Uso posterior e Interactuar comparten una fuente de verdad.")
	setup_completed.emit(get_setup_summary())
	state_changed.emit(match_state)
	return true


func build_full_legal_actions(
	player: KarmanyPlayerState
) -> Array[KarmanyAiActionCandidate]:
	var inherited := super.build_full_legal_actions(player)
	if universal_tile_interactions == null or not universal_tile_interactions.is_configured():
		return inherited
	var result: Array[KarmanyAiActionCandidate] = []
	var tile := runtime.get_public_tile_data(player.current_coord) if player != null else null
	for candidate in inherited:
		if candidate == null:
			continue
		if _is_legacy_tile_use_duplicate(candidate, player, tile):
			continue
		result.append(candidate)
	return result


func _phase39_build_tile_special_candidates(
	player: KarmanyPlayerState
) -> Array[KarmanyAiActionCandidate]:
	var result: Array[KarmanyAiActionCandidate] = []
	if player == null or runtime == null:
		return result
	var tile := runtime.get_public_tile_data(player.current_coord)
	if tile == null or not tile.has_universal_interaction_definition():
		return result

	if tile.interaction_profile_id in [
		KarmanyUniversalTileInteractionService.PROFILE_CAMP_BASIC,
		KarmanyUniversalTileInteractionService.PROFILE_CRYSTAL_PASS,
		KarmanyUniversalTileInteractionService.PROFILE_FORGE
	]:
		_append_craft_candidate(result, player)
	if tile.interaction_profile_id == KarmanyUniversalTileInteractionService.PROFILE_FORGE:
		_append_forge_candidate(result, player)
		var book_candidate := KarmanyAiLegalActionGenerator.build_book_upgrade_candidate(
			runtime.coordinator,
			player
		)
		if book_candidate != null:
			result.append(book_candidate)
	if tile.interaction_profile_id in [
		KarmanyUniversalTileInteractionService.PROFILE_BEAST_MEDIUM,
		KarmanyUniversalTileInteractionService.PROFILE_CRYSTAL_CAVE
	]:
		var beast_candidates: Array[KarmanyAiActionCandidate] = []
		_append_beast_candidate(beast_candidates, player)
		for candidate in beast_candidates:
			if (
				candidate != null
				and candidate.target_coord == player.current_coord
				and bool(candidate.payload.get("spawn_if_missing", false))
			):
				result.append(candidate)
	if tile.interaction_profile_id == KarmanyUniversalTileInteractionService.PROFILE_AETERNA:
		_append_aeterna_candidate(result, player)
	return result


func _is_legacy_tile_use_duplicate(
	candidate: KarmanyAiActionCandidate,
	player: KarmanyPlayerState,
	tile: KarmanyTileData
) -> bool:
	if candidate == null or player == null or tile == null:
		return false
	var profile_id: StringName = tile.interaction_profile_id
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT:
		return profile_id in [
			KarmanyUniversalTileInteractionService.PROFILE_CAMP_BASIC,
			KarmanyUniversalTileInteractionService.PROFILE_CRYSTAL_PASS,
			KarmanyUniversalTileInteractionService.PROFILE_FORGE
		]
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.FORGE:
		return profile_id == KarmanyUniversalTileInteractionService.PROFILE_FORGE
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		return profile_id == KarmanyUniversalTileInteractionService.PROFILE_AETERNA
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
		return (
			profile_id in [
				KarmanyUniversalTileInteractionService.PROFILE_BEAST_MEDIUM,
				KarmanyUniversalTileInteractionService.PROFILE_CRYSTAL_CAVE
			]
			and candidate.target_coord == player.current_coord
			and bool(candidate.payload.get("spawn_if_missing", false))
		)
	return false


func start_playing() -> bool:
	if not configured or match_state != MatchState.SETUP:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		return _fail("No se puede iniciar: TurnManager detenido.")
	match_state = MatchState.PLAYING
	_log("MATCH START | seed=%d | modo=MAP41_STANDARD | rondas=%d" % [
		match_seed,
		runtime.local_session.legacy_mode_config.standard_round_limit
	])
	_log("ROUND START | %d" % manager.current_round)
	state_changed.emit(match_state)
	return true


func auto_complete_match(max_turns: int = DEFAULT_WATCHDOG_TURNS) -> bool:
	if not configured:
		return false
	if match_state == MatchState.SETUP and not start_playing():
		return false
	if match_state == MatchState.FINISHED:
		return true
	if max_turns <= 0:
		return false

	var resolved_turns: int = 0
	var previous_round: int = runtime.local_session.turn_manager.current_round
	while match_state == MatchState.PLAYING:
		var manager := runtime.local_session.turn_manager
		if manager == null or not manager.is_running:
			if runtime.coordinator.is_finished:
				_finalize_from_coordinator()
				break
			return _fail("TurnManager se detuvo antes de FINISHED.")
		if resolved_turns >= max_turns:
			_log("FULL MATCH DEADLOCK | watchdog=%d" % max_turns)
			return _fail("FULL MATCH DEADLOCK")
		var active := manager.get_active_player()
		if active == null:
			return _fail("Jugador activo inexistente.")
		if not run_automated_current_turn():
			return false
		resolved_turns += 1
		statistics["turns"] = resolved_turns
		if match_state == MatchState.PLAYING and manager.current_round != previous_round:
			if manager.current_round <= previous_round:
				return _fail("La ronda no avanzo de forma monotona.")
			previous_round = manager.current_round

	return match_state == MatchState.FINISHED


func get_setup_summary() -> Dictionary:
	var player_rows: Array[Dictionary] = []
	if runtime != null and runtime.local_session != null:
		for player in runtime.local_session.players:
			var trainer: KarmanyTrainerData = trainer_by_player.get(
				player.player_id,
				null
			) as KarmanyTrainerData
			var starting: KarmanyData = starting_karmany_by_player.get(
				player.player_id,
				null
			) as KarmanyData
			var mission: KarmanyMissionData = runtime.get_secret_mission_for_viewer(
				player.player_id,
				player.player_id
			)
			player_rows.append({
				"player_id": player.player_id,
				"trainer": trainer.display_name if trainer != null else "",
				"starting_karmany": starting.display_name if starting != null else "",
				"mission": (
					mission.display_name
					if mission != null and player.player_id == runtime.human_player_id
					else "PRIVADA"
				),
				"resonance_count": player.get_resonance_count(),
				"resources": player.get_resource_snapshot(),
				"start_coord": player.current_coord
			})
	var objective_ids: PackedStringArray = PackedStringArray()
	for objective in selected_public_objectives:
		if objective != null:
			objective_ids.append(String(objective.objective_id))
	return {
		"seed": match_seed,
		"map_cells": runtime.board_state.get_cell_count() if runtime != null else 0,
		"players": player_rows,
		"objectives": objective_ids,
		"standard_rounds": (
			runtime.local_session.legacy_mode_config.standard_round_limit
			if runtime != null and runtime.local_session != null
			else 0
		)
	}


func get_human_supported_combat_resonances() -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	if runtime == null or runtime.local_session == null:
		return result
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return result
	for card in player.get_resonance_hand():
		if card == null:
			continue
		if not KarmanyV074CanonicalRuntimeCatalog.is_resonance_automated(card.resonance_id):
			continue
		if GENERIC_COMBAT_RESONANCE_EXCLUSIONS.has(String(card.resonance_id)):
			continue
		if not card.can_use_in(KarmanyResonanceUseContext.WINDOW_COMBAT):
			continue
		result.append(card)
	return result


func execute_human_combat_with_resonance(
	resonance_id: StringName = &""
) -> bool:
	if not configured or match_state != MatchState.PLAYING:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return false
	if resonance_id != &"":
		var allowed: bool = false
		for card in get_human_supported_combat_resonances():
			if card.resonance_id == resonance_id:
				allowed = true
				break
		if not allowed:
			return false

	var candidates := build_full_legal_actions(player)
	var preferred_types: Array[int] = [
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST,
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT,
		KarmanyAiActionCandidate.ActionType.PVP,
		KarmanyAiActionCandidate.ActionType.AETERNA
	]
	for preferred_type in preferred_types:
		for candidate in candidates:
			if candidate == null or candidate.action_type != preferred_type:
				continue
			candidate.payload.erase("resonance_id")
			candidate.payload.erase("attacker_resonance_id")
			if resonance_id != &"":
				if preferred_type == KarmanyAiActionCandidate.ActionType.PVP:
					candidate.payload["attacker_resonance_id"] = resonance_id
				else:
					candidate.payload["resonance_id"] = resonance_id
			var success: bool = _execute_candidate(player, candidate)
			full_action_resolved.emit(player.player_id, candidate.debug_label, success)
			if success:
				statistics["actions"] = int(statistics.get("actions", 0)) + 1
				if manager.actions_remaining == 0 and manager.get_active_player() == player:
					_end_turn_with_hand_limit(player)
			return success
	return false


func _choose_automated_combat_resonance(
	player: KarmanyPlayerState
) -> StringName:
	if player == null:
		return &""
	var best_id: StringName = &""
	var best_power: int = -1
	for card in player.get_resonance_hand():
		if card == null:
			continue
		if not KarmanyV074CanonicalRuntimeCatalog.is_resonance_automated(card.resonance_id):
			continue
		if GENERIC_COMBAT_RESONANCE_EXCLUSIONS.has(String(card.resonance_id)):
			continue
		if not card.can_use_in(KarmanyResonanceUseContext.WINDOW_COMBAT):
			continue
		if card.printed_power > best_power:
			best_power = card.printed_power
			best_id = card.resonance_id
	return best_id


func _choose_first_game_mission(
	missions: Array[KarmanyMissionData],
	trainer_id: StringName
) -> KarmanyMissionData:
	var alternatives: Array[KarmanyMissionData] = []
	for mission in missions:
		if mission == null or mission.trainer_id != trainer_id or not mission.is_valid_definition():
			continue
		if mission.mission_id == &"ME-M1":
			mission.display_name = "Resonancia Decisiva"
			mission.condition_text = "Gana 2 combates en los que hayas jugado una Resonancia."
		elif mission.mission_id == &"ME-S1":
			mission.display_name = "Cartografia Viva"
			mission.condition_text = "Visita 5 losetas distintas e incluye al menos una N2 y una N3."
		if mission.recommended_first_game:
			return mission
		alternatives.append(mission)
	if alternatives.is_empty():
		return null
	return alternatives[_setup_rng.randi_range(0, alternatives.size() - 1)]
