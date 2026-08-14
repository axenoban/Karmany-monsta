class_name KarmanyPhase39UniversalTileInteractionBridge
extends Node3D


@onready var phase_38: KarmanyPhase38FullMatchBridge = $Phase38FullMatchPrototype

var panel: PanelContainer = null
var selected_label: Label = null
var requirements_label: Label = null
var option_selector: OptionButton = null
var status_label: Label = null

var _current_candidates: Array[KarmanyAiActionCandidate] = []
var _last_signature: String = ""
var setup_ok: bool = false


func _ready() -> void:
	if phase_38 == null or phase_38.full_session == null:
		push_error("FASE 39 ERROR: F38 aprobado no esta disponible.")
		return
	var service := phase_38.full_session.universal_tile_interactions
	if service == null or not service.is_configured():
		push_error("FASE 39 ERROR: fuente universal de Interactuar no configurada.")
		return
	_build_panel()
	_take_over_interact_button()
	_refresh(true)
	setup_ok = true
	print("FASE 39 UX OK - Uso posterior, requisitos y opciones de Interactuar visibles.")


func _process(_delta: float) -> void:
	if setup_ok:
		_refresh(false)


func get_selected_interaction_text() -> String:
	return selected_label.text if selected_label != null else ""


func get_requirements_text() -> String:
	return requirements_label.text if requirements_label != null else ""


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Phase39InteractionLayer"
	layer.layer = 38
	add_child(layer)

	panel = PanelContainer.new()
	panel.name = "Phase39InteractionPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-390, 96)
	panel.size = Vector2(370, 260)
	layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var title := Label.new()
	title.text = "FASE 39 · INTERACCION UNIVERSAL"
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)

	selected_label = Label.new()
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_label.custom_minimum_size = Vector2(340, 70)
	column.add_child(selected_label)

	requirements_label = Label.new()
	requirements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirements_label.custom_minimum_size = Vector2(340, 70)
	column.add_child(requirements_label)

	option_selector = OptionButton.new()
	option_selector.tooltip_text = "Opciones legales de Uso posterior en la loseta donde se encuentra P1."
	option_selector.item_selected.connect(_on_option_selected)
	column.add_child(option_selector)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 11)
	column.add_child(status_label)


func _take_over_interact_button() -> void:
	var phase_36 := phase_38.phase_37.phase_36
	if phase_36 == null or phase_36.interact_button == null:
		return
	var old_handler := Callable(phase_36, "_on_interact_pressed")
	if phase_36.interact_button.pressed.is_connected(old_handler):
		phase_36.interact_button.pressed.disconnect(old_handler)
	if not phase_36.interact_button.pressed.is_connected(_on_interact_pressed):
		phase_36.interact_button.pressed.connect(_on_interact_pressed)
	phase_36.interact_button.tooltip_text = "F39: ejecuta la opcion de Uso posterior seleccionada."


func _refresh(force: bool) -> void:
	if phase_38 == null or phase_38.full_session == null:
		return
	var session := phase_38.full_session
	var runtime := session.runtime
	var manager := runtime.local_session.turn_manager
	var active := manager.get_active_player() if manager != null else null
	var phase_37 := phase_38.phase_37
	var phase_36 := phase_37.phase_36 if phase_37 != null else null
	var selected: Vector2i = (
		phase_36.get_selected_coord()
		if phase_36 != null
		else KarmanyPhase37ContentPreviewBridge.INVALID_COORD
	)
	if selected == KarmanyPhase37ContentPreviewBridge.INVALID_COORD and active != null:
		selected = active.current_coord
	var signature := "%s|%d|%d|%s|%s" % [
		String(active.player_id) if active != null else "-",
		manager.current_round if manager != null else 0,
		manager.actions_remaining if manager != null else 0,
		str(selected),
		String(session.match_state)
	]
	if not force and signature == _last_signature:
		return
	_last_signature = signature

	var human_active: bool = (
		active != null
		and manager != null
		and manager.is_running
		and session.match_state == KarmanyFullMatchSession.MatchState.PLAYING
		and runtime.ai_match_controller.is_human_player(active.player_id)
	)
	var preview := session.universal_tile_interactions.get_public_preview(
		active if human_active else null,
		selected
	)
	if not bool(preview.get("visible", false)):
		selected_label.text = "INTERACTUAR\nOCULTA"
		requirements_label.text = "REQUISITOS / LIMITACIONES\nLa identidad y el Uso posterior permanecen ocultos."
	else:
		selected_label.text = "INTERACTUAR\n%s" % String(
			preview.get("interaction_text", "")
		)
		requirements_label.text = "REQUISITOS / LIMITACIONES\n%s" % String(
			preview.get("requirements_text", "")
		)

	_refresh_current_options(active if human_active else null)
	if phase_37 != null and phase_37.interact_preview_label != null:
		phase_37.interact_preview_label.text = "%s\n\n%s" % [
			selected_label.text,
			requirements_label.text
		]
	if phase_36 != null and phase_36.interact_button != null:
		phase_36.interact_button.disabled = not human_active or _current_candidates.is_empty()


func _refresh_current_options(player: KarmanyPlayerState) -> void:
	var previous_key: StringName = _selected_key()
	_current_candidates.clear()
	option_selector.clear()
	if player == null:
		option_selector.add_item("Sin opciones legales")
		option_selector.disabled = true
		status_label.text = "Interactuar se habilita durante el turno humano cuando exista una opcion legal."
		return

	for candidate in phase_38.full_session.universal_tile_interactions.build_legal_candidates(player):
		if candidate == null:
			continue
		_current_candidates.append(candidate)
		option_selector.add_item(candidate.debug_label.trim_prefix("Interactuar · "))
	if _current_candidates.is_empty():
		option_selector.add_item("Sin opciones legales")
		option_selector.disabled = true
		status_label.text = "No se ofrece una accion que el executor conozca de antemano que sera rechazada."
		return
	option_selector.disabled = false
	var selected_index: int = 0
	for index in range(_current_candidates.size()):
		var key: StringName = StringName(
			_current_candidates[index].payload.get(
				KarmanyUniversalTileInteractionService.PAYLOAD_KEY,
				""
			)
		)
		if key == previous_key:
			selected_index = index
			break
	option_selector.select(selected_index)
	status_label.text = "%d opcion(es) legal(es) en la loseta actual." % _current_candidates.size()


func _selected_key() -> StringName:
	if option_selector == null or option_selector.selected < 0:
		return &""
	var index: int = option_selector.selected
	if index < 0 or index >= _current_candidates.size():
		return &""
	return StringName(
		_current_candidates[index].payload.get(
			KarmanyUniversalTileInteractionService.PAYLOAD_KEY,
			""
		)
	)


func _on_option_selected(_index: int) -> void:
	_refresh(true)


func _on_interact_pressed() -> void:
	if phase_38 == null or phase_38.full_session == null:
		return
	var session := phase_38.full_session
	var manager := session.runtime.local_session.turn_manager
	var player := manager.get_active_player() if manager != null else null
	if (
		player == null
		or not session.runtime.ai_match_controller.is_human_player(player.player_id)
		or _current_candidates.is_empty()
	):
		_refresh(true)
		return
	var index: int = option_selector.selected
	if index < 0 or index >= _current_candidates.size():
		index = 0
	var candidate := _current_candidates[index]
	var execution := KarmanyAiActionExecutor.execute(
		session.runtime.coordinator,
		player,
		candidate
	)
	var success: bool = execution != null and execution.was_executed()
	status_label.text = (
		"Interaccion resuelta: %s" % candidate.debug_label
		if success
		else "La interaccion cambio de estado antes de ejecutarse y fue rechazada de forma segura."
	)
	if success:
		session.full_action_resolved.emit(
			player.player_id,
			candidate.debug_label,
			true
		)
	_refresh(true)
