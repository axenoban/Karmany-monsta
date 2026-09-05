extends Node

# Characterization of known F26 boundaries on the audited F46 runtime.
# This is NOT a passing FullMatch save/load contract. F47-A must replace the
# known-gap expectations with lossless/transactional assertions as gaps close.
const TEST_SEED: int = 470047
var _failures: Array[String] = []


func _ready() -> void:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED):
		_finish_with_setup_error("Runtime no configurado.")
		return
	var session := KarmanyFullMatchSession.new()
	session.verbose_console_output = false
	if not session.configure(runtime) or not session.start_playing():
		_finish_with_setup_error("FullMatchSession no configurada.")
		return
	var context := _build_context(runtime)
	if context == null:
		_finish_with_setup_error("Contexto F26 no configurado.")
		return

	_test_generated_content(context)
	_test_hidden_board(context)
	_test_partial_restore(context)

	if _failures.is_empty():
		print("FASE 47.1 DIAGNOSTICO OK - gaps F26 reproducidos: contenido sin ruta, nivel oculto y mutacion parcial. NO valida guardado FullMatch.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _build_context(runtime: KarmanyMultiAiAlphaRuntime) -> KarmanySaveGameContext:
	# F26 expects string keys. Passing the current integer tier keys directly
	# triggers String(int) errors before the independent defects below.
	var decks: Dictionary = {}
	for tier in runtime.beast_decks_by_tier:
		decks[str(tier)] = runtime.beast_decks_by_tier[tier]
	var context := KarmanySaveGameContext.new()
	if not context.configure(
		runtime.board_state, runtime.local_session.turn_manager,
		runtime.local_session.players, runtime.resonance_deck,
		runtime.equipment_market, runtime.local_session.legacy_points,
		runtime.objectives_missions, runtime.coordinator, decks
	):
		return null
	return context


func _test_generated_content(context: KarmanySaveGameContext) -> void:
	var snapshot := KarmanySaveGameFacade.capture(context)
	var original_count: int = context.resonance_deck.get_draw_count()
	var serialized_count: int = snapshot.get("resonance_deck", {}).get("draw", []).size()
	_expect(serialized_count < original_count, "Cambió el gap de cartas sin ruta; revisar y actualizar el contrato de migración.")
	var generated_missions: int = 0
	for row in snapshot.get("objectives_missions", {}).get("missions", []):
		if String(row.get("data", "")).is_empty():
			generated_missions += 1
	_expect(generated_missions > 0, "La fixture ya no demuestra Misiones generadas sin ruta.")
	print("F47.1 KNOWN GAP | draw=%d serialized=%d | missions_without_path=%d" % [original_count, serialized_count, generated_missions])


func _test_hidden_board(context: KarmanySaveGameContext) -> void:
	var original := context.board_state
	var snapshot := KarmanySaveGameService._capture_board(original)
	var restored := KarmanyBoardState.new()
	_expect(KarmanySaveGameService._restore_board(restored, snapshot), "Round-trip aislado de BoardState falló.")
	var lost_levels: int = 0
	for coord in original.get_coords():
		if not original.is_revealed(coord):
			if original.get_structural_level(coord) >= 0 and restored.get_structural_level(coord) == -1:
				lost_levels += 1
	_expect(lost_levels > 0, "Cambió el gap structural_level; convertir esta caracterización en assert de igualdad.")
	print("F47.1 KNOWN GAP | hidden_structural_levels_lost=%d" % lost_levels)


func _test_partial_restore(context: KarmanySaveGameContext) -> void:
	var player := context.players[0]
	var before: int = player.mn
	var snapshot := KarmanySaveGameFacade.capture(context)
	# Invalid board fails after restoring players, before resolving generated
	# missions; no expected engine exceptions or real save files are involved.
	snapshot["players"][0]["resources"][0] = before + 7
	snapshot["board"] = []
	_expect(not KarmanySaveGameFacade.restore(context, snapshot), "F26 aceptó un tablero vacío.")
	_expect(player.mn == before + 7, "Cambió el gap de mutación parcial; exigir transacción sin mutación en F47-A.")
	print("F47.1 KNOWN GAP | rejected_load_mn_before=%d after=%d" % [before, player.mn])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 47.1 DIAGNOSTICO ERROR: %s" % message)


func _finish_with_setup_error(message: String) -> void:
	push_error("FASE 47.1 DIAGNOSTICO ERROR: %s" % message)
	get_tree().quit(1)
