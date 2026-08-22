extends Node


const TEST_SEED: int = 470047
const TEST_SAVE_PATH: String = "user://phase_47_save_load_continue_test.json"

var _failures: Array[String] = []


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 47 SAVE/LOAD/CONTINUE")
	print("================================")
	KarmanyFullMatchSaveFacade.delete_save(TEST_SAVE_PATH)
	_test_round_trip_and_pending_action()
	_test_disk_continue()
	_test_transactional_rollback()
	KarmanyFullMatchSaveFacade.delete_save(TEST_SAVE_PATH)
	print("")
	print("================================")
	if _failures.is_empty():
		print("FASE 47 OK - guardar/cargar/continuar restaura partida, RNG, IA y decisiones humanas pendientes sin reejecutar gameplay.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_round_trip_and_pending_action() -> void:
	var session := _new_playing_session(TEST_SEED)
	if session == null:
		return
	var manager := session.runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null:
		_fail("ROUNDTRIP: P1 activo inexistente.")
		return

	var request := session.build_human_action_choice_request()
	if request == null:
		_fail("ROUNDTRIP: no se creo ChoiceRequest humano inicial.")
		return
	var option_ids_before := request.get_option_ids()
	var options_before := request.get_options()
	var package := KarmanyFullMatchSaveAdapter.capture(session)
	if package.is_empty():
		_fail("ROUNDTRIP: capture devolvio paquete vacio.")
		return

	var overlay: Dictionary = package.get("session", {})
	var saved_action_rng: int = int(String(overlay.get("action_rng_state", "0")))
	var saved_content_rng: int = int(String(overlay.get("content_rng_state", "0")))
	var expected_action_rng := RandomNumberGenerator.new()
	expected_action_rng.state = saved_action_rng
	var expected_next_action: int = expected_action_rng.randi_range(1, 1000000)
	var expected_content_rng := RandomNumberGenerator.new()
	expected_content_rng.state = saved_content_rng
	var expected_next_content: int = expected_content_rng.randi_range(1, 1000000)

	var saved_mn: int = player.mn
	var saved_round: int = manager.current_round
	var saved_actions: int = manager.actions_remaining
	var saved_coord: Vector2i = player.current_coord
	var ai_id: StringName = session.runtime.ai_match_controller.get_ai_player_ids()[0]
	var ai_controller := session.runtime.ai_match_controller.get_ai_controller(ai_id)
	var saved_ai_state: int = ai_controller.brain.rng.state
	var expected_ai_rng := RandomNumberGenerator.new()
	expected_ai_rng.state = saved_ai_state
	var expected_next_ai: int = expected_ai_rng.randi_range(1, 1000000)

	# Mutaciones que deben desaparecer al cargar.
	player.mn = saved_mn + 9
	session._action_rng.randi()
	session.runtime._content_rng.randi()
	ai_controller.brain.rng.randi()
	session.statistics["actions"] = 999
	session._last_coord_by_player[player.player_id] = Vector2i(20, 20)
	session._pending_human_choice_request = null

	_expect(KarmanyFullMatchSaveAdapter.restore(session, package), "ROUNDTRIP: restore fallo.")
	player = manager.get_active_player()
	_expect(player != null and player.mn == saved_mn, "ROUNDTRIP: recursos no volvieron al snapshot.")
	_expect(manager.current_round == saved_round and manager.actions_remaining == saved_actions, "ROUNDTRIP: turno/acciones divergieron.")
	_expect(player != null and player.current_coord == saved_coord, "ROUNDTRIP: posicion del jugador divergio.")
	_expect(int(session.statistics.get("actions", -1)) != 999, "ROUNDTRIP: estadisticas FullMatch no se restauraron.")
	var restored_request := session.get_pending_human_choice_request()
	_expect(restored_request != null, "ROUNDTRIP: ChoiceRequest pendiente se perdio.")
	if restored_request != null:
		_expect(restored_request.get_option_ids() == option_ids_before, "ROUNDTRIP: option_ids humanos cambiaron al cargar.")
		_expect(_option_signature(restored_request.get_options()) == _option_signature(options_before), "ROUNDTRIP: opciones humanas cambiaron al cargar.")

	_expect(session._action_rng.randi_range(1, 1000000) == expected_next_action, "ROUNDTRIP: RNG de acciones no continuo exactamente.")
	_expect(session.runtime._content_rng.randi_range(1, 1000000) == expected_next_content, "ROUNDTRIP: RNG de contenido no continuo exactamente.")
	ai_controller = session.runtime.ai_match_controller.get_ai_controller(ai_id)
	_expect(ai_controller.brain.rng.randi_range(1, 1000000) == expected_next_ai, "ROUNDTRIP: RNG de IA no continuo exactamente.")
	print("F47 ROUNDTRIP | runtime + overlay + ChoiceRequest + RNG exactos.")


func _test_disk_continue() -> void:
	var session := _new_playing_session(TEST_SEED + 1)
	if session == null:
		return
	var request := session.build_human_action_choice_request()
	if request == null:
		_fail("DISK: no se creo decision humana antes del save.")
		return
	var package_before := KarmanyFullMatchSaveAdapter.capture(session)
	var runtime_before: Dictionary = package_before.get("runtime", {})
	var pending_before: Dictionary = package_before.get("session", {}).get("pending", {})
	_expect(KarmanyFullMatchSaveFacade.save_session(session, TEST_SAVE_PATH), "DISK: no pudo escribir archivo.")
	_expect(KarmanyFullMatchSaveFacade.has_compatible_save(TEST_SAVE_PATH), "DISK: archivo escrito no se reconoce como compatible.")
	var continued := KarmanyFullMatchSaveFacade.continue_session(TEST_SAVE_PATH)
	_expect(bool(continued.get("ok", false)), "DISK: Continuar no pudo crear runtime/sesion nuevos.")
	if not bool(continued.get("ok", false)):
		return
	var resumed := continued.get("session", null) as KarmanyFullMatchSession
	if resumed == null:
		_fail("DISK: Continuar no devolvio FullMatchSession.")
		return
	var package_after := KarmanyFullMatchSaveAdapter.capture(resumed)
	_expect(package_after.get("runtime", {}) == runtime_before, "DISK: runtime reconstruido no coincide con el guardado.")
	_expect(package_after.get("session", {}).get("pending", {}) == pending_before, "DISK: decision humana pendiente no coincide tras Continuar.")
	_expect(resumed.match_state == KarmanyFullMatchSessionBase.MatchState.PLAYING, "DISK: Continuar no regreso a PLAYING.")
	print("F47 CONTINUE | archivo -> runtime limpio -> FullMatchSession -> estado exacto.")


func _test_transactional_rollback() -> void:
	var session := _new_playing_session(TEST_SEED + 2)
	if session == null:
		return
	var request := session.build_human_action_choice_request()
	if request == null:
		_fail("ROLLBACK: no se creo ChoiceRequest de control.")
		return
	var player := session.runtime.local_session.turn_manager.get_active_player()
	if player == null:
		_fail("ROLLBACK: P1 inexistente.")
		return
	player.mn = 17
	var before := KarmanyFullMatchSaveAdapter.capture(session)
	var bad: Dictionary = before.duplicate(true)
	var runtime_bad: Dictionary = bad.get("runtime", {})
	var players_bad: Array = runtime_bad.get("players", [])
	if players_bad.is_empty():
		_fail("ROLLBACK: snapshot sin jugadores.")
		return
	var first_player: Dictionary = players_bad[0]
	first_player["resources"] = [1, 1, 1, 0]
	players_bad[0] = first_player
	runtime_bad["players"] = players_bad
	bad["runtime"] = runtime_bad
	var overlay_bad: Dictionary = bad.get("session", {})
	overlay_bad["pending"] = {"stage": "fase_47_invalid_stage", "request_id": 999}
	bad["session"] = overlay_bad

	_expect(not KarmanyFullMatchSaveAdapter.restore(session, bad), "ROLLBACK: paquete inconsistente fue aceptado.")
	player = session.runtime.local_session.turn_manager.get_active_player()
	_expect(player != null and player.mn == 17, "ROLLBACK: fallo de carga dejo mutacion parcial de recursos.")
	_expect(session.get_pending_human_choice_request() != null, "ROLLBACK: fallo de carga destruyo decision previa.")
	var after := KarmanyFullMatchSaveAdapter.capture(session)
	_expect(after.get("runtime", {}) == before.get("runtime", {}), "ROLLBACK: runtime no volvio exactamente al estado previo.")
	print("F47 ROLLBACK | error tardio revierte mutaciones parciales y conserva decision previa.")


func _new_playing_session(seed_value: int) -> KarmanyFullMatchSession:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_fail("SETUP %d: runtime F37 no configuro." % seed_value)
		return null
	var session := KarmanyFullMatchSession.new()
	session.verbose_console_output = false
	if not session.configure(runtime):
		_fail("SETUP %d: FullMatchSession fallo: %s" % [seed_value, session.last_error])
		return null
	if not session.start_playing():
		_fail("SETUP %d: no pudo entrar a PLAYING." % seed_value)
		return null
	return session


func _option_signature(options: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for row in options:
		result.append("%s|%s|%s|%s" % [
			String(row.get("option_id", "")),
			String(row.get("action_name", "")),
			String(row.get("debug_label", "")),
			str(row.get("target_coord", Vector2i.ZERO)),
		])
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	_failures.append("FASE 47 TEST ERROR: %s" % message)
