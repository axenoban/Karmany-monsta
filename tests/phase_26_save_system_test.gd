extends Node


@onready var prototype: KarmanyPhase26SaveBridge = $Phase26SavePrototype


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 26 SAVE SYSTEM TEST")
	print("================================")

	var ok: bool = true
	ok = _expect(prototype != null and prototype.current_match != null, "No se creo la partida inicial de Fase 26.") and ok
	if not ok:
		_finish(false)
		return

	ok = _test_new_game_state() and ok
	ok = _expect(prototype.prepare_demo_checkpoint(), "No se pudo preparar el checkpoint tecnico.") and ok
	var before: Dictionary = prototype.capture_current_snapshot()
	ok = _expect(not before.is_empty(), "El snapshot previo al guardado esta vacio.") and ok
	ok = _test_checkpoint_state() and ok
	ok = _expect(prototype.save_game(), "Guardar devolvio false.") and ok
	ok = _expect(FileAccess.file_exists(KarmanyPhase26SaveBridge.SAVE_PATH), "El archivo de guardado no fue creado en user://.") and ok

	var disk_snapshot := KarmanySaveGameService.load_snapshot_from_path(KarmanyPhase26SaveBridge.SAVE_PATH)
	ok = _expect(KarmanySaveGameService.is_supported_snapshot(disk_snapshot), "El JSON guardado no tiene formato/version soportados.") and ok
	var incompatible := disk_snapshot.duplicate(true)
	incompatible["version"] = KarmanySaveGameService.FORMAT_VERSION + 1
	ok = _expect(not KarmanySaveGameService.is_supported_snapshot(incompatible), "Una version futura/incompatible fue aceptada.") and ok

	ok = _expect(await prototype.new_game(), "Nueva partida fallo antes de probar Cargar.") and ok
	ok = _test_new_game_state() and ok
	ok = _expect(await prototype.load_game(), "Cargar devolvio false.") and ok
	var after: Dictionary = prototype.capture_current_snapshot()
	ok = _expect(_snapshots_equivalent(before, after), "El estado capturado despues de Cargar no coincide con el guardado.") and ok
	ok = _test_checkpoint_state() and ok
	ok = _test_loaded_match_can_continue() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 26 OK - Nueva partida, Guardar y Cargar restauran tablero, jugadores, inventarios, mazos, ronda, PL y encuentros.")
	else:
		push_error("FASE 26 ERROR - Revisar round-trip de guardado/carga.")
	print("================================")


func _test_new_game_state() -> bool:
	var match := prototype.current_match
	var ok: bool = true
	ok = _expect(match.turn_manager.current_round == 1, "Nueva partida debe iniciar en ronda 1.") and ok
	ok = _expect(match.turn_manager.actions_remaining == 2, "Nueva partida debe iniciar con 2 acciones.") and ok
	ok = _expect(match.turn_manager.get_active_player() == match.player_1, "player_1 debe iniciar una nueva partida.") and ok
	ok = _expect(match.player_1.mn == 2 and match.player_1.mr == 1 and match.player_1.ek == 1 and match.player_1.fa == 0, "Recursos iniciales P1 incorrectos.") and ok
	ok = _expect(match.player_1.get_equipment_count() == 0, "Nueva partida no debe conservar Equipo cargado.") and ok
	ok = _expect(match.coordinator.encounter_resolver.active_encounters.is_empty(), "Nueva partida no debe conservar encuentros.") and ok
	ok = _expect(_count_beasts(match) == 0, "Nueva partida no debe conservar Bestias de un save anterior.") and ok
	print("Nueva partida limpia: ", "OK" if ok else "ERROR")
	return ok


func _test_checkpoint_state() -> bool:
	var match := prototype.current_match
	var ok: bool = true
	ok = _expect(match.turn_manager.current_round == 1, "Checkpoint debe conservar ronda 1.") and ok
	ok = _expect(match.turn_manager.actions_remaining == 1, "Checkpoint debe conservar turno parcial con 1 accion.") and ok
	ok = _expect(match.turn_manager.get_action_usage(KarmanyTileInteractionResolver.ACTION_ID_INTERACT) == 1, "Uso de Interactuar del turno no fue preservado.") and ok
	ok = _expect(match.player_1.ek == 3, "Checkpoint debe conservar +2 EK de Interactuar.") and ok
	ok = _expect(match.player_1.get_equipment_count() == 1, "Inventario de Equipo no fue preservado.") and ok
	ok = _expect(match.player_1.get_resonance_count() == 6, "Mano de Resonancia no fue preservada.") and ok
	ok = _expect(match.player_1.resonance_hand.get_pending_discard_count() == 1, "Descarte pendiente de Resonancia no fue preservado.") and ok
	ok = _expect(match.legacy_points.get_total(match.player_1.player_id) == 2, "PL del checkpoint no fueron preservados.") and ok
	var book := match.coordinator.get_book_state(match.player_1.player_id)
	ok = _expect(book != null and book.level == 2, "Libro II del checkpoint no fue preservado.") and ok
	ok = _expect(match.coordinator.encounter_resolver.active_encounters.size() == 1, "Encuentro visible no fue preservado.") and ok
	if match.coordinator.encounter_resolver.active_encounters.size() == 1:
		var encounter := match.coordinator.encounter_resolver.active_encounters[0]
		ok = _expect(encounter.get_karmany_data() == KarmanyPhase24FullMatchBridge.BRUMAK, "El encuentro restaurado no es Brumak.") and ok
	ok = _expect(_count_beasts(match) == 1, "Bestia en tablero no fue preservada.") and ok
	ok = _expect(match.resonance_deck.get_draw_count() == 0, "El orden/consumo del mazo de Resonancias no coincide con el checkpoint esperado.") and ok
	ok = _expect(match.equipment_market.get_visible_count() == 4, "Mercado visible debe conservar 4 Equipos tras take/refill.") and ok
	print("Checkpoint: turno + inventarios + mazos + PL + Libro + encuentros + tablero: ", "OK" if ok else "ERROR")
	return ok


func _test_loaded_match_can_continue() -> bool:
	var match := prototype.current_match
	var interaction := match.coordinator.interact_effect_option(match.player_1, 0)
	var ok: bool = true
	ok = _expect(interaction != null and interaction.is_success(), "La partida cargada no pudo ejecutar su accion restante.") and ok
	ok = _expect(match.turn_manager.actions_remaining == 0, "La accion posterior a Cargar no consumio la accion restante.") and ok
	ok = _expect(match.player_1.ek == 5, "La accion posterior a Cargar no aplico el efecto real de la loseta.") and ok
	print("Partida cargada continua usando reglas normales: ", "OK" if ok else "ERROR")
	return ok


func _snapshots_equivalent(a: Dictionary, b: Dictionary) -> bool:
	# El servicio reconstruye el snapshot en el mismo orden semantico. Usar
	# JSON permite comparar solo datos persistentes, no identidades de objetos.
	return JSON.stringify(a) == JSON.stringify(b)


func _count_beasts(match: KarmanyPhase24FullMatchBridge) -> int:
	var total: int = 0
	for coord in match.board_prototype.board_state.get_coords():
		if match.board_prototype.board_state.has_beast(coord):
			total += 1
	return total


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 26 TEST ERROR: %s" % message)
	return false


func _finish(ok: bool) -> void:
	print("FASE 26 ABORTADA" if not ok else "FASE 26 PRECHECK OK")
