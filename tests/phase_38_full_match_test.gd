extends Node


const TEST_SEEDS: Array[int] = [38001, 38017, 38103, 38211, 38999]
const WATCHDOG_TURNS: int = 80


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 38 FULL MATCH TEST")
	print("================================")

	var ok: bool = true
	var map_fingerprints: Dictionary = {}
	var result_signatures: Dictionary = {}
	var finished_count: int = 0

	for seed_value in TEST_SEEDS:
		var seed_ok: bool = _run_seed(seed_value, map_fingerprints, result_signatures)
		ok = seed_ok and ok
		if seed_ok:
			finished_count += 1

	if map_fingerprints.size() < 2:
		ok = _fail("Las 5 seeds no produjeron variacion de mapa.") and ok
	if finished_count != TEST_SEEDS.size():
		ok = _fail("No todas las partidas llegaron a FINISHED.") and ok

	print("")
	print("================================")
	if ok:
		print("FASE 38 OK - 5 partidas 4P completaron setup -> juego -> FINISHED -> resultado sin deadlock.")
	else:
		push_error("FASE 38 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _run_seed(
	seed_value: int,
	map_fingerprints: Dictionary,
	result_signatures: Dictionary
) -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		return _fail("Seed %d: runtime F37 no pudo configurarse." % seed_value)

	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		return _fail("Seed %d: setup F38 fallo: %s" % [seed_value, session.last_error])

	if runtime.board_state.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("Seed %d: mapa no tiene 41 posiciones." % seed_value)
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		return _fail("Seed %d: layout canonico no esta conectado." % seed_value)
	if runtime.local_session.get_player_count() != 4:
		return _fail("Seed %d: no hay 4 participantes." % seed_value)
	if runtime.local_session.legacy_mode_config.standard_round_limit != 8:
		return _fail("Seed %d: MAP41 principal no usa 8 rondas." % seed_value)
	if session.selected_public_objectives.size() != 4:
		return _fail("Seed %d: setup no selecciono 4 Objetivos Publicos." % seed_value)

	var families: Dictionary = {}
	for objective in session.selected_public_objectives:
		if objective == null:
			return _fail("Seed %d: Objetivo nulo." % seed_value)
		families[int(objective.family)] = true
	if families.size() != 4:
		return _fail("Seed %d: falta una familia de Objetivo en mapa 41." % seed_value)

	var trainer_ids: Dictionary = {}
	var initial_ids: Dictionary = {}
	for player in runtime.local_session.players:
		if player == null:
			return _fail("Seed %d: PlayerState nulo." % seed_value)
		if player.mn != 2 or player.mr != 1 or player.ek != 1 or player.fa != 0:
			return _fail("Seed %d: recursos iniciales incorrectos para %s." % [seed_value, player.player_id])
		var trainer: KarmanyTrainerData = session.trainer_by_player.get(player.player_id, null) as KarmanyTrainerData
		if trainer == null:
			return _fail("Seed %d: setup sin Entrenador para %s." % [seed_value, player.player_id])
		var expected_hand: int = KarmanyResonanceDeck.INITIAL_HAND_SIZE
		if trainer.trainer_id == &"dorian" or trainer.trainer_id == &"oryn":
			expected_hand += 1
		if player.get_resonance_count() != expected_hand:
			return _fail(
				"Seed %d: mano inicial de %s no respeta bonus de %s."
				% [seed_value, player.player_id, trainer.display_name]
			)
		if not player.has_active_karmany():
			return _fail("Seed %d: %s no tiene Karmany inicial activo." % [seed_value, player.player_id])
		if player.get_linked_karmanys().size() != 1:
			return _fail("Seed %d: %s no inicia con exactamente un Karmany." % [seed_value, player.player_id])
		var starting: KarmanyData = session.starting_karmany_by_player.get(player.player_id, null) as KarmanyData
		if starting == null:
			return _fail("Seed %d: setup incompleto para %s." % [seed_value, player.player_id])
		trainer_ids[trainer.trainer_id] = true
		initial_ids[starting.karmany_id] = true
		var own_mission := runtime.get_secret_mission_for_viewer(player.player_id, player.player_id)
		if own_mission == null or own_mission.trainer_id != trainer.trainer_id:
			return _fail("Seed %d: Mision no corresponde al Entrenador de %s." % [seed_value, player.player_id])
		for rival in runtime.local_session.players:
			if rival == player:
				continue
			if runtime.get_secret_mission_for_viewer(player.player_id, rival.player_id) != null:
				return _fail("Seed %d: fuga de Mision rival %s -> %s." % [seed_value, player.player_id, rival.player_id])

	if trainer_ids.size() != 4:
		return _fail("Seed %d: Entrenadores de setup no son unicos." % seed_value)
	if initial_ids.size() != 4:
		return _fail("Seed %d: Karmany iniciales elegidos no son unicos." % seed_value)

	var cards_in_hands: int = 0
	for player in runtime.local_session.players:
		cards_in_hands += player.get_resonance_count()
	var expected_remaining_deck: int = (
		KarmanyV074CanonicalRuntimeCatalog.CANONICAL_COUNTS["resonances"]
		- cards_in_hands
		- runtime.resonance_deck.get_discard_count()
	)
	if runtime.resonance_deck.get_draw_count() != expected_remaining_deck:
		return _fail("Seed %d: mazo de Resonancias no quedo en %d tras setup." % [seed_value, expected_remaining_deck])

	var public_summary := session.get_setup_summary()
	var rows: Array = public_summary.get("players", [])
	for row_value in rows:
		if not (row_value is Dictionary):
			continue
		var row: Dictionary = row_value
		if String(row.get("player_id", "")) != String(runtime.human_player_id):
			if String(row.get("mission", "")) != "PRIVADA":
				return _fail("Seed %d: resumen publico filtra una Mision rival." % seed_value)

	map_fingerprints[runtime.content_session.get_assignment_fingerprint()] = true

	if not session.start_playing():
		return _fail("Seed %d: no pudo pasar SETUP -> PLAYING." % seed_value)
	if session.get_state_label() != "PLAYING":
		return _fail("Seed %d: estado no es PLAYING." % seed_value)
	if not session.auto_complete_match(WATCHDOG_TURNS):
		return _fail("Seed %d: %s" % [seed_value, session.last_error])
	if session.get_state_label() != "FINISHED":
		return _fail("Seed %d: partida no termino en FINISHED." % seed_value)
	if not runtime.coordinator.is_finished:
		return _fail("Seed %d: MatchCoordinator no marco final." % seed_value)
	if runtime.local_session.turn_manager.is_running:
		return _fail("Seed %d: TurnManager sigue aceptando acciones despues del final." % seed_value)

	var result := session.get_final_result()
	if int(result.get("rounds", 0)) != 8:
		return _fail("Seed %d: final principal MAP41 no ocurrio al cierre de ronda 8." % seed_value)
	if String(result.get("reason_id", "")) != String(KarmanyLegacyPointsController.REASON_STANDARD_ROUND_LIMIT):
		return _fail("Seed %d: motivo de final inesperado." % seed_value)

	var ranking: Array = result.get("ranking", [])
	if ranking.size() != 4:
		return _fail("Seed %d: ranking no contiene 4 participantes." % seed_value)
	var winners: Array = result.get("winner_ids", [])
	if winners.is_empty():
		return _fail("Seed %d: resultado final sin ganador/empate valido." % seed_value)

	var score_parts: PackedStringArray = PackedStringArray()
	for row_value in ranking:
		if not (row_value is Dictionary):
			return _fail("Seed %d: fila de ranking invalida." % seed_value)
		var row: Dictionary = row_value
		var player_id: StringName = StringName(row.get("player_id", ""))
		var score: int = int(row.get("legacy_points", -1))
		if score != runtime.local_session.legacy_points.get_total(player_id):
			return _fail("Seed %d: PL visual/resultado diverge del gameplay para %s." % [seed_value, player_id])
		score_parts.append("%s=%d" % [String(player_id), score])

	var total_pl: int = 0
	for player in runtime.local_session.players:
		total_pl += runtime.local_session.legacy_points.get_total(player.player_id)
	if total_pl <= 0:
		return _fail("Seed %d: la partida llego al final sin progreso de PL." % seed_value)

	for coord in runtime.board_state.get_coords():
		if runtime.board_state.is_revealed(coord):
			continue
		var public_snapshot := runtime.get_public_ai_snapshot(coord)
		if public_snapshot.has("tile_id") or public_snapshot.has("display_name"):
			return _fail("Seed %d: identidad oculta filtrada en %s." % [seed_value, coord])

	var actions_before: int = runtime.local_session.turn_manager.actions_remaining
	if runtime.local_session.turn_manager.spend_action_for(&"phase38_after_finished_probe", 1):
		return _fail("Seed %d: se acepto una accion despues de FINISHED." % seed_value)
	if runtime.local_session.turn_manager.actions_remaining != actions_before:
		return _fail("Seed %d: presupuesto cambio despues de FINISHED." % seed_value)

	var log_text: String = "\n".join(session.get_alpha_log())
	if not log_text.contains("MATCH START") or not log_text.contains("MATCH END") or not log_text.contains("WINNER"):
		return _fail("Seed %d: log Alpha no registra inicio/final/ganador." % seed_value)

	var stats: Dictionary = result.get("statistics", {})
	var signature := "%s|R%d|E%d|W%s" % [
		",".join(score_parts),
		int(result.get("rounds", 0)),
		int(stats.get("explorations", 0)),
		str(winners)
	]
	result_signatures[signature] = true

	print("Seed %d | ganador=%s | PL=%s | rondas=%d | exploraciones=%d | acciones=%d" % [
		seed_value,
		str(winners),
		",".join(score_parts),
		int(result.get("rounds", 0)),
		int(stats.get("explorations", 0)),
		int(stats.get("actions", 0))
	])
	return true


func _fail(message: String) -> bool:
	push_error("FASE 38 FULL MATCH TEST ERROR: %s" % message)
	return false
