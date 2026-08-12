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

var selected_tile: KarmanyHexTile3D = null

func _ready() -> void:

	_generate_board()

	camera.look_at(
		Vector3.ZERO,
		Vector3.UP
	)

	print("")
	print("================================")
	print("KARMANY MONSTA - 3D BOARD")
	print("================================")
	print("7 hexagonos generados.")
	print("Centro: I-01 Refugio del Valle Jade")
	print("FASE 1E OK")
	print("================================")


func _generate_board() -> void:

	var coordinates: Array[Vector2i] = []

	coordinates.append(
		Vector2i.ZERO
	)


	var neighbors := (
		KarmanyHexGridMath.get_neighbors(
			Vector2i.ZERO
		)
	)


	for neighbor in neighbors:
		coordinates.append(neighbor)


	for current_coord in coordinates:

		var tile := (
			HEX_TILE_SCENE.instantiate()
			as KarmanyHexTile3D
		)


		tile.coord = current_coord

		tile.hex_size = VISUAL_HEX_SIZE

		tile.position = (
			KarmanyHexGridMath.axial_to_world(
				current_coord,
				GRID_HEX_SIZE
			)
		)


		if current_coord == Vector2i.ZERO:

			tile.tile_data = CENTER_TILE_DATA

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


	print("")
	print("--------------------------------")
	print("LOSETA SELECCIONADA")
	print("--------------------------------")

	print(
		"Coordenada: ",
		tile.coord
	)


	if tile.tile_data != null:

		print(
			"ID: ",
			tile.tile_data.tile_id
		)

		print(
			"Nombre: ",
			tile.tile_data.display_name
		)

		print(
			"Nivel: ",
			KarmanyTileData.TileLevel.keys()[
				tile.tile_data.level
			]
		)

	else:

		print(
			"Datos: Sin KarmanyTileData asignado"
		)


	print("--------------------------------")
