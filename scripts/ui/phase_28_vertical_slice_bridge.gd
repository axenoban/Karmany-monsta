class_name KarmanyPhase28VerticalSliceBridge
extends Node3D

@onready var slice_match: KarmanyPhase24FullMatchBridge = $Phase24FullMatchPrototype
@onready var goal_label: Label = $SliceOverlay/Panel/Margin/VBox/GoalLabel
@onready var progress_label: Label = $SliceOverlay/Panel/Margin/VBox/ProgressLabel
@onready var message_label: Label = $SliceOverlay/Panel/Margin/VBox/MessageLabel
@onready var metrics_label: Label = $SliceOverlay/Panel/Margin/VBox/MetricsLabel
@onready var action_grid: GridContainer = $SliceOverlay/Panel/Margin/VBox/ActionGrid
@onready var save_button: Button = $SliceOverlay/Panel/Margin/VBox/SaveRow/SaveButton
@onready var load_button: Button = $SliceOverlay/Panel/Margin/VBox/SaveRow/LoadButton

var session: KarmanyVerticalSliceSession = KarmanyVerticalSliceSession.new()
var setup_ok: bool = false

func _ready() -> void:
	var old_overlay := slice_match.get_node_or_null("Phase24Overlay") as CanvasLayer
	if old_overlay != null:
		old_overlay.visible = false
	setup_ok = session.configure(slice_match)
	if not setup_ok:
		push_error("FASE 28 ERROR: VerticalSliceSession no pudo configurarse.")
		_refresh_all()
		return
	_bind_actions()
	session.state_changed.connect(_refresh_all)
	session.slice_event.connect(_on_slice_event)
	_refresh_all()
	print("FASE 28 VERTICAL SLICE OK - escena interactiva inicializada.")

func selected_coord() -> Vector2i:
	var tile: KarmanyHexTile3D = slice_match.board_prototype.selected_tile
	return tile.coord if tile != null else session.human_player.current_coord

func _bind_actions() -> void:
	var methods: Array[StringName] = [&"move_to", &"explore_to", &"interact_current_tile", &"call_or_bond", &"craft_slice_equipment", &"fight_current_beast", &"improve_book", &"end_human_turn_and_run_ai"]
	for index in range(action_grid.get_child_count()):
		var button := action_grid.get_child(index) as Button
		if button != null and index < methods.size():
			button.pressed.connect(_on_action_pressed.bind(methods[index]))
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)

func _on_action_pressed(method_name: StringName) -> void:
	if method_name == &"move_to" or method_name == &"explore_to":
		session.call(method_name, selected_coord())
	else:
		session.call(method_name)

func _on_save_pressed() -> void:
	session.save_slice()

func _on_load_pressed() -> void:
	if session.load_slice():
		for coord in slice_match.board_prototype.board_state.get_coords():
			slice_match.board_prototype.call("_refresh_tile_view_from_state", coord)
		slice_match.board_prototype.call("place_trainer_at", session.human_player.current_coord)
		_refresh_all()

func _on_slice_event(kind: StringName, text: String, _coord: Vector2i) -> void:
	message_label.text = "%s · %s" % [String(kind), text]

func _refresh_all() -> void:
	if not setup_ok:
		goal_label.text = "Vertical Slice no disponible. Revisa Salida."
		return
	slice_match.board_ux.refresh_board_ux()
	slice_match.phase_23.refresh_visual_direction()
	if slice_match.hud != null:
		slice_match.hud.call("_refresh")
	goal_label.text = "OBJETIVO ACTUAL\n" + session.get_current_goal()
	progress_label.text = session.get_progress_summary()
	metrics_label.text = session.get_metrics_summary()
	var human_turn: bool = session.is_human_turn()
	var has_action: bool = human_turn and session.turn_manager.actions_remaining > 0
	for child in action_grid.get_children():
		var button := child as Button
		if button != null:
			button.disabled = not has_action
	var end_button := action_grid.get_child(7) as Button
	if end_button != null:
		end_button.disabled = not human_turn or session.turn_manager.actions_remaining != 0
