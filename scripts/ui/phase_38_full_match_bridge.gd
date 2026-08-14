class_name KarmanyPhase38FullMatchBridge
extends Node3D


@onready var phase_37: KarmanyPhase37ContentPreviewBridge = $Phase37ContentPreviewPrototype

var full_session: KarmanyFullMatchSession = null

var setup_overlay: Control = null
var setup_summary_label: Label = null
var start_button: Button = null

var controls_panel: PanelContainer = null
var state_label: Label = null
var action_label: Label = null
var link_call_button: Button = null
var combat_button: Button = null
var equipment_button: Button = null
var auto_p1_button: Button = null
var auto_match_button: Button = null

var result_overlay: Control = null
var result_label: Label = null

var _ai_driver_busy: bool = false
var _auto_match_busy: bool = false


func _ready() -> void:
	if phase_37 == null or not phase_37.setup_ok:
		push_error("FASE 38 ERROR: F37 no esta disponible como baseline validado.")
		return
	var runtime := phase_37.get_runtime()
	if runtime == null:
		push_error("FASE 38 ERROR: runtime F37 no disponible.")
		return

	full_session = KarmanyFullMatchSession.new()
	if not full_session.configure(runtime):
		push_error("FASE 38 ERROR: %s" % full_session.last_error)
		return

	_build_setup_overlay()
	_build_match_controls()
	_build_result_overlay()
	_connect_full_match_signals()
	_disable_obsolete_debug_controls()
	_refresh_ui()
	print("FASE 38 UX OK - partida completa 4P preparada en estado SETUP.")


func get_full_session() -> KarmanyFullMatchSession:
	return full_session


func _build_setup_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Phase38SetupLayer"
	layer.layer = 40
	add_child(layer)

	setup_overlay = Control.new()
	setup_overlay.name = "Phase38SetupOverlay"
	setup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(setup_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.04, 0.06, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 430)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var title := Label.new()
	title.text = "KARMANY MONSTA · PARTIDA COMPLETA 4P"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)

	setup_summary_label = Label.new()
	setup_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_summary_label.custom_minimum_size = Vector2(610, 300)
	setup_summary_label.add_theme_font_size_override("font_size", 14)
	content.add_child(setup_summary_label)

	start_button = Button.new()
	start_button.text = "INICIAR PARTIDA · RONDA 1"
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.pressed.connect(_on_start_pressed)
	content.add_child(start_button)
	_refresh_setup_summary()


func _build_match_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Phase38ControlsLayer"
	layer.layer = 35
	add_child(layer)

	controls_panel = PanelContainer.new()
	controls_panel.name = "Phase38Controls"
	controls_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls_panel.position = Vector2(-390, -78)
	controls_panel.size = Vector2(780, 70)
	layer.add_child(controls_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	controls_panel.add_child(row)

	state_label = Label.new()
	state_label.custom_minimum_size = Vector2(126, 0)
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(state_label)

	link_call_button = Button.new()
	link_call_button.text = "Llamar / Vincular"
	link_call_button.pressed.connect(_on_link_call_pressed)
	row.add_child(link_call_button)

	combat_button = Button.new()
	combat_button.text = "Combatir"
	combat_button.pressed.connect(_on_combat_pressed)
	row.add_child(combat_button)

	equipment_button = Button.new()
	equipment_button.text = "Equipo / Forja"
	equipment_button.pressed.connect(_on_equipment_pressed)
	row.add_child(equipment_button)

	auto_p1_button = Button.new()
	auto_p1_button.text = "Auto P1"
	auto_p1_button.pressed.connect(_on_auto_p1_pressed)
	row.add_child(auto_p1_button)

	auto_match_button = Button.new()
	auto_match_button.text = "AUTO PARTIDA"
	auto_match_button.pressed.connect(_on_auto_match_pressed)
	row.add_child(auto_match_button)

	action_label = Label.new()
	action_label.custom_minimum_size = Vector2(180, 0)
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(action_label)


func _build_result_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Phase38ResultLayer"
	layer.layer = 50
	add_child(layer)

	result_overlay = Control.new()
	result_overlay.name = "Phase38ResultOverlay"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	layer.add_child(result_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.05, 0.92)
	result_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 400)
	center.add_child(panel)

	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 18)
	panel.add_child(result_label)


func _connect_full_match_signals() -> void:
	full_session.state_changed.connect(_on_state_changed)
	full_session.full_action_resolved.connect(_on_full_action_resolved)
	full_session.result_ready.connect(_on_result_ready)
	var manager := full_session.runtime.local_session.turn_manager
	if not manager.turn_started.is_connected(_on_turn_started):
		manager.turn_started.connect(_on_turn_started)
	if not manager.action_spent.is_connected(_on_action_spent):
		manager.action_spent.connect(_on_action_spent)
	var phase_31 := phase_37.phase_36.phase_35.phase_34.phase_32.phase_31
	if phase_31 != null:
		for coord_value in phase_31.get_level_map().keys():
			var coord: Vector2i = coord_value
			var tile := phase_31.get_tile_view(coord)
			if tile != null and not tile.tile_clicked.is_connected(_on_phase38_tile_clicked):
				tile.tile_clicked.connect(_on_phase38_tile_clicked)


func _disable_obsolete_debug_controls() -> void:
	var phase_36 := phase_37.phase_36
	if phase_36 == null:
		return
	if phase_36.ai_button != null:
		phase_36.ai_button.disabled = true
		phase_36.ai_button.tooltip_text = "F38 controla automaticamente P2/P3/P4."
	if phase_36.all_ai_button != null:
		phase_36.all_ai_button.disabled = true
		phase_36.all_ai_button.tooltip_text = "Usa AUTO PARTIDA de F38."
	# Cerrar P1 era una sonda de F35/F36 que gastaba presupuesto tecnico.
	# En F38 la partida humana normal termina despues de resolver sus 2 acciones.
	if phase_36.pass_button != null:
		phase_36.pass_button.disabled = true
		phase_36.pass_button.tooltip_text = "F38: resuelve las 2 acciones reglamentarias; el turno termina automaticamente."


func _on_start_pressed() -> void:
	if full_session == null or not full_session.start_playing():
		return
	setup_overlay.visible = false
	_refresh_ui()


func _on_link_call_pressed() -> void:
	var preferred: Array[int] = [
		KarmanyAiActionCandidate.ActionType.BOND_PAYMENT,
		KarmanyAiActionCandidate.ActionType.BOND_COMBAT,
		KarmanyAiActionCandidate.ActionType.CALL_KARMANY
	]
	_resolve_human_special(preferred, "Llamar/Vincular no es legal ahora.")


func _on_combat_pressed() -> void:
	var preferred: Array[int] = [
		KarmanyAiActionCandidate.ActionType.FIGHT_BEAST,
		KarmanyAiActionCandidate.ActionType.PVP,
		KarmanyAiActionCandidate.ActionType.AETERNA
	]
	_resolve_human_special(preferred, "No existe combate legal disponible.")


func _on_equipment_pressed() -> void:
	var preferred: Array[int] = [
		KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT,
		KarmanyAiActionCandidate.ActionType.FORGE
	]
	_resolve_human_special(preferred, "Equipo/Forja no es legal aqui.")


func _resolve_human_special(preferred: Array[int], unavailable_text: String) -> void:
	if full_session == null or _auto_match_busy:
		return
	var success: bool = full_session.execute_human_special(preferred)
	action_label.text = "Accion resuelta." if success else unavailable_text
	_refresh_ui()


func _on_auto_p1_pressed() -> void:
	if full_session == null or _auto_match_busy:
		return
	var manager := full_session.runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not full_session.runtime.ai_match_controller.is_human_player(player.player_id):
		action_label.text = "Auto P1 solo funciona durante el turno humano."
		return
	var success: bool = full_session.run_automated_current_turn()
	action_label.text = "P1 automatico completo." if success else full_session.last_error
	_refresh_ui()


func _on_auto_match_pressed() -> void:
	if full_session == null or _auto_match_busy:
		return
	if full_session.match_state == KarmanyFullMatchSession.MatchState.SETUP:
		if not full_session.start_playing():
			return
		setup_overlay.visible = false
	_auto_match_busy = true
	_set_gameplay_enabled(false)
	_run_auto_match_visual()


func _run_auto_match_visual() -> void:
	while full_session != null and full_session.match_state == KarmanyFullMatchSession.MatchState.PLAYING:
		var success: bool = full_session.run_automated_current_turn()
		if not success:
			action_label.text = full_session.last_error
			break
		await phase_37.phase_36.phase_35.wait_for_presentation_idle()
		await get_tree().create_timer(0.08).timeout
		_refresh_ui()
	_auto_match_busy = false
	if full_session.match_state == KarmanyFullMatchSession.MatchState.PLAYING:
		_set_gameplay_enabled(true)
	_refresh_ui()


func _on_turn_started(
	player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	_refresh_ui()
	if (
		player != null
		and full_session != null
		and full_session.match_state == KarmanyFullMatchSession.MatchState.PLAYING
		and full_session.runtime.ai_match_controller.is_ai_player(player.player_id)
		and not _auto_match_busy
	):
		call_deferred("_drive_ai_until_human")


func _drive_ai_until_human() -> void:
	if _ai_driver_busy or _auto_match_busy:
		return
	_ai_driver_busy = true
	while full_session != null and full_session.match_state == KarmanyFullMatchSession.MatchState.PLAYING:
		var manager := full_session.runtime.local_session.turn_manager
		if manager == null or not manager.is_running:
			break
		var player := manager.get_active_player()
		if player == null or full_session.runtime.ai_match_controller.is_human_player(player.player_id):
			break
		await get_tree().create_timer(0.22).timeout
		var success: bool = full_session.run_automated_current_turn()
		if not success:
			action_label.text = full_session.last_error
			break
		await phase_37.phase_36.phase_35.wait_for_presentation_idle()
		_refresh_ui()
	_ai_driver_busy = false


func _on_full_action_resolved(
	player_id: StringName,
	action_text: String,
	success: bool
) -> void:
	action_label.text = "%s: %s%s" % [
		String(player_id).to_upper(),
		action_text,
		"" if success else " · RECHAZADA"
	]
	_refresh_ui()
	if success:
		call_deferred("_reconcile_visuals_to_logic")


func _reconcile_visuals_to_logic() -> void:
	if full_session == null:
		return
	var phase_35 := phase_37.phase_36.phase_35
	if phase_35 == null:
		return
	await phase_35.wait_for_presentation_idle()
	var phase_31 := phase_35.phase_34.phase_32.phase_31
	if phase_31 == null:
		return
	for player in full_session.runtime.local_session.players:
		if player == null or phase_35.get_visual_coord(player.player_id) == player.current_coord:
			continue
		var unit := phase_35.get_trainer_unit(player.player_id)
		var tile := phase_31.get_tile_view(player.current_coord)
		if unit == null or tile == null or tile.unit_anchor == null:
			continue
		phase_35.feedback.animate_unit_move(unit, unit.global_position, tile.unit_anchor.global_position)
		var wait_seconds: float = phase_35.feedback.movement_duration * phase_35.feedback.duration_scale
		if wait_seconds > 0.0:
			await get_tree().create_timer(wait_seconds).timeout
		unit.snap_visual_to(tile.unit_anchor)
		phase_35._visual_coord_by_player[player.player_id] = player.current_coord
		phase_35._logic_coord_snapshot[player.player_id] = player.current_coord


func _on_phase38_tile_clicked(_tile: KarmanyHexTile3D) -> void:
	call_deferred("_refresh_ui")


func _on_action_spent(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	call_deferred("_finish_human_end_turn_if_needed")
	call_deferred("_refresh_ui")


func _finish_human_end_turn_if_needed() -> void:
	if full_session == null:
		return
	var manager := full_session.runtime.local_session.turn_manager
	if manager == null or not manager.is_running or manager.actions_remaining != 0:
		return
	var active := manager.get_active_player()
	if active != null and full_session.runtime.ai_match_controller.is_human_player(active.player_id):
		full_session.finish_human_turn_if_ready()


func _on_state_changed(_state_value: int) -> void:
	_refresh_ui()


func _on_result_ready(result: Dictionary) -> void:
	_set_gameplay_enabled(false)
	result_label.text = _format_result(result)
	result_overlay.visible = true
	_refresh_ui()


func _refresh_setup_summary() -> void:
	if setup_summary_label == null or full_session == null:
		return
	var summary := full_session.get_setup_summary()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Seed: %d · Mapa: %d posiciones · Modo principal: %d rondas" % [
		int(summary.get("seed", 0)),
		int(summary.get("map_cells", 0)),
		int(summary.get("standard_rounds", 0))
	])
	var objective_ids: PackedStringArray = summary.get("objectives", PackedStringArray())
	lines.append("Objetivos Publicos: %s" % ", ".join(objective_ids))
	lines.append("")
	var player_rows: Array = summary.get("players", [])
	for row_value in player_rows:
		if not (row_value is Dictionary):
			continue
		var row: Dictionary = row_value
		lines.append("%s · %s · Inicial: %s · Resonancias: %d" % [
			String(row.get("player_id", "")).to_upper(),
			String(row.get("trainer", "")),
			String(row.get("starting_karmany", "")),
			int(row.get("resonance_count", 0))
		])
		lines.append(
			"  Tu Mision Secreta: %s" % String(row.get("mission", ""))
			if String(row.get("player_id", "")) == String(full_session.runtime.human_player_id)
			else "  Mision: PRIVADA"
		)
	lines.append("")
	lines.append("P1 usa Mover / Explorar / Interactuar / Mejorar Libro del HUD existente.")
	lines.append("F38 agrega Llamar/Vincular, Combate, Equipo/Forja y automatizacion legal.")
	setup_summary_label.text = "\n".join(lines)


func _refresh_ui() -> void:
	if full_session == null or state_label == null:
		return
	var manager := full_session.runtime.local_session.turn_manager
	var active_text: String = "-"
	var actions: int = 0
	var round_number: int = 0
	if manager != null:
		var active := manager.get_active_player()
		active_text = String(active.player_id).to_upper() if active != null else "-"
		actions = manager.actions_remaining
		round_number = manager.current_round
	state_label.text = "%s\nR%d · %s · %d/2" % [
		full_session.get_state_label(),
		round_number,
		active_text,
		actions
	]

	var human_turn: bool = (
		full_session.match_state == KarmanyFullMatchSession.MatchState.PLAYING
		and manager != null
		and manager.is_running
		and manager.get_active_player() != null
		and full_session.runtime.ai_match_controller.is_human_player(manager.get_active_player().player_id)
	)
	if not _auto_match_busy:
		link_call_button.disabled = not human_turn
		combat_button.disabled = not human_turn
		equipment_button.disabled = not human_turn
		auto_p1_button.disabled = not human_turn
		auto_match_button.disabled = full_session.match_state != KarmanyFullMatchSession.MatchState.PLAYING

	var phase_36 := phase_37.phase_36
	if phase_36 != null:
		phase_36.pass_button.disabled = true
		if human_turn and not _auto_match_busy:
			phase_36.explore_button.tooltip_text = ""
	_refresh_entry_preview_guard(human_turn)


func _refresh_entry_preview_guard(human_turn: bool) -> void:
	if not human_turn or phase_37.move_preview_label == null:
		return
	var coord: Vector2i = phase_37.phase_36.get_selected_coord()
	if coord == KarmanyPhase37ContentPreviewBridge.INVALID_COORD:
		return
	var player := full_session.runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return
	var status: StringName = full_session.get_entry_bonus_status(player, coord)
	if status == &"eligible" or status == &"text_only" or status == &"no_bonus":
		return
	var tile := full_session.runtime.get_public_tile_data(coord)
	if tile == null:
		return
	var reason: String = ""
	if status == &"turn_start":
		reason = "no se activa al volver a la loseta donde comenzaste el turno"
	elif status == &"already_used":
		reason = "esta loseta ya otorgo su Bonificacion de entrada este turno"
	elif status == &"limit":
		reason = "ya resolviste 2 Bonificaciones de entrada este turno"
	if reason.is_empty():
		return
	phase_37.move_preview_label.text = "MOVER\n→ Entraras en %s\n→ ENTRADA: %s." % [tile.display_name, reason]


func _set_gameplay_enabled(enabled: bool) -> void:
	var phase_36 := phase_37.phase_36
	if phase_36 != null:
		phase_36.move_button.disabled = not enabled
		phase_36.explore_button.disabled = not enabled
		phase_36.interact_button.disabled = not enabled
		phase_36.improve_button.disabled = not enabled
		phase_36.pass_button.disabled = true
	if link_call_button != null:
		link_call_button.disabled = not enabled
	if combat_button != null:
		combat_button.disabled = not enabled
	if equipment_button != null:
		equipment_button.disabled = not enabled
	if auto_p1_button != null:
		auto_p1_button.disabled = not enabled


func _format_result(result: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray(["PARTIDA FINALIZADA", ""])
	var ranking: Array = result.get("ranking", [])
	for row_value in ranking:
		if not (row_value is Dictionary):
			continue
		var row: Dictionary = row_value
		lines.append("%dº %s — %d PL" % [
			int(row.get("rank", 0)),
			String(row.get("player_id", "")).to_upper(),
			int(row.get("legacy_points", 0))
		])
	lines.append("")
	var winners: Array = result.get("winner_ids", [])
	lines.append(
		"EMPATE / VICTORIA COMPARTIDA: %s" % str(winners)
		if bool(result.get("shared_victory", false))
		else "GANADOR: %s" % (String(winners[0]).to_upper() if not winners.is_empty() else "-")
	)
	lines.append("Rondas: %d · Seed: %d" % [int(result.get("rounds", 0)), int(result.get("seed", 0))])
	lines.append("Motivo: %s" % String(result.get("reason_id", "")))
	return "\n".join(lines)
