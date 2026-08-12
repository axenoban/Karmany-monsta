extends Node3D


const HEX_TILE_SCENE: PackedScene = preload(
	"res://scenes/tiles/hex_tile_3d.tscn"
)

const TRAINER_UNIT_SCENE: PackedScene = preload(
	"res://scenes/trainers/trainer_unit_3d.tscn"
)

const CENTER_TILE_DATA: KarmanyTileData = preload(
	"res://data/tiles/i_01_refugio_valle_jade.tres"
)


const GRID_HEX_SIZE: float = 1.0
const VISUAL_HEX_SIZE: float = 0.94
const PROTOTYPE_PLAYER_ID: StringName = &"player_1"
const PROTOTYPE_TRAINER_UNIT_ID: StringName = &"trainer_player_1"


@onready var board: Node3D = $Board
@onready var units: Node3D = $Units
@onready var camera: Camera3D = $Camera3D


var board_state: KarmanyBoardState = KarmanyBoardState.new()
var player_state: KarmanyPlayerState = KarmanyPlayerState.new()
var trainer_unit: KarmanyTrainerUnit3D = null
var selected_tile: KarmanyHexTile3D = null

var _tile_views: Dictionary = {}


func _ready() -> void:
	_build_board_state()
	_generate_board_from_state()
	_spawn_prototype_trainer()

	camera.look_at(
		Vector3.ZERO,
		Vector3.UP
	)

	print("")
	print("================================")
	print("KARMANY MONSTA - 3D BOARD")
	print("================================")
	print(board_state.get_cell_count(), " hexagonos logicos generados.")
	print("Centro: I-01 Refugio del Valle Jade")
	print("Entrenador: ", PROTOTYPE_TRAINER_UNIT_ID, " en ", player_state.current_coord)
	print("FASE 3 - Unidad 3D conectada a BoardState y UnitAnchor")
	print("================================")


func _build_board_state() -> void:
	board_state.clear()

	var center := Vector2i.ZERO

	board_state.add_cell(
		center,
		CENTER_TILE_DATA,
		CENTER_TILE_DATA.starts_revealed
	)

	for neighbor in KarmanyHexGridMath.get_neighbors(center):
		board_state.add_cell(
			neighbor,
			null,
			false
		)


func _generate_board_from_state() -> void:
	_tile_views.clear()

	for current_coord in board_state.get_coords():
		var cell := board_state.get_cell(current_coord)

		if cell == null:
			continue

		var tile := (
			HEX_TILE_SCENE.instantiate()
			as KarmanyHexTile3D
		)

		tile.coord = current_coord
		tile.tile_data = cell.tile_data
		tile.hex_size = VISUAL_HEX_SIZE

		tile.position = (
			KarmanyHexGridMath.axial_to_world(
				current_coord,
				GRID_HEX_SIZE
			)
		)

		if cell.revealed and cell.tile_data != null:
			tile.base_color = Color(
				0.30,
				0.48,
				0.27,
				1.0
			)
		else:
			tile.base_color = Color(
				0.17,
				0.21,
				0.27,
				1.0
			)

		tile.name = (
			"Hex_%s_%s"
			% [
				current_coord.x,
				current_coord.y
			]
		)

		tile.tile_clicked.connect(
			_on_tile_clicked
		)

		board.add_child(tile)
		_tile_views[current_coord] = tile


func _spawn_prototype_trainer() -> void:
	player_state.setup_new_game(
		PROTOTYPE_PLAYER_ID,
		Vector2i.ZERO
	)

	trainer_unit = (
		TRAINER_UNIT_SCENE.instantiate()
		as KarmanyTrainerUnit3D
	)

	if trainer_unit == null:
		push_error("FASE 3 ERROR: No se pudo instanciar TrainerUnit3D.")
		return

	trainer_unit.configure(
		player_state,
		PROTOTYPE_TRAINER_UNIT_ID
	)

	units.add_child(trainer_unit)

	if not place_trainer_at(Vector2i.ZERO):
		push_error("FASE 3 ERROR: No se pudo colocar el Entrenador en el centro.")


func get_tile_view(coord: Vector2i) -> KarmanyHexTile3D:
	if not _tile_views.has(coord):
		return null

	return _tile_views[coord] as KarmanyHexTile3D


func place_trainer_at(coord: Vector2i) -> bool:
	if trainer_unit == null:
		return false

	if not board_state.has_coord(coord):
		return false

	var target_tile := get_tile_view(coord)

	if target_tile == null:
		return false

	var target_occupant := board_state.get_occupying_unit_id(coord)

	if (
		target_occupant != &""
		and target_occupant != trainer_unit.unit_id
	):
		return false

	var previous_coord := player_state.current_coord

	if (
		board_state.has_coord(previous_coord)
		and board_state.get_occupying_unit_id(previous_coord) == trainer_unit.unit_id
	):
		board_state.clear_unit_occupant(previous_coord)

	if not board_state.set_unit_occupant(
		coord,
		trainer_unit.unit_id
	):
		return false

	if not trainer_unit.place_at(
		target_tile.unit_anchor,
		coord
	):
		board_state.clear_unit_occupant(coord)
		return false

	return true


func _on_tile_clicked(
	tile: KarmanyHexTile3D
) -> void:
	if selected_tile != null:
		if selected_tile != tile:
			selected_tile.set_selected(false)

	selected_tile = tile
	selected_tile.set_selected(true)

	var cell := board_state.get_cell(tile.coord)

	print("")
	print("--------------------------------")
	print("LOSETA SELECCIONADA")
	print("--------------------------------")
	print("Coordenada: ", tile.coord)

	if cell == null:
		print("Estado logico: coordenada no registrada")
		print("--------------------------------")
		return

	print("Revelada: ", cell.revealed)

	if cell.tile_data != null:
		print("ID: ", cell.tile_data.tile_id)
		print("Nombre: ", cell.tile_data.display_name)
		print(
			"Nivel: ",
			KarmanyTileData.TileLevel.keys()[
				cell.tile_data.level
			]
		)
	else:
		print("Datos: Sin KarmanyTileData asignado")

	if cell.is_occupied():
		print("Ocupante: ", cell.occupying_unit_id)
	else:
		print("Ocupante: ninguno")

	print("--------------------------------")
