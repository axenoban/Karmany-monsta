extends Node


@onready var prototype: KarmanyPhase21CameraBridge = $Phase21CameraPrototype


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 21 CAMERA TEST")
	print("================================")

	var ok: bool = true
	ok = _test_initial_camera() and ok
	ok = _test_zoom_limits() and ok
	ok = _test_pan_bounds_and_rotation() and ok
	ok = _test_focus_helpers() and ok
	ok = _test_reset_view() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 21 OK - Paneo, zoom, rotacion, limites y enfoque validados.")
	else:
		push_error("FASE 21 ERROR - Revisar camara estrategica.")
	print("================================")


func _test_initial_camera() -> bool:
	var controller: KarmanyStrategicCameraController = prototype.camera_controller
	var ok: bool = true
	ok = _expect(controller != null and controller.is_configured(), "El controlador debe quedar configurado.") and ok
	if controller == null:
		return false

	ok = _expect(prototype.board_ux.board_camera.is_current(), "La Camera3D del tablero debe seguir activa.") and ok
	ok = _expect(prototype.tiles_root.get_child_count() == 7, "El sandbox debe conservar sus 7 losetas.") and ok
	var bounds: Rect2 = controller.get_bounds()
	ok = _expect(bounds.size.x > 0.0 and bounds.size.y > 0.0, "Los limites deben calcularse desde el tablero.") and ok
	print("Camara activa + limites derivados de 7 losetas: ", "OK" if ok else "ERROR")
	return ok


func _test_zoom_limits() -> bool:
	var controller: KarmanyStrategicCameraController = prototype.camera_controller
	var ok: bool = true
	controller.zoom_by_steps(100.0)
	ok = _expect(
		is_equal_approx(controller.get_distance(), controller.get_min_distance()),
		"El zoom-in debe respetar distancia minima."
	) and ok

	controller.zoom_by_steps(-100.0)
	ok = _expect(
		is_equal_approx(controller.get_distance(), controller.get_max_distance()),
		"El zoom-out debe respetar distancia maxima."
	) and ok
	controller.reset_view()
	print("Zoom con limites minimo/maximo: ", "OK" if ok else "ERROR")
	return ok


func _test_pan_bounds_and_rotation() -> bool:
	var controller: KarmanyStrategicCameraController = prototype.camera_controller
	var ok: bool = true
	var bounds: Rect2 = controller.get_bounds()

	controller.pan_world(Vector2(999.0, 999.0))
	var target: Vector3 = controller.get_target()
	ok = _expect(target.x <= bounds.end.x + 0.001, "Paneo X no debe superar limite maximo.") and ok
	ok = _expect(target.z <= bounds.end.y + 0.001, "Paneo Z no debe superar limite maximo.") and ok

	controller.pan_world(Vector2(-1998.0, -1998.0))
	target = controller.get_target()
	ok = _expect(target.x >= bounds.position.x - 0.001, "Paneo X no debe superar limite minimo.") and ok
	ok = _expect(target.z >= bounds.position.y - 0.001, "Paneo Z no debe superar limite minimo.") and ok

	controller.reset_view()
	var yaw_before: float = controller.get_yaw_degrees()
	controller.rotate_by_degrees(45.0)
	var yaw_after: float = controller.get_yaw_degrees()
	ok = _expect(absf(yaw_after - yaw_before) > 1.0, "La rotacion debe modificar el yaw.") and ok
	ok = _expect(prototype.board_ux.board_camera.is_current(), "Rotar no debe perder la camara activa.") and ok
	print("Paneo limitado + rotacion estrategica: ", "OK" if ok else "ERROR")
	return ok


func _test_focus_helpers() -> bool:
	var controller: KarmanyStrategicCameraController = prototype.camera_controller
	var ok: bool = true
	var coord := Vector2i(1, 0)
	var tile_value: Variant = prototype.board_ux.board_prototype.call("get_tile_view", coord)
	var tile := tile_value as KarmanyHexTile3D
	ok = _expect(tile != null, "Debe existir una loseta para probar enfoque.") and ok
	if tile == null:
		return false

	tile.tile_clicked.emit(tile)
	ok = _expect(tile.is_selected(), "La seleccion de Fase 20 debe seguir funcionando con la camara.") and ok
	ok = _expect(prototype.focus_selected_tile(), "F debe poder enfocarse conceptualmente en la loseta seleccionada.") and ok
	var target: Vector3 = controller.get_target()
	ok = _expect(
		Vector2(target.x, target.z).distance_to(
			Vector2(tile.global_position.x, tile.global_position.z)
		) < 0.001,
		"El foco de loseta debe centrar su posicion XZ."
	) and ok

	ok = _expect(prototype.focus_active_trainer(), "Debe poder enfocarse el Entrenador activo del sandbox.") and ok
	var trainer_value: Variant = prototype.board_ux.board_prototype.get("trainer_unit")
	var trainer := trainer_value as KarmanyTrainerUnit3D
	ok = _expect(trainer != null, "Debe existir TrainerUnit3D para enfoque.") and ok
	if trainer != null:
		target = controller.get_target()
		ok = _expect(
			Vector2(target.x, target.z).distance_to(
				Vector2(trainer.global_position.x, trainer.global_position.z)
			) < 0.001,
			"El foco del Entrenador debe centrar su posicion XZ."
		) and ok

	prototype.focus_event_world_position(Vector3(0.5, 0.0, 0.5))
	target = controller.get_target()
	ok = _expect(
		Vector2(target.x, target.z).distance_to(Vector2(0.5, 0.5)) < 0.001,
		"El API de enfoque de eventos debe aceptar una posicion del mundo."
	) and ok
	print("Seleccion + foco loseta/Entrenador/evento: ", "OK" if ok else "ERROR")
	return ok


func _test_reset_view() -> bool:
	var controller: KarmanyStrategicCameraController = prototype.camera_controller
	var ok: bool = true
	prototype.reset_camera_view()
	var target: Vector3 = controller.get_target()
	ok = _expect(
		Vector2(target.x, target.z).distance_to(Vector2.ZERO) < 0.001,
		"Home/reset debe volver al centro inicial."
	) and ok
	ok = _expect(prototype.board_ux.board_camera.is_current(), "Reset debe conservar la camara activa.") and ok
	print("Restauracion de vista inicial: ", "OK" if ok else "ERROR")
	return ok


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 21 ERROR: %s" % message)
	return false
