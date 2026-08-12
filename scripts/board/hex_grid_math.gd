class_name KarmanyHexGridMath
extends RefCounted


const SQRT_3: float = 1.7320508075688772


# Direcciones axiales de los seis vecinos de un hexágono.
const DIRECTIONS = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1)
]


static func get_neighbor(
	coord: Vector2i,
	direction: int
) -> Vector2i:

	if direction < 0 or direction >= DIRECTIONS.size():
		push_error("Dirección hexagonal inválida: %s" % direction)
		return coord

	return coord + DIRECTIONS[direction]


static func get_neighbors(
	coord: Vector2i
) -> Array[Vector2i]:

	var result: Array[Vector2i] = []

	for direction_index in range(DIRECTIONS.size()):
		result.append(
			coord + DIRECTIONS[direction_index]
		)

	return result


static func distance(
	a: Vector2i,
	b: Vector2i
) -> int:

	var a_s: int = -a.x - a.y
	var b_s: int = -b.x - b.y

	var dq: int = abs(a.x - b.x)
	var dr: int = abs(a.y - b.y)
	var ds: int = abs(a_s - b_s)

	return int((dq + dr + ds) / 2)


static func are_adjacent(
	a: Vector2i,
	b: Vector2i
) -> bool:

	return distance(a, b) == 1


static func axial_to_world(
	coord: Vector2i,
	hex_size: float = 1.0,
	height: float = 0.0
) -> Vector3:

	var world_x: float = (
		hex_size
		* 1.5
		* float(coord.x)
	)

	var world_z: float = (
		hex_size
		* SQRT_3
		* (
			float(coord.y)
			+ float(coord.x) * 0.5
		)
	)

	return Vector3(
		world_x,
		height,
		world_z
	)
