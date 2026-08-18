class_name KarmanyFullMatchResultSession
extends KarmanyFullMatchHumanCombatChoiceSession


func _on_integration_event(message: String) -> void:
	if match_state == MatchState.PLAYING and not message.strip_edges().is_empty():
		_log("SYSTEM ACTION | %s" % message)


func _on_action_spent(
	player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	if player == null:
		return
	var previous_value: Variant = _last_coord_by_player.get(
		player.player_id,
		player.current_coord
	)
	var previous_coord: Vector2i = player.current_coord
	if previous_value is Vector2i:
		previous_coord = previous_value
	_record_level_entry(player, previous_coord)
	_last_coord_by_player[player.player_id] = player.current_coord


func _on_round_started(round_number: int) -> void:
	if match_state == MatchState.PLAYING:
		_log("ROUND START | %d" % round_number)


func _on_turn_started(
	player: KarmanyPlayerState,
	round_number: int,
	actions_available: int
) -> void:
	if player != null:
		_reset_turn_rule_trackers(player)
	if match_state == MatchState.PLAYING and player != null:
		_log("TURN | R%d | %s | acciones=%d" % [
			round_number,
			String(player.player_id),
			actions_available
		])


func _on_turn_ended(
	player: KarmanyPlayerState,
	round_number: int
) -> void:
	if match_state == MatchState.PLAYING and player != null:
		_log("TURN END | R%d | %s" % [round_number, String(player.player_id)])


func _on_points_awarded(
	player_id: StringName,
	points: int,
	total_after: int,
	_source_type: int,
	source_id: StringName
) -> void:
	_log("PL | %s | +%d | total=%d | %s" % [
		String(player_id),
		points,
		total_after,
		String(source_id)
	])


func _on_objective_claimed(
	player_id: StringName,
	objective_id: StringName,
	legacy_points_pending: int
) -> void:
	_log("OBJETIVO | %s | %s | %d PL pendientes" % [
		String(player_id),
		String(objective_id),
		legacy_points_pending
	])


func _on_mission_completed(
	player_id: StringName,
	mission_id: StringName,
	legacy_points_pending: int
) -> void:
	completed_mission_players[player_id] = true
	_log("MISION | %s | %s | %d PL pendientes" % [
		String(player_id),
		String(mission_id),
		legacy_points_pending
	])


func _on_match_finished(
	_evaluation: KarmanyLegacyMatchEvaluation
) -> void:
	# MatchCoordinator determino la condicion reglamentaria. F38 detiene el
	# TurnManager en la misma transicion para impedir una ronda fantasma.
	if runtime != null and runtime.local_session != null:
		var manager := runtime.local_session.turn_manager
		if manager != null and manager.is_running:
			manager.stop_match()
	_finalize_from_coordinator()


func _finalize_from_coordinator() -> void:
	if match_state == MatchState.FINISHED:
		return
	if runtime == null or runtime.coordinator == null or not runtime.coordinator.is_finished:
		return
	match_state = MatchState.FINISHED
	final_result = _build_ranked_result(runtime.coordinator.final_evaluation)
	_log("MATCH END | round=%d | reason=%s" % [
		int(final_result.get("rounds", 0)),
		String(final_result.get("reason_id", ""))
	])
	var winner_ids: Array = final_result.get("winner_ids", [])
	_log("WINNER | %s" % str(winner_ids))
	state_changed.emit(match_state)
	result_ready.emit(final_result.duplicate(true))


func _build_ranked_result(
	evaluation: KarmanyLegacyMatchEvaluation
) -> Dictionary:
	var rows: Array[Dictionary] = []
	for player in runtime.local_session.players:
		var book := runtime.coordinator.get_book_state(player.player_id)
		var resources := player.get_resource_snapshot()
		var resource_total: int = 0
		for amount in resources.values():
			resource_total += int(amount)
		rows.append({
			"player_id": player.player_id,
			"legacy_points": runtime.local_session.legacy_points.get_total(player.player_id),
			"public_objectives": runtime.objectives_missions.get_claimed_objective_count(player.player_id),
			"mission_completed": bool(completed_mission_players.get(player.player_id, false)),
			"book_level": book.level if book != null else 1,
			"linked_karmany": player.get_linked_karmanys().size(),
			"total_resources": resource_total,
			"rank": 0
		})

	_sort_result_rows(rows)
	var current_rank: int = 0
	var previous_row: Dictionary = {}
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		if index == 0:
			current_rank = 1
		elif not _same_tiebreak_score(row, previous_row):
			current_rank = index + 1
		row["rank"] = current_rank
		rows[index] = row
		previous_row = row

	var winner_ids: Array[StringName] = []
	if not rows.is_empty():
		var top: Dictionary = rows[0]
		for row in rows:
			if int(row.get("rank", 0)) == 1 and _same_tiebreak_score(row, top):
				winner_ids.append(StringName(row.get("player_id", "")))

	return {
		"state": "FINISHED",
		"seed": match_seed,
		"rounds": evaluation.round_number if evaluation != null else runtime.local_session.turn_manager.current_round,
		"reason_id": String(evaluation.reason_id) if evaluation != null else "",
		"ranking": rows,
		"winner_ids": winner_ids,
		"shared_victory": winner_ids.size() > 1,
		"statistics": statistics.duplicate(true)
	}


func _sort_result_rows(rows: Array[Dictionary]) -> void:
	# 4P: una ordenacion simple evita depender de lambdas durante la fase Alpha.
	for outer in range(rows.size()):
		for inner in range(0, rows.size() - 1 - outer):
			if _row_should_rank_after(rows[inner], rows[inner + 1]):
				var temp: Dictionary = rows[inner]
				rows[inner] = rows[inner + 1]
				rows[inner + 1] = temp


func _row_should_rank_after(a: Dictionary, b: Dictionary) -> bool:
	var keys: PackedStringArray = PackedStringArray([
		"legacy_points",
		"public_objectives",
		"mission_completed",
		"book_level",
		"linked_karmany",
		"total_resources"
	])
	for key in keys:
		var av: int = int(a.get(key, 0))
		var bv: int = int(b.get(key, 0))
		if av == bv:
			continue
		return av < bv
	# Si todos los criterios canonicos siguen empatados, el orden alfabetico
	# solo estabiliza la presentacion; no rompe el empate reglamentario.
	return String(a.get("player_id", "")) > String(b.get("player_id", ""))


func _same_tiebreak_score(a: Dictionary, b: Dictionary) -> bool:
	return (
		int(a.get("legacy_points", 0)) == int(b.get("legacy_points", 0))
		and int(a.get("public_objectives", 0)) == int(b.get("public_objectives", 0))
		and bool(a.get("mission_completed", false)) == bool(b.get("mission_completed", false))
		and int(a.get("book_level", 0)) == int(b.get("book_level", 0))
		and int(a.get("linked_karmany", 0)) == int(b.get("linked_karmany", 0))
		and int(a.get("total_resources", 0)) == int(b.get("total_resources", 0))
	)
