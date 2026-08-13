class_name KarmanyPhase21CameraBridge
extends Node3D


@onready var board_ux: KarmanyPhase20BoardUXBridge = $Phase20BoardUXPrototype
@onready var camera_controller: KarmanyStrategicCameraController = $StrategicCameraController
@onready var tiles_root: Node3D = $Phase20BoardUXPrototype/Board3DPrototype/Board


func _ready() -> void:
	if board_ux == null or camera_controller == null or tiles_root == null:
		push_error("FASE 21 ERROR: No se pudo conectar UX de tablero y camara estrategica.")
		return

	if not camera_controller.configure(
		board_ux.board_camera,
		tiles_root,
		Vector3.ZERO
	):
		push_error("FASE 21 ERROR: No se pudo configurar la camara estrategica.")
		return

	print(
		"FASE 21 CAMARA: controles estrategicos activos; limites calculados desde ",
		tiles_root.get_child_count(),
		" losetas."
	)


func focus_selected_tile() -> bool:
	if board_ux == null or camera_controller == null:
		return false

	var selected_value: Variant = board_ux.board_prototype.get("selected_tile")
	var selected_tile := selected_value as KarmanyHexTile3D
	if selected_tile == null:
		return false

	camera_controller.focus_world_position(selected_tile.global_position)
	return true


func focus_tile(coord: Vector2i) -> bool:
	if board_ux == null or camera_controller == null:
		return false

	var tile_value: Variant = board_ux.board_prototype.call("get_tile_view", coord)
	var tile := tile_value as KarmanyHexTile3D
	if tile == null:
		return false

	camera_controller.focus_world_position(tile.global_position)
	return true


func focus_active_trainer() -> bool:
	if board_ux == null or camera_controller == null:
		return false

	var trainer_value: Variant = board_ux.board_prototype.get("trainer_unit")
	var trainer := trainer_value as KarmanyTrainerUnit3D
	if trainer == null:
		return false

	camera_controller.focus_world_position(trainer.global_position)
	return true


func focus_event_world_position(world_position: Vector3) -> void:
	if camera_controller == null:
		return
	camera_controller.focus_world_position(world_position)


func reset_camera_view() -> void:
	if camera_controller == null:
		return
	camera_controller.reset_view()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_F:
			if not focus_selected_tile():
				focus_active_trainer()
		KEY_C:
			focus_active_trainer()
		KEY_HOME:
			reset_camera_view()
