extends Node


const PHASE_24_SCENE: PackedScene = preload("res://scenes/ui/phase_24_full_match_prototype.tscn")
const REPORT_PATH: String = "user://karmany_phase27_baseline.json"
const LOGIC_ITERATIONS: int = 5000
const VISUAL_REFRESH_ITERATIONS: int = 50
const SNAPSHOT_ITERATIONS: int = 40

var match_instance: KarmanyPhase24FullMatchBridge = null
var report: Dictionary = {}


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 27 BASELINE DE RENDIMIENTO")
	print("================================")

	var ok: bool = await _measure_baseline()
	if ok:
		_print_report()
		print("FASE 27 BASELINE OK - Medicion completada; optimizar solo con estos datos.")
	else:
		push_error("FASE 27 BASELINE ERROR - No se pudo obtener una medicion valida.")
	print("================================")


func _measure_baseline() -> bool:
	var instantiate_start: int = Time.get_ticks_usec()
	match_instance = PHASE_24_SCENE.instantiate() as KarmanyPhase24FullMatchBridge
	var instantiate_us: int = Time.get_ticks_usec() - instantiate_start
	if match_instance == null:
		return false

	var ready_start: int = Time.get_ticks_usec()
	add_child(match_instance)
	await get_tree().process_frame
	await get_tree().process_frame
	var ready_us: int = Time.get_ticks_usec() - ready_start
	if not match_instance.setup_ok:
		return false

	var debug_overlay := match_instance.get_node_or_null("Phase24Overlay") as CanvasLayer
	if debug_overlay != null:
		debug_overlay.visible = false

	await get_tree().create_timer(1.15).timeout
	report = {
		"phase": 27,
		"purpose": "baseline_before_optimization",
		"startup": {
			"instantiate_us": instantiate_us,
			"attach_ready_2frames_us": ready_us
		},
		"runtime_before_stress": KarmanyPerformanceMetrics.runtime_monitors(),
		"scene_structure": _scene_structure(),
		"tile_resources": KarmanyPerformanceMetrics.tile_resource_counts(match_instance),
		"signal_connections": KarmanyPerformanceMetrics.turn_signal_counts(match_instance.turn_manager),
		"benchmarks": {}
	}

	var movement: Dictionary = _benchmark_movement()
	var exploration: Dictionary = _benchmark_exploration()
	var snapshots: Dictionary = _benchmark_snapshot_capture()
	var visual: Dictionary = await _benchmark_visual_refresh()
	report["benchmarks"] = {
		"movement_validation": movement,
		"exploration_validation": exploration,
		"save_snapshot_capture": snapshots,
		"visual_direction_refresh": visual
	}
	report["runtime_after_stress"] = KarmanyPerformanceMetrics.runtime_monitors()
	report["observations"] = _observations()
	_save_report()
	return (
		int(report["tile_resources"].get("tile_count", 0)) == 7
		and int(movement.get("valid_results", 0)) == LOGIC_ITERATIONS
		and int(exploration.get("valid_results", 0)) == LOGIC_ITERATIONS
		and int(snapshots.get("non_empty_results", 0)) == SNAPSHOT_ITERATIONS
	)


func _benchmark_movement() -> Dictionary:
	var valid_count: int = 0
	var start: int = Time.get_ticks_usec()
	for _index in range(LOGIC_ITERATIONS):
		var validation := KarmanyMovementRules.validate_move(
			match_instance.board_prototype.board_state,
			match_instance.turn_manager,
			match_instance.player_1,
			KarmanyPhase24FullMatchBridge.P2_START
		)
		if validation == KarmanyMovementRules.MoveValidation.OK:
			valid_count += 1
	var result := KarmanyPerformanceMetrics.timing(Time.get_ticks_usec() - start, LOGIC_ITERATIONS)
	result["valid_results"] = valid_count
	return result


func _benchmark_exploration() -> Dictionary:
	var valid_count: int = 0
	var start: int = Time.get_ticks_usec()
	for _index in range(LOGIC_ITERATIONS):
		var validation := KarmanyExplorationRules.validate_exploration(
			match_instance.board_prototype.board_state,
			match_instance.turn_manager,
			match_instance.player_1,
			KarmanyPhase24FullMatchBridge.TILE_MR
		)
		if validation == KarmanyExplorationRules.ExplorationValidation.OK:
			valid_count += 1
	var result := KarmanyPerformanceMetrics.timing(Time.get_ticks_usec() - start, LOGIC_ITERATIONS)
	result["valid_results"] = valid_count
	return result


func _benchmark_snapshot_capture() -> Dictionary:
	var context := KarmanySaveGameContext.new()
	var players: Array[KarmanyPlayerState] = [match_instance.player_1, match_instance.player_2]
	var beast_decks: Dictionary = {"basic": match_instance.beast_deck, "complex": match_instance.complex_beast_deck}
	if not context.configure(
		match_instance.board_prototype.board_state,
		match_instance.turn_manager,
		players,
		match_instance.resonance_deck,
		match_instance.equipment_market,
		match_instance.legacy_points,
		match_instance.objectives_missions,
		match_instance.coordinator,
		beast_decks,
		match_instance.dorian_pvp
	):
		return {"error": "invalid_save_context"}
	var non_empty: int = 0
	var start: int = Time.get_ticks_usec()
	for _index in range(SNAPSHOT_ITERATIONS):
		var snapshot: Dictionary = KarmanySaveGameFacade.capture(context)
		if not snapshot.is_empty():
			non_empty += 1
	var result := KarmanyPerformanceMetrics.timing(Time.get_ticks_usec() - start, SNAPSHOT_ITERATIONS)
	result["non_empty_results"] = non_empty
	return result


func _benchmark_visual_refresh() -> Dictionary:
	var resources_before: float = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var memory_before: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var start: int = Time.get_ticks_usec()
	for _index in range(VISUAL_REFRESH_ITERATIONS):
		match_instance.phase_23.refresh_visual_direction()
	var elapsed: int = Time.get_ticks_usec() - start
	await get_tree().create_timer(1.15).timeout
	var result := KarmanyPerformanceMetrics.timing(elapsed, VISUAL_REFRESH_ITERATIONS)
	var resources_after: float = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	var memory_after: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	result["resource_count_before"] = resources_before
	result["resource_count_after"] = resources_after
	result["resource_count_delta"] = resources_after - resources_before
	result["static_memory_before"] = memory_before
	result["static_memory_after"] = memory_after
	result["static_memory_delta"] = memory_after - memory_before
	return result


func _scene_structure() -> Dictionary:
	var result: Dictionary = {
		"nodes": 0,
		"mesh_instances": 0,
		"collision_shapes": 0,
		"controls": 0,
		"scripted_nodes": 0,
		"unique_scripts": 0
	}
	var scripts: Dictionary = {}
	_count_structure(match_instance, result, scripts)
	result["unique_scripts"] = scripts.size()
	return result


func _count_structure(node: Node, counts: Dictionary, scripts: Dictionary) -> void:
	counts["nodes"] = int(counts["nodes"]) + 1
	if node is MeshInstance3D:
		counts["mesh_instances"] = int(counts["mesh_instances"]) + 1
	if node is CollisionShape3D:
		counts["collision_shapes"] = int(counts["collision_shapes"]) + 1
	if node is Control:
		counts["controls"] = int(counts["controls"]) + 1
	var script_value: Variant = node.get_script()
	if script_value is Script:
		counts["scripted_nodes"] = int(counts["scripted_nodes"]) + 1
		var script := script_value as Script
		var key: String = script.resource_path
		if key.is_empty():
			key = str(script.get_instance_id())
		scripts[key] = true
	for child in node.get_children():
		if child is Node:
			_count_structure(child, counts, scripts)


func _observations() -> Array[String]:
	var result: Array[String] = []
	var tile_data: Dictionary = report.get("tile_resources", {})
	var tile_count: int = int(tile_data.get("tile_count", 0))
	if tile_count > 0 and int(tile_data.get("unique_mesh_resources", 0)) == tile_count:
		result.append("Cada loseta usa Mesh propio; medir beneficio de compartir geometria antes de cambiarlo.")
	if tile_count > 0 and int(tile_data.get("unique_collision_shapes", 0)) == tile_count:
		result.append("Cada loseta usa CollisionShape propio; candidato de memoria, no cambio automatico.")
	var visual: Dictionary = report.get("benchmarks", {}).get("visual_direction_refresh", {})
	if float(visual.get("resource_count_delta", 0.0)) > 2.0:
		result.append("El refresh visual deja Resources adicionales vivos; candidato prioritario.")
	if float(report.get("runtime_before_stress", {}).get("orphans", 0.0)) > 0.0:
		result.append("Hay nodos huerfanos; investigar ciclo de vida antes de otras optimizaciones.")
	if result.is_empty():
		result.append("Sin hotspot estructural concluyente; usar tiempos/draw calls locales para decidir.")
	return result


func _save_report() -> void:
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("FASE 27: no se pudo escribir el reporte JSON.")
		return
	file.store_string(JSON.stringify(report, "  "))
	file.close()


func _print_report() -> void:
	var runtime: Dictionary = report.get("runtime_before_stress", {})
	var tiles: Dictionary = report.get("tile_resources", {})
	var benchmarks: Dictionary = report.get("benchmarks", {})
	print("Startup instantiate: ", report["startup"]["instantiate_us"], " us")
	print("Startup attach+ready(2 frames): ", report["startup"]["attach_ready_2frames_us"], " us")
	print("FPS: ", runtime.get("fps", 0.0), " | process: ", runtime.get("process_ms", 0.0), " ms")
	print("Draw calls: ", runtime.get("draw_calls", 0.0), " | render objects: ", runtime.get("render_objects", 0.0))
	print("Nodes: ", runtime.get("nodes", 0.0), " | Resources: ", runtime.get("resources", 0.0), " | Orphans: ", runtime.get("orphans", 0.0))
	print("Static memory: ", runtime.get("static_memory_bytes", 0.0), " bytes")
	print("Tiles: ", tiles.get("tile_count", 0), " | meshes unicos: ", tiles.get("unique_mesh_resources", 0), " | materiales unicos: ", tiles.get("unique_material_resources", 0), " | shapes unicos: ", tiles.get("unique_collision_shapes", 0))
	print("Mover validacion avg: ", benchmarks.get("movement_validation", {}).get("average_us", 0.0), " us")
	print("Explorar validacion avg: ", benchmarks.get("exploration_validation", {}).get("average_us", 0.0), " us")
	print("Snapshot guardado avg: ", benchmarks.get("save_snapshot_capture", {}).get("average_us", 0.0), " us")
	print("Refresh visual avg: ", benchmarks.get("visual_direction_refresh", {}).get("average_us", 0.0), " us")
	print("Refresh visual Resource delta: ", benchmarks.get("visual_direction_refresh", {}).get("resource_count_delta", 0.0))
	print("Conexiones TurnManager: ", report.get("signal_connections", {}))
	for observation in report.get("observations", []):
		print("OBSERVACION: ", observation)
	print("Reporte: ", REPORT_PATH)
