class_name KarmanyPhase34MultiAiBridge
extends Node3D


const DEFAULT_PHASE_34_SEED: int = 34001
const TRAINER_UNIT_SCENE: PackedScene = preload(
	"res://scenes/trainers/trainer_unit_3d.tscn"
)
const PLAYER_TINTS: Array[Color] = [
	Color(0.22, 0.58, 0.95, 1.0),
	Color(0.95, 0.55, 0.22, 1.0),
	Color(0.35, 0.78, 0.38, 1.0),
	Color(0.72, 0.38, 0.88, 1.0)
]


@onready var phase_32: KarmanyPhase32RandomMapBridge = $Phase32RandomMapPrototype
@onready var status_label: Label = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/StatusLabel
@onready var participants_label: Label = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/ParticipantsLabel
@onready var active_label: Label = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/ActiveLabel
@onready var last_action_label: Label = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/LastActionLabel
@onready var event_label: Label = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/EventLabel
@onready var pass_human_button: Button = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/Controls/PassHumanButton
@onready var run_ai_button: Button = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/Controls/RunAiButton
@onready var run_all_ai_button: Button = $Phase34Overlay/RootMargin/Panel/InnerMargin/VBox/Controls/RunAllAiButton


var runtime: KarmanyMultiAiAlphaRuntime = null
var trainer_units: Array[KarmanyTrainerUnit3D] = []
var setup_ok: bool = false
var _event_lines: Array[String] = []
var _last_action_text: String = "Sin acciones IA ejecutadas."


func _ready() -> void:
	if phase_32 == null or not phase_32.setup_ok or phase_32.phase_31 == null:
		push_error("FASE 34 ERROR: Fase 32/Fase 31 no esta disponible.")
		return

	var phase_32_overlay := phase_32.get_node_or_null("Phase32Overlay") as CanvasLayer
	if phase_32_overlay != null:
		phase_32_overlay.visible = false

	if not phase_32.set_seed_and_regenerate(DEFAULT_PHASE_34_SEED):
		push_error("FASE 34 ERROR: No se pudo preparar la seed visual.")
		return

	_remove_phase_31_prototype_trainer()

	runtime = KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_existing(
		4,
		DEFAULT_PHASE_34_SEED,
		phase_32.phase_31.board_state,
		phase_32.content_session,
		&"player_1"
	):
		push_error("FASE 34 ERROR: No se pudo configurar 1 humano + 3 IA.")
		return

	_connect_runtime_signals()
	_connect_controls()
	if not _spawn_trainer_units():
		push_error("FASE 34 ERROR: No se pudieron crear placeholders de participantes.")
		return

	setup_ok = true
	_append_event("Fase 34 lista: P1 humano + P2/P3/P4 IA.")
	_refresh_visual_state()
	print("FASE 34 VISUAL OK - P1 humano + 3 IA sobre mapa 41 randomizado.")


func pass_human_turn() -> bool:
	if runtime == null or not runtime.simulate_human_probe_turn():
		return false
	_append_event("P1 HUMANO: turno de prueba cerrado.")
	_refresh_visual_state()
	return true


func run_current_ai_turn() -> bool:
	if runtime == null or runtime.ai_match_controller == null:
		return false
	if not runtime.ai_match_controller.run_current_ai_turn():
		return false
	_refresh_visual_state()
	return true


func run_all_ai_until_human() -> bool:
	if runtime == null or runtime.ai_match_controller == null:
		return false
	if not runtime.run_ai_until_human():
		return false
	_refresh_visual_state()
	return true


func get_active_player_id() -> StringName:
	if runtime == null or runtime.local_session == null:
		return &""
	var player := runtime.local_session.turn_manager.get_active_player()
	if player == null:
		return &""
	return player.player_id


func get_current_round() -> int:
	if runtime == null or runtime.local_session == null:
		return 0
	return runtime.local_session.turn_manager.current_round


func _connect_controls() -> void:
	if not pass_human_button.pressed.is_connected(_on_pass_human_pressed):
		pass_human_button.pressed.connect(_on_pass_human_pressed)
	if not run_ai_button.pressed.is_connected(_on_run_ai_pressed):
		run_ai_button.pressed.connect(_on_run_ai_pressed)
	if not run_all_ai_button.pressed.is_connected(_on_run_all_ai_pressed):
		run_all_ai_button.pressed.connect(_on_run_all_ai_pressed)


func _connect_runtime_signals() -> void:
	var ai_control := runtime.ai_match_controller
	if not ai_control.ai_turn_started.is_connected(_on_ai_turn_started):
		ai_control.ai_turn_started.connect(_on_ai_turn_started)
	if not ai_control.ai_action_chosen.is_connected(_on_ai_action_chosen):
		ai_control.ai_action_chosen.connect(_on_ai_action_chosen)
	if not ai_control.ai_action_executed.is_connected(_on_ai_action_executed):
		ai_control.ai_action_executed.connect(_on_ai_action_executed)
	if not ai_control.ai_turn_finished.is_connected(_on_ai_turn_finished):
		ai_control.ai_turn_finished.connect(_on_ai_turn_finished)
	if not ai_control.ai_turn_blocked.is_connected(_on_ai_turn_blocked):
		ai_control.ai_turn_blocked.connect(_on_ai_turn_blocked)


func _on_pass_human_pressed() -> void:
	if not pass_human_turn():
		_append_event("No se pudo cerrar el turno humano de prueba.")
		_refresh_visual_state()


func _on_run_ai_pressed() -> void:
	if not run_current_ai_turn():
		_append_event("No hay una IA activa que pueda ejecutar turno.")
		_refresh_visual_state()


func _on_run_all_ai_pressed() -> void:
	if not run_all_ai_until_human():
		_append_event("No se pudo completar la secuencia IA hasta el humano.")
		_refresh_visual_state()


func _on_ai_turn_started(
	player_id: StringName,
	profile_name: String
) -> void:
	_append_event("%s IA %s: inicia turno." % [String(player_id), profile_name])


func _on_ai_action_chosen(
	player_id: StringName,
	action_label: String,
	actions_remaining: int
) -> void:
	_last_action_text = "%s elige: %s | antes=%d" % [
		String(player_id),
		action_label,
		actions_remaining
	]
	_refresh_overlay()


func _on_ai_action_executed(
	player_id: StringName,
	action_label: String,
	success: bool,
	actions_remaining: int
) -> void:
	_last_action_text = "%s: %s | %s | restantes=%d" % [
		String(player_id),
		action_label,
		"OK" if success else "RECHAZADA",
		actions_remaining
	]
	_append_event(_last_action_text)


func _on_ai_turn_finished(
	player_id: StringName,
	profile_name: String,
	round_number: int
) -> void:
	_append_event(
		"%s IA %s: turno terminado | ronda=%d."
		% [String(player_id), profile_name, round_number]
	)


func _on_ai_turn_blocked(
	player_id: StringName,
	reason: String
) -> void:
	_append_event("%s sin accion legal: %s" % [String(player_id), reason])


func _remove_phase_31_prototype_trainer() -> void:
	var phase_31 := phase_32.phase_31
	if phase_31.trainer_unit == null:
		return
	var old_coord: Vector2i = phase_31.player_state.current_coord
	var old_unit_id: StringName = phase_31.trainer_unit.unit_id
	if phase_31.board_state.get_occupying_unit_id(old_coord) == old_unit_id:
		phase_31.board_state.clear_unit_occupant(old_coord)
	phase_31.trainer_unit.free()
	phase_31.trainer_unit = null


func _spawn_trainer_units() -> bool:
	_clear_trainer_units()
	if runtime == null or runtime.local_session == null:
		return false
	var phase_31 := phase_32.phase_31

	for index in range(runtime.local_session.players.size()):
		var player: KarmanyPlayerState = runtime.local_session.players[index]
		var tile := phase_31.get_tile_view(player.current_coord)
		if tile == null:
			return false
		var anchor := tile.get_node_or_null("UnitAnchor") as Marker3D
		if anchor == null:
			return false

		var unit := TRAINER_UNIT_SCENE.instantiate() as KarmanyTrainerUnit3D
		if unit == null:
			return false
		unit.configure(
			player,
			runtime.local_session.unit_ids[index]
		)
		phase_31.units.add_child(unit)
		_apply_placeholder_tint(unit, index)
		if not unit.place_at(anchor, player.current_coord):
			unit.free()
			return false
		trainer_units.append(unit)

	return trainer_units.size() == runtime.local_session.get_player_count()


func _clear_trainer_units() -> void:
	for unit in trainer_units:
		if unit != null and is_instance_valid(unit):
			unit.free()
	trainer_units.clear()


func _apply_placeholder_tint(
	unit: KarmanyTrainerUnit3D,
	player_index: int
) -> void:
	if unit == null or PLAYER_TINTS.is_empty():
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = PLAYER_TINTS[player_index % PLAYER_TINTS.size()]
	material.roughness = 0.72
	var body := unit.get_node_or_null("Body") as MeshInstance3D
	var head := unit.get_node_or_null("Head") as MeshInstance3D
	if body != null:
		body.material_override = material
	if head != null:
		head.material_override = material


func _sync_trainer_units() -> void:
	if runtime == null or runtime.local_session == null:
		return
	for index in range(trainer_units.size()):
		if index >= runtime.local_session.players.size():
			break
		var unit := trainer_units[index]
		var player: KarmanyPlayerState = runtime.local_session.players[index]
		var tile := phase_32.phase_31.get_tile_view(player.current_coord)
		if unit == null or tile == null:
			continue
		var anchor := tile.get_node_or_null("UnitAnchor") as Marker3D
		if anchor != null:
			unit.place_at(anchor, player.current_coord)


func _refresh_board_tiles() -> void:
	if runtime == null:
		return
	for coord_value in phase_32.phase_31.get_level_map().keys():
		var coord: Vector2i = coord_value
		var tile := phase_32.phase_31.get_tile_view(coord)
		var cell := runtime.board_state.get_cell(coord)
		if tile == null or cell == null:
			continue
		tile.tile_data = cell.tile_data if cell.revealed else null


func _refresh_visual_state() -> void:
	_sync_trainer_units()
	_refresh_board_tiles()
	_refresh_overlay()


func _refresh_overlay() -> void:
	if runtime == null or runtime.local_session == null:
		status_label.text = "Runtime F34 no configurado."
		return

	var manager := runtime.local_session.turn_manager
	var active := manager.get_active_player()
	var active_id: String = "ninguno"
	var active_kind: String = ""
	var active_profile: String = ""
	if active != null:
		active_id = String(active.player_id)
		var kind: int = runtime.ai_match_controller.get_controller_kind(active.player_id)
		active_kind = KarmanyPlayerControllerType.get_display_name(kind)
		if runtime.ai_match_controller.is_ai_player(active.player_id):
			active_profile = runtime.ai_match_controller.get_ai_profile_name(active.player_id)

	status_label.text = "seed=%d | mapa 41 | F31-F33 preservadas" % runtime.match_seed
	active_label.text = "Ronda %d | activo=%s %s %s | acciones=%d/2" % [
		manager.current_round,
		active_id,
		active_kind,
		active_profile,
		manager.actions_remaining
	]
	last_action_label.text = "Ultima decision: %s" % _last_action_text

	var participant_lines: PackedStringArray = PackedStringArray()
	for player in runtime.local_session.players:
		var kind: int = runtime.ai_match_controller.get_controller_kind(player.player_id)
		var description: String = KarmanyPlayerControllerType.get_display_name(kind)
		if runtime.ai_match_controller.is_ai_player(player.player_id):
			description += " " + runtime.ai_match_controller.get_ai_profile_name(player.player_id)
		participant_lines.append(
			"%s | %s | pos=%s" % [
				String(player.player_id),
				description,
				str(player.current_coord)
			]
		)
	participants_label.text = "\n".join(participant_lines)
	event_label.text = "\n".join(_event_lines)

	var human_active: bool = (
		active != null
		and runtime.ai_match_controller.is_human_player(active.player_id)
	)
	var ai_active: bool = (
		active != null
		and runtime.ai_match_controller.is_ai_player(active.player_id)
	)
	pass_human_button.disabled = not human_active
	run_ai_button.disabled = not ai_active
	run_all_ai_button.disabled = not ai_active


func _append_event(text: String) -> void:
	if text.is_empty():
		return
	_event_lines.append(text)
	while _event_lines.size() > 8:
		_event_lines.pop_front()
	if event_label != null:
		event_label.text = "\n".join(_event_lines)
