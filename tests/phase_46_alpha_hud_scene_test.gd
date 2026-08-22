extends Node


const INVALID_COORD: Vector2i = Vector2i(999, 999)

var _failures: Array[String] = []


func _ready() -> void:
	await _test_scene_contract()
	if _failures.is_empty():
		print("FASE 46 HUD SCENE OK - HUD completo monta sobre F38, sustituye controles Alpha obsoletos y expone decisiones humanas reales sin filtrar revelaciones visuales.")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_scene_contract() -> void:
	var packed := load("res://scenes/ui/phase_46_alpha_hud_prototype.tscn") as PackedScene
	if packed == null:
		_failures.append("No se pudo cargar phase_46_alpha_hud_prototype.tscn.")
		return
	var prototype := packed.instantiate() as KarmanyPhase46PresentationSafeController
	if prototype == null:
		_failures.append("La escena F46 no instancia KarmanyPhase46PresentationSafeController.")
		return
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(prototype.phase_38 != null, "F38 baseline no esta montado.")
	if prototype.phase_38 == null:
		prototype.queue_free()
		return
	_expect(prototype.phase_38.full_session != null, "FullMatchSession no esta disponible.")
	_expect(prototype.hud_bridge.is_configured(), "Read model HUD no esta configurado.")
	_expect(prototype.hud_root != null, "HUD root no fue creado.")
	if prototype.hud_root == null:
		prototype.queue_free()
		return

	var player_panel := prototype.hud_root.find_child("PlayerPanel", true, false) as PanelContainer
	var objective_panel := prototype.hud_root.find_child("ObjectivePanel", true, false) as PanelContainer
	var choice_panel := prototype.hud_root.find_child("ChoicePanel", true, false) as PanelContainer
	var feedback_banner := prototype.hud_root.find_child("FeedbackBanner", true, false) as PanelContainer
	var context_strip := prototype.hud_root.find_child("ContextStrip", true, false) as PanelContainer

	_expect(prototype.hud_root.find_child("TopBar", true, false) != null, "Falta TopBar.")
	_expect(player_panel != null, "Falta PlayerPanel.")
	_expect(objective_panel != null, "Falta ObjectivePanel.")
	_expect(choice_panel != null, "Falta ChoicePanel.")
	_expect(prototype.hud_root.find_child("Inspector", true, false) != null, "Falta Inspector modal.")
	_expect(feedback_banner != null, "Falta FeedbackBanner de exito/error/combate.")
	_expect(context_strip != null, "Falta resumen visible de Entrenador/reserva/seleccion.")
	_expect(prototype.hud_root.find_child("ContextInspector", true, false) != null, "Falta inspector contextual de loseta/Bestia/PvP/Aeterna.")
	_expect(
		prototype.hud_root.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"El Control transparente de pantalla completa interceptaria clicks destinados al tablero."
	)
	_expect(objective_panel != null and objective_panel.size.y <= 395.0, "ObjectivePanel invade verticalmente el area de decisiones.")
	if player_panel != null and choice_panel != null:
		_expect(not _controls_overlap(player_panel, choice_panel), "PlayerPanel se solapa con ChoicePanel.")
	if objective_panel != null and choice_panel != null:
		_expect(not _controls_overlap(objective_panel, choice_panel), "ObjectivePanel se solapa con ChoicePanel.")
	if feedback_banner != null and objective_panel != null:
		_expect(not _controls_overlap(feedback_banner, objective_panel), "FeedbackBanner se solapa con ObjectivePanel.")
	if context_strip != null and objective_panel != null:
		_expect(not _controls_overlap(context_strip, objective_panel), "ContextStrip se solapa con ObjectivePanel.")
	_expect(prototype.phase_38.controls_panel == null or not prototype.phase_38.controls_panel.visible, "Controles F38 obsoletos siguen visibles.")

	if prototype.phase_38.full_session != null:
		_expect(prototype.phase_38.full_session.start_playing(), "No pudo iniciar PLAYING para validar HUD.")
		prototype._refresh(true)
		await get_tree().process_frame
		_expect(prototype.hud_root.visible, "HUD no se hizo visible durante PLAYING.")
		_expect(not prototype.top_label.text.is_empty(), "TopBar no muestra ronda/acciones/jugador activo.")
		_expect(not prototype.player_label.text.is_empty(), "Panel P1 no muestra informacion critica.")
		_expect(not prototype.objective_label.text.is_empty(), "Panel de objetivos/mision no muestra datos.")
		_expect(prototype.objective_label.text.contains("Marcador publico"), "HUD no expone el marcador publico de los cuatro participantes.")
		_expect(prototype.objective_label.text.contains("player_2"), "Marcador publico no incluye rivales.")
		_expect(not prototype._choice_data.is_empty(), "HUD no construyo ChoiceRequest para el turno humano inicial.")
		_expect(not prototype.choice_options.get_children().is_empty(), "ChoicePanel no tiene opciones interactivas.")
		var context_summary := prototype.hud_root.find_child("ContextSummary", true, false) as Label
		_expect(context_summary != null and context_summary.text.contains("Entrenador:"), "ContextStrip no expone Entrenador.")
		_expect(context_summary != null and context_summary.text.contains("Reserva:"), "ContextStrip no expone Karmany de reserva.")
		_expect(context_summary != null and context_summary.text.contains("Seleccion:"), "ContextStrip no expone loseta seleccionada.")
		_test_visual_reveal_gate(prototype)

	prototype.queue_free()
	await get_tree().process_frame


func _test_visual_reveal_gate(prototype: KarmanyPhase46PresentationSafeController) -> void:
	var session := prototype.phase_38.full_session
	if session == null or session.runtime == null:
		_expect(false, "No hay runtime para probar compuerta visual.")
		return
	var runtime := session.runtime
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if human == null:
		_expect(false, "P1 no disponible para probar compuerta visual.")
		return

	var hidden_coord := INVALID_COORD
	for coord in runtime.board_state.get_coords():
		if not runtime.board_state.is_revealed(coord):
			hidden_coord = coord
			break
	_expect(hidden_coord != INVALID_COORD, "No existe una loseta inicialmente oculta para probar la compuerta visual.")
	if hidden_coord == INVALID_COORD:
		return

	var original_coord: Vector2i = human.current_coord
	_expect(runtime.board_state.set_revealed(hidden_coord, true), "No pudo preparar revelacion logica adelantada de prueba.")
	var hidden_tile := runtime.get_public_tile_data(hidden_coord)
	human.current_coord = hidden_coord
	prototype._refresh(true)
	_expect(prototype.player_label.text.contains("Zona oculta"), "El HUD filtro identidad entre revelacion logica y visual.")
	if hidden_tile != null:
		_expect(not prototype.player_label.text.contains(hidden_tile.display_name), "El HUD mostro el nombre real antes de la compuerta visual.")
	_expect(prototype._choice_data.is_empty(), "El HUD expuso decisiones dependientes de una loseta aun no presentada.")
	prototype._on_inspect_tile()
	_expect(prototype.inspector.title == "Zona oculta", "El inspector permitio saltarse la compuerta visual.")

	human.current_coord = original_coord
	runtime.board_state.set_revealed(hidden_coord, false)
	prototype._refresh(true)


func _controls_overlap(a: Control, b: Control) -> bool:
	if a == null or b == null:
		return false
	return a.get_global_rect().intersects(b.get_global_rect())


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 46 HUD SCENE ERROR: %s" % message)
