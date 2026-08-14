class_name KarmanyPhase38ResonanceChoicePanel
extends Node


var phase_38: KarmanyPhase38FullMatchBridge = null
var selector: OptionButton = null
var resolve_button: Button = null
var _resonance_id_by_index: Dictionary = {}


func _ready() -> void:
	call_deferred("_build_panel")


func _build_panel() -> void:
	phase_38 = get_parent() as KarmanyPhase38FullMatchBridge
	if phase_38 == null or phase_38.full_session == null or phase_38.controls_panel == null:
		push_error("FASE 38 ERROR: selector de Resonancias no pudo encontrar la sesion completa.")
		return
	var row := phase_38.controls_panel.get_child(0) as HBoxContainer
	if row == null:
		push_error("FASE 38 ERROR: controles de combate no disponibles para selector de Resonancias.")
		return

	# F38 agrega dos controles al bar Alpha de F36/F37. En la escena de prueba
	# objetivo 1152x648, 1100 px deja margen lateral sin crear un segundo HUD.
	phase_38.controls_panel.position = Vector2(-550.0, -78.0)
	phase_38.controls_panel.size = Vector2(1100.0, 70.0)

	selector = OptionButton.new()
	selector.name = "Phase38ResonanceSelector"
	selector.custom_minimum_size = Vector2(154, 0)
	selector.tooltip_text = "Elige una Resonancia de combate digitalmente soportada. Las cartas solo textuales no se ofrecen para no fingir efectos."
	row.add_child(selector)

	resolve_button = Button.new()
	resolve_button.name = "Phase38ChosenCombatButton"
	resolve_button.text = "Combatir + carta"
	resolve_button.tooltip_text = "Resuelve el combate legal usando exactamente la Resonancia seleccionada, o ninguna."
	resolve_button.pressed.connect(_on_resolve_pressed)
	row.add_child(resolve_button)

	if phase_38.action_label != null:
		row.move_child(selector, phase_38.action_label.get_index())
		row.move_child(resolve_button, phase_38.action_label.get_index())
	if phase_38.combat_button != null:
		phase_38.combat_button.text = "Combatir (auto)"
		phase_38.combat_button.tooltip_text = "Deja que el controlador Alpha elija una Resonancia soportada. Usa Combatir + carta para elegir manualmente."

	var session := phase_38.full_session
	if not session.state_changed.is_connected(_on_session_changed):
		session.state_changed.connect(_on_session_changed)
	if not session.full_action_resolved.is_connected(_on_full_action_resolved):
		session.full_action_resolved.connect(_on_full_action_resolved)
	var manager := session.runtime.local_session.turn_manager
	if not manager.turn_started.is_connected(_on_turn_started):
		manager.turn_started.connect(_on_turn_started)
	if not manager.action_spent.is_connected(_on_action_spent):
		manager.action_spent.connect(_on_action_spent)
	_refresh()


func _refresh() -> void:
	if selector == null or resolve_button == null or phase_38 == null or phase_38.full_session == null:
		return
	var session := phase_38.full_session
	var manager := session.runtime.local_session.turn_manager
	var active := manager.get_active_player() if manager != null else null
	var human_turn: bool = (
		session.match_state == KarmanyFullMatchSessionBase.MatchState.PLAYING
		and manager != null
		and manager.is_running
		and active != null
		and session.runtime.ai_match_controller.is_human_player(active.player_id)
		and not phase_38._auto_match_busy
	)

	var previous_id: StringName = get_selected_resonance_id()
	selector.clear()
	_resonance_id_by_index.clear()
	selector.add_item("Sin Resonancia")
	_resonance_id_by_index[0] = &""
	for card in session.get_human_supported_combat_resonances():
		if card == null:
			continue
		var index: int = selector.item_count
		selector.add_item("%s (+%d)" % [card.display_name, card.printed_power])
		_resonance_id_by_index[index] = card.resonance_id
		if card.resonance_id == previous_id:
			selector.select(index)

	selector.disabled = not human_turn
	resolve_button.disabled = not human_turn


func get_selected_resonance_id() -> StringName:
	if selector == null or selector.item_count <= 0:
		return &""
	return StringName(_resonance_id_by_index.get(selector.selected, ""))


func _on_resolve_pressed() -> void:
	if phase_38 == null or phase_38.full_session == null:
		return
	var resonance_id: StringName = get_selected_resonance_id()
	var success: bool = phase_38.full_session.execute_human_combat_with_resonance(
		resonance_id
	)
	if phase_38.action_label != null:
		phase_38.action_label.text = (
			"Combate resuelto con %s." % (
				"sin Resonancia" if resonance_id == &"" else String(resonance_id)
			)
			if success
			else "No existe un combate legal compatible con la seleccion."
		)
	phase_38._refresh_ui()
	_refresh()


func _on_session_changed(_state_value: int) -> void:
	call_deferred("_refresh")


func _on_full_action_resolved(
	_player_id: StringName,
	_action_text: String,
	_success: bool
) -> void:
	call_deferred("_refresh")


func _on_turn_started(
	_player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	call_deferred("_refresh")


func _on_action_spent(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	call_deferred("_refresh")
