class_name KarmanyPhase22FeedbackBridge
extends Node3D


@export var auto_intro_transition: bool = true


@onready var phase_21: KarmanyPhase21CameraBridge = $Phase21CameraPrototype
@onready var feedback: KarmanyPresentationFeedbackController = $PresentationFeedbackController
@onready var feedback_root: Node3D = $FeedbackRoot
@onready var overlay_rect: ColorRect = $FeedbackOverlay/TransitionRect
@onready var overlay_label: Label = $FeedbackOverlay/TransitionLabel


var board_ux: KarmanyPhase20BoardUXBridge = null
var _last_trainer_target: Vector3 = Vector3.ZERO
var _revealed_snapshot: Dictionary = {}
var _demo_karmany: Node3D = null


func _ready() -> void:
	if phase_21 == null or feedback == null or feedback_root == null:
		push_error("FASE 22 ERROR: No se pudo conectar camara y feedback de presentacion.")
		return

	board_ux = phase_21.board_ux
	if board_ux == null:
		push_error("FASE 22 ERROR: No se encontro la UX de tablero de Fase 20.")
		return

	if not feedback.configure(feedback_root, overlay_rect, overlay_label):
		push_error("FASE 22 ERROR: No se pudo configurar PresentationFeedbackController.")
		return

	var trainer := _get_trainer()
	if trainer != null:
		_last_trainer_target = trainer.global_position

	_seed_revealed_snapshot()
	_bind_feedback_signals()

	if auto_intro_transition:
		call_deferred("_play_intro_transition")

	print("FASE 22 FEEDBACK: capa de presentacion conectada sin controlar gameplay.")
	print("Demo visual: H=golpe/dano, K=aparicion Karmany, T=transicion.")


func get_feedback_controller() -> KarmanyPresentationFeedbackController:
	return feedback


func play_hit_demo(damage: int = 4) -> bool:
	var trainer := _get_trainer()
	if trainer == null:
		return false
	var hit_ok: bool = feedback.play_hit_feedback(trainer)
	var damage_ok: bool = feedback.play_damage_feedback(trainer, damage)
	return hit_ok and damage_ok


func play_karmany_appearance_demo() -> bool:
	if feedback == null or board_ux == null:
		return false

	if _demo_karmany != null and is_instance_valid(_demo_karmany):
		_demo_karmany.queue_free()
		_demo_karmany = null

	var world_position: Vector3 = Vector3.ZERO
	var selected_value: Variant = board_ux.board_prototype.get("selected_tile")
	var selected_tile := selected_value as KarmanyHexTile3D
	if selected_tile != null:
		world_position = selected_tile.global_position
	else:
		var trainer := _get_trainer()
		if trainer != null:
			world_position = trainer.global_position + Vector3(0.9, 0.0, 0.0)

	_demo_karmany = feedback.create_demo_karmany_marker(
		world_position,
		"Karmany demo"
	)
	if _demo_karmany == null:
		return false

	phase_21.focus_event_world_position(world_position)
	return true


func play_transition_demo(message: String = "ECO KARMNICO") -> bool:
	return feedback != null and feedback.play_transition(message)


func notify_combat_hit(
	target: Node3D,
	damage: int
) -> bool:
	if feedback == null or target == null:
		return false
	var hit_ok: bool = feedback.play_hit_feedback(target)
	var damage_ok: bool = feedback.play_damage_feedback(target, damage)
	return hit_ok and damage_ok


func notify_karmany_appeared(target: Node3D) -> bool:
	if feedback == null or target == null:
		return false
	phase_21.focus_event_world_position(target.global_position)
	return feedback.animate_karmany_appearance(target)


func notify_tile_revealed(coord: Vector2i) -> bool:
	if board_ux == null or feedback == null:
		return false
	var tile_value: Variant = board_ux.board_prototype.call("get_tile_view", coord)
	var tile := tile_value as KarmanyHexTile3D
	if tile == null:
		return false
	_revealed_snapshot[coord] = true
	return feedback.animate_tile_reveal(tile)


func _play_intro_transition() -> void:
	feedback.play_transition("FASE 22 — FEEDBACK VISUAL")


func _bind_feedback_signals() -> void:
	var manager: KarmanyTurnManager = board_ux.board_prototype.turn_manager
	if not manager.action_spent.is_connected(_on_action_spent_feedback):
		manager.action_spent.connect(_on_action_spent_feedback)

	for coord in board_ux.board_prototype.board_state.get_coords():
		var tile_value: Variant = board_ux.board_prototype.call("get_tile_view", coord)
		var tile := tile_value as KarmanyHexTile3D
		if tile == null:
			continue
		if not tile.tile_clicked.is_connected(_on_tile_clicked_feedback):
			tile.tile_clicked.connect(_on_tile_clicked_feedback)


func _seed_revealed_snapshot() -> void:
	_revealed_snapshot.clear()
	for coord in board_ux.board_prototype.board_state.get_coords():
		if board_ux.board_prototype.board_state.is_revealed(coord):
			_revealed_snapshot[coord] = true


func _on_action_spent_feedback(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	var trainer := _get_trainer()
	if trainer != null:
		var final_position: Vector3 = trainer.global_position
		if not final_position.is_equal_approx(_last_trainer_target):
			feedback.animate_unit_move(
				trainer,
				_last_trainer_target,
				final_position
			)
			_last_trainer_target = final_position

	_animate_newly_revealed_tiles()


func _animate_newly_revealed_tiles() -> void:
	for coord in board_ux.board_prototype.board_state.get_coords():
		if not board_ux.board_prototype.board_state.is_revealed(coord):
			continue
		if _revealed_snapshot.has(coord):
			continue
		notify_tile_revealed(coord)


func _on_tile_clicked_feedback(tile: KarmanyHexTile3D) -> void:
	if tile != null:
		feedback.animate_selection(tile)


func _get_trainer() -> KarmanyTrainerUnit3D:
	if board_ux == null:
		return null
	var trainer_value: Variant = board_ux.board_prototype.get("trainer_unit")
	return trainer_value as KarmanyTrainerUnit3D


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_H:
			play_hit_demo(4)
		KEY_K:
			play_karmany_appearance_demo()
		KEY_T:
			play_transition_demo()
