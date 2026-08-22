extends Node


var _failures: Array[String] = []


func _ready() -> void:
	_test_complete_snapshot_and_inspectors()
	if _failures.is_empty():
		print("FASE 46 HUD MODEL OK - recursos, FA, PL, Libro, zona, Karmany, objetivos, mision, mano, Equipo, mercado e historial son accesibles sin debug.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_complete_snapshot_and_inspectors() -> void:
	var fixture := _new_fixture(460101)
	if fixture.is_empty():
		return
	var session := fixture.get("session", null) as KarmanyFullMatchSession
	var bridge := KarmanyPhase46AlphaHudBridge.new()
	_expect(bridge.configure(session), "No pudo configurar bridge HUD.")
	if not bridge.is_configured():
		return

	var snapshot := bridge.get_snapshot()
	_expect(not snapshot.is_empty(), "Snapshot vacio.")
	for key in [
		"round", "actions_remaining", "active_player_id", "human_player_id",
		"resources", "legacy_points", "position", "zone", "visible_effects",
		"book_level", "active_karmany", "public_objectives", "secret_mission",
		"resonances", "equipment", "market", "participants", "recent_events",
	]:
		_expect(snapshot.has(key), "Falta campo obligatorio: %s" % key)

	var resources: Dictionary = snapshot.get("resources", {})
	for resource_key in ["MN", "MR", "EK", "FA"]:
		_expect(resources.has(resource_key), "Falta recurso HUD: %s" % resource_key)
	var active_karmany: Dictionary = snapshot.get("active_karmany", {})
	var market_rows: Array = snapshot.get("market", [])
	var objective_rows: Array = snapshot.get("public_objectives", [])
	var secret_mission: Dictionary = snapshot.get("secret_mission", {})
	var participant_rows: Array = snapshot.get("participants", [])
	var recent_events: PackedStringArray = snapshot.get("recent_events", PackedStringArray())
	_expect(int(snapshot.get("book_level", 0)) >= 1, "Libro no tiene nivel visible valido.")
	_expect(not active_karmany.is_empty(), "Karmany activo no visible.")
	_expect(market_rows.size() == KarmanyEquipmentMarket.MARKET_SIZE, "Mercado HUD no muestra exactamente las 4 cartas visibles.")
	_expect(not objective_rows.is_empty(), "Objetivos publicos no visibles.")
	_expect(not secret_mission.is_empty(), "Mision secreta propia no visible para P1.")
	_expect(participant_rows.size() == 4, "HUD no muestra los cuatro participantes.")
	_expect(not recent_events.is_empty(), "Historial no captura los eventos de inicio.")

	var tile_inspector := bridge.inspect_current_tile()
	_expect(not tile_inspector.is_empty(), "Inspector de loseta actual vacio.")
	var karmany_inspector := bridge.inspect_active_karmany()
	_expect(not karmany_inspector.is_empty(), "Inspector de Karmany activo vacio.")

	var resonance_rows: Array = snapshot.get("resonances", [])
	if not resonance_rows.is_empty():
		var resonance_row: Dictionary = resonance_rows[0]
		var resonance_id := StringName(resonance_row.get("resonance_id", ""))
		_expect(not bridge.inspect_resonance(resonance_id).is_empty(), "Inspector de Resonancia no resuelve carta de la mano.")

	if not market_rows.is_empty():
		var market_row: Dictionary = market_rows[0]
		var equipment_id := StringName(market_row.get("equipment_id", ""))
		_expect(not bridge.inspect_equipment(equipment_id).is_empty(), "Inspector de Equipo no resuelve mercado visible.")


func _new_fixture(seed_value: int) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_failures.append("No se pudo configurar runtime MAP41.")
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_failures.append("No se pudo configurar FullMatchSession: %s" % session.last_error)
		return {}
	if not session.start_playing():
		_failures.append("No se pudo iniciar PLAYING.")
		return {}
	return {"runtime": runtime, "session": session}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 46 HUD MODEL ERROR: %s" % message)
