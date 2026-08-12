class_name KarmanyHexTile3D
extends StaticBody3D


signal tile_clicked(tile: KarmanyHexTile3D)


@export_group("Karmany Data")

@export var coord: Vector2i = Vector2i.ZERO
@export var tile_data: KarmanyTileData


@export_group("Geometry")

@export_range(0.2, 5.0, 0.05) var hex_size: float = 1.0
@export_range(0.05, 1.0, 0.01) var thickness: float = 0.22


@export_group("Appearance")

@export var base_color: Color = Color(
	0.24,
	0.32,
	0.25,
	1.0
)

@export var hover_color: Color = Color(
	0.35,
	0.65,
	0.85,
	1.0
)

@export var selected_color: Color = Color(
	0.85,
	0.65,
	0.22,
	1.0
)

@export_range(0.0, 360.0, 1.0) var visual_y_rotation_degrees: float = 30.0


@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var unit_anchor: Marker3D = $UnitAnchor


var _material: StandardMaterial3D

var _is_hovered: bool = false
var _is_selected: bool = false


func _ready() -> void:

	rotation_degrees.y = visual_y_rotation_degrees

	input_ray_pickable = true
	collision_layer = 1

	_build_mesh()
	_build_collision()

	unit_anchor.position.y = thickness * 0.5 + 0.05

	_refresh_visual()


func _build_mesh() -> void:

	var hex_mesh := CylinderMesh.new()

	hex_mesh.top_radius = hex_size
	hex_mesh.bottom_radius = hex_size
	hex_mesh.height = thickness
	hex_mesh.radial_segments = 6

	mesh_instance.mesh = hex_mesh


	_material = StandardMaterial3D.new()

	_material.albedo_color = base_color
	_material.roughness = 0.85

	mesh_instance.material_override = _material


func _build_collision() -> void:

	var shape := ConvexPolygonShape3D.new()

	var points := PackedVector3Array()

	var half_height: float = thickness * 0.5


	for i in range(6):

		var angle: float = deg_to_rad(
			60.0 * float(i)
		)

		var x: float = cos(angle) * hex_size
		var z: float = sin(angle) * hex_size


		points.append(
			Vector3(
				x,
				half_height,
				z
			)
		)

		points.append(
			Vector3(
				x,
				-half_height,
				z
			)
		)


	shape.points = points

	collision_shape.shape = shape


func _mouse_enter() -> void:

	_is_hovered = true
	_refresh_visual()


func _mouse_exit() -> void:

	_is_hovered = false
	_refresh_visual()


func _input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:

	if event is InputEventMouseButton:

		var mouse_event := event as InputEventMouseButton

		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		):
			tile_clicked.emit(self)


func set_selected(value: bool) -> void:

	_is_selected = value
	_refresh_visual()


func is_selected() -> bool:

	return _is_selected


func set_base_color(value: Color) -> void:
	base_color = value
	_refresh_visual()


func _refresh_visual() -> void:

	if _material == null:
		return


	if _is_selected:

		_material.albedo_color = selected_color

	elif _is_hovered:

		_material.albedo_color = hover_color

	else:

		_material.albedo_color = base_color
