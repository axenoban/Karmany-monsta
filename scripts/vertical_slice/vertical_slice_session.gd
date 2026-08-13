class_name KarmanyVerticalSliceSession
extends RefCounted

signal slice_event(kind: StringName, message: String, coord: Vector2i)
signal state_changed
signal slice_finished(evaluation: KarmanyLegacyMatchEvaluation)

const SAVE_PATH: String = "user://karmany_phase28_vertical_slice.json"

var slice_match: KarmanyPhase24FullMatchBridge
var human_player: KarmanyPlayerState
var ai_player: KarmanyPlayerState
var coordinator: KarmanyMatchCoordinator
var turn_manager: KarmanyTurnManager
var legacy_points: KarmanyLegacyPointsController
var objectives_missions: KarmanyObjectiveMissionManager
var action_router := KarmanyVerticalSliceActionRouter.new()
var turn_support := KarmanyVerticalSliceTurnSupport.new()
var save_support := KarmanyVerticalSliceSaveSupport.new()
var configured: bool = false
var last_message: String = ""

func configure(value: KarmanyPhase24FullMatchBridge) -> bool:
	if value == null or not value.setup_ok:
		return false
	slice_match = value
	human_player = value.player_1
	ai_player = value.player_2
	coordinator = value.coordinator
	turn_manager = value.turn_manager
	legacy_points = value.legacy_points
	objectives_missions = value.objectives_missions
	if human_player == null or ai_player == null or coordinator == null or turn_manager == null:
		return false
	var standard_mode := KarmanyLegacyModeConfig.new()
	if not standard_mode.configure_standard(KarmanyLegacyModeConfig.MapFormat.MAP_22):
		return false
	var players: Array[KarmanyPlayerState] = [human_player, ai_player]
	if not legacy_points.configure(players, standard_mode):
		return false
	if not action_router.configure(value, coordinator, human_player):
		return false
	if not turn_support.configure(human_player, ai_player, coordinator, turn_manager):
		return false
	if not save_support.configure(value):
		return false
	if not coordinator.match_finished.is_connected(_on_match_finished):
		coordinator.match_finished.connect(_on_match_finished)
	configured = true
	_emit(&"slice_started", "Vertical Slice listo: modo estandar de 7 rondas.", human_player.current_coord)
	return true

func is_human_turn() -> bool:
	return configured and turn_manager.is_running and turn_manager.get_active_player() == human_player

func move_to(coord: Vector2i) -> bool:
	return _action(action_router.move_to(coord), &"move", "Mover resuelto.", coord)

func explore_to(coord: Vector2i) -> bool:
	var had_beast: bool = slice_match.board_prototype.board_state.has_beast(coord)
	if not action_router.explore_to(coord):
		return _fail("Explorar fue rechazado por las reglas.")
	_emit(&"explore", "Loseta explorada.", coord)
	if not had_beast and slice_match.board_prototype.board_state.has_beast(coord):
		_emit(&"beast_spawned", "Garravol aparece en el escenario.", coord)
	return true

func interact_current_tile(option_index: int = 0) -> bool:
	return _action(action_router.interact_current_tile(option_index), &"interact", "Interactuar resuelto.", human_player.current_coord)

func call_or_bond() -> bool:
	var before: int = human_player.get_linked_karmanys().size()
	if not action_router.call_or_bond():
		return _fail("Llamar/Vincular fue rechazado por las reglas.")
	var linked: bool = human_player.get_linked_karmanys().size() > before
	return _action(true, &"karmany_linked" if linked else &"karmany_called", "Brumak vinculado y activo." if linked else "Brumak aparece como encuentro.", human_player.current_coord)

func craft_slice_equipment() -> bool:
	return _action(action_router.craft_slice_equipment(), &"equipment_crafted", "EQ-01 equipado.", human_player.current_coord)

func fight_current_beast() -> bool:
	return _action(action_router.fight_current_beast(), &"beast_defeated", "Garravol derrotado con Brumak + EQ-01 + R-04.", human_player.current_coord)

func improve_book() -> bool:
	return _action(action_router.improve_book(), &"book_upgraded", "Libro mejorado.", human_player.current_coord)

func end_human_turn_and_run_ai() -> bool:
	if not is_human_turn() or turn_manager.actions_remaining != 0:
		return _fail("Debes consumir las 2 acciones antes de finalizar turno.")
	if not turn_support.close_human_turn_and_run_ai():
		return _fail("No se pudo cerrar el turno o resolver la IA.")
	_emit(&"turn_end", "IA Oportunista completo su turno.", human_player.current_coord)
	return true

func save_slice() -> bool:
	if not save_support.save_to(SAVE_PATH):
		return _fail("No se pudo guardar.")
	_emit(&"save", "Partida guardada.", human_player.current_coord)
	return true

func load_slice() -> bool:
	if not save_support.load_from(SAVE_PATH):
		return _fail("No se pudo cargar.")
	_emit(&"load", "Partida cargada.", human_player.current_coord)
	return true

func get_current_goal() -> String:
	return KarmanyVerticalSliceGoal.get_text(self)

func get_progress_summary() -> String:
	return KarmanyVerticalSliceProgress.get_text(self)

func get_metrics_summary() -> String:
	var values := KarmanyPerformanceMetrics.runtime_monitors()
	return "FPS %.0f · %.2f ms · Draw calls %.0f · Nodos %.0f" % [float(values.get("fps", 0.0)), float(values.get("process_ms", 0.0)), float(values.get("draw_calls", 0.0)), float(values.get("nodes", 0.0))]

func _action(ok: bool, kind: StringName, text: String, coord: Vector2i) -> bool:
	if not ok:
		return _fail("La accion fue rechazada por las reglas.")
	_emit(kind, text, coord)
	return true

func _on_match_finished(evaluation: KarmanyLegacyMatchEvaluation) -> void:
	_emit(&"slice_finished", "Vertical Slice finalizado por limite de rondas.", human_player.current_coord)
	slice_finished.emit(evaluation)

func _emit(kind: StringName, text: String, coord: Vector2i) -> void:
	last_message = text
	print("FASE 28: ", text)
	slice_event.emit(kind, text, coord)
	state_changed.emit()

func _fail(text: String) -> bool:
	last_message = text
	print("FASE 28 ACCION RECHAZADA: ", text)
	slice_event.emit(&"invalid", text, human_player.current_coord if human_player != null else Vector2i.ZERO)
	state_changed.emit()
	return false
