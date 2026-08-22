class_name KarmanyPhase46AlphaHudController
extends Node3D


@onready var phase_38: KarmanyPhase38FullMatchBridge = $Phase38FullMatchPrototype

var hud_bridge: KarmanyPhase46AlphaHudBridge = KarmanyPhase46AlphaHudBridge.new()
var choice_router: KarmanyPhase46ChoiceRouter = KarmanyPhase46ChoiceRouter.new()

var hud_layer: CanvasLayer = null
var hud_root: Control = null
var top_label: Label = null
var player_label: RichTextLabel = null
var objective_label: RichTextLabel = null
var event_label: RichTextLabel = null
var choice_prompt: Label = null
var choice_options: VBoxContainer = null
var replacement_options: HBoxContainer = null
var confirm_button: Button = null
var inspector: AcceptDialog = null

var _choice_data: Dictionary = {}
var _selected_option_ids: Array[StringName] = []
var _replacement_equipment_id: StringName = &""
var _last_snapshot_signature: String = ""
var _last_choice_signature: String = ""
var _refresh_accumulator: float = 0.0


func _ready() -> void:
	if phase_38 == null or phase_38.full_session == null:
		push_error("FASE 46 ERROR: F38/full_session no esta disponible.")
		return
	if not hud_bridge.configure(phase_38.full_session):
		push_error("FASE 46 ERROR: no se pudo configurar el read model del HUD.")
		return
	if not choice_router.configure(phase_38.full_session):
		push_error("FASE 46 ERROR: no se pudo configurar el router de decisiones.")
		return
	_disable_obsolete_alpha_hud()
	_build_hud()
	_connect_session_signals()
	_refresh(true)
	print("FASE 46 HUD READY - informacion critica y ChoiceRequests conectados al FullMatchSession.")


func _process(delta: float) -> void:
	if hud_root == null:
		return
	_refresh_accumulator += delta
	if _refresh_accumulator < 0.2:
		return
	_refresh_accumulator = 0.0
	_refresh(false)


func _disable_obsolete_alpha_hud() -> void:
	if phase_38.controls_panel != null:
		phase_38.controls_panel.visible = false
	var phase_36 := phase_38.phase_37.phase_36 if phase_38.phase_37 != null else null
	if phase_36 == null:
		return
	if phase_36.top_bar != null:
		phase_36.top_bar.visible = false
	if phase_36.bottom_bar != null:
		phase_36.bottom_bar.visible = false
	if phase_36.right_panel != null:
		phase_36.right_panel.visible = false


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "Phase46AlphaHudLayer"
	hud_layer.layer = 45
	add_child(hud_layer)

	hud_root = Control.new()
	hud_root.name = "Phase46AlphaHud"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(hud_root)

	_build_top_bar()
	_build_player_panel()
	_build_objective_panel()
	_build_choice_panel()
	_build_inspector()


func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.name = "TopBar"
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 12
	panel.offset_top = 8
	panel.offset_right = -12
	panel.offset_bottom = 54
	hud_root.add_child(panel)

	top_label = Label.new()
	top_label.name = "MatchState"
	top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_label.add_theme_font_size_override("font_size", 17)
	panel.add_child(top_label)


func _build_player_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "PlayerPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(12, 66)
	panel.size = Vector2(300, 395)
	hud_root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	var header := Label.new()
	header.text = "P1 · ESTADO DEL ENTRENADOR"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(header)

	player_label = RichTextLabel.new()
	player_label.name = "PlayerReadout"
	player_label.bbcode_enabled = true
	player_label.fit_content = false
	player_label.custom_minimum_size = Vector2(280, 215)
	content.add_child(player_label)

	var inspect_row := HBoxContainer.new()
	content.add_child(inspect_row)
	var tile_button := Button.new()
	tile_button.text = "Ver loseta"
	tile_button.tooltip_text = "Inspector de reglas de la zona actual."
	tile_button.pressed.connect(_on_inspect_tile)
	inspect_row.add_child(tile_button)
	var karmany_button := Button.new()
	karmany_button.text = "Ver Karmany"
	karmany_button.tooltip_text = "Inspector del Karmany activo."
	karmany_button.pressed.connect(_on_inspect_karmany)
	inspect_row.add_child(karmany_button)

	var hand_title := Label.new()
	hand_title.text = "Mano / Equipo"
	content.add_child(hand_title)
	var hand_scroll := ScrollContainer.new()
	hand_scroll.custom_minimum_size = Vector2(280, 105)
	content.add_child(hand_scroll)
	var hand_box := VBoxContainer.new()
	hand_box.name = "HandAndEquipmentButtons"
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_scroll.add_child(hand_box)


func _build_objective_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "ObjectivePanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-352, 66)
	panel.size = Vector2(340, 480)
	hud_root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	var title := Label.new()
	title.text = "OBJETIVOS · MERCADO · HISTORIAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	objective_label = RichTextLabel.new()
	objective_label.bbcode_enabled = true
	objective_label.fit_content = true
	objective_label.custom_minimum_size = Vector2(310, 180)
	box.add_child(objective_label)

	var market_title := Label.new()
	market_title.text = "Mercado visible · pulsa para inspeccionar"
	box.add_child(market_title)
	var market_box := VBoxContainer.new()
	market_box.name = "MarketButtons"
	box.add_child(market_box)

	var event_title := Label.new()
	event_title.text = "Ultimos eventos relevantes"
	box.add_child(event_title)
	event_label = RichTextLabel.new()
	event_label.fit_content = true
	event_label.custom_minimum_size = Vector2(310, 120)
	box.add_child(event_label)


func _build_choice_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "ChoicePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-430, -184)
	panel.size = Vector2(860, 172)
	hud_root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)

	choice_prompt = Label.new()
	choice_prompt.name = "ChoicePrompt"
	choice_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(choice_prompt)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(820, 78)
	content.add_child(scroll)
	choice_options = VBoxContainer.new()
	choice_options.name = "ChoiceOptions"
	choice_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(choice_options)

	replacement_options = HBoxContainer.new()
	replacement_options.name = "ReplacementOptions"
	content.add_child(replacement_options)

	confirm_button = Button.new()
	confirm_button.text = "CONFIRMAR DECISION"
	confirm_button.custom_minimum_size = Vector2(0, 32)
	confirm_button.pressed.connect(_on_confirm_choice)
	content.add_child(confirm_button)


func _build_inspector() -> void:
	inspector = AcceptDialog.new()
	inspector.name = "Inspector"
	inspector.title = "Inspector"
	inspector.dialog_text = ""
	inspector.min_size = Vector2i(540, 320)
	hud_root.add_child(inspector)


func _connect_session_signals() -> void:
	var session := phase_38.full_session
	if not session.state_changed.is_connected(_on_session_changed):
		session.state_changed.connect(_on_session_changed)
	if not session.full_action_resolved.is_connected(_on_action_resolved):
		session.full_action_resolved.connect(_on_action_resolved)
	if not session.alpha_log_event.is_connected(_on_log_event):
		session.alpha_log_event.connect(_on_log_event)
	var manager := session.runtime.local_session.turn_manager
	if not manager.turn_started.is_connected(_on_turn_changed):
		manager.turn_started.connect(_on_turn_changed)
	if not manager.action_spent.is_connected(_on_action_spent):
		manager.action_spent.connect(_on_action_spent)


func _refresh(force: bool) -> void:
	var snapshot := hud_bridge.get_snapshot()
	if snapshot.is_empty():
		return
	hud_root.visible = String(snapshot.get("match_state", "")) == "PLAYING"
	if not hud_root.visible:
		return

	var snapshot_signature := str(snapshot)
	if force or snapshot_signature != _last_snapshot_signature:
		_last_snapshot_signature = snapshot_signature
		_render_snapshot(snapshot)

	var new_choice := choice_router.get_pending_choice()
	var choice_signature := str(new_choice)
	if force or choice_signature != _last_choice_signature:
		_last_choice_signature = choice_signature
		_choice_data = new_choice
		_selected_option_ids.clear()
		_replacement_equipment_id = &""
		_render_choice()


func _render_snapshot(snapshot: Dictionary) -> void:
	var resources: Dictionary = snapshot.get("resources", {})
	top_label.text = "Ronda %d · Acciones %d · Activo: %s · %s" % [
		int(snapshot.get("round", 0)),
		int(snapshot.get("actions_remaining", 0)),
		String(snapshot.get("active_player_id", "-")),
		"TU TURNO" if bool(snapshot.get("is_human_turn", false)) else "Turno rival",
	]
	var zone: Dictionary = snapshot.get("zone", {})
	var karmany: Dictionary = snapshot.get("active_karmany", {})
	var effects: PackedStringArray = snapshot.get("visible_effects", PackedStringArray())
	player_label.text = (
		"[b]Recursos[/b]  MN %d · MR %d · EK %d · FA %d\n"
		+ "[b]PL[/b] %d   [b]Libro[/b] %d\n"
		+ "[b]Zona[/b] %s (%s) %s\n"
		+ "[b]Karmany activo[/b] %s · Poder %s\n"
		+ "[b]Efectos visibles[/b]\n%s"
	) % [
		int(resources.get("MN", 0)), int(resources.get("MR", 0)),
		int(resources.get("EK", 0)), int(resources.get("FA", 0)),
		int(snapshot.get("legacy_points", 0)), int(snapshot.get("book_level", 0)),
		String(zone.get("display_name", "?")), String(zone.get("level", "?")), str(snapshot.get("position", Vector2i.ZERO)),
		String(karmany.get("display_name", "Sin Karmany")), str(karmany.get("power", "-")),
		"\n".join(effects) if not effects.is_empty() else "Sin texto de efecto en la zona actual.",
	]
	_render_hand_equipment(snapshot)
	_render_objectives(snapshot)
	_render_market(snapshot)
	var event_lines: PackedStringArray = snapshot.get("recent_events", PackedStringArray())
	event_label.text = "\n".join(event_lines) if not event_lines.is_empty() else "Sin eventos aun."


func _render_hand_equipment(snapshot: Dictionary) -> void:
	var box := _find_named_container("HandAndEquipmentButtons")
	if box == null:
		return
	_clear_children(box)
	for row in snapshot.get("resonances", []):
		var button := Button.new()
		button.text = "R · %s (+%d)" % [String(row.get("display_name", "")), int(row.get("printed_power", 0))]
		button.tooltip_text = String(row.get("rules_text", ""))
		var resonance_id := StringName(row.get("resonance_id", ""))
		button.pressed.connect(func() -> void: _show_inspector(hud_bridge.inspect_resonance(resonance_id)))
		box.add_child(button)
	for row in snapshot.get("equipment", []):
		var button := Button.new()
		button.text = "E · %s [%s]" % [String(row.get("display_name", "")), String(row.get("rarity", ""))]
		button.tooltip_text = String(row.get("rules_text", ""))
		var equipment_id := StringName(row.get("equipment_id", ""))
		button.pressed.connect(func() -> void: _show_inspector(hud_bridge.inspect_equipment(equipment_id)))
		box.add_child(button)


func _render_objectives(snapshot: Dictionary) -> void:
	var lines := PackedStringArray()
	lines.append("[b]Objetivos publicos[/b]")
	for row in snapshot.get("public_objectives", []):
		var status := "COBRADO por %s" % String(row.get("claimed_by", "")) if bool(row.get("claimed", false)) else "Disponible"
		lines.append("• %s — %s — +%d PL\n  %s" % [
			String(row.get("display_name", "")), status, int(row.get("reward_pl", 0)), String(row.get("condition_text", "")),
		])
	var mission: Dictionary = snapshot.get("secret_mission", {})
	lines.append("\n[b]Mision secreta P1[/b]")
	if mission.is_empty():
		lines.append("Sin mision visible.")
	else:
		lines.append("%s · %s · +%d PL\n%s" % [
			String(mission.get("display_name", "")),
			"COMPLETADA" if bool(mission.get("completed", false)) else "Activa",
			int(mission.get("reward_pl", 0)),
			String(mission.get("condition_text", "")),
		])
	objective_label.text = "\n".join(lines)


func _render_market(snapshot: Dictionary) -> void:
	var box := _find_named_container("MarketButtons")
	if box == null:
		return
	_clear_children(box)
	for row in snapshot.get("market", []):
		var button := Button.new()
		button.text = "%s · %s · %s" % [
			String(row.get("display_name", "")), String(row.get("rarity", "")), String(row.get("cost", "-")),
		]
		button.tooltip_text = String(row.get("rules_text", ""))
		var equipment_id := StringName(row.get("equipment_id", ""))
		button.pressed.connect(func() -> void: _show_inspector(hud_bridge.inspect_equipment(equipment_id)))
		box.add_child(button)


func _render_choice() -> void:
	_clear_children(choice_options)
	_clear_children(replacement_options)
	if _choice_data.is_empty():
		choice_prompt.text = "Esperando turno o resolucion del sistema."
		confirm_button.disabled = true
		return
	choice_prompt.text = String(_choice_data.get("prompt", "Elige una opcion"))
	for row in _choice_data.get("options", []):
		var option_id := StringName(row.get("option_id", ""))
		if option_id == &"":
			continue
		var button := Button.new()
		button.text = String(row.get("label", String(option_id)))
		button.tooltip_text = String(row.get("detail", ""))
		button.pressed.connect(func() -> void: _toggle_choice_option(option_id))
		choice_options.add_child(button)
	if bool(_choice_data.get("requires_equipment_replacement", false)):
		var label := Label.new()
		label.text = "Si eliges Equipo y tienes 3: reemplazar"
		replacement_options.add_child(label)
		for equipment_id_value in _choice_data.get("replacement_equipment_ids", []):
			var equipment_id := StringName(equipment_id_value)
			var button := Button.new()
			button.text = String(equipment_id)
			button.pressed.connect(func() -> void:
				_replacement_equipment_id = equipment_id
				_update_choice_controls()
			)
			replacement_options.add_child(button)
	_update_choice_controls()


func _toggle_choice_option(option_id: StringName) -> void:
	var required: int = int(_choice_data.get("required_count", 1))
	var allow_repeated: bool = bool(_choice_data.get("allow_repeated_options", false))
	if not allow_repeated and _selected_option_ids.has(option_id):
		_selected_option_ids.erase(option_id)
	elif required == 1:
		_selected_option_ids.clear()
		_selected_option_ids.append(option_id)
	elif _selected_option_ids.size() < required:
		if allow_repeated:
			var max_count: int = _get_option_available_count(option_id)
			if _selected_option_ids.count(option_id) < max_count:
				_selected_option_ids.append(option_id)
		elif not _selected_option_ids.has(option_id):
			_selected_option_ids.append(option_id)
	_update_choice_controls()


func _get_option_available_count(option_id: StringName) -> int:
	for row in _choice_data.get("options", []):
		if StringName(row.get("option_id", "")) == option_id:
			return int(row.get("available_count", 1))
	return 1


func _update_choice_controls() -> void:
	var required: int = int(_choice_data.get("required_count", 1))
	var valid: bool = _selected_option_ids.size() == required
	if valid and int(_choice_data.get("kind", -1)) == KarmanyPhase46ChoiceRouter.ChoiceKind.AETERNA_REWARD:
		var selected := String(_selected_option_ids[0]) if not _selected_option_ids.is_empty() else ""
		if selected.begins_with(KarmanyAeternaRewardChoiceRequest.EQUIPMENT_PREFIX):
			valid = (not bool(_choice_data.get("requires_equipment_replacement", false))) or _replacement_equipment_id != &""
	confirm_button.disabled = not valid
	confirm_button.text = "CONFIRMAR DECISION (%d/%d)" % [_selected_option_ids.size(), required]


func _on_confirm_choice() -> void:
	if _choice_data.is_empty() or confirm_button.disabled:
		return
	var kind: int = int(_choice_data.get("kind", KarmanyPhase46ChoiceRouter.ChoiceKind.NONE))
	var selected: Array[StringName] = []
	selected.assign(_selected_option_ids)
	var success := choice_router.resolve_choice(kind, selected, _replacement_equipment_id)
	if not success:
		choice_prompt.text = "Decision rechazada por el estado actual. Revisa la seleccion."
		return
	_choice_data.clear()
	_selected_option_ids.clear()
	_replacement_equipment_id = &""
	_last_choice_signature = ""
	_refresh(true)


func _on_inspect_tile() -> void:
	_show_inspector(hud_bridge.inspect_current_tile())


func _on_inspect_karmany() -> void:
	_show_inspector(hud_bridge.inspect_active_karmany())


func _show_inspector(data: Dictionary) -> void:
	if inspector == null or data.is_empty():
		return
	inspector.title = String(data.get("title", "Inspector"))
	inspector.dialog_text = "%s\n\n%s" % [String(data.get("subtitle", "")), String(data.get("body", ""))]
	inspector.popup_centered()


func _find_named_container(node_name: String) -> VBoxContainer:
	if hud_root == null:
		return null
	return hud_root.find_child(node_name, true, false) as VBoxContainer


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _on_session_changed(_state: int) -> void:
	_refresh(true)


func _on_action_resolved(_player_id: StringName, _label: String, _success: bool) -> void:
	_refresh(true)


func _on_log_event(_message: String) -> void:
	_refresh(true)


func _on_turn_changed(_player: KarmanyPlayerState, _round: int, _actions: int) -> void:
	_refresh(true)


func _on_action_spent(_player: KarmanyPlayerState, _cost: int, _remaining: int) -> void:
	_refresh(true)
