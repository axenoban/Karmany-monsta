class_name KarmanyHumanSetupFlow
extends RefCounted


signal setup_state_changed(state_value: int)
signal starting_candidate_selected(candidate_index: int)
signal human_setup_confirmed()
signal playing_started()


enum SetupState {
	UNCONFIGURED,
	AWAITING_STARTING_KARMANY,
	READY_TO_PLAY,
	PLAYING
}


const SETUP_SEED_SALT: int = 380011
const EXPECTED_PLAYER_COUNT: int = 4
const EXPECTED_STARTING_KARMANYS: int = 8
const HUMAN_PLAYER_ID: StringName = &"player_1"


var runtime: KarmanyMultiAiAlphaRuntime = null
var full_session: KarmanyFullMatchSession = null
var setup_state: SetupState = SetupState.UNCONFIGURED
var selected_candidate_index: int = -1
var confirmed: bool = false
var last_error: String = ""

var _preview_plan: KarmanyStartingKarmanySetupPlan = null
var _human_candidates: Array[KarmanyData] = []
var _human_trainer: KarmanyTrainerData = null


func configure(p_runtime: KarmanyMultiAiAlphaRuntime) -> bool:
	last_error = ""
	if p_runtime == null or not p_runtime.configured:
		return _fail("Runtime no configurado para setup humano F41.")
	if p_runtime.local_session == null or p_runtime.local_session.get_player_count() != EXPECTED_PLAYER_COUNT:
		return _fail("F41 requiere exactamente 4 participantes.")
	if p_runtime.human_player_id != HUMAN_PLAYER_ID:
		return _fail("F41 Alpha requiere P1 como jugador humano.")
	if p_runtime.board_state == null or p_runtime.board_state.get_cell_count() != 41:
		return _fail("F41 requiere el MAP41 canonico.")

	var manager := p_runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		return _fail("TurnManager debe llegar desde el runtime base antes de entrar a SETUP F41.")
	if manager.current_round != 1 or manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _fail("F41 solo puede tomar autoridad antes de consumir acciones de Ronda 1.")

	var trainer_resources := KarmanyPhase37AlphaContentCatalog.load_category(&"trainers")
	var trainers: Array[KarmanyTrainerData] = []
	for value in trainer_resources:
		if value is KarmanyTrainerData and (value as KarmanyTrainerData).is_valid_definition():
			trainers.append(value as KarmanyTrainerData)
	if trainers.size() != KarmanyV074CanonicalRuntimeCatalog.CANONICAL_COUNTS["trainers"]:
		return _fail("F41 no encontro los 8 Entrenadores canonicos.")

	var starting_karmanys := KarmanyPhase37AlphaContentCatalog.get_starting_karmanys()
	if starting_karmanys.size() != EXPECTED_STARTING_KARMANYS:
		return _fail("F41 no encontro los 8 Karmany iniciales canonicos.")

	var preview_rng := RandomNumberGenerator.new()
	preview_rng.seed = _derive_seed(p_runtime.match_seed, SETUP_SEED_SALT)
	var plan := KarmanyStartingKarmanySetupPlan.new()
	if not plan.build(
		p_runtime.local_session.players,
		trainers,
		starting_karmanys,
		preview_rng,
		{},
		p_runtime.human_player_id
	):
		return _fail(plan.last_error)
	if plan.pending_player_id != p_runtime.human_player_id:
		return _fail("El plan F41 no quedo detenido ante la decision privada de P1.")

	var candidates: Array[KarmanyData] = plan.get_offered(p_runtime.human_player_id)
	if candidates.size() != 3 or not _are_unique_valid_starting_karmanys(candidates):
		return _fail("P1 debe recibir exactamente 3 Karmany iniciales validos y unicos.")
	var trainer: KarmanyTrainerData = plan.get_trainer(p_runtime.human_player_id)
	if trainer == null:
		return _fail("P1 no recibio Entrenador determinado por seed.")

	# Autoridad logica: durante SETUP no existe presupuesto de acciones activo.
	# El TurnManager se reiniciara en Ronda 1 solamente al comenzar PLAYING.
	if not manager.stop_match():
		return _fail("No se pudo pausar el presupuesto de turnos durante SETUP F41.")

	runtime = p_runtime
	_preview_plan = plan
	_human_candidates = candidates
	_human_trainer = trainer
	full_session = null
	selected_candidate_index = -1
	confirmed = false
	setup_state = SetupState.AWAITING_STARTING_KARMANY
	setup_state_changed.emit(setup_state)
	return true


func select_starting_candidate(candidate_index: int) -> bool:
	if setup_state != SetupState.AWAITING_STARTING_KARMANY or confirmed:
		return false
	if candidate_index < 0 or candidate_index >= _human_candidates.size():
		return false
	selected_candidate_index = candidate_index
	starting_candidate_selected.emit(candidate_index)
	return true


func confirm_starting_candidate() -> bool:
	if confirmed:
		# Confirmacion idempotente: no vuelve a crear roster, mazos ni misiones.
		return setup_state == SetupState.READY_TO_PLAY or setup_state == SetupState.PLAYING
	if setup_state != SetupState.AWAITING_STARTING_KARMANY:
		return false
	if selected_candidate_index < 0 or selected_candidate_index >= _human_candidates.size():
		return false
	if runtime == null or runtime.local_session == null:
		return _fail("Runtime perdido antes de confirmar setup.")

	var selected: KarmanyData = _human_candidates[selected_candidate_index]
	if selected == null or not selected.is_starting_karmany:
		return _fail("La opcion seleccionada dejo de ser un Karmany inicial valido.")

	var manager := runtime.local_session.turn_manager
	if manager == null or manager.is_running:
		return _fail("TurnManager debe permanecer detenido mientras P1 confirma setup.")
	if not manager.start_match():
		return _fail("No se pudo preparar Ronda 1 para aplicar el setup completo.")

	var session := KarmanyFullMatchSession.new()
	session.forced_starting_choice_by_player = {
		runtime.human_player_id: selected.karmany_id
	}
	if not session.configure(runtime):
		manager.stop_match()
		return _fail("Setup completo rechazo la eleccion humana: %s" % session.last_error)

	var human_player := runtime.local_session.get_player_by_id(runtime.human_player_id)
	var active := human_player.get_active_karmany() if human_player != null else null
	if active == null or active.data == null or active.data.karmany_id != selected.karmany_id:
		manager.stop_match()
		return _fail("La eleccion confirmada no se convirtio en Karmany activo de P1.")

	# F38 deja TurnManager listo en R1. F41 vuelve a cerrarlo hasta que el
	# jugador pulse INICIAR PARTIDA; asi SETUP no puede gastar acciones ni
	# adelantar rondas mediante APIs de gameplay existentes.
	if manager.is_running and not manager.stop_match():
		return _fail("No se pudo mantener SETUP separado de PLAYING tras confirmar.")

	full_session = session
	confirmed = true
	setup_state = SetupState.READY_TO_PLAY
	human_setup_confirmed.emit()
	setup_state_changed.emit(setup_state)
	return true


func start_playing() -> bool:
	if setup_state == SetupState.PLAYING:
		return true
	if setup_state != SetupState.READY_TO_PLAY or not confirmed or full_session == null:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or manager.is_running:
		return _fail("Ronda 1 debe iniciar una sola vez desde READY_TO_PLAY.")
	if not manager.start_match():
		return _fail("TurnManager no pudo iniciar Ronda 1.")
	if not full_session.start_playing():
		manager.stop_match()
		return _fail("FullMatchSession no pudo cambiar de SETUP a PLAYING.")
	if (
		manager.current_round != 1
		or manager.get_active_player() == null
		or manager.get_active_player().player_id != runtime.human_player_id
		or manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN
	):
		manager.stop_match()
		return _fail("Ronda 1 no inicio con P1 y 2 acciones.")
	setup_state = SetupState.PLAYING
	setup_state_changed.emit(setup_state)
	playing_started.emit()
	return true


func get_state_label() -> String:
	match setup_state:
		SetupState.UNCONFIGURED:
			return "UNCONFIGURED"
		SetupState.AWAITING_STARTING_KARMANY:
			return "SETUP"
		SetupState.READY_TO_PLAY:
			return "SETUP_READY"
		SetupState.PLAYING:
			return "PLAYING"
	return "?"


func is_setup_pending() -> bool:
	return setup_state == SetupState.AWAITING_STARTING_KARMANY


func is_ready_to_play() -> bool:
	return setup_state == SetupState.READY_TO_PLAY and confirmed and full_session != null


func get_full_session() -> KarmanyFullMatchSession:
	return full_session


func get_human_starting_candidates(
	viewer_player_id: StringName
) -> Array[KarmanyData]:
	if runtime == null or viewer_player_id != runtime.human_player_id:
		return []
	var result: Array[KarmanyData] = []
	for candidate in _human_candidates:
		if candidate != null:
			result.append(candidate)
	return result


func get_human_trainer(viewer_player_id: StringName) -> KarmanyTrainerData:
	if runtime == null or viewer_player_id != runtime.human_player_id:
		return null
	return _human_trainer


func get_private_mission_for_viewer(
	viewer_player_id: StringName,
	target_player_id: StringName
) -> KarmanyMissionData:
	if not confirmed or runtime == null:
		return null
	if viewer_player_id != target_player_id:
		return null
	return runtime.get_secret_mission_for_viewer(viewer_player_id, target_player_id)


func get_private_resonance_hand_for_viewer(
	viewer_player_id: StringName,
	target_player_id: StringName
) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	if not confirmed or runtime == null:
		return result
	if viewer_player_id != target_player_id or viewer_player_id != runtime.human_player_id:
		return result
	var player := runtime.local_session.get_player_by_id(target_player_id)
	if player == null:
		return result
	for card in player.get_resonance_hand():
		if card != null:
			result.append(card)
	return result


func get_public_objectives() -> Array[KarmanyObjectiveData]:
	if not confirmed or runtime == null or runtime.objectives_missions == null:
		return []
	return runtime.objectives_missions.get_public_objectives()


func get_public_setup_snapshot() -> Dictionary:
	var rows: Array[Dictionary] = []
	if runtime != null and runtime.local_session != null:
		for player in runtime.local_session.players:
			var trainer: KarmanyTrainerData = null
			var starting: KarmanyData = null
			if full_session != null:
				trainer = full_session.trainer_by_player.get(player.player_id, null) as KarmanyTrainerData
				starting = full_session.starting_karmany_by_player.get(player.player_id, null) as KarmanyData
			else:
				trainer = _preview_plan.get_trainer(player.player_id) if _preview_plan != null else null
			rows.append({
				"player_id": player.player_id,
				"trainer": trainer.display_name if trainer != null else "",
				"starting_karmany": starting.display_name if starting != null else "PENDIENTE"
			})
	return {
		"state": get_state_label(),
		"players": rows,
		"map_cells": runtime.board_state.get_cell_count() if runtime != null else 0
	}


func get_human_private_snapshot(viewer_player_id: StringName) -> Dictionary:
	if runtime == null or viewer_player_id != runtime.human_player_id:
		return {}
	var candidate_ids: PackedStringArray = PackedStringArray()
	for candidate in _human_candidates:
		if candidate != null:
			candidate_ids.append(String(candidate.karmany_id))
	var mission := get_private_mission_for_viewer(viewer_player_id, viewer_player_id)
	var resonance_ids: PackedStringArray = PackedStringArray()
	for card in get_private_resonance_hand_for_viewer(viewer_player_id, viewer_player_id):
		resonance_ids.append(String(card.resonance_id))
	return {
		"candidate_ids": candidate_ids,
		"selected_index": selected_candidate_index,
		"confirmed": confirmed,
		"trainer_id": String(_human_trainer.trainer_id) if _human_trainer != null else "",
		"mission_id": String(mission.mission_id) if mission != null else "",
		"resonance_ids": resonance_ids
	}


func get_trainer_setup_automation_note(trainer: KarmanyTrainerData) -> String:
	if trainer == null:
		return ""
	if trainer.trainer_id in [&"dorian", &"oryn", &"maelis"]:
		return "Bonificacion de setup automatizada por el runtime actual."
	return (
		"PENDIENTE ALPHA: esta bonificacion requiere mirar/reordenar un mazo. "
		+ "No se simula hasta disponer de una API privada segura."
	)


func _are_unique_valid_starting_karmanys(values: Array[KarmanyData]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if value == null or not value.is_starting_karmany or not value.is_valid_definition():
			return false
		if seen.has(value.karmany_id):
			return false
		seen[value.karmany_id] = true
	return true


func _derive_seed(base_value: int, salt: int) -> int:
	var value: int = absi(base_value)
	if value == 0:
		value = 1
	return value + salt


func _fail(message: String) -> bool:
	last_error = message
	push_error("FASE 41 ERROR: %s" % message)
	return false
