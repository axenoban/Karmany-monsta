extends Node3D


const HEX_TILE_SCENE: PackedScene = preload(
	"res://scenes/tiles/hex_tile_3d.tscn"
)


const CENTER_TILE_DATA: KarmanyTileData = preload(
	"res://data/tiles/i_01_refugio_valle_jade.tres"
)


const GRID_HEX_SIZE: float = 1.0
const VISUAL_HEX_SIZE: float = 0.94


@onready var board: Node3D = $Board
@onready var camera: Camera3D = $Camera3D


var board_state: KarmanyBoardState = KarmanyBoardState.new()
var selected_tile: KarmanyHexTile3D = null


func _ready() -> void:
	_build_board_state()
	_generate_board_from_state()

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
	print("FASE 2 - BoardState conectado a representacion 3D")
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
