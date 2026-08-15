class_name KarmanyPhase41HumanSetupBridge
extends KarmanyPhase38FullMatchBridge


var setup_ok: bool = false
var human_setup: KarmanyHumanSetupFlow = null

var status_label: Label = null
var trainer_label: Label = null
var candidate_grid: GridContainer = null
var candidate_panels: Array[PanelContainer] = []
var candidate_select_buttons: Array[Button] = []
var objectives_label: Label = null
var mission_label: Label = null
var hand_label: Label = null
var pending_bonus_label: Label = null
var confirm_button: Button = null
var scroll: ScrollContainer = null


func _ready() -> void:
	if phase_37 == null or not phase_37.setup_ok:
		push_error("FASE 41 ERROR: F37 no esta disponible como baseline visual.")
		return
	var runtime := phase_37.get_runtime()
	if runtime == null:
		push_error("FASE 41 ERROR: runtime base no disponible.")
		return

	human_setup = KarmanyHumanSetupFlow.new()
	if not human_setup.configure(runtime):
		push_error("FASE 41 ERROR: %s" % human_setup.last_error)
		return

	_build_phase41_setup_overlay()
	_build_match_controls()
	_build_result_overlay()
	_disable_obsolete_debug_controls()
	controls_panel.visible = false
	_set_gameplay_enabled(false)
	_refresh_phase41_setup()
	setup_ok = true
	print("FASE 41 UX OK - setup humano privado preparado antes de PLAYING.")


func get_human_setup() -> KarmanyHumanSetupFlow:
	return human_setup


func _build_phase41_setup_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Phase41SetupLayer"
	layer.layer = 60
	add_child(layer)

	setup_overlay = Control.new()
	setup_overlay.name = "Phase41SetupOverlay"
	setup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(setup_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.035, 0.055, 0.98)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_overlay.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	setup_overlay.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 54)
	root.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)
	var title := Label.new()
	title.text = "KARMANY MONSTA · PREPARACION DE PARTIDA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	header_row.add_child(title)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size = Vector2(300, 0)
	status_label.add_theme_font_size_override("font_size", 13)
	header_row.add_child(status_label)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	var trainer_panel := PanelContainer.new()
	content.add_child(trainer_panel)
	trainer_label = _new_wrapped_label(12)
	trainer_label.custom_minimum_size = Vector2(0, 92)
	trainer_panel.add_child(trainer_label)

	var choice_title := Label.new()
	choice_title.text = "TU DECISION PRIVADA · REVELA 3 KARMANY INICIALES Y CONSERVA 1"
	choice_title.add_theme_font_size_override("font_size", 15)
	content.add_child(choice_title)

	candidate_grid = GridContainer.new()
	candidate_grid.columns = 3
	candidate_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	candidate_grid.add_theme_constant_override("h_separation", 8)
	content.add_child(candidate_grid)
	_build_candidate_cards()

	var private_title := Label.new()
	private_title.text = "INFORMACION DE PARTIDA"
	private_title.add_theme_font_size_override("font_size", 15)
	content.add_child(private_title)

	var private_grid := GridContainer.new()
	private_grid.columns = 2
	private_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_grid.add_theme_constant_override("h_separation", 8)
	private_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(private_grid)

	var objectives_panel := PanelContainer.new()
	objectives_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_grid.add_child(objectives_panel)
	objectives_label = _new_wrapped_label(11)
	objectives_label.custom_minimum_size = Vector2(0, 110)
	objectives_panel.add_child(objectives_label)

	var mission_panel := PanelContainer.new()
	mission_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_grid.add_child(mission_panel)
	mission_label = _new_wrapped_label(11)
	mission_label.custom_minimum_size = Vector2(0, 110)
	mission_panel.add_child(mission_label)

	var hand_panel := PanelContainer.new()
	hand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_grid.add_child(hand_panel)
	hand_label = _new_wrapped_label(11)
	hand_label.custom_minimum_size = Vector2(0, 120)
	hand_panel.add_child(hand_label)

	var pending_panel := PanelContainer.new()
	pending_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_grid.add_child(pending_panel)
	pending_bonus_label = _new_wrapped_label(11)
	pending_bonus_label.custom_minimum_size = Vector2(0, 120)
	pending_panel.add_child(pending_bonus_label)

	var footer := PanelContainer.new()
	footer.custom_minimum_size = Vector2(0, 58)
	root.add_child(footer)
	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	footer.add_child(footer_row)
	var hint := Label.new()
	hint.text = "Selecciona una opcion, comparala y confirma. La partida no consume acciones durante SETUP."
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_row.add_child(hint)

	confirm_button = Button.new()
	confirm_button.text = "CONFIRMAR KARMANY"
	confirm_button.custom_minimum_size = Vector2(190, 42)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_confirm_candidate_pressed)
	footer_row.add_child(confirm_button)

	start_button = Button.new()
	start_button.text = "INICIAR PARTIDA · RONDA 1"
	start_button.custom_minimum_size = Vector2(210, 42)
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	footer_row.add_child(start_button)


func _build_candidate_cards() -> void:
	candidate_panels.clear()
	candidate_select_buttons.clear()
	var candidates := human_setup.get_human_starting_candidates(human_setup.runtime.human_player_id)
	for index in range(candidates.size()):
		var candidate: KarmanyData = candidates[index]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(270, 225)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		candidate_grid.add_child(panel)
		candidate_panels.append(panel)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		panel.add_child(box)
		var marker := Label.new()
		marker.text = "MARCADOR ALPHA · %s" % String(candidate.karmany_id)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 11)
		box.add_child(marker)
		var name_label := Label.new()
		name_label.text = candidate.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 17)
		box.add_child(name_label)
		var stats := _new_wrapped_label(11)
		stats.text = "Poder %d · %s\n%s" % [
			candidate.power,
			candidate.get_primary_type_label(),
			_format_candidate_abilities(candidate)
		]
		stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(stats)
		var select_button := Button.new()
		select_button.text = "SELECCIONAR"
		select_button.custom_minimum_size = Vector2(0, 34)
		select_button.pressed.connect(_on_candidate_pressed.bind(index))
		box.add_child(select_button)
		candidate_select_buttons.append(select_button)


func _new_wrapped_label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _format_candidate_abilities(candidate: KarmanyData) -> String:
	if candidate == null or candidate.abilities.is_empty():
		return "Sin habilidad adicional materializada."
	var lines: PackedStringArray = PackedStringArray()
	for ability in candidate.abilities:
		if ability == null:
			continue
		var ability_name: String = ability.display_name if not ability.display_name.is_empty() else String(ability.ability_id)
		lines.append("%s: %s" % [ability_name, ability.rules_text])
	return "\n".join(lines)


func _on_candidate_pressed(candidate_index: int) -> void:
	if human_setup == null or not human_setup.select_starting_candidate(candidate_index):
		return
	_refresh_phase41_setup()


func _on_confirm_candidate_pressed() -> void:
	if human_setup == null or not human_setup.confirm_starting_candidate():
		status_label.text = "SETUP · selecciona una opcion valida antes de confirmar."
		return
	full_session = human_setup.get_full_session()
	if full_session == null:
		status_label.text = "SETUP · error al materializar la partida completa."
		return
	_connect_full_match_signals()
	_spawn_resonance_choice_panel()
	_refresh_phase41_setup()
	_refresh_ui()


func _spawn_resonance_choice_panel() -> void:
	if get_node_or_null("Phase41ResonanceChoicePanel") != null:
		return
	var panel := KarmanyPhase38ResonanceChoicePanel.new()
	panel.name = "Phase41ResonanceChoicePanel"
	add_child(panel)


func _on_start_pressed() -> void:
	if human_setup == null or not human_setup.start_playing():
		if status_label != null:
			status_label.text = "SETUP · confirma primero tu Karmany inicial."
		return
	setup_overlay.visible = false
	controls_panel.visible = true
	_set_gameplay_enabled(true)
	_refresh_ui()
	phase_37.refresh_preview()
	print("FASE 41 PLAYING - Ronda 1 iniciada con P1 y 2 acciones.")


func _refresh_phase41_setup() -> void:
	if human_setup == null:
		return
	var human_id: StringName = human_setup.runtime.human_player_id
	var trainer := human_setup.get_human_trainer(human_id)
	if trainer != null:
		trainer_label.text = "ENTRENADOR ASIGNADO POR SEED · %s — %s\nPasiva: %s\nActiva: %s\nSetup: %s" % [
			trainer.display_name,
			trainer.title,
			trainer.passive_text,
			trainer.active_text,
			trainer.setup_bonus_text
		]
		pending_bonus_label.text = "BONIFICACION DE ENTRENADOR\n%s\n%s" % [
			trainer.setup_bonus_text,
			human_setup.get_trainer_setup_automation_note(trainer)
		]

	for index in range(candidate_select_buttons.size()):
		var button: Button = candidate_select_buttons[index]
		var selected: bool = index == human_setup.selected_candidate_index
		button.text = "SELECCIONADO ✓" if selected else "SELECCIONAR"
		button.disabled = human_setup.confirmed
		if index < candidate_panels.size():
			candidate_panels[index].modulate = Color(0.78, 1.0, 0.82, 1.0) if selected else Color.WHITE

	confirm_button.disabled = human_setup.selected_candidate_index < 0 or human_setup.confirmed
	start_button.disabled = not human_setup.is_ready_to_play()

	if not human_setup.confirmed:
		status_label.text = "SETUP · TurnManager detenido · elige 1 de 3"
		objectives_label.text = "OBJETIVOS PUBLICOS\nSe revelan al completar el setup."
		mission_label.text = "TU MISION SECRETA\nSe mostrara de forma privada despues de confirmar tu Karmany."
		hand_label.text = "TU MANO INICIAL DE RESONANCIAS\nSe repartira despues de confirmar. Las manos de P2-P4 no se muestran."
		return

	status_label.text = "SETUP LISTO · revisa tu informacion privada y comienza Ronda 1"
	var objective_lines: PackedStringArray = PackedStringArray(["OBJETIVOS PUBLICOS"])
	for objective in human_setup.get_public_objectives():
		if objective != null:
			objective_lines.append("• %s · %s · %d PL" % [
				objective.display_name,
				objective.condition_text,
				objective.reward_legacy_points
			])
	objectives_label.text = "\n".join(objective_lines)

	var mission := human_setup.get_private_mission_for_viewer(human_id, human_id)
	mission_label.text = (
		"TU MISION SECRETA\n%s\n%s\nRecompensa: %d PL" % [
			mission.display_name,
			mission.condition_text,
			mission.reward_legacy_points
		]
		if mission != null
		else "TU MISION SECRETA\nNo disponible."
	)

	var hand_lines: PackedStringArray = PackedStringArray(["TU MANO INICIAL DE RESONANCIAS"])
	for card in human_setup.get_private_resonance_hand_for_viewer(human_id, human_id):
		if card != null:
			hand_lines.append("• %s · %s · Poder %d" % [
				String(card.resonance_id),
				card.display_name,
				card.printed_power
			])
	hand_label.text = "\n".join(hand_lines)


func _set_gameplay_enabled(enabled: bool) -> void:
	# Conserva la autoridad de F38/F39 una vez existe full_session. Durante
	# SETUP, ademas del overlay, TurnManager esta detenido por KarmanyHumanSetupFlow.
	super(enabled)
