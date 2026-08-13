class_name KarmanyPerformanceMetrics
extends RefCounted


static func runtime_monitors() -> Dictionary:
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"render_objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"render_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"texture_memory_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"buffer_memory_bytes": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)
	}


static func tile_resource_counts(match: KarmanyPhase24FullMatchBridge) -> Dictionary:
	if match == null or match.board_prototype == null:
		return {}
	var tile_count: int = 0
	var meshes: Dictionary = {}
	var materials: Dictionary = {}
	var shapes: Dictionary = {}
	for coord in match.board_prototype.board_state.get_coords():
		var value: Variant = match.board_prototype.call("get_tile_view", coord)
		var tile := value as KarmanyHexTile3D
		if tile == null:
			continue
		tile_count += 1
		if tile.mesh_instance != null and tile.mesh_instance.mesh != null:
			meshes[tile.mesh_instance.mesh.get_instance_id()] = true
		if tile.mesh_instance != null and tile.mesh_instance.material_override != null:
			materials[tile.mesh_instance.material_override.get_instance_id()] = true
		if tile.collision_shape != null and tile.collision_shape.shape != null:
			shapes[tile.collision_shape.shape.get_instance_id()] = true
	return {
		"tile_count": tile_count,
		"unique_mesh_resources": meshes.size(),
		"unique_material_resources": materials.size(),
		"unique_collision_shapes": shapes.size()
	}


static func turn_signal_counts(manager: KarmanyTurnManager) -> Dictionary:
	if manager == null:
		return {}
	var result: Dictionary = {}
	var signal_names: Array[StringName] = [
		&"round_started",
		&"round_ended",
		&"turn_started",
		&"turn_ended",
		&"action_spent"
	]
	for signal_name in signal_names:
		result[String(signal_name)] = manager.get_signal_connection_list(signal_name).size()
	return result


static func timing(elapsed_us: int, iterations: int) -> Dictionary:
	return {
		"iterations": iterations,
		"total_us": elapsed_us,
		"average_us": float(elapsed_us) / float(maxi(iterations, 1))
	}
