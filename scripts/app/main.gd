class_name KarmanyAlphaGameShell
extends Node


signal app_state_changed(state_value: int)
signal match_created(seed_value: int)
signal match_destroyed()
signal result_presented(result: Dictionary)


enum AppState {
	MAIN_MENU,
	SETUP,
	PLAYING,
	RESULT
}


const PHASE_41_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_41_human_setup_prototype.tscn"
)
const DEFAULT_AUTOMATION_WATCHDOG: int = 96


@onready var match_host: Node3D = $MatchHost
@onready var app_ui: CanvasLayer = $AppUi

var app_state: int = AppState.MAIN_MENU
var current_seed: int = 0
var final_result: Dictionary = {}
var completed_match_count: int = 0
var last_error: String = ""

var active_match_root: KarmanyPhase41HumanSetupBridge = null
var active_human_setup: KarmanyHumanSetupFlow = null
var active_full_session: KarmanyFullMatchSession = null

var menu_overlay: Control = null
var result_overlay: Control = null
var result_label: Label = null
var new_match_button: Button = null
var quit_button: Button = null
var result_new_match_button: Button = null
var result_menu_button: Button = null

var _seed_counter: int = 0


func _ready() -> void:
	_build_app_ui()
	_show_main_menu()
	print("FASE 42 GAME SHELL - MAIN_MENU listo.")


func start_new_match(seed_value: int = 0) -> bool:
	last_error = ""
	_destroy_active_match()
	final_result.clear()
	current_seed = seed_value if seed_value != 0 else _generate_match_seed()

	var instance := PHASE_41_SCENE.instantiate() as KarmanyPhase41HumanSetupBridge
	if instance == null:
		return _fail("No se pudo instanciar el setup F41.")
	if not _inject_match_seed(instance, current_seed):
		instance.free()
		return _fail("No se encontro KarmanyPhase34MultiAiBridge para inyectar la seed.")

	active_match_root = instance
	match_host.add_child(active_match_root)
	if not active_match_root.setup_ok:
		var setup_error: String = "F41 no completo su inicializacion dentro del Game Shell."
		_destroy_active_match()
		return _fail(setup_error)

	active_human_setup = active_match_root.get_human_setup()
	if active_human_setup == null or active_human_setup.runtime == null:
		_destroy_active_match()
		return _fail("F41 no expuso HumanSetupFlow/runtime.")
	if active_human_setup.runtime.match_seed != current_seed:
		_destroy_active_match()
		return _fail("La seed del runtime no coincide con la seed creada por Game Shell.")

	_connect_setup_signals()
	match_host.visible = true
	_set_app_state(AppState.SETUP)
	match_created.emit(current_seed)
	return true


func select_starting_karmany(candidate_index: int) -> bool:
	if app_state != AppState.SETUP or active_match_root == null or active_human_setup == null:
		return false
	if candidate_index < 0 or candidate_index >= active_match_root.candidate_select_buttons.size():
		return false
	var button: Button = active_match_root.candidate_select_buttons[candidate_index]
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	return active_human_setup.selected_candidate_index == candidate_index


func confirm_starting_karmany() -> bool:
	if app_state != AppState.SETUP or active_match_root == null or active_human_setup == null:
		return false
	if active_match_root.confirm_button == null or active_match_root.confirm_button.disabled:
		return false
	active_match_root.confirm_button.pressed.emit()
	_bind_full_session()
	return active_human_setup.is_ready_to_play() and active_full_session != null


func start_current_match() -> bool:
	if app_state != AppState.SETUP or active_match_root == null or active_human_setup == null:
		return false
	if not active_human_setup.is_ready_to_play():
		return false
	if active_match_root.start_button == null or active_match_root.start_button.disabled:
		return false
	active_match_root.start_button.pressed.emit()
	return app_state == AppState.PLAYING


func auto_complete_active_match(
	max_turns: int = DEFAULT_AUTOMATION_WATCHDOG
) -> bool:
	if app_state != AppState.PLAYING or active_full_session == null:
		return false
	return active_full_session.auto_complete_match(max_turns)


func return_to_main_menu() -> void:
	_destroy_active_match()
	current_seed = 0
	final_result.clear()
	_show_main_menu()


func get_active_runtime() -> KarmanyMultiAiAlphaRuntime:
	if active_human_setup == null:
		return null
	return active_human_setup.runtime


func get_active_human_setup() -> KarmanyHumanSetupFlow:
	return active_human_setup


func get_active_full_session() -> KarmanyFullMatchSession:
	return active_full_session


func get_match_host_child_count() -> int:
	return match_host.get_child_count() if match_host != null else 0


func has_active_match() -> bool:
	return active_match_root != null and is_instance_valid(active_match_root)


func _connect_setup_signals() -> void:
	if active_human_setup == null:
		return
	var confirmed_cb := Callable(self, "_on_human_setup_confirmed")
	var playing_cb := Callable(self, "_on_playing_started")
	if not active_human_setup.human_setup_confirmed.is_connected(confirmed_cb):
		active_human_setup.human_setup_confirmed.connect(confirmed_cb)
	if not active_human_setup.playing_started.is_connected(playing_cb):
		active_human_setup.playing_started.connect(playing_cb)


func _bind_full_session() -> void:
	if active_human_setup == null:
		return
	var session := active_human_setup.get_full_session()
	if session == null:
		return
	active_full_session = session
	var result_cb := Callable(self, "_on_match_result_ready")
	if not active_full_session.result_ready.is_connected(result_cb):
		active_full_session.result_ready.connect(result_cb)


func _disconnect_active_shell_signals() -> void:
	if active_human_setup != null:
		var confirmed_cb := Callable(self, "_on_human_setup_confirmed")
		var playing_cb := Callable(self, "_on_playing_started")
		if active_human_setup.human_setup_confirmed.is_connected(confirmed_cb):
			active_human_setup.human_setup_confirmed.disconnect(confirmed_cb)
		if active_human_setup.playing_started.is_connected(playing_cb):
			active_human_setup.playing_started.disconnect(playing_cb)
	if active_full_session != null:
		var result_cb := Callable(self, "_on_match_result_ready")
		if active_full_session.result_ready.is_connected(result_cb):
			active_full_session.result_ready.disconnect(result_cb)


func _on_human_setup_confirmed() -> void:
	_bind_full_session()


func _on_playing_started() -> void:
	_bind_full_session()
	_set_app_state(AppState.PLAYING)


func _on_match_result_ready(result: Dictionary) -> void:
	if app_state == AppState.RESULT:
		return
	final_result = result.duplicate(true)
	completed_match_count += 1
	_render_result(final_result)
	_set_app_state(AppState.RESULT)
	# El runtime ya esta FINISHED y TurnManager detenido. Se conserva unicamente
	# mientras el jugador ve RESULT para no invalidar callbacks/coroutines del
	# frame final. NUEVA PARTIDA o MENÚ destruyen la raiz completa antes de seguir.
	result_presented.emit(final_result.duplicate(true))


func _destroy_active_match() -> void:
	_disconnect_active_shell_signals()
	if active_human_setup != null and active_human_setup.runtime != null:
		var runtime := active_human_setup.runtime
		if runtime.local_session != null:
			var manager := runtime.local_session.turn_manager
			if manager != null and manager.is_running:
				manager.stop_match()

	var old_root := active_match_root
	if old_root != null and is_instance_valid(old_root):
		# F42 lifecycle: primero se cancela la presentacion asíncrona y luego se
		# agenda la liberacion manteniendo la raiz dentro del SceneTree. No usamos
		# remove_child(): eso convertia F35/F38 en [Orphan] mientras sus awaits
		# pendientes todavia podian reanudarse.
		old_root.begin_teardown()
		old_root.visible = false
		old_root.process_mode = Node.PROCESS_MODE_DISABLED
		old_root.queue_free()
		match_destroyed.emit()

	active_match_root = null
	active_human_setup = null
	active_full_session = null
	if match_host != null:
		match_host.visible = false


func _inject_match_seed(node: Node, seed_value: int) -> bool:
	if node is KarmanyPhase34MultiAiBridge:
		var phase_34 := node as KarmanyPhase34MultiAiBridge
		phase_34.requested_match_seed = seed_value
		return true
	for child in node.get_children():
		if _inject_match_seed(child, seed_value):
			return true
	return false


func _generate_match_seed() -> int:
	_seed_counter += 1
	var unix_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var ticks: int = Time.get_ticks_msec()
	var generated: int = abs(unix_ms ^ (ticks << 1) ^ (_seed_counter * 1000003))
	if generated == 0:
		generated = 42001 + _seed_counter
	return generated


func _set_app_state(next_state: int) -> void:
	app_state = next_state
	if menu_overlay != null:
		menu_overlay.visible = app_state == AppState.MAIN_MENU
	if result_overlay != null:
		result_overlay.visible = app_state == AppState.RESULT
	if match_host != null:
		match_host.visible = app_state == AppState.SETUP or app_state == AppState.PLAYING
	app_state_changed.emit(app_state)


func _show_main_menu() -> void:
	_set_app_state(AppState.MAIN_MENU)


func _build_app_ui() -> void:
	menu_overlay = _build_fullscreen_overlay("MainMenuOverlay")
	var menu_center := CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(menu_center)
	var menu_panel := PanelContainer.new()
	menu_panel.custom_minimum_size = Vector2(460, 300)
	menu_center.add_child(menu_panel)
	var menu_box := VBoxContainer.new()
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_box.add_theme_constant_override("separation", 18)
	menu_panel.add_child(menu_box)
	var title := Label.new()
	title.text = "KARMANY MONSTA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	menu_box.add_child(title)
	var alpha := Label.new()
	alpha.text = "ALPHA v0.74 · FASE 42"
	alpha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alpha.add_theme_font_size_override("font_size", 14)
	menu_box.add_child(alpha)
	new_match_button = Button.new()
	new_match_button.text = "NUEVA PARTIDA"
	new_match_button.custom_minimum_size = Vector2(320, 52)
	new_match_button.pressed.connect(_on_new_match_pressed)
	menu_box.add_child(new_match_button)
	quit_button = Button.new()
	quit_button.text = "SALIR"
	quit_button.custom_minimum_size = Vector2(320, 46)
	quit_button.pressed.connect(_on_quit_pressed)
	menu_box.add_child(quit_button)

	result_overlay = _build_fullscreen_overlay("ResultOverlay")
	var result_center := CenterContainer.new()
	result_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(result_center)
	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size = Vector2(620, 500)
	result_center.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_box.alignment = BoxContainer.ALIGNMENT_CENTER
	result_box.add_theme_constant_override("separation", 14)
	result_panel.add_child(result_box)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(560, 330)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 18)
	result_box.add_child(result_label)
	result_new_match_button = Button.new()
	result_new_match_button.text = "NUEVA PARTIDA"
	result_new_match_button.custom_minimum_size = Vector2(320, 48)
	result_new_match_button.pressed.connect(_on_result_new_match_pressed)
	result_box.add_child(result_new_match_button)
	result_menu_button = Button.new()
	result_menu_button.text = "MENÚ PRINCIPAL"
	result_menu_button.custom_minimum_size = Vector2(320, 46)
	result_menu_button.pressed.connect(_on_result_menu_pressed)
	result_box.add_child(result_menu_button)


func _build_fullscreen_overlay(node_name: String) -> Control:
	var overlay := Control.new()
	overlay.name = node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	app_ui.add_child(overlay)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.035, 0.055, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)
	return overlay


func _render_result(result: Dictionary) -> void:
	if result_label == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	lines.append("PARTIDA FINALIZADA")
	lines.append("")
	var winners: Array = result.get("winner_ids", [])
	var winner_names: PackedStringArray = PackedStringArray()
	for winner_value in winners:
		winner_names.append(String(winner_value).to_upper())
	lines.append("Ganador: %s" % (", ".join(winner_names) if not winner_names.is_empty() else "SIN GANADOR"))
	lines.append("Seed: %d · Rondas: %d" % [
		int(result.get("seed", current_seed)),
		int(result.get("rounds", 0))
	])
	lines.append("")
	lines.append("PUNTOS DE LEGADO")
	var points_by_player: Dictionary = {}
	var ranking: Array = result.get("ranking", [])
	for row_value in ranking:
		if row_value is Dictionary:
			var row: Dictionary = row_value
			points_by_player[String(row.get("player_id", ""))] = int(row.get("legacy_points", 0))
	for player_id in ["player_1", "player_2", "player_3", "player_4"]:
		lines.append("%s · %d PL" % [player_id.to_upper(), int(points_by_player.get(player_id, 0))])
	result_label.text = "\n".join(lines)


func _on_new_match_pressed() -> void:
	if not start_new_match():
		push_error("FASE 42 ERROR: %s" % last_error)


func _on_result_new_match_pressed() -> void:
	if not start_new_match():
		push_error("FASE 42 ERROR: %s" % last_error)


func _on_result_menu_pressed() -> void:
	return_to_main_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _fail(message: String) -> bool:
	last_error = message
	push_error("FASE 42 ERROR: %s" % message)
	return false
