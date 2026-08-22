extends Node


var _failures: Array[String] = []


func _ready() -> void:
	await _test_scene_contract()
	if _failures.is_empty():
		print("FASE 46 HUD SCENE OK - HUD completo monta sobre F38, sustituye controles Alpha obsoletos y expone decisiones humanas reales.")
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
	var prototype := packed.instantiate() as KarmanyPhase46AlphaHudController
	if prototype == null:
		_failures.append("La escena F46 no instancia KarmanyPhase46AlphaHudController.")
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
	_expect(prototype.hud_root.find_child("TopBar", true, false) != null, "Falta TopBar.")
	_expect(prototype.hud_root.find_child("PlayerPanel", true, false) != null, "Falta PlayerPanel.")
	_expect(prototype.hud_root.find_child("ObjectivePanel", true, false) != null, "Falta ObjectivePanel.")
	_expect(prototype.hud_root.find_child("ChoicePanel", true, false) != null, "Falta ChoicePanel.")
	_expect(prototype.hud_root.find_child("Inspector", true, false) != null, "Falta Inspector modal.")
	_expect(prototype.phase_38.controls_panel == null or not prototype.phase_38.controls_panel.visible, "Controles F38 obsoletos siguen visibles.")

	if prototype.phase_38.full_session != null:
		_expect(prototype.phase_38.full_session.start_playing(), "No pudo iniciar PLAYING para validar HUD.")
		prototype._refresh(true)
		_expect(prototype.hud_root.visible, "HUD no se hizo visible durante PLAYING.")
		_expect(not prototype.top_label.text.is_empty(), "TopBar no muestra ronda/acciones/jugador activo.")
		_expect(not prototype.player_label.text.is_empty(), "Panel P1 no muestra informacion critica.")
		_expect(not prototype.objective_label.text.is_empty(), "Panel de objetivos/mision no muestra datos.")
		_expect(not prototype._choice_data.is_empty(), "HUD no construyo ChoiceRequest para el turno humano inicial.")
		_expect(not prototype.confirm_button.disabled or not prototype.choice_options.get_children().is_empty(), "ChoicePanel no tiene opciones interactivas.")

	prototype.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append("FASE 46 HUD SCENE ERROR: %s" % message)
