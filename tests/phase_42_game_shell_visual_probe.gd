extends Node


const VISUAL_SEED: int = 42420

@onready var shell: KarmanyAlphaGameShell = $KarmanyAlphaGameShell

var status_label: Label = null
var auto_button: Button = null
var menu_button: Button = null


func _ready() -> void:
	_build_probe_controls()
	if shell != null:
		shell.app_state_changed.connect(_on_shell_state_changed)
		_refresh_status()
	print("FASE 42 VISUAL PROBE - usa el flujo manual o AUTO AL RESULTADO (ALPHA).")


func _build_probe_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Phase42VisualProbeLayer"
	layer.layer = 200
	add_child(layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.size = Vector2(650, 54)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(330, 0)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(status_label)

	auto_button = Button.new()
	auto_button.text = "AUTO AL RESULTADO · ALPHA"
	auto_button.tooltip_text = "Solo para inspeccion visual F42: elige candidato 1 y automatiza la partida."
	auto_button.pressed.connect(_on_auto_pressed)
	row.add_child(auto_button)

	menu_button = Button.new()
	menu_button.text = "MENÚ"
	menu_button.pressed.connect(_on_menu_pressed)
	row.add_child(menu_button)


func _on_auto_pressed() -> void:
	if shell == null:
		return
	if shell.app_state == KarmanyAlphaGameShell.AppState.MAIN_MENU:
		if not shell.start_new_match(VISUAL_SEED):
			status_label.text = "ERROR: %s" % shell.last_error
			return
	if shell.app_state == KarmanyAlphaGameShell.AppState.SETUP:
		var setup := shell.get_active_human_setup()
		if setup != null and not setup.confirmed:
			if not shell.select_starting_karmany(0) or not shell.confirm_starting_karmany():
				status_label.text = "ERROR al automatizar setup."
				return
		if not shell.start_current_match():
			status_label.text = "ERROR al entrar a PLAYING."
			return
	if shell.app_state == KarmanyAlphaGameShell.AppState.PLAYING:
		var session := shell.get_active_full_session()
		if session == null or not shell.auto_complete_active_match():
			status_label.text = "ERROR al completar partida: %s" % (session.last_error if session != null else "sin sesion")
			return
	_refresh_status()


func _on_menu_pressed() -> void:
	if shell != null:
		shell.return_to_main_menu()


func _on_shell_state_changed(_state_value: int) -> void:
	call_deferred("_refresh_status")


func _refresh_status() -> void:
	if shell == null or status_label == null:
		return
	status_label.text = "PROBE F42 · estado=%s · seed=%d · partidas terminadas=%d" % [
		_state_label(shell.app_state),
		shell.current_seed,
		shell.completed_match_count
	]


func _state_label(state_value: int) -> String:
	match state_value:
		KarmanyAlphaGameShell.AppState.MAIN_MENU:
			return "MAIN_MENU"
		KarmanyAlphaGameShell.AppState.SETUP:
			return "SETUP"
		KarmanyAlphaGameShell.AppState.PLAYING:
			return "PLAYING"
		KarmanyAlphaGameShell.AppState.RESULT:
			return "RESULT"
	return "UNKNOWN"
