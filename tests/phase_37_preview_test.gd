extends Node


const PHASE_37_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_37_content_preview_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 37 PREVIEW TEST")
	print("================================")

	var ok: bool = await _test_preview_and_execution_share_data()

	print("")
	print("================================")
	if ok:
		print("FASE 37 PREVIEW OK - ocultamiento, Entrada e Interactuar usan datos publicos compartidos.")
	else:
		push_error("FASE 37 PREVIEW ERROR - revisar el primer fallo real.")
	print("================================")


func _test_preview_and_execution_share_data() -> bool:
	var prototype := PHASE_37_SCENE.instantiate() as KarmanyPhase37ContentPreviewBridge
	if prototype == null:
		return _fail("No se pudo instanciar F37.")
	add_child(prototype)
	await _wait_frames(4)
	if not prototype.setup_ok:
		prototype.queue_free()
		return _fail("F37 no completo setup sobre F36.")
	prototype.phase_36.phase_35.set_presentation_speed_multiplier(100.0)

	var runtime := prototype.get_runtime()
	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	if p1 == null:
		prototype.queue_free()
		return _fail("P1 no existe.")
	var start_coord: Vector2i = p1.current_coord
	var start_tile: KarmanyTileData = runtime.get_public_tile_data(start_coord)
	if start_tile == null:
		prototype.queue_free()
		return _fail("Inicial de P1 no esta publica.")

	# La vista de setup prueba privacidad mientras todas las Misiones siguen
	# secretas. La UI F37 solo renderiza la del humano propietario.
	var own_mission := runtime.get_secret_mission_for_viewer(&"player_1", &"player_1")
	var rival_mission := runtime.get_secret_mission_for_viewer(&"player_1", &"player_2")
	if own_mission == null or rival_mission != null:
		prototype.queue_free()
		return _fail("Privacidad inicial de Misiones Secretas no se preservo.")
	if not prototype.get_content_status_text().contains(own_mission.display_name):
		prototype.queue_free()
		return _fail("La UI no muestra la Mision propia del humano.")
	if prototype.get_content_status_text().contains("player_2"):
		prototype.queue_free()
		return _fail("La UI de contenido contiene una referencia a Mision rival.")

	var hidden_target: Vector2i = _find_legal_target(
		runtime,
		p1,
		KarmanyAiActionCandidate.ActionType.EXPLORE
	)
	if hidden_target == KarmanyPhase36MatchUxBridge.INVALID_COORD:
		prototype.queue_free()
		return _fail("P1 no tiene N oculta legal para el test.")
	if not _select_coord(prototype, hidden_target):
		prototype.queue_free()
		return _fail("No se pudo seleccionar destino oculto.")
	await _wait_frames(2)
	prototype.refresh_preview()
	var hidden_preview: String = prototype.get_selected_preview_text()
	if not hidden_preview.contains("OCULTA"):
		prototype.queue_free()
		return _fail("Preview oculto no muestra OCULTA.")
	if hidden_preview.contains("ENTRADA") or hidden_preview.contains("INTERACTUAR"):
		prototype.queue_free()
		return _fail("Preview oculto filtro secciones de efectos.")
	if runtime.get_public_tile_data(hidden_target) != null:
		prototype.queue_free()
		return _fail("BoardState expuso KarmanyTileData antes de Explorar.")

	# Interactuar en la Inicial usa exactamente later_use_effects del Resource.
	var interaction_text: String = prototype.get_interact_preview_text()
	var expected_interaction: String = KarmanyEffectDescriptionFormatter.describe_interaction(start_tile)
	if not interaction_text.contains(expected_interaction):
		prototype.queue_free()
		return _fail("Preview Interactuar no deriva del KarmanyTileData real.")
	if start_tile.later_use_effects.is_empty():
		prototype.queue_free()
		return _fail("Inicial P1 no tiene efecto ejecutable para comparar.")
	var interact_effect: KarmanyEffectData = start_tile.later_use_effects[0]
	var resource_before_interact: int = p1.get_resource(interact_effect.resource_type)
	prototype.phase_36.interact_button.pressed.emit()
	await _wait_frames(3)
	var resource_after_interact: int = p1.get_resource(interact_effect.resource_type)
	if resource_after_interact - resource_before_interact != interact_effect.amount:
		prototype.queue_free()
		return _fail("Interactuar ejecuto un resultado distinto al efecto previsualizado.")
	if runtime.local_session.turn_manager.actions_remaining != 1:
		prototype.queue_free()
		return _fail("Interactuar no consumio exactamente una accion.")

	# La segunda accion explora el destino previamente inspeccionado sin fuga.
	if not _select_coord(prototype, hidden_target):
		prototype.queue_free()
		return _fail("No se pudo reseleccionar la N oculta.")
	await _wait_frames(2)
	if prototype.phase_36.explore_button.disabled:
		prototype.queue_free()
		return _fail("Explorar legal no quedo habilitado.")
	prototype.phase_36.explore_button.pressed.emit()
	var exploration_idle: bool = await prototype.phase_36.phase_35.wait_for_presentation_idle()
	await _wait_frames(2)
	prototype.refresh_preview()
	if not exploration_idle:
		prototype.queue_free()
		return _fail("Presentacion de Explorar quedo bloqueada.")
	var revealed_tile: KarmanyTileData = runtime.get_public_tile_data(hidden_target)
	if revealed_tile == null:
		prototype.queue_free()
		return _fail("La loseta no se hizo publica despues de Explorar.")
	if hidden_preview.contains(revealed_tile.display_name) or hidden_preview.contains(String(revealed_tile.tile_id)):
		prototype.queue_free()
		return _fail("El preview previo a Explorar conocia la identidad futura.")
	var revealed_preview: String = prototype.get_selected_preview_text()
	if not revealed_preview.contains(revealed_tile.display_name):
		prototype.queue_free()
		return _fail("Preview revelado no muestra nombre real.")
	if not revealed_preview.contains("ENTRADA") or not revealed_preview.contains("INTERACTUAR"):
		prototype.queue_free()
		return _fail("Preview revelado no separa Entrada e Interactuar.")
	if not revealed_preview.contains(KarmanyEffectDescriptionFormatter.describe_entry(revealed_tile)):
		prototype.queue_free()
		return _fail("Descripcion de Entrada no corresponde al Resource revelado.")
	if not revealed_preview.contains(KarmanyEffectDescriptionFormatter.describe_interaction(revealed_tile)):
		prototype.queue_free()
		return _fail("Descripcion de Interactuar no corresponde al Resource revelado.")

	# Explorar consumio la segunda accion, asi que P2 esta activo. Ejecutar el
	# ciclo real P2->P4 y volver a P1 permite probar Mover en ronda siguiente.
	var ai_cycle_ok: bool = await prototype.phase_36.phase_35.run_all_ai_until_human_presented()
	await _wait_frames(2)
	if not ai_cycle_ok:
		prototype.queue_free()
		return _fail("P2->P4 no regreso a P1.")
	if runtime.local_session.turn_manager.get_active_player() != p1:
		prototype.queue_free()
		return _fail("P1 no recupero el turno.")

	if not _select_coord(prototype, start_coord):
		prototype.queue_free()
		return _fail("No se pudo seleccionar la Inicial revelada para Mover.")
	await _wait_frames(2)
	prototype.refresh_preview()
	if prototype.phase_36.move_button.disabled:
		prototype.queue_free()
		return _fail("Mover de regreso a Inicial revelada no es legal.")
	var move_preview: String = prototype.get_move_preview_text()
	var expected_entry: String = KarmanyEffectDescriptionFormatter.describe_entry(start_tile)
	if not move_preview.contains(start_tile.display_name) or not move_preview.contains(expected_entry):
		prototype.queue_free()
		return _fail("Preview Mover no muestra destino y efecto de Entrada reales.")
	if start_tile.entry_effects.is_empty():
		prototype.queue_free()
		return _fail("Inicial P1 no tiene Entrada ejecutable para comparar.")
	var entry_effect: KarmanyEffectData = start_tile.entry_effects[0]
	var resource_before_move: int = p1.get_resource(entry_effect.resource_type)
	prototype.phase_36.move_button.pressed.emit()
	var move_idle: bool = await prototype.phase_36.phase_35.wait_for_presentation_idle()
	await _wait_frames(2)
	if not move_idle:
		prototype.queue_free()
		return _fail("Presentacion de Mover quedo bloqueada.")
	var resource_after_move: int = p1.get_resource(entry_effect.resource_type)
	if resource_after_move - resource_before_move != entry_effect.amount:
		prototype.queue_free()
		return _fail("Mover aplico una Entrada distinta a la previsualizada.")

	print("Oculta -> revelar -> preview de datos -> Interactuar/Mover coinciden con resolver: OK")
	prototype.queue_free()
	await _wait_frames(2)
	return true


func _find_legal_target(
	runtime: KarmanyMultiAiAlphaRuntime,
	player: KarmanyPlayerState,
	action_type: int
) -> Vector2i:
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		player
	)
	for candidate in candidates:
		if candidate != null and candidate.action_type == action_type:
			return candidate.target_coord
	return KarmanyPhase36MatchUxBridge.INVALID_COORD


func _select_coord(
	prototype: KarmanyPhase37ContentPreviewBridge,
	coord: Vector2i
) -> bool:
	var phase_31 := prototype.phase_36.phase_35.phase_34.phase_32.phase_31
	var tile := phase_31.get_tile_view(coord)
	if tile == null:
		return false
	tile.tile_clicked.emit(tile)
	prototype.phase_36.refresh_for_test()
	prototype.refresh_preview()
	return true


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _fail(message: String) -> bool:
	push_error("FASE 37 PREVIEW TEST ERROR: %s" % message)
	return false
