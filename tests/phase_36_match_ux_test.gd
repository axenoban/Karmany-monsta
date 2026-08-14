extends Node


const PHASE_36_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_36_match_ux_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 36 MATCH UX TEST")
	print("================================")

	var ok: bool = await _test_phase_36_ux_flow()

	print("")
	print("================================")
	if ok:
		print("FASE 36 OK - IA anti-farming y UX de partida completa listas para validacion local.")
	else:
		push_error("FASE 36 ERROR - revisar el primer fallo real.")
	print("================================")


func _test_phase_36_ux_flow() -> bool:
	var prototype := PHASE_36_SCENE.instantiate() as KarmanyPhase36MatchUxBridge
	if prototype == null:
		return _fail("No se pudo instanciar escena F36.")
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame
	if not prototype.setup_ok:
		prototype.queue_free()
		return _fail("F36 no completo setup sobre F35.")
	prototype.phase_35.set_presentation_speed_multiplier(100.0)

	var runtime := prototype.get_runtime()
	if runtime == null or not runtime.configured:
		prototype.queue_free()
		return _fail("Runtime F34/F35 no sigue disponible en F36.")
	if runtime.board_state.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		prototype.queue_free()
		return _fail("F36 altero el mapa canonico de 41 posiciones.")
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		prototype.queue_free()
		return _fail("F36 rompio conectividad F31.")
	if prototype.phase_35.phase_34.trainer_units.size() != 4:
		prototype.queue_free()
		return _fail("F36 perdio las cuatro unidades visuales de F35.")

	var old_overlay := prototype.phase_35.get_node_or_null("Phase35Overlay") as CanvasLayer
	if old_overlay == null or old_overlay.visible:
		prototype.queue_free()
		return _fail("HUD F35 no fue sustituido por la capa compacta F36.")
	if not prototype.get_turn_text().contains("P1 HUMANO"):
		prototype.queue_free()
		return _fail("Barra superior no identifica turno humano inicial.")
	if not prototype.get_turn_text().contains("ACCIONES 2/2"):
		prototype.queue_free()
		return _fail("Barra superior no muestra presupuesto de acciones.")

	var participant_text: String = prototype.participants_label.text
	for expected_text in ["P1 HUMANO", "P2 EXPLORADORA", "P3 OPORTUNISTA", "P4 AGRESIVA"]:
		if not participant_text.contains(expected_text):
			prototype.queue_free()
			return _fail("Panel compacto no identifica %s." % expected_text)
	for private_marker in ["MN=", "EK=", "FA=", "Resonancias", "Equipos"]:
		if participant_text.contains(private_marker):
			prototype.queue_free()
			return _fail("Panel publico expone informacion privada: %s." % private_marker)

	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	var legal := KarmanyAiLegalActionGenerator.build_legal_actions(runtime.coordinator, p1)
	var explore_target := _first_target(legal, KarmanyAiActionCandidate.ActionType.EXPLORE)
	if explore_target == Vector2i(999, 999):
		prototype.queue_free()
		return _fail("P1 no tiene exploracion legal para probar UX.")
	var before_summary: String = prototype.get_location_summary(explore_target)
	if not before_summary.contains("OCULTA"):
		prototype.queue_free()
		return _fail("F36 muestra identidad antes de explorar.")
	if runtime.get_public_tile_data(explore_target) != null:
		prototype.queue_free()
		return _fail("F32 expone tile_data oculta antes de la accion.")

	var phase_31 := prototype.phase_35.phase_34.phase_32.phase_31
	var target_tile := phase_31.get_tile_view(explore_target)
	if target_tile == null:
		prototype.queue_free()
		return _fail("No existe visual de destino legal.")
	target_tile.tile_clicked.emit(target_tile)
	await get_tree().process_frame
	prototype.refresh_for_test()
	if prototype.explore_button.disabled:
		prototype.queue_free()
		return _fail("Explorar seleccionada no se habilita sobre destino legal.")
	if not prototype.get_action_summary_text().contains("Explorar"):
		prototype.queue_free()
		return _fail("Resumen de acciones no muestra opcion legal Explorar.")

	prototype.explore_button.pressed.emit()
	var idle_ok: bool = await prototype.phase_35.wait_for_presentation_idle()
	await get_tree().process_frame
	if not idle_ok:
		prototype.queue_free()
		return _fail("Presentacion humana F36 quedo bloqueada.")
	if p1.current_coord != explore_target:
		prototype.queue_free()
		return _fail("Accion UX no llego al MatchCoordinator real.")
	if runtime.local_session.turn_manager.actions_remaining != 1:
		prototype.queue_free()
		return _fail("Explorar desde UX no consumio exactamente una accion.")
	var after_summary: String = prototype.get_location_summary(explore_target)
	if after_summary.contains("OCULTA"):
		prototype.queue_free()
		return _fail("Ubicacion no actualizo identidad tras revelacion publica.")

	# El boton Alpha consume el presupuesto restante sin cambiar reglas y
	# permite observar P2/P3/P4 en la misma escena F6.
	prototype.pass_button.pressed.emit()
	await get_tree().process_frame
	if runtime.local_session.turn_manager.get_active_player().player_id != &"player_2":
		prototype.queue_free()
		return _fail("Pasar resto P1 no entrego turno a P2.")

	var ai_cycle_ok: bool = await prototype.phase_35.run_all_ai_until_human_presented()
	await get_tree().process_frame
	prototype.refresh_for_test()
	if not ai_cycle_ok:
		prototype.queue_free()
		return _fail("Ciclo P2→P4 no regreso al humano.")
	if runtime.local_session.turn_manager.get_active_player().player_id != &"player_1":
		prototype.queue_free()
		return _fail("Tras P4 no regreso P1.")
	if runtime.local_session.turn_manager.actions_remaining != 2:
		prototype.queue_free()
		return _fail("P1 no recupero 2/2 acciones en ronda siguiente.")
	if not prototype.get_p3_debug_text().contains("score"):
		prototype.queue_free()
		return _fail("Debug P3 no muestra score de decision.")
	if not prototype.get_p3_debug_text().contains("MR"):
		prototype.queue_free()
		return _fail("Debug P3 no muestra recurso antes/despues.")

	for player in runtime.local_session.players:
		if prototype.phase_35.get_visual_coord(player.player_id) != player.current_coord:
			prototype.queue_free()
			return _fail("F36 desincronizo PlayerState y visual de %s." % player.player_id)

	var remaining_hidden := _find_hidden_coord(runtime)
	if remaining_hidden != Vector2i(999, 999):
		var hidden_summary: String = prototype.get_location_summary(remaining_hidden)
		if not hidden_summary.contains("OCULTA"):
			prototype.queue_free()
			return _fail("Una loseta aun oculta filtra identidad en UX F36.")

	print("UX F36: tablero, HUD, acciones, ocultamiento, P3 debug y ciclo 4 jugadores: OK")
	prototype.queue_free()
	await get_tree().process_frame
	return true


func _first_target(
	candidates: Array[KarmanyAiActionCandidate],
	action_type: int
) -> Vector2i:
	for candidate in candidates:
		if candidate != null and candidate.action_type == action_type:
			return candidate.target_coord
	return Vector2i(999, 999)


func _find_hidden_coord(runtime: KarmanyMultiAiAlphaRuntime) -> Vector2i:
	for level in [
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3
	]:
		for coord in KarmanyCanonicalMap41Layout.get_coords_for_level(level):
			if not runtime.board_state.is_revealed(coord):
				return coord
	return Vector2i(999, 999)


func _fail(message: String) -> bool:
	push_error("FASE 36 UX TEST ERROR: %s" % message)
	return false
