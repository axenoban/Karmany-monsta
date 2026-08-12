extends Node


const BOARD_SCENE: PackedScene = preload(
	"res://scenes/board/board_3d_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 1 BOARD TEST")
	print("================================")

	var test_passed: bool = true
	var board_scene := BOARD_SCENE.instantiate()
	add_child(board_scene)

	# Allow the board and every generated tile to finish _ready().
	await get_tree().process_frame

	var board_node := board_scene.get_node_or_null("Board") as Node3D

	if board_node == null:
		test_passed = false
		push_error("PHASE 1 ERROR: Board node was not found.")
		_finish_test(test_passed, board_scene)
		return

	var children := board_node.get_children()
	var tiles: Array[KarmanyHexTile3D] = []
	var seen_coords: Dictionary = {}
	var center_tile: KarmanyHexTile3D = null

	if children.size() != 7:
		test_passed = false
		push_error(
			"PHASE 1 ERROR: Expected 7 generated hexes, got %s."
			% children.size()
		)

	for child in children:
		if not child is KarmanyHexTile3D:
			test_passed = false
			push_error(
				"PHASE 1 ERROR: Board contains a non-KarmanyHexTile3D child: %s."
				% child.name
			)
			continue

		var tile := child as KarmanyHexTile3D
		tiles.append(tile)

		var coord_key := "%s,%s" % [tile.coord.x, tile.coord.y]

		if seen_coords.has(coord_key):
			test_passed = false
			push_error(
				"PHASE 1 ERROR: Duplicate coordinate detected: %s."
				% tile.coord
			)
		else:
			seen_coords[coord_key] = true

		if tile.get_node_or_null("UnitAnchor") == null:
			test_passed = false
			push_error(
				"PHASE 1 ERROR: %s has no UnitAnchor."
				% tile.name
			)

		if tile.coord == Vector2i.ZERO:
			center_tile = tile
		elif not KarmanyHexGridMath.are_adjacent(Vector2i.ZERO, tile.coord):
			test_passed = false
			push_error(
				"PHASE 1 ERROR: Outer tile %s is not adjacent to the center."
				% tile.coord
			)

	if seen_coords.size() != 7:
		test_passed = false
		push_error(
			"PHASE 1 ERROR: Expected 7 unique coordinates, got %s."
			% seen_coords.size()
		)

	if center_tile == null:
		test_passed = false
		push_error("PHASE 1 ERROR: Center coordinate (0, 0) was not generated.")
	elif center_tile.tile_data == null:
		test_passed = false
		push_error("PHASE 1 ERROR: Center tile has no KarmanyTileData.")
	elif center_tile.tile_data.tile_id != "I-01":
		test_passed = false
		push_error(
			"PHASE 1 ERROR: Center tile should be I-01, got %s."
			% center_tile.tile_data.tile_id
		)

	# Validate the board-level selection wiring without duplicating input logic.
	if tiles.size() >= 2:
		var first_tile := tiles[0]
		var second_tile := tiles[1]

		first_tile.tile_clicked.emit(first_tile)

		if board_scene.get("selected_tile") != first_tile:
			test_passed = false
			push_error("PHASE 1 ERROR: First tile was not registered as selected.")

		if not first_tile.is_selected():
			test_passed = false
			push_error("PHASE 1 ERROR: First tile did not enter selected visual state.")

		second_tile.tile_clicked.emit(second_tile)

		if board_scene.get("selected_tile") != second_tile:
			test_passed = false
			push_error("PHASE 1 ERROR: Selection did not move to the second tile.")

		if first_tile.is_selected():
			test_passed = false
			push_error("PHASE 1 ERROR: Previous tile remained selected.")

		if not second_tile.is_selected():
			test_passed = false
			push_error("PHASE 1 ERROR: Second tile did not enter selected visual state.")
	else:
		test_passed = false
		push_error("PHASE 1 ERROR: Not enough tiles to validate selection.")

	_finish_test(test_passed, board_scene)


func _finish_test(test_passed: bool, board_scene: Node) -> void:
	print("")
	print("================================")

	if test_passed:
		print("FASE 1 OK - Sistema hexagonal 3D validado.")
	else:
		push_error("FASE 1 ERROR - Revisar sistema hexagonal 3D.")

	print("================================")
	board_scene.queue_free()
