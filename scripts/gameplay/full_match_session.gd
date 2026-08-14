class_name KarmanyFullMatchSession
extends KarmanyFullMatchResultSession


# F38 keeps the inherited setup implementation but resolves the round limit
# through the canonical public property exposed by KarmanyLegacyModeConfig.
# This override avoids requiring a new API in the already validated F31-F37
# baseline solely for the Alpha full-match orchestration.
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

	runtime.coordinator._move_executor = Callable(self, "_full_move_executor")
	runtime.coordinator._explore_executor = Callable(self, "_full_explore_executor")
	_initialize_turn_rule_trackers()
	_connect_runtime_observers()
	match_state = MatchState.SETUP
	configured = true
	_log("SETUP COMPLETE | seed=%d | mapa=41 | jugadores=4" % match_seed)
	setup_completed.emit(get_setup_summary())
	state_changed.emit(match_state)
	return true


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
