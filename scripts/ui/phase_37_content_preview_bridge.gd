class_name KarmanyPhase37ContentPreviewBridge
extends Node3D


const INVALID_COORD: Vector2i = Vector2i(999, 999)

@onready var phase_36: KarmanyPhase36MatchUxBridge = $Phase36MatchUxPrototype

var setup_ok: bool = false
var preview_section: VBoxContainer = null
var selected_preview_label: Label = null
var move_preview_label: Label = null
var interact_preview_label: Label = null
var content_status_label: Label = null


func _ready() -> void:
	if phase_36 == null or not phase_36.setup_ok:
		push_error("FASE 37 ERROR: F36 no esta disponible como baseline.")
		return
	if not _build_preview_section():
		push_error("FASE 37 ERROR: no se pudo integrar preview en panel derecho.")
		return
	_connect_observers()
	refresh_preview()
	setup_ok = true
	print("FASE 37 UX OK - preview publico basado en KarmanyTileData activo.")


func get_runtime() -> KarmanyMultiAiAlphaRuntime:
	return phase_36.get_runtime() if phase_36 != null else null


func get_selected_preview_text() -> String:
	return selected_preview_label.text if selected_preview_label != null else ""


func get_move_preview_text() -> String:
	return move_preview_label.text if move_preview_label != null else ""


func get_interact_preview_text() -> String:
	return interact_preview_label.text if interact_preview_label != null else ""


func get_content_status_text() -> String:
	return content_status_label.text if content_status_label != null else ""


func refresh_preview() -> void:
	if phase_36 == null:
		return
	_refresh_selected_tile()
	_refresh_move_consequence()
	_refresh_interact_consequence()
	_refresh_content_status()


func _build_preview_section() -> bool:
	if phase_36.right_scroll == null:
		return false
	var right_vbox := phase_36.right_scroll.get_child(0) as VBoxContainer
	if right_vbox == null:
		return false

	preview_section = VBoxContainer.new()
	preview_section.name = "Phase37PreviewSection"
	preview_section.add_theme_constant_override("separation", 5)

	var separator := HSeparator.new()
	preview_section.add_child(separator)

	var title := Label.new()
	title.text = "CONSECUENCIAS · INFORMACION PUBLICA"
	title.add_theme_font_size_override("font_size", 13)
	preview_section.add_child(title)

	selected_preview_label = _new_wrapped_label(12)
	selected_preview_label.name = "SelectedConsequencePreview"
	preview_section.add_child(selected_preview_label)

	move_preview_label = _new_wrapped_label(12)
	move_preview_label.name = "MoveConsequencePreview"
	preview_section.add_child(move_preview_label)

	interact_preview_label = _new_wrapped_label(12)
	interact_preview_label.name = "InteractConsequencePreview"
	preview_section.add_child(interact_preview_label)

	var content_separator := HSeparator.new()
	preview_section.add_child(content_separator)
	content_status_label = _new_wrapped_label(10)
	content_status_label.name = "Phase37ContentStatus"
	preview_section.add_child(content_status_label)

	right_vbox.add_child(preview_section)
	var alpha_index: int = phase_36.alpha_tools_toggle.get_index()
	right_vbox.move_child(preview_section, alpha_index)
	return true


func _new_wrapped_label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _connect_observers() -> void:
	var phase_31 := _get_phase_31()
	if phase_31 != null:
		for coord_value in phase_31.get_level_map().keys():
			var coord: Vector2i = coord_value
			var tile := phase_31.get_tile_view(coord)
			if tile != null and not tile.tile_clicked.is_connected(_on_tile_clicked):
				tile.tile_clicked.connect(_on_tile_clicked)

	var runtime := get_runtime()
	if runtime == null:
		return
	var manager := runtime.local_session.turn_manager
	if not manager.action_spent.is_connected(_on_game_state_changed):
		manager.action_spent.connect(_on_game_state_changed)
	if not manager.turn_started.is_connected(_on_turn_started):
		manager.turn_started.connect(_on_turn_started)
	if not phase_36.phase_35.visual_action_finished.is_connected(_on_visual_action_finished):
		phase_36.phase_35.visual_action_finished.connect(_on_visual_action_finished)


func _refresh_selected_tile() -> void:
	var runtime := get_runtime()
	if runtime == null or selected_preview_label == null:
		return
	var coord: Vector2i = phase_36.get_selected_coord()
	if coord == INVALID_COORD or not runtime.board_state.has_coord(coord):
		selected_preview_label.text = "SELECCION\nSelecciona una loseta para consultar consecuencias."
		return

	var level_label: String = KarmanyEffectDescriptionFormatter.tile_level_label(
		runtime.get_public_level(coord)
	)
	if not runtime.board_state.is_revealed(coord):
		var explore_available: bool = _find_candidate(
			KarmanyAiActionCandidate.ActionType.EXPLORE,
			coord
		) != null
		selected_preview_label.text = "SELECCION\nOCULTA\nNivel %s\n%s" % [
			level_label,
			"Explorar disponible" if explore_available else "Explorar no disponible ahora"
		]
		return

	var tile: KarmanyTileData = runtime.get_public_tile_data(coord)
	if tile == null:
		selected_preview_label.text = "SELECCION\nRevelada · identidad publica no disponible."
		return
	selected_preview_label.text = "SELECCION\n%s" % (
		KarmanyEffectDescriptionFormatter.build_revealed_tile_preview(tile)
	)


func _refresh_move_consequence() -> void:
	var runtime := get_runtime()
	if runtime == null or move_preview_label == null:
		return
	var coord: Vector2i = phase_36.get_selected_coord()
	var move_candidate := _find_candidate(
		KarmanyAiActionCandidate.ActionType.MOVE,
		coord
	)
	if move_candidate == null:
		move_preview_label.text = "MOVER\nNo disponible para la seleccion actual."
		return

	var tile: KarmanyTileData = runtime.get_public_tile_data(coord)
	if tile == null or not runtime.board_state.is_revealed(coord):
		# MovementRules no deberia permitir Mover a una oculta. Mantener una
		# compuerta adicional evita cualquier fuga si otro sistema regresa una
		# candidatura inconsistente.
		move_preview_label.text = "MOVER\nDestino sin informacion publica suficiente."
		return
	move_preview_label.text = "MOVER\n→ Entraras en %s\n→ ENTRADA: %s" % [
		tile.display_name,
		KarmanyEffectDescriptionFormatter.describe_entry(tile)
	]


func _refresh_interact_consequence() -> void:
	var runtime := get_runtime()
	if runtime == null or interact_preview_label == null:
		return
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		interact_preview_label.text = "INTERACTUAR\nDisponible para consultar durante el turno humano."
		return
	var interaction := _find_candidate(
		KarmanyAiActionCandidate.ActionType.INTERACT,
		player.current_coord
	)
	if interaction == null:
		interact_preview_label.text = "INTERACTUAR\nNo hay Uso posterior legal en la ubicacion actual."
		return
	var tile: KarmanyTileData = runtime.get_public_tile_data(player.current_coord)
	if tile == null:
		interact_preview_label.text = "INTERACTUAR\nInformacion publica no disponible."
		return
	interact_preview_label.text = "INTERACTUAR\n→ %s\n→ %s" % [
		KarmanyEffectDescriptionFormatter.describe_interaction(tile),
		KarmanyEffectDescriptionFormatter.describe_limit(tile)
	]


func _refresh_content_status() -> void:
	var runtime := get_runtime()
	if runtime == null or content_status_label == null:
		return
	var own_mission: KarmanyMissionData = runtime.get_secret_mission_for_viewer(
		runtime.human_player_id,
		runtime.human_player_id
	)
	var mission_text: String = own_mission.display_name if own_mission != null else "sin asignar"
	content_status_label.text = "CONTENIDO DE PARTIDA\nObjetivos publicos: %d · Mercado: %d Equipos · Resonancias en mazo: %d\nTu Mision Secreta: %s" % [
		runtime.objectives_missions.get_public_objectives().size(),
		runtime.equipment_market.get_visible_count(),
		runtime.resonance_deck.get_draw_count(),
		mission_text
	]


func _find_candidate(
	action_type: int,
	target_coord: Vector2i
) -> KarmanyAiActionCandidate:
	var runtime := get_runtime()
	if runtime == null:
		return null
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return null
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		player
	)
	for candidate in candidates:
		if candidate == null or candidate.action_type != action_type:
			continue
		if (
			action_type == KarmanyAiActionCandidate.ActionType.MOVE
			or action_type == KarmanyAiActionCandidate.ActionType.EXPLORE
		):
			if candidate.target_coord != target_coord:
				continue
		return candidate
	return null


func _get_phase_31() -> KarmanyPhase31Map41Bridge:
	if phase_36 == null or phase_36.phase_35 == null:
		return null
	return phase_36.phase_35.phase_34.phase_32.phase_31


func _on_tile_clicked(_tile: KarmanyHexTile3D) -> void:
	call_deferred("refresh_preview")


func _on_game_state_changed(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	call_deferred("refresh_preview")


func _on_turn_started(
	_player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	call_deferred("refresh_preview")


func _on_visual_action_finished(
	_player_id: StringName,
	_action_text: String
) -> void:
	call_deferred("refresh_preview")
