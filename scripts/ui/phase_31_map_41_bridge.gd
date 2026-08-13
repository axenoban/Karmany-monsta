class_name KarmanyPhase31Map41Bridge
extends Node3D

const HEX_TILE_SCENE: PackedScene = preload("res://scenes/tiles/hex_tile_3d.tscn")
const TRAINER_UNIT_SCENE: PackedScene = preload("res://scenes/trainers/trainer_unit_3d.tscn")

const GRID_HEX_SIZE: float = 1.0
const VISUAL_HEX_SIZE: float = 0.94
const PROTOTYPE_PLAYER_ID: StringName = &"player_1"
const PROTOTYPE_UNIT_ID: StringName = &"trainer_player_1"

const COLOR_START: Color = Color(0.24, 0.58, 0.38, 1.0)
const COLOR_N1: Color = Color(0.25, 0.46, 0.66, 1.0)
const COLOR_N2: Color = Color(0.34, 0.34, 0.58, 1.0)
const COLOR_N3: Color = Color(0.62, 0.46, 0.22, 1.0)
const COLOR_LEGENDARY: Color = Color(0.70, 0.34, 0.18, 1.0)
const COLOR_FALLBACK: Color = Color(0.30, 0.34, 0.38, 1.0)

@onready var board: Node3D = $Board
@onready var units: Node3D = $Units
@onready var camera: Camera3D = $Camera3D
@onready var camera_controller: KarmanyStrategicCameraController = $StrategicCameraController
@onready var status_label: Label = $Phase31Overlay/MainMargin/Panel/InnerMargin/VBox/StatusLabel
@onready var selection_label: Label = $Phase31Overlay/MainMargin/Panel/InnerMargin/VBox/SelectionLabel

var board_state: KarmanyBoardState = KarmanyBoardState.new()
var player_state: KarmanyPlayerState = KarmanyPlayerState.new()
var trainer_unit: KarmanyTrainerUnit3D = null
var selected_tile: KarmanyHexTile3D = null
var setup_ok: bool = false

var _level_map: Dictionary = {}
var _tile_views: Dictionary = {}

func _ready() -> void:
	setup_ok = _setup_map_41()
	if setup_ok:
		print("")
		print("================================")
		print("KARMANY MONSTA - FASE 31 MAPA 41")
		print("================================")
		print("Posiciones: 41 | I 4 | N1 18 | N2 12 | N3 6 | L 1")
		print("Inicial de prueba: ", player_state.current_coord)
		print("Camara: WASD/flechas pan | rueda zoom | Q-E rotar | F foco | C jugador | Home reset")
		print("FASE 31 VISUAL OK - geometria canonica y camara estrategica activas.")
		print("================================")
	else:
		push_error("FASE 31 ERROR: No se pudo construir el mapa canonico de 41 posiciones.")

func _setup_map_41() -> bool:
	_level_map = KarmanyCanonicalMap41Layout.build_level_map()
	if _level_map.size() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return false
	if not KarmanyCanonicalMap41Layout.is_connected():
		return false

	board_state.clear()
	_tile_views.clear()
	for coord_value in _level_map.keys():
		var coord: Vector2i = coord_value
		var level: int = int(_level_map[coord])
		var structurally_revealed: bool = (
			level == KarmanyTileData.TileLevel.START
			or level == KarmanyTileData.TileLevel.SANCTUARY
		)
		if not board_state.add_cell(coord, null, structurally_revealed):
			return false
		if not _spawn_tile(coord, level):
			return false

	if not _spawn_prototype_trainer():
		return false
	if not camera_controller.configure(camera, board, Vector3.ZERO):
		return false

	_update_overlay()
	return true

func _spawn_tile(coord: Vector2i, level: int) -> bool:
	var tile := HEX_TILE_SCENE.instantiate() as KarmanyHexTile3D
	if tile == null:
		return false

	tile.coord = coord
	tile.tile_data = null
	tile.hex_size = VISUAL_HEX_SIZE
	tile.base_color = _get_level_color(level)
	tile.position = KarmanyHexGridMath.axial_to_world(coord, GRID_HEX_SIZE)
	tile.name = "Hex_%s_%s" % [coord.x, coord.y]
	tile.tile_clicked.connect(_on_tile_clicked)
	board.add_child(tile)
	_tile_views[coord] = tile
	return true

func _spawn_prototype_trainer() -> bool:
	var starting_coords := KarmanyCanonicalMap41Layout.get_starting_coords()
	if starting_coords.is_empty():
		return false
	var start_coord: Vector2i = starting_coords[0]
	var start_tile := get_tile_view(start_coord)
	if start_tile == null:
		return false

	player_state.setup_new_game(PROTOTYPE_PLAYER_ID, start_coord)
	trainer_unit = TRAINER_UNIT_SCENE.instantiate() as KarmanyTrainerUnit3D
	if trainer_unit == null:
		return false
	trainer_unit.configure(player_state, PROTOTYPE_UNIT_ID)
	units.add_child(trainer_unit)
	if not board_state.set_unit_occupant(start_coord, PROTOTYPE_UNIT_ID):
		return false
	return trainer_unit.place_at(start_tile.unit_anchor, start_coord)

func get_tile_view(coord: Vector2i) -> KarmanyHexTile3D:
	if not _tile_views.has(coord):
		return null
	return _tile_views[coord] as KarmanyHexTile3D

func get_visual_tile_count() -> int:
	return _tile_views.size()

func get_level_map() -> Dictionary:
	return _level_map.duplicate()

func get_level_count(level: int) -> int:
	var count: int = 0
	for level_value in _level_map.values():
		if int(level_value) == level:
			count += 1
	return count

func _get_level_color(level: int) -> Color:
	match level:
		KarmanyTileData.TileLevel.START:
			return COLOR_START
		KarmanyTileData.TileLevel.N1:
			return COLOR_N1
		KarmanyTileData.TileLevel.N2:
			return COLOR_N2
		KarmanyTileData.TileLevel.N3:
			return COLOR_N3
		KarmanyTileData.TileLevel.SANCTUARY:
			return COLOR_LEGENDARY
		_:
			return COLOR_FALLBACK

func _on_tile_clicked(tile: KarmanyHexTile3D) -> void:
	if tile == null:
		return
	if selected_tile != null and selected_tile != tile:
		selected_tile.set_selected(false)
	selected_tile = tile
	selected_tile.set_selected(true)
	var level: int = int(_level_map.get(tile.coord, -1))
	selection_label.text = "Seleccion: %s en %s. Contenido aun no asignado." % [
		KarmanyCanonicalMap41Layout.get_level_short_name(level),
		tile.coord
	]

func _update_overlay() -> void:
	status_label.text = "41 posiciones | I 4 | N1 18 | N2 12 | N3 6 | L 1 | cuatro accesos externos."
	selection_label.text = (
		"Verde=I | azul=N1 | violeta=N2 | ambar=N3 | naranja=L. "
		+ "N1/N2/N3 muestran nivel sin revelar identidad."
	)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_F:
			if selected_tile != null:
				camera_controller.focus_world_position(selected_tile.global_position)
		KEY_C:
			if trainer_unit != null:
				camera_controller.focus_world_position(trainer_unit.global_position)
		KEY_HOME:
			camera_controller.reset_view()
