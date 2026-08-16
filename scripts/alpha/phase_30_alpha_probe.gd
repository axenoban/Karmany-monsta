extends Node

const ALPHA_SCENE: PackedScene = preload("res://scenes/ui/phase_30_alpha_prototype.tscn")
const MATCH_SCENE: PackedScene = preload("res://scenes/ui/phase_24_full_match_prototype.tscn")

func _ready() -> void:
	print("\n=== KARMANY MONSTA - FASE 30 ALPHA PROBE ===")
	var alpha_ok: bool = await _check_alpha()
	var repeat_ok: bool = false
	if alpha_ok:
		repeat_ok = await _check_repeatability()
	if alpha_ok and repeat_ok:
		print("FASE 30 OK - Alpha repetible, observable y guiado.")
	else:
		push_error("FASE 30 ERROR - Revisa el primer fallo del probe.")

func _check_alpha() -> bool:
	var alpha := ALPHA_SCENE.instantiate() as KarmanyPhase30AlphaBridge
	if alpha == null:
		return false
	add_child(alpha)
	await get_tree().process_frame
	await get_tree().process_frame
	var ok: bool = alpha.setup_ok and alpha.telemetry.configured
	ok = ok and not alpha.get_onboarding_text().is_empty()
	ok = ok and not alpha.telemetry.get_runtime_summary().is_empty()
	ok = ok and not alpha.telemetry.get_balance_summary().is_empty()
	alpha.queue_free()
	await get_tree().process_frame
	print("Capa Alpha + metricas + onboarding: ", "OK" if ok else "ERROR")
	return ok

func _check_repeatability() -> bool:
	var signatures: Array[String] = []
	for index in range(2):
		var match_bridge := MATCH_SCENE.instantiate() as KarmanyPhase24FullMatchBridge
		if match_bridge == null:
			return false
		add_child(match_bridge)
		await get_tree().process_frame
		await get_tree().process_frame
		if not match_bridge.setup_ok or not match_bridge.run_complete_match_fast():
			match_bridge.queue_free()
			return false
		if not match_bridge.coordinator.is_finished or match_bridge.coordinator.final_evaluation == null:
			match_bridge.queue_free()
			return false
		var p1: int = match_bridge.legacy_points.get_total(match_bridge.player_1.player_id)
		var p2: int = match_bridge.legacy_points.get_total(match_bridge.player_2.player_id)
		signatures.append("%d:%d:%d" % [p1, p2, match_bridge.turn_manager.current_round])
		print("Run %d · PL %d-%d · ronda %d: OK" % [index + 1, p1, p2, match_bridge.turn_manager.current_round])
		match_bridge.queue_free()
		await get_tree().process_frame
	return signatures.size() == 2 and signatures[0] == signatures[1]
