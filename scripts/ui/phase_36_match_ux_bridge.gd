class_name KarmanyPhase36MatchUxBridge
extends Node3D


const INVALID_COORD: Vector2i = Vector2i(999, 999)

@onready var phase_35: KarmanyPhase35FourPlayerVisualBridge = $Phase35FourPlayerVisualPrototype

@onready var top_bar: PanelContainer = %TopBar
@onready var bottom_bar: PanelContainer = %BottomBar
@onready var board_space: Control = %BoardSpace
@onready var right_panel: PanelContainer = %RightPanel
@onready var right_scroll: ScrollContainer = %RightScroll

@onready var turn_label: Label = %TurnLabel
@onready var activity_label: Label = %ActivityLabel
@onready var participants_label: Label = %ParticipantsLabel
@onready var location_label: Label = %LocationLabel
@onready var selected_label: Label = %SelectedLabel
@onready var actions_label: Label = %ActionsLabel
@onready var action_reason_label: Label = %ActionReasonLabel
@onready var p3_debug_label: Label = %P3DebugLabel

@onready var move_button: Button = %MoveButton
@onready var explore_button: Button = %ExploreButton
@onready var interact_button: Button = %InteractButton
@onready var improve_button: Button = %ImproveButton
@onready var pass_button: Button = %PassButton
@onready var ai_button: Button = %AiButton
@onready var all_ai_button: Button = %AllAiButton
@onready var center_button: Button = %CenterButton

@onready var alpha_tools_toggle: CheckButton = %AlphaToolsToggle
@onready var alpha_tools_content: VBoxContainer = %AlphaToolsContent

var setup_ok: bool = false
var _latest_p3_diagnostic: Dictionary = {}
var _human_action_busy: bool = false


func _ready() -> void:
	if phase_35 == null or not phase_35.setup_ok or phase_35.phase_34 == null:
		push_error("FASE 36 ERROR: Fase 35 no esta disponible.")
		return

	var old_overlay := phase_35.get_node_or_null("Phase35Overlay") as CanvasLayer
	if old_overlay != null:
		old_overlay.visible = false

	alpha_tools_content.visible = alpha_tools_toggle.button_pressed
	_connect_runtime_signals()
	_connect_tile_selection()
	_connect_controls()
	_refresh_all()
	setup_ok = true
	print("FASE 36 UX OK - layout responsivo, tablero priorizado y controles fijos activos.")


func get_runtime() -> KarmanyMultiAiAlphaRuntime:
	if phase_35 == null or phase_35.phase_34 == null:
		return null
	return phase_35.phase_34.runtime


func get_selected_coord() -> Vector2i:
	var phase_31 := _get_phase_31()
	if phase_31 == null or phase_31.selected_tile == null:
		return INVALID_COORD
	return phase_31.selected_tile.coord


func get_location_summary(coord: Vector2i) -> String:
	var runtime := get_runtime()
	if runtime == null or not runtime.board_state.has_coord(coord):
		return "Sin ubicacion valida."

	var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(
		runtime.get_public_level(coord)
	)
	var occupants: PackedStringArray = PackedStringArray()
	for player in runtime.local_session.players:
		if player != null and phase_35.get_visual_coord(player.player_id) == coord:
			occupants.append(_short_player_id(player.player_id))
	var occupants_text: String = "ninguno" if occupants.is_empty() else ", ".join(occupants)

	# F35 mantiene una compuerta visual separada de la revelacion logica.
	# Se usa esa vista publica para no adelantar identidad durante un replay.
	var presentation_text: String = phase_35.get_public_location_text_for_coord(coord)
	var identity: String = "OCULTA"
	if not presentation_text.contains("OCULTA"):
		var tile: KarmanyTileData = runtime.get_public_tile_data(coord)
		identity = tile.display_name if tile != null else "Revelada"

	var public_elements: PackedStringArray = PackedStringArray()
	if runtime.board_state.has_beast(coord):
		var beast := runtime.board_state.get_beast(coord)
		if beast != null and beast.beast_data != null:
			public_elements.append("Bestia: %s" % beast.beast_data.display_name)
	if not occupants.is_empty():
		public_elements.append("Entrenadores: %s" % occupants_text)
	if public_elements.is_empty():
		public_elements.append("Sin elementos publicos adicionales")

	return "%s\nNivel %s | %s\nOcupantes: %s\n%s" % [
		identity,
		level_name,
		str(coord),
		occupants_text,
		" | ".join(public_elements)
	]


func get_p3_debug_text() -> String:
	return p3_debug_label.text if p3_debug_label != null else ""


func get_turn_text() -> String:
	return turn_label.text if turn_label != null else ""


func get_action_summary_text() -> String:
	return actions_label.text if actions_label != null else ""


func get_critical_controls() -> Array[Control]:
	var result: Array[Control] = []
	result.append(move_button)
	result.append(explore_button)
	result.append(interact_button)
	result.append(improve_button)
	result.append(pass_button)
	result.append(ai_button)
	result.append(all_ai_button)
	result.append(center_button)
	return result


func get_mandatory_info_controls() -> Array[Control]:
	var result: Array[Control] = []
	result.append(turn_label)
	result.append(activity_label)
	result.append(participants_label)
	result.append(location_label)
	result.append(selected_label)
	result.append(actions_label)
	return result


func set_alpha_tools_expanded(value: bool) -> void:
	alpha_tools_toggle.button_pressed = value
	alpha_tools_content.visible = value
	if not value:
		right_scroll.scroll_vertical = 0


func refresh_for_test() -> void:
	_refresh_all()


func _connect_runtime_signals() -> void:
	var runtime := get_runtime()
	if runtime == null:
		return
	var manager := runtime.local_session.turn_manager
	if not manager.turn_started.is_connected(_on_turn_state_changed):
		manager.turn_started.connect(_on_turn_state_changed)
	if not manager.action_spent.is_connected(_on_action_spent):
		manager.action_spent.connect(_on_action_spent)
	if not phase_35.visual_action_started.is_connected(_on_visual_action_started):
		phase_35.visual_action_started.connect(_on_visual_action_started)
	if not phase_35.visual_action_finished.is_connected(_on_visual_action_finished):
		phase_35.visual_action_finished.connect(_on_visual_action_finished)
	var ai_control := runtime.ai_match_controller
	if not ai_control.ai_decision_diagnostic.is_connected(_on_ai_decision_diagnostic):
		ai_control.ai_decision_diagnostic.connect(_on_ai_decision_diagnostic)


func _connect_tile_selection() -> void:
	var phase_31 := _get_phase_31()
	if phase_31 == null:
		return
	for coord_value in phase_31.get_level_map().keys():
		var coord: Vector2i = coord_value
		var tile := phase_31.get_tile_view(coord)
		if tile != null and not tile.tile_clicked.is_connected(_on_tile_clicked):
			tile.tile_clicked.connect(_on_tile_clicked)


func _connect_controls() -> void:
	if not move_button.pressed.is_connected(_on_move_pressed):
		move_button.pressed.connect(_on_move_pressed)
	if not explore_button.pressed.is_connected(_on_explore_pressed):
		explore_button.pressed.connect(_on_explore_pressed)
	if not interact_button.pressed.is_connected(_on_interact_pressed):
		interact_button.pressed.connect(_on_interact_pressed)
	if not improve_button.pressed.is_connected(_on_improve_pressed):
		improve_button.pressed.connect(_on_improve_pressed)
	if not pass_button.pressed.is_connected(_on_pass_pressed):
		pass_button.pressed.connect(_on_pass_pressed)
	if not ai_button.pressed.is_connected(_on_ai_pressed):
		ai_button.pressed.connect(_on_ai_pressed)
	if not all_ai_button.pressed.is_connected(_on_all_ai_pressed):
		all_ai_button.pressed.connect(_on_all_ai_pressed)
	if not center_button.pressed.is_connected(_on_center_pressed):
		center_button.pressed.connect(_on_center_pressed)
	if not alpha_tools_toggle.toggled.is_connected(_on_alpha_tools_toggled):
		alpha_tools_toggle.toggled.connect(_on_alpha_tools_toggled)


func _refresh_all() -> void:
	_refresh_turn()
	_refresh_participants()
	_refresh_location()
	_refresh_selected()
	_refresh_actions()
	_refresh_p3_debug()


func _refresh_turn() -> void:
	var runtime := get_runtime()
	if runtime == null:
		return
	var display_id: StringName = phase_35.get_display_active_player_id()
	if display_id == &"":
		var logical_active := runtime.local_session.turn_manager.get_active_player()
		if logical_active == null:
			turn_label.text = "Partida sin jugador activo"
			return
		display_id = logical_active.player_id
	turn_label.text = "RONDA %d  ·  %s  ·  ACCIONES %d/%d" % [
		phase_35.get_display_round_number(),
		_player_role(display_id),
		phase_35.get_display_actions_remaining(),
		KarmanyTurnManager.ACTIONS_PER_TURN
	]


func _refresh_participants() -> void:
	var runtime := get_runtime()
	if runtime == null:
		return
	var display_id: StringName = phase_35.get_display_active_player_id()
	var lines: PackedStringArray = PackedStringArray()
	for player in runtime.local_session.players:
		if player == null:
			continue
		var marker: String = "▶" if player.player_id == display_id else " "
		var coord: Vector2i = phase_35.get_visual_coord(player.player_id)
		var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(
			runtime.get_public_level(coord)
		)
		var points: int = runtime.local_session.get_player_legacy_points(player.player_id)
		lines.append("%s %s | %d PL | %s" % [
			marker,
			_player_role(player.player_id),
			points,
			level_name
		])
	participants_label.text = "\n".join(lines)


func _refresh_location() -> void:
	var runtime := get_runtime()
	if runtime == null:
		return
	var display_id: StringName = phase_35.get_display_active_player_id()
	var display_player := runtime.local_session.get_player_by_id(display_id)
	if display_player == null:
		location_label.text = "Sin jugador presentado."
		return
	location_label.text = "%s\n%s" % [
		_player_role(display_id),
		get_location_summary(phase_35.get_visual_coord(display_id))
	]


func _refresh_selected() -> void:
	var selected: Vector2i = get_selected_coord()
	if selected == INVALID_COORD:
		selected_label.text = "SELECCION: ninguna"
		return
	selected_label.text = "SELECCION\n%s" % get_location_summary(selected)


func _refresh_actions() -> void:
	var runtime := get_runtime()
	if runtime == null:
		return
	var manager := runtime.local_session.turn_manager
	var active := manager.get_active_player()
	var human_active: bool = (
		active != null
		and runtime.ai_match_controller.is_human_player(active.player_id)
		and not _human_action_busy
	)
	var ai_active: bool = (
		active != null
		and runtime.ai_match_controller.is_ai_player(active.player_id)
	)

	move_button.disabled = true
	explore_button.disabled = true
	interact_button.disabled = true
	improve_button.disabled = true
	pass_button.disabled = not human_active
	ai_button.disabled = not ai_active
	all_ai_button.disabled = not ai_active
	center_button.disabled = false

	if not human_active:
		actions_label.text = "ACCIONES HUMANAS: esperando turno P1"
		action_reason_label.text = (
			"Turno IA: usa IA actual o P2->P4 para observar sus decisiones."
			if ai_active
			else "Esperando estado de partida."
		)
		return

	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		active
	)
	var selected: Vector2i = get_selected_coord()
	var move_candidate := _find_target_candidate(
		candidates,
		KarmanyAiActionCandidate.ActionType.MOVE,
		selected
	)
	var explore_candidate := _find_target_candidate(
		candidates,
		KarmanyAiActionCandidate.ActionType.EXPLORE,
		selected
	)
	var interact_candidate := _find_first_candidate(
		candidates,
		KarmanyAiActionCandidate.ActionType.INTERACT
	)
	var improve_candidate := _find_first_candidate(
		candidates,
		KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK
	)

	move_button.disabled = move_candidate == null
	explore_button.disabled = explore_candidate == null
	interact_button.disabled = interact_candidate == null
	improve_button.disabled = improve_candidate == null

	var available: PackedStringArray = PackedStringArray()
	if _has_action_type(candidates, KarmanyAiActionCandidate.ActionType.MOVE):
		available.append("Mover")
	if _has_action_type(candidates, KarmanyAiActionCandidate.ActionType.EXPLORE):
		available.append("Explorar")
	if interact_candidate != null:
		available.append("Interactuar")
	if improve_candidate != null:
		available.append("Mejorar Libro")
	actions_label.text = "LEGALES AHORA: %s" % (
		", ".join(available) if not available.is_empty() else "ninguna"
	)

	var reasons: PackedStringArray = PackedStringArray()
	if selected == INVALID_COORD:
		reasons.append("Mover/Explorar: selecciona una loseta.")
	else:
		if move_candidate == null:
			reasons.append("Mover: destino seleccionado no legal.")
		if explore_candidate == null:
			reasons.append("Explorar: destino seleccionado no legal.")
	if interact_candidate == null:
		reasons.append("Interactuar: no hay Uso posterior legal aqui.")
	if improve_candidate == null:
		reasons.append("Libro: nivel/coste actual no permite mejorar.")
	if reasons.is_empty():
		reasons.append("Seleccion valida: elige una accion habilitada.")
	action_reason_label.text = " ".join(reasons)


func _refresh_p3_debug() -> void:
	if _latest_p3_diagnostic.is_empty():
		p3_debug_label.text = "DEBUG P3 OPORTUNISTA\nSin decision registrada todavia."
		return

	var before_value: Variant = _latest_p3_diagnostic.get("resources_before", {})
	var after_value: Variant = _latest_p3_diagnostic.get("resources_after", {})
	var before: Dictionary = {}
	var after: Dictionary = {}
	if before_value is Dictionary:
		before = before_value
	if after_value is Dictionary:
		after = after_value

	var mr_before: int = int(before.get(KarmanyEffectData.ResourceType.MR, 0))
	var mr_after: int = int(after.get(KarmanyEffectData.ResourceType.MR, 0))
	var score: float = float(_latest_p3_diagnostic.get("score", 0.0))
	var penalty: float = float(_latest_p3_diagnostic.get("repetition_penalty", 0.0))
	var marginal_text: String = "n/a"
	var utility_value: Variant = _latest_p3_diagnostic.get("resource_utility", {})
	if utility_value is Dictionary:
		var utility: Dictionary = utility_value
		var details_value: Variant = utility.get("resource_details", [])
		if details_value is Array:
			var details: Array = details_value
			if not details.is_empty() and details[0] is Dictionary:
				var detail: Dictionary = details[0]
				marginal_text = "%.2f (objetivo %d)" % [
					float(detail.get("value", 0.0)),
					int(detail.get("target", 0))
				]
	p3_debug_label.text = "DEBUG P3 OPORTUNISTA\n%s\nscore %.2f | penalizacion %.2f\nMR %d -> %d | valor marginal %s" % [
		String(_latest_p3_diagnostic.get("action_label", "sin accion")),
		score,
		penalty,
		mr_before,
		mr_after,
		marginal_text
	]


func _execute_human_candidate(action_type: int) -> bool:
	var runtime := get_runtime()
	if runtime == null or _human_action_busy:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return false
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		player
	)
	var selected: Vector2i = get_selected_coord()
	var candidate: KarmanyAiActionCandidate = null
	if (
		action_type == KarmanyAiActionCandidate.ActionType.MOVE
		or action_type == KarmanyAiActionCandidate.ActionType.EXPLORE
	):
		candidate = _find_target_candidate(candidates, action_type, selected)
	else:
		candidate = _find_first_candidate(candidates, action_type)
	if candidate == null:
		_refresh_actions()
		return false

	_human_action_busy = true
	var success: bool = false
	match action_type:
		KarmanyAiActionCandidate.ActionType.MOVE:
			success = runtime.coordinator.move_player(player, candidate.target_coord)
		KarmanyAiActionCandidate.ActionType.EXPLORE:
			success = runtime.coordinator.explore_player(player, candidate.target_coord)
		KarmanyAiActionCandidate.ActionType.INTERACT:
			var interaction := runtime.coordinator.interact_effect_option(
				player,
				candidate.option_index
			)
			success = interaction != null and interaction.is_success()
		KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK:
			var improvement := runtime.coordinator.improve_book(player)
			success = improvement != null and improvement.is_success()

	if success:
		activity_label.text = "P1: %s" % candidate.debug_label
		await phase_35.wait_for_presentation_idle()
		if manager.actions_remaining == 0 and manager.get_active_player() == player:
			runtime.coordinator.end_turn()
	_human_action_busy = false
	_refresh_all()
	return success


func _find_target_candidate(
	candidates: Array[KarmanyAiActionCandidate],
	action_type: int,
	target: Vector2i
) -> KarmanyAiActionCandidate:
	for candidate in candidates:
		if (
			candidate != null
			and candidate.action_type == action_type
			and candidate.target_coord == target
		):
			return candidate
	return null


func _find_first_candidate(
	candidates: Array[KarmanyAiActionCandidate],
	action_type: int
) -> KarmanyAiActionCandidate:
	for candidate in candidates:
		if candidate != null and candidate.action_type == action_type:
			return candidate
	return null


func _has_action_type(
	candidates: Array[KarmanyAiActionCandidate],
	action_type: int
) -> bool:
	return _find_first_candidate(candidates, action_type) != null


func _get_phase_31() -> KarmanyPhase31Map41Bridge:
	if phase_35 == null or phase_35.phase_34 == null:
		return null
	return phase_35.phase_34.phase_32.phase_31


func _player_role(player_id: StringName) -> String:
	var runtime := get_runtime()
	if runtime == null:
		return String(player_id)
	if runtime.ai_match_controller.is_human_player(player_id):
		return "%s HUMANO" % _short_player_id(player_id)
	return "%s %s" % [
		_short_player_id(player_id),
		runtime.ai_match_controller.get_ai_profile_name(player_id).to_upper()
	]


func _short_player_id(player_id: StringName) -> String:
	var text: String = String(player_id)
	return "P%s" % text.trim_prefix("player_") if text.begins_with("player_") else text


func _on_tile_clicked(_tile: KarmanyHexTile3D) -> void:
	call_deferred("_refresh_all")


func _on_turn_state_changed(
	_player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	call_deferred("_refresh_all")


func _on_action_spent(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	call_deferred("_refresh_all")


func _on_visual_action_started(
	player_id: StringName,
	action_text: String
) -> void:
	activity_label.text = (
		action_text
		if action_text.begins_with(_short_player_id(player_id))
		else "%s · %s" % [_short_player_id(player_id), action_text]
	)
	_refresh_turn()
	_refresh_participants()
	_refresh_location()


func _on_visual_action_finished(
	_player_id: StringName,
	_action_text: String
) -> void:
	_refresh_all()


func _on_ai_decision_diagnostic(
	player_id: StringName,
	diagnostic: Dictionary
) -> void:
	if player_id == &"player_3":
		_latest_p3_diagnostic = diagnostic.duplicate(true)
		_refresh_p3_debug()


func _on_alpha_tools_toggled(button_pressed: bool) -> void:
	alpha_tools_content.visible = button_pressed
	if not button_pressed:
		right_scroll.scroll_vertical = 0


func _on_move_pressed() -> void:
	await _execute_human_candidate(KarmanyAiActionCandidate.ActionType.MOVE)


func _on_explore_pressed() -> void:
	await _execute_human_candidate(KarmanyAiActionCandidate.ActionType.EXPLORE)


func _on_interact_pressed() -> void:
	await _execute_human_candidate(KarmanyAiActionCandidate.ActionType.INTERACT)


func _on_improve_pressed() -> void:
	await _execute_human_candidate(KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK)


func _on_pass_pressed() -> void:
	if _human_action_busy:
		return
	_human_action_busy = true
	await phase_35.wait_for_presentation_idle()
	phase_35.pass_human_turn_presented()
	_human_action_busy = false
	_refresh_all()


func _on_ai_pressed() -> void:
	await phase_35.run_current_ai_turn_presented()
	_refresh_all()


func _on_all_ai_pressed() -> void:
	await phase_35.run_all_ai_until_human_presented()
	_refresh_all()


func _on_center_pressed() -> void:
	phase_35.center_on_human()
