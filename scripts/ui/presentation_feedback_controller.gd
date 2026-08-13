class_name KarmanyPresentationFeedbackController
extends Node


signal feedback_started(kind: StringName)
signal feedback_finished(kind: StringName)


const FEEDBACK_MOVE: StringName = &"unit_move"
const FEEDBACK_REVEAL: StringName = &"tile_reveal"
const FEEDBACK_SELECTION: StringName = &"selection"
const FEEDBACK_HIT: StringName = &"hit"
const FEEDBACK_DAMAGE: StringName = &"damage"
const FEEDBACK_APPEARANCE: StringName = &"karmany_appearance"
const FEEDBACK_TRANSITION: StringName = &"transition"


@export_group("Timing")
@export var movement_duration: float = 0.28
@export var reveal_duration: float = 0.32
@export var selection_duration: float = 0.18
@export var hit_duration: float = 0.18
@export var damage_duration: float = 0.55
@export var appearance_duration: float = 0.42
@export var transition_duration: float = 0.22


var world_feedback_root: Node3D = null
var overlay_rect: ColorRect = null
var overlay_label: Label = null
var duration_scale: float = 1.0

var _feedback_counts: Dictionary = {}
var _node_tweens: Dictionary = {}
var _transition_tween: Tween = null


func configure(
	p_world_feedback_root: Node3D,
	p_overlay_rect: ColorRect,
	p_overlay_label: Label
) -> bool:
	if p_world_feedback_root == null:
		return false
	if p_overlay_rect == null or p_overlay_label == null:
		return false

	world_feedback_root = p_world_feedback_root
	overlay_rect = p_overlay_rect
	overlay_label = p_overlay_label
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.color.a = 0.0
	overlay_label.visible = false
	return true


func set_duration_scale(value: float) -> void:
	duration_scale = maxf(value, 0.0)


func get_feedback_count(kind: StringName) -> int:
	return int(_feedback_counts.get(kind, 0))


func animate_unit_move(
	unit: Node3D,
	from_position: Vector3,
	to_position: Vector3
) -> bool:
	if unit == null:
		return false

	_begin_feedback(FEEDBACK_MOVE)
	_kill_node_tween(unit)
	unit.global_position = from_position

	var duration: float = _scaled_duration(movement_duration)
	if duration <= 0.0:
		unit.global_position = to_position
		_finish_feedback(FEEDBACK_MOVE)
		return true

	var tween := create_tween()
	_node_tweens[unit.get_instance_id()] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(unit, "global_position", to_position, duration)
	tween.finished.connect(
		func() -> void:
			_node_tweens.erase(unit.get_instance_id())
			_finish_feedback(FEEDBACK_MOVE)
	)
	return true


func animate_tile_reveal(tile: Node3D) -> bool:
	if tile == null:
		return false

	_begin_feedback(FEEDBACK_REVEAL)
	_kill_node_tween(tile)
	var final_scale: Vector3 = tile.scale
	tile.scale = Vector3(
		final_scale.x * 0.12,
		final_scale.y * 0.35,
		final_scale.z * 0.12
	)

	var duration: float = _scaled_duration(reveal_duration)
	if duration <= 0.0:
		tile.scale = final_scale
		_finish_feedback(FEEDBACK_REVEAL)
		return true

	var tween := create_tween()
	_node_tweens[tile.get_instance_id()] = tween
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "scale", final_scale, duration)
	tween.finished.connect(
		func() -> void:
			_node_tweens.erase(tile.get_instance_id())
			_finish_feedback(FEEDBACK_REVEAL)
	)
	return true


func animate_selection(tile: Node3D) -> bool:
	if tile == null:
		return false

	_begin_feedback(FEEDBACK_SELECTION)
	_kill_node_tween(tile)
	var base_scale: Vector3 = tile.scale
	var pulse_scale: Vector3 = base_scale * 1.07
	var duration: float = _scaled_duration(selection_duration)

	if duration <= 0.0:
		tile.scale = base_scale
		_finish_feedback(FEEDBACK_SELECTION)
		return true

	var tween := create_tween()
	_node_tweens[tile.get_instance_id()] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(tile, "scale", pulse_scale, duration * 0.45)
	tween.tween_property(tile, "scale", base_scale, duration * 0.55)
	tween.finished.connect(
		func() -> void:
			_node_tweens.erase(tile.get_instance_id())
			_finish_feedback(FEEDBACK_SELECTION)
	)
	return true


func play_hit_feedback(target: Node3D) -> bool:
	if target == null or world_feedback_root == null:
		return false

	_begin_feedback(FEEDBACK_HIT)

	var flash := MeshInstance3D.new()
	flash.name = "HitFlash"
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	flash.mesh = mesh

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.92, 0.52, 0.82)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.78, 0.28, 1.0)
	material.emission_energy_multiplier = 2.0
	flash.material_override = material

	world_feedback_root.add_child(flash)
	flash.global_position = target.global_position + Vector3(0.0, 0.75, 0.0)
	flash.scale = Vector3.ONE * 0.35

	var duration: float = _scaled_duration(hit_duration)
	if duration <= 0.0:
		flash.queue_free()
		_finish_feedback(FEEDBACK_HIT)
		return true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "scale", Vector3.ONE * 1.65, duration)
	tween.parallel().tween_property(
		material,
		"albedo_color",
		Color(1.0, 0.92, 0.52, 0.0),
		duration
	)
	tween.finished.connect(
		func() -> void:
			if is_instance_valid(flash):
				flash.queue_free()
			_finish_feedback(FEEDBACK_HIT)
	)
	return true


func play_damage_feedback(
	target: Node3D,
	amount: int
) -> bool:
	if target == null or world_feedback_root == null:
		return false

	_begin_feedback(FEEDBACK_DAMAGE)

	var label := Label3D.new()
	label.name = "DamageFeedback"
	label.text = "-%d" % absi(amount)
	label.font_size = 48
	label.outline_size = 10
	label.modulate = Color(1.0, 0.35, 0.24, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	world_feedback_root.add_child(label)
	label.global_position = target.global_position + Vector3(0.0, 1.25, 0.0)

	var start_position: Vector3 = label.global_position
	var end_position: Vector3 = start_position + Vector3(0.0, 0.85, 0.0)
	var duration: float = _scaled_duration(damage_duration)
	if duration <= 0.0:
		label.queue_free()
		_finish_feedback(FEEDBACK_DAMAGE)
		return true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position", end_position, duration)
	tween.parallel().tween_property(
		label,
		"modulate",
		Color(1.0, 0.35, 0.24, 0.0),
		duration
	)
	tween.finished.connect(
		func() -> void:
			if is_instance_valid(label):
				label.queue_free()
			_finish_feedback(FEEDBACK_DAMAGE)
	)
	return true


func animate_karmany_appearance(target: Node3D) -> bool:
	if target == null:
		return false

	_begin_feedback(FEEDBACK_APPEARANCE)
	_kill_node_tween(target)
	var final_position: Vector3 = target.global_position
	var final_scale: Vector3 = target.scale
	target.visible = true
	target.global_position = final_position + Vector3(0.0, -0.35, 0.0)
	target.scale = final_scale * 0.08
	play_hit_feedback(target)

	var duration: float = _scaled_duration(appearance_duration)
	if duration <= 0.0:
		target.global_position = final_position
		target.scale = final_scale
		_finish_feedback(FEEDBACK_APPEARANCE)
		return true

	var tween := create_tween()
	_node_tweens[target.get_instance_id()] = tween
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "global_position", final_position, duration)
	tween.parallel().tween_property(target, "scale", final_scale, duration)
	tween.finished.connect(
		func() -> void:
			_node_tweens.erase(target.get_instance_id())
			_finish_feedback(FEEDBACK_APPEARANCE)
	)
	return true


func play_transition(message: String = "") -> bool:
	if overlay_rect == null or overlay_label == null:
		return false

	_begin_feedback(FEEDBACK_TRANSITION)
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()

	overlay_label.text = message
	overlay_label.visible = not message.is_empty()
	overlay_rect.color = Color(0.035, 0.045, 0.065, 0.0)
	var duration: float = _scaled_duration(transition_duration)

	if duration <= 0.0:
		overlay_rect.color.a = 0.0
		overlay_label.visible = false
		_finish_feedback(FEEDBACK_TRANSITION)
		return true

	_transition_tween = create_tween()
	_transition_tween.tween_property(
		overlay_rect,
		"color",
		Color(0.035, 0.045, 0.065, 0.58),
		duration
	)
	_transition_tween.tween_interval(duration * 0.45)
	_transition_tween.tween_property(
		overlay_rect,
		"color",
		Color(0.035, 0.045, 0.065, 0.0),
		duration
	)
	_transition_tween.finished.connect(
		func() -> void:
			overlay_label.visible = false
			_transition_tween = null
			_finish_feedback(FEEDBACK_TRANSITION)
	)
	return true


func create_demo_karmany_marker(
	world_position: Vector3,
	display_name: String = "Karmany"
) -> Node3D:
	if world_feedback_root == null:
		return null

	var root := Node3D.new()
	root.name = "KarmanyAppearanceDemo"
	world_feedback_root.add_child(root)
	root.global_position = world_position

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.30
	body_mesh.height = 0.90
	body.mesh = body_mesh
	body.position.y = 0.48

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.68, 0.78, 1.0)
	material.roughness = 0.55
	material.emission_enabled = true
	material.emission = Color(0.10, 0.28, 0.38, 1.0)
	material.emission_energy_multiplier = 0.7
	body.material_override = material
	root.add_child(body)

	var label := Label3D.new()
	label.text = display_name
	label.font_size = 34
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = 1.25
	root.add_child(label)

	animate_karmany_appearance(root)
	return root


func _scaled_duration(base_duration: float) -> float:
	return maxf(base_duration * duration_scale, 0.0)


func _kill_node_tween(node: Node) -> void:
	if node == null:
		return
	var instance_id: int = node.get_instance_id()
	if not _node_tweens.has(instance_id):
		return
	var tween := _node_tweens[instance_id] as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_node_tweens.erase(instance_id)


func _begin_feedback(kind: StringName) -> void:
	_feedback_counts[kind] = get_feedback_count(kind) + 1
	feedback_started.emit(kind)


func _finish_feedback(kind: StringName) -> void:
	feedback_finished.emit(kind)
