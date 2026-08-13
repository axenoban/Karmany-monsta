class_name KarmanyAlphaTelemetry
extends RefCounted

signal updated

const MAX_LOG_LINES: int = 12

var session: KarmanyVerticalSliceSession = null
var configured: bool = false
var completed: bool = false
var invalid_action_count: int = 0
var successful_event_count: int = 0
var max_round_seen: int = 0
var sample_count: int = 0
var peak_nodes: float = 0.0
var peak_draw_calls: float = 0.0
var minimum_fps: float = 1000000.0
var final_human_pl: int = 0
var final_ai_pl: int = 0
var event_counts: Dictionary = {}
var log_lines: Array[String] = []

func configure(value: KarmanyVerticalSliceSession) -> bool:
	if value == null or not value.configured:
		return false
	session = value
	if not session.slice_event.is_connected(_on_slice_event):
		session.slice_event.connect(_on_slice_event)
	if not session.state_changed.is_connected(_on_state_changed):
		session.state_changed.connect(_on_state_changed)
	if not session.slice_finished.is_connected(_on_slice_finished):
		session.slice_finished.connect(_on_slice_finished)
	configured = true
	_sample_runtime()
	_record_log(&"alpha_started", "Telemetria alpha conectada.", session.human_player.current_coord)
	return true

func get_gameplay_summary() -> String:
	if not configured:
		return "Telemetria no disponible."
	return "Ronda max %d · eventos %d · invalidas %d" % [max_round_seen, successful_event_count, invalid_action_count]

func get_runtime_summary() -> String:
	if not configured:
		return "Rendimiento no disponible."
	var values: Dictionary = KarmanyPerformanceMetrics.runtime_monitors()
	var current_fps: float = float(values.get("fps", 0.0))
	var min_fps_value: float = 0.0 if sample_count == 0 else minimum_fps
	return "FPS %.0f (min %.0f) · draw %.0f (pico %.0f) · nodos %.0f (pico %.0f)" % [current_fps, min_fps_value, float(values.get("draw_calls", 0.0)), peak_draw_calls, float(values.get("nodes", 0.0)), peak_nodes]

func get_balance_summary() -> String:
	if not configured or session.legacy_points == null:
		return "Balance preliminar no disponible."
	var human_pl: int = session.legacy_points.get_total(session.human_player.player_id)
	var ai_pl: int = session.legacy_points.get_total(session.ai_player.player_id)
	var delta: int = human_pl - ai_pl
	var linked: int = session.human_player.get_linked_karmanys().size()
	var equipment: int = session.human_player.equipment_inventory.get_all().size()
	return "PL jugador %d · IA %d · delta %+d · Karmany %d · Equipo %d" % [human_pl, ai_pl, delta, linked, equipment]

func get_recent_log() -> String:
	if log_lines.is_empty():
		return "Sin eventos alpha."
	return "\n".join(log_lines)

func get_event_count(kind: StringName) -> int:
	return int(event_counts.get(kind, 0))

func is_repeatable_run_healthy() -> bool:
	return configured and completed and invalid_action_count == 0 and final_human_pl >= 0 and final_ai_pl >= 0

func _on_slice_event(kind: StringName, message: String, coord: Vector2i) -> void:
	if kind == &"invalid":
		invalid_action_count += 1
	else:
		successful_event_count += 1
	event_counts[kind] = int(event_counts.get(kind, 0)) + 1
	_record_log(kind, message, coord)
	_sample_runtime()
	updated.emit()

func _on_state_changed() -> void:
	if session != null and session.turn_manager != null:
		max_round_seen = maxi(max_round_seen, session.turn_manager.current_round)
	_sample_runtime()
	updated.emit()

func _on_slice_finished(_evaluation: KarmanyLegacyMatchEvaluation) -> void:
	completed = true
	if session != null and session.legacy_points != null:
		final_human_pl = session.legacy_points.get_total(session.human_player.player_id)
		final_ai_pl = session.legacy_points.get_total(session.ai_player.player_id)
	_record_log(&"alpha_finished", "Partida completa registrada.", session.human_player.current_coord)
	_sample_runtime()
	updated.emit()

func _sample_runtime() -> void:
	if not configured and session == null:
		return
	var values: Dictionary = KarmanyPerformanceMetrics.runtime_monitors()
	var fps: float = float(values.get("fps", 0.0))
	var nodes: float = float(values.get("nodes", 0.0))
	var draw_calls: float = float(values.get("draw_calls", 0.0))
	if fps > 0.0:
		minimum_fps = minf(minimum_fps, fps)
	peak_nodes = maxf(peak_nodes, nodes)
	peak_draw_calls = maxf(peak_draw_calls, draw_calls)
	sample_count += 1
	if session != null and session.turn_manager != null:
		max_round_seen = maxi(max_round_seen, session.turn_manager.current_round)

func _record_log(kind: StringName, message: String, coord: Vector2i) -> void:
	var round_number: int = 0
	if session != null and session.turn_manager != null:
		round_number = session.turn_manager.current_round
	var line: String = "R%d · %s · %s · (%d,%d)" % [round_number, String(kind), message, coord.x, coord.y]
	log_lines.append(line)
	while log_lines.size() > MAX_LOG_LINES:
		log_lines.pop_front()
	print("ALPHA LOG | ", line)
