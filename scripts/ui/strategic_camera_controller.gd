class_name KarmanyStrategicCameraController
extends Node


@export_group("Strategic Camera")
@export var pan_speed: float = 5.5
@export var keyboard_rotation_speed_degrees: float = 70.0
@export var mouse_rotation_sensitivity: float = 0.22
@export var mouse_pan_sensitivity: float = 0.012
@export var zoom_step: float = 1.0
@export var min_distance: float = 4.5
@export var max_distance: float = 14.0
@export var bounds_padding: float = 1.75


var camera: Camera3D = null
var tiles_root: Node3D = null

var _target: Vector3 = Vector3.ZERO
var _distance: float = 10.0
var _yaw_radians: float = 0.0
var _pitch_radians: float = deg_to_rad(45.0)

var _initial_target: Vector3 = Vector3.ZERO
var _initial_distance: float = 10.0
var _initial_yaw_radians: float = 0.0
var _initial_pitch_radians: float = deg_to_rad(45.0)

var _bounds_min: Vector2 = Vector2(-10.0, -10.0)
var _bounds_max: Vector2 = Vector2(10.0, 10.0)
var _configured: bool = false
var _middle_dragging: bool = false
var _right_dragging: bool = false


func configure(
	p_camera: Camera3D,
	p_tiles_root: Node3D,
	initial_target: Vector3 = Vector3.ZERO
) -> bool:
	if p_camera == null or p_tiles_root == null:
		return false

	camera = p_camera
	tiles_root = p_tiles_root
	_target = initial_target

	var offset: Vector3 = camera.global_position - _target
	_distance = maxf(offset.length(), 0.001)
	_yaw_radians = atan2(offset.x, offset.z)
	_pitch_radians = asin(clampf(offset.y / _distance, -1.0, 1.0))

	_initial_target = _target
	_initial_distance = clampf(_distance, min_distance, max_distance)
	_initial_yaw_radians = _yaw_radians
	_initial_pitch_radians = _pitch_radians
	_distance = _initial_distance

	_refresh_bounds_from_tiles()
	_target = _clamp_target(_target)
	_configured = true

	camera.make_current()
	_apply_camera_transform()
	return true


func is_configured() -> bool:
	return _configured and camera != null and tiles_root != null


func refresh_bounds() -> bool:
	if tiles_root == null:
		return false
	_refresh_bounds_from_tiles()
	_target = _clamp_target(_target)
	_apply_camera_transform()
	return true


func get_target() -> Vector3:
	return _target


func get_distance() -> float:
	return _distance


func get_yaw_degrees() -> float:
	return rad_to_deg(_yaw_radians)


func get_pitch_degrees() -> float:
	return rad_to_deg(_pitch_radians)


func get_bounds() -> Rect2:
	return Rect2(
		_bounds_min,
		_bounds_max - _bounds_min
	)


func get_min_distance() -> float:
	return min_distance


func get_max_distance() -> float:
	return max_distance


func pan_world(delta_xz: Vector2) -> void:
	if not is_configured():
		return
	_target += Vector3(delta_xz.x, 0.0, delta_xz.y)
	_target = _clamp_target(_target)
	_apply_camera_transform()


func pan_screen(axis: Vector2, amount: float) -> void:
	if not is_configured() or axis == Vector2.ZERO or amount == 0.0:
		return

	var forward := Vector3(
		-sin(_yaw_radians),
		0.0,
		-cos(_yaw_radians)
	).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	var world_delta := (
		right * axis.x
		+ forward * axis.y
	) * amount

	_target += world_delta
	_target = _clamp_target(_target)
	_apply_camera_transform()


func zoom_by_steps(steps: float) -> void:
	if not is_configured() or steps == 0.0:
		return
	_distance = clampf(
		_distance - steps * zoom_step,
		min_distance,
		max_distance
	)
	_apply_camera_transform()


func rotate_by_degrees(delta_degrees: float) -> void:
	if not is_configured() or delta_degrees == 0.0:
		return
	_yaw_radians = wrapf(
		_yaw_radians + deg_to_rad(delta_degrees),
		-PI,
		PI
	)
	_apply_camera_transform()


func focus_world_position(world_position: Vector3) -> void:
	if not is_configured():
		return
	_target = _clamp_target(
		Vector3(
			world_position.x,
			_initial_target.y,
			world_position.z
		)
	)
	_apply_camera_transform()


func reset_view() -> void:
	if not is_configured():
		return
	_target = _clamp_target(_initial_target)
	_distance = _initial_distance
	_yaw_radians = _initial_yaw_radians
	_pitch_radians = _initial_pitch_radians
	_apply_camera_transform()


func _process(delta: float) -> void:
	if not is_configured():
		return

	var pan_axis := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan_axis.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan_axis.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan_axis.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan_axis.y -= 1.0

	if pan_axis != Vector2.ZERO:
		pan_screen(
			pan_axis.normalized(),
			pan_speed * delta
		)

	var rotation_direction: float = 0.0
	if Input.is_key_pressed(KEY_Q):
		rotation_direction -= 1.0
	if Input.is_key_pressed(KEY_E):
		rotation_direction += 1.0

	if rotation_direction != 0.0:
		rotate_by_degrees(
			rotation_direction
			* keyboard_rotation_speed_degrees
			* delta
		)


func _unhandled_input(event: InputEvent) -> void:
	if not is_configured():
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		match mouse_button.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if mouse_button.pressed:
					zoom_by_steps(1.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mouse_button.pressed:
					zoom_by_steps(-1.0)
			MOUSE_BUTTON_MIDDLE:
				_middle_dragging = mouse_button.pressed
			MOUSE_BUTTON_RIGHT:
				_right_dragging = mouse_button.pressed
		return

	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _middle_dragging:
			pan_screen(
				Vector2(-motion.relative.x, motion.relative.y),
				mouse_pan_sensitivity
			)
		if _right_dragging:
			rotate_by_degrees(
				-motion.relative.x
				* mouse_rotation_sensitivity
			)


func _refresh_bounds_from_tiles() -> void:
	var has_point: bool = false
	var min_x: float = 0.0
	var max_x: float = 0.0
	var min_z: float = 0.0
	var max_z: float = 0.0

	for child in tiles_root.get_children():
		if child is not Node3D:
			continue
		var node := child as Node3D
		var position := node.global_position
		if not has_point:
			min_x = position.x
			max_x = position.x
			min_z = position.z
			max_z = position.z
			has_point = true
		else:
			min_x = minf(min_x, position.x)
			max_x = maxf(max_x, position.x)
			min_z = minf(min_z, position.z)
			max_z = maxf(max_z, position.z)

	if not has_point:
		_bounds_min = Vector2(-10.0, -10.0)
		_bounds_max = Vector2(10.0, 10.0)
		return

	_bounds_min = Vector2(
		min_x - bounds_padding,
		min_z - bounds_padding
	)
	_bounds_max = Vector2(
		max_x + bounds_padding,
		max_z + bounds_padding
	)


func _clamp_target(value: Vector3) -> Vector3:
	return Vector3(
		clampf(value.x, _bounds_min.x, _bounds_max.x),
		_initial_target.y,
		clampf(value.z, _bounds_min.y, _bounds_max.y)
	)


func _apply_camera_transform() -> void:
	if camera == null:
		return

	var horizontal_distance: float = cos(_pitch_radians) * _distance
	var vertical_distance: float = sin(_pitch_radians) * _distance
	var offset := Vector3(
		sin(_yaw_radians) * horizontal_distance,
		vertical_distance,
		cos(_yaw_radians) * horizontal_distance
	)

	camera.global_position = _target + offset
	camera.look_at(_target, Vector3.UP)
	if not camera.is_current():
		camera.make_current()
