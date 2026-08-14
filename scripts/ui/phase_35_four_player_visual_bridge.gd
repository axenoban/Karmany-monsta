class_name KarmanyPhase35FourPlayerVisualBridge
extends Node3D


signal visual_action_started(
	player_id: StringName,
	action_text: String
)
signal visual_action_finished(
	player_id: StringName,
	action_text: String
)


const PLAYER_TINTS: Array[Color] = [
	Color(0.22, 0.58, 0.95, 1.0),
	Color(0.95, 0.55, 0.22, 1.0),
	Color(0.35, 0.78, 0.38, 1.0),
	Color(0.72, 0.38, 0.88, 1.0)
]
const VISUAL_SLOT_OFFSETS: Array[Vector3] = [
	Vector3(-0.22, 0.0, -0.12),
	Vector3(0.22, 0.0, -0.12),
	Vector3(-0.22, 0.0, 0.16),
	Vector3(0.22, 0.0, 0.16)
]
const EVENT_HISTORY_LIMIT: int = 32


@export_group("Alpha presentation pacing")
@export_range(0.0, 2.0, 0.05) var ai_turn_intro_delay: float = 0.30
@export_range(0.0, 2.0, 0.05) var ai_action_pause: float = 0.24
@export_range(0.0, 2.0, 0.05) var ai_turn_pause: float = 0.28
@export_range(0.25, 4.0, 0.25) var presentation_speed_multiplier: float = 1.0


@onready var phase_34: KarmanyPhase34MultiAiBridge = $Phase34MultiAiPrototype
@onready var feedback: KarmanyPresentationFeedbackController = $PresentationFeedbackController
@onready var feedback_root: Node3D = $FeedbackRoot
@onready var transition_rect: ColorRect = $PresentationOverlay/TransitionRect
@onready var transition_label: Label = $PresentationOverlay/TransitionLabel

@onready var active_turn_label: Label = $Phase35Overlay/MainMargin/MainRow/PublicPanel/PublicMargin/PublicVBox/ActiveTurnLabel
@onready var participants_label: Label = $Phase35Overlay/MainMargin/MainRow/PublicPanel/PublicMargin/PublicVBox/ParticipantsLabel
@onready var location_label: Label = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/LocationLabel
@onready var action_feedback_label: Label = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/ActionFeedbackLabel
@onready var status_label: Label = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/StatusLabel
@onready var pass_human_button: Button = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/Controls/PassHumanButton
@onready var run_ai_button: Button = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/Controls/RunAiButton
@onready var run_all_ai_button: Button = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/Controls/RunAllAiButton
@onready var center_human_button: Button = $Phase35Overlay/MainMargin/MainRow/ContextPanel/ContextMargin/ContextVBox/Controls/CenterHumanButton


var setup_ok: bool = false
var _trainer_by_player: Dictionary = {}
var _halo_by_player: Dictionary = {}
var _visual_coord_by_player: Dictionary = {}
var _logic_coord_snapshot: Dictionary = {}
var _logical_revealed_snapshot: Dictionary = {}
var _visually_revealed_coords: Dictionary = {}
var _pending_ai_origin: Dictionary = {}
var _captured_ai_steps: Array[Dictionary] = []
var _queued_external_steps: Array[Dictionary] = []
var _presentation_events: Array[Dictionary] = []
var _display_active_player_id: StringName = &""
var _display_round_number: int = 0
var _display_actions_remaining: int = 0
var _capturing_ai_logic: bool = false
var _presentation_busy: bool = false
var _external_drain_scheduled: bool = false


func _ready() -> void:
	if phase_34 == null or not phase_34.setup_ok or phase_34.runtime == null:
		push_error("FASE 35 ERROR: Fase 34 no esta disponible.")
		return
	if phase_34.trainer_units.size() != 4:
		push_error("FASE 35 ERROR: Se requieren cuatro TrainerUnit3D reales de Fase 34.")
		return

	var old_overlay := phase_34.get_node_or_null("Phase34Overlay") as CanvasLayer
	if old_overlay != null:
		old_overlay.visible = false

	if not feedback.configure(feedback_root, transition_rect, transition_label):
		push_error("FASE 35 ERROR: PresentationFeedbackController no pudo configurarse.")
		return
	set_presentation_speed_multiplier(presentation_speed_multiplier)

	if not _bind_existing_four_trainers():
		push_error("FASE 35 ERROR: No se pudieron enlazar las cuatro unidades a sus PlayerState.")
		return
	_seed_reveal_snapshots()
	_connect_gameplay_observers()
	_connect_controls()

	_sync_display_to_logical_active()
	_refresh_public_hud()
	setup_ok = true
	print("FASE 35 VISUAL OK - cuatro TrainerUnit3D, movimiento interpolado y HUD publico activos.")


func set_presentation_speed_multiplier(value: float) -> void:
	presentation_speed_multiplier = clampf(value, 0.1, 100.0)
	if feedback != null:
		feedback.set_duration_scale(1.0 / presentation_speed_multiplier)


func get_trainer_unit(player_id: StringName) -> KarmanyTrainerUnit3D:
	return _trainer_by_player.get(player_id, null) as KarmanyTrainerUnit3D


func get_visual_coord(player_id: StringName) -> Vector2i:
	var value: Variant = _visual_coord_by_player.get(player_id, Vector2i.ZERO)
	if value is Vector2i:
		var coord: Vector2i = value
		return coord
	return Vector2i.ZERO


func get_display_active_player_id() -> StringName:
	return _display_active_player_id


func get_display_actions_remaining() -> int:
	return _display_actions_remaining


func get_display_round_number() -> int:
	return _display_round_number


func get_public_participants_text() -> String:
	return participants_label.text if participants_label != null else ""


func get_human_location_text() -> String:
	return location_label.text if location_label != null else ""


func get_presentation_events() -> Array[Dictionary]:
	return _presentation_events.duplicate(true)


func is_player_halo_visible(player_id: StringName) -> bool:
	var halo := _halo_by_player.get(player_id, null) as MeshInstance3D
	return halo != null and halo.visible


func center_on_human() -> bool:
	if phase_34 == null or phase_34.runtime == null:
		return false
	var human_id: StringName = phase_34.runtime.human_player_id
	var unit := get_trainer_unit(human_id)
	var camera_controller := _get_camera_controller()
	if unit == null or camera_controller == null:
		return false
	camera_controller.focus_world_position(unit.global_position)
	return true


func pass_human_turn_presented() -> bool:
	if not setup_ok or _presentation_busy or phase_34.runtime == null:
		return false
	var manager := phase_34.runtime.local_session.turn_manager
	var active := manager.get_active_player()
	if active == null or not phase_34.runtime.ai_match_controller.is_human_player(active.player_id):
		return false

	_presentation_busy = true
	_set_controls_disabled(true)
	action_feedback_label.text = "P1 termina su turno."
	_append_event(active.player_id, "turn_finished", "P1 termina turno")
	var success: bool = phase_34.runtime.simulate_human_probe_turn()
	_presentation_busy = false
	_set_controls_disabled(false)
	_sync_display_to_logical_active()
	_refresh_public_hud()
	return success


func run_current_ai_turn_presented() -> bool:
	if not setup_ok or _presentation_busy or phase_34.runtime == null:
		return false
	var manager := phase_34.runtime.local_session.turn_manager
	var ai_control := phase_34.runtime.ai_match_controller
	var active := manager.get_active_player()
	if active == null or not ai_control.is_ai_player(active.player_id):
		return false

	_presentation_busy = true
	_set_controls_disabled(true)
	_captured_ai_steps.clear()
	_pending_ai_origin.clear()
	_capturing_ai_logic = true
	var acting_player_id: StringName = active.player_id
	var acting_profile: String = ai_control.get_ai_profile_name(acting_player_id)
	var acting_round: int = manager.current_round
	var acting_actions: int = manager.actions_remaining

	# Gameplay resolves first through the already validated F34 controller.
	# F35 records the emitted events and replays only their presentation.
	var logical_success: bool = ai_control.run_current_ai_turn()
	_capturing_ai_logic = false
	if not logical_success:
		_presentation_busy = false
		_set_controls_disabled(false)
		_sync_display_to_logical_active()
		_refresh_public_hud()
		return false

	_set_display_active_player(acting_player_id, acting_round, acting_actions)
	action_feedback_label.text = "%s comienza turno." % _short_player_role(acting_player_id)
	_append_event(acting_player_id, "turn_started", "%s comienza turno" % acting_profile)
	_focus_player_visual(acting_player_id)
	await _wait_presentation_delay(ai_turn_intro_delay)

	for step in _captured_ai_steps:
		await _present_step(step)

	action_feedback_label.text = "%s termina turno." % _short_player_role(acting_player_id)
	_append_event(acting_player_id, "turn_finished", "%s termina turno" % acting_profile)
	await _wait_presentation_delay(ai_turn_pause)

	_presentation_busy = false
	_set_controls_disabled(false)
	_sync_display_to_logical_active()
	_refresh_public_hud()
	if _is_human_logically_active():
		center_on_human()
	if not _queued_external_steps.is_empty():
		_schedule_external_step_drain()
	return true


func run_all_ai_until_human_presented() -> bool:
	if not setup_ok or _presentation_busy:
		return false
	var resolved: int = 0
	while resolved < KarmanyTurnManager.MAX_PLAYERS - 1:
		var active := phase_34.runtime.local_session.turn_manager.get_active_player()
		if active == null:
			return false
		if phase_34.runtime.ai_match_controller.is_human_player(active.player_id):
			center_on_human()
			return true
		if not phase_34.runtime.ai_match_controller.is_ai_player(active.player_id):
			return false
		var turn_ok: bool = await run_current_ai_turn_presented()
		if not turn_ok:
			return false
		resolved += 1
	return _is_human_logically_active()


func wait_for_presentation_idle(max_frames: int = 360) -> bool:
	for _index in range(max_frames):
		if not _presentation_busy and _queued_external_steps.is_empty():
			return true
		await get_tree().process_frame
	return false


func get_public_location_text_for_coord(coord: Vector2i) -> String:
	if phase_34 == null or phase_34.runtime == null:
		return "Sin ubicacion publica."
	var runtime := phase_34.runtime
	if not runtime.board_state.has_coord(coord):
		return "Coordenada fuera del mapa."

	var level: int = runtime.get_public_level(coord)
	var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(level)
	var occupants: PackedStringArray = PackedStringArray()
	for player in runtime.local_session.players:
		if player != null and get_visual_coord(player.player_id) == coord:
			occupants.append(_short_player_id(player.player_id))
	var occupant_text: String = "ninguno"
	if not occupants.is_empty():
		occupant_text = ", ".join(occupants)

	if not _visually_revealed_coords.has(coord):
		return "%s | OCULTA | %s | presentes: %s" % [
			level_name,
			str(coord),
			occupant_text
		]

	var public_tile: KarmanyTileData = runtime.get_public_tile_data(coord)
	if public_tile == null:
		return "%s | %s | presentes: %s" % [level_name, str(coord), occupant_text]
	return "%s\n%s | %s | presentes: %s" % [
		public_tile.display_name,
		level_name,
		str(coord),
		occupant_text
	]


func _bind_existing_four_trainers() -> bool:
	_trainer_by_player.clear()
	_halo_by_player.clear()
	_visual_coord_by_player.clear()
	_logic_coord_snapshot.clear()

	var players := phase_34.runtime.local_session.players
	if players.size() != 4 or phase_34.trainer_units.size() != 4:
		return false

	for index in range(players.size()):
		var player: KarmanyPlayerState = players[index]
		var unit: KarmanyTrainerUnit3D = phase_34.trainer_units[index]
		if player == null or unit == null or unit.player_state != player:
			return false
		_trainer_by_player[player.player_id] = unit
		_visual_coord_by_player[player.player_id] = player.current_coord
		_logic_coord_snapshot[player.player_id] = player.current_coord
		_add_player_label(unit, index)
		var halo := _add_active_halo(unit, index)
		_halo_by_player[player.player_id] = halo
		if not _snap_unit_to_visual_coord(player.player_id, player.current_coord):
			return false
	return _trainer_by_player.size() == 4


func _add_player_label(unit: KarmanyTrainerUnit3D, player_index: int) -> void:
	var existing := unit.get_node_or_null("Phase35PlayerLabel") as Label3D
	if existing != null:
		return
	var label := Label3D.new()
	label.name = "Phase35PlayerLabel"
	label.text = "P%d" % (player_index + 1)
	label.font_size = 36
	label.outline_size = 9
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = PLAYER_TINTS[player_index % PLAYER_TINTS.size()]
	label.position = Vector3(0.0, 1.85, 0.0)
	unit.add_child(label)


func _add_active_halo(
	unit: KarmanyTrainerUnit3D,
	player_index: int
) -> MeshInstance3D:
	var existing := unit.get_node_or_null("Phase35ActiveHalo") as MeshInstance3D
	if existing != null:
		return existing

	var halo := MeshInstance3D.new()
	halo.name = "Phase35ActiveHalo"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.48
	mesh.bottom_radius = 0.48
	mesh.height = 0.035
	mesh.radial_segments = 32
	halo.mesh = mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var tint: Color = PLAYER_TINTS[player_index % PLAYER_TINTS.size()]
	material.albedo_color = Color(tint.r, tint.g, tint.b, 0.72)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 1.25
	halo.material_override = material
	halo.position = Vector3(0.0, 0.07, 0.0)
	halo.visible = false
	unit.add_child(halo)
	return halo


func _seed_reveal_snapshots() -> void:
	_logical_revealed_snapshot.clear()
	_visually_revealed_coords.clear()
	for coord in phase_34.runtime.board_state.get_coords():
		if phase_34.runtime.board_state.is_revealed(coord):
			_logical_revealed_snapshot[coord] = true
			_visually_revealed_coords[coord] = true


func _connect_gameplay_observers() -> void:
	var ai_control := phase_34.runtime.ai_match_controller
	if not ai_control.ai_action_chosen.is_connected(_on_ai_action_chosen):
		ai_control.ai_action_chosen.connect(_on_ai_action_chosen)
	if not ai_control.ai_action_executed.is_connected(_on_ai_action_executed):
		ai_control.ai_action_executed.connect(_on_ai_action_executed)

	var manager := phase_34.runtime.local_session.turn_manager
	if not manager.action_spent.is_connected(_on_action_spent):
		manager.action_spent.connect(_on_action_spent)
	if not manager.turn_started.is_connected(_on_turn_started):
		manager.turn_started.connect(_on_turn_started)
	if not manager.turn_ended.is_connected(_on_turn_ended):
		manager.turn_ended.connect(_on_turn_ended)


func _connect_controls() -> void:
	if not pass_human_button.pressed.is_connected(_on_pass_human_pressed):
		pass_human_button.pressed.connect(_on_pass_human_pressed)
	if not run_ai_button.pressed.is_connected(_on_run_ai_pressed):
		run_ai_button.pressed.connect(_on_run_ai_pressed)
	if not run_all_ai_button.pressed.is_connected(_on_run_all_ai_pressed):
		run_all_ai_button.pressed.connect(_on_run_all_ai_pressed)
	if not center_human_button.pressed.is_connected(_on_center_human_pressed):
		center_human_button.pressed.connect(_on_center_human_pressed)


func _on_ai_action_chosen(
	player_id: StringName,
	action_label: String,
	_actions_remaining: int
) -> void:
	if not _capturing_ai_logic:
		return
	var player := phase_34.runtime.local_session.get_player_by_id(player_id)
	if player == null:
		return
	_pending_ai_origin[player_id] = player.current_coord
	action_feedback_label.text = "%s elige: %s" % [
		_short_player_id(player_id),
		_compact_action_label(action_label)
	]


func _on_ai_action_executed(
	player_id: StringName,
	action_label: String,
	success: bool,
	actions_remaining: int
) -> void:
	if not _capturing_ai_logic:
		return
	var player := phase_34.runtime.local_session.get_player_by_id(player_id)
	if player == null:
		return
	var origin: Vector2i = player.current_coord
	var origin_value: Variant = _pending_ai_origin.get(player_id, player.current_coord)
	if origin_value is Vector2i:
		origin = origin_value
	var reveals: Array[Vector2i] = _collect_new_logical_reveals()
	_logic_coord_snapshot[player_id] = player.current_coord
	if success:
		_captured_ai_steps.append({
			"player_id": player_id,
			"action_label": action_label,
			"origin": origin,
			"destination": player.current_coord,
			"revealed_coords": reveals,
			"actions_remaining": actions_remaining
		})


func _on_action_spent(
	player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	if player == null:
		return
	if _capturing_ai_logic:
		return

	var previous: Vector2i = player.current_coord
	var previous_value: Variant = _logic_coord_snapshot.get(player.player_id, player.current_coord)
	if previous_value is Vector2i:
		previous = previous_value
	var reveals: Array[Vector2i] = _collect_new_logical_reveals()
	_logic_coord_snapshot[player.player_id] = player.current_coord

	if previous == player.current_coord and reveals.is_empty():
		return
	var action_label: String = "Mover"
	if reveals.has(player.current_coord):
		action_label = "Explorar"
	_queued_external_steps.append({
		"player_id": player.player_id,
		"action_label": action_label,
		"origin": previous,
		"destination": player.current_coord,
		"revealed_coords": reveals,
		"actions_remaining": phase_34.runtime.local_session.turn_manager.actions_remaining
	})
	_schedule_external_step_drain()


func _on_turn_started(
	player: KarmanyPlayerState,
	round_number: int,
	actions_available: int
) -> void:
	if player == null:
		return
	if not _capturing_ai_logic and not _presentation_busy:
		_set_display_active_player(player.player_id, round_number, actions_available)
		_refresh_public_hud()


func _on_turn_ended(
	player: KarmanyPlayerState,
	_round_number: int
) -> void:
	if player != null and not _capturing_ai_logic:
		_append_event(player.player_id, "turn_finished", "%s termina turno" % _short_player_id(player.player_id))


func _schedule_external_step_drain() -> void:
	if _external_drain_scheduled:
		return
	_external_drain_scheduled = true
	call_deferred("_drain_external_steps")


func _drain_external_steps() -> void:
	_external_drain_scheduled = false
	if _presentation_busy:
		return
	if _queued_external_steps.is_empty():
		return
	_presentation_busy = true
	while not _queued_external_steps.is_empty():
		var step: Dictionary = _queued_external_steps.pop_front()
		await _present_step(step)
	_presentation_busy = false
	_sync_display_to_logical_active()
	_refresh_public_hud()


func _collect_new_logical_reveals() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for coord in phase_34.runtime.board_state.get_coords():
		if not phase_34.runtime.board_state.is_revealed(coord):
			continue
		if _logical_revealed_snapshot.has(coord):
			continue
		_logical_revealed_snapshot[coord] = true
		result.append(coord)
	return result


func _present_step(step: Dictionary) -> void:
	var player_id: StringName = StringName(step.get("player_id", ""))
	var unit := get_trainer_unit(player_id)
	if player_id == &"" or unit == null:
		return

	var origin: Vector2i = get_visual_coord(player_id)
	var origin_value: Variant = step.get("origin", origin)
	if origin_value is Vector2i:
		origin = origin_value
	var destination: Vector2i = origin
	var destination_value: Variant = step.get("destination", origin)
	if destination_value is Vector2i:
		destination = destination_value
	var action_label: String = String(step.get("action_label", "Accion"))
	_display_actions_remaining = int(step.get("actions_remaining", _display_actions_remaining))
	_set_display_active_player(
		player_id,
		_display_round_number,
		_display_actions_remaining
	)
	var feedback_text: String = _build_feedback_text(player_id, action_label, destination)
	action_feedback_label.text = feedback_text
	visual_action_started.emit(player_id, feedback_text)
	_append_event(player_id, "action", feedback_text)

	if origin != destination:
		_focus_coord(destination)
		var target_position: Vector3 = _get_visual_world_position(player_id, destination)
		var from_position: Vector3 = unit.global_position
		feedback.animate_unit_move(unit, from_position, target_position)
		await _wait_presentation_delay(feedback.movement_duration)
		_snap_unit_to_visual_coord(player_id, destination)
		_visual_coord_by_player[player_id] = destination

	var revealed_value: Variant = step.get("revealed_coords", [])
	if revealed_value is Array:
		for coord_value in revealed_value:
			if coord_value is Vector2i:
				var revealed_coord: Vector2i = coord_value
				await _present_tile_reveal(revealed_coord)

	_refresh_public_hud()
	await _wait_presentation_delay(ai_action_pause)
	visual_action_finished.emit(player_id, feedback_text)


func _present_tile_reveal(coord: Vector2i) -> void:
	var tile := _get_tile_view(coord)
	var cell := phase_34.runtime.board_state.get_cell(coord)
	if tile == null or cell == null or not cell.revealed:
		return

	# Identity is copied into the visual tile only at this presentation point.
	# Before this, the board may already be logically resolved but F35 UI and
	# visuals continue to gate identity behind _visually_revealed_coords.
	tile.tile_data = cell.tile_data
	_visually_revealed_coords[coord] = true
	feedback.animate_tile_reveal(tile)
	var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(
		phase_34.runtime.get_public_level(coord)
	)
	action_feedback_label.text = "%s revelada." % level_name
	_append_event(&"", "reveal", "%s revelada en %s" % [level_name, str(coord)])
	await _wait_presentation_delay(feedback.reveal_duration)


func _snap_unit_to_visual_coord(
	player_id: StringName,
	coord: Vector2i
) -> bool:
	var unit := get_trainer_unit(player_id)
	var tile := _get_tile_view(coord)
	if unit == null or tile == null:
		return false
	var anchor := tile.get_node_or_null("UnitAnchor") as Marker3D
	if anchor == null:
		return false
	return unit.snap_visual_to(anchor, _get_visual_slot_offset(player_id, coord))


func _get_visual_world_position(
	player_id: StringName,
	coord: Vector2i
) -> Vector3:
	var tile := _get_tile_view(coord)
	if tile == null:
		return Vector3.ZERO
	var anchor := tile.get_node_or_null("UnitAnchor") as Marker3D
	if anchor == null:
		return tile.global_position
	return anchor.global_position + _get_visual_slot_offset(player_id, coord)


func _get_visual_slot_offset(
	player_id: StringName,
	coord: Vector2i
) -> Vector3:
	var player_ids: Array[StringName] = []
	for key in _visual_coord_by_player.keys():
		var other_id := StringName(key)
		if other_id == player_id:
			continue
		var value: Variant = _visual_coord_by_player.get(other_id, Vector2i.ZERO)
		if value is Vector2i and value == coord:
			player_ids.append(other_id)
	player_ids.append(player_id)
	player_ids.sort()
	if player_ids.size() <= 1:
		return Vector3.ZERO
	var slot_index: int = player_ids.find(player_id)
	if slot_index < 0:
		return Vector3.ZERO
	return VISUAL_SLOT_OFFSETS[slot_index % VISUAL_SLOT_OFFSETS.size()]


func _get_tile_view(coord: Vector2i) -> KarmanyHexTile3D:
	if phase_34 == null or phase_34.phase_32 == null or phase_34.phase_32.phase_31 == null:
		return null
	return phase_34.phase_32.phase_31.get_tile_view(coord)


func _get_camera_controller() -> KarmanyStrategicCameraController:
	if phase_34 == null or phase_34.phase_32 == null or phase_34.phase_32.phase_31 == null:
		return null
	return phase_34.phase_32.phase_31.camera_controller


func _focus_player_visual(player_id: StringName) -> void:
	var unit := get_trainer_unit(player_id)
	var controller := _get_camera_controller()
	if unit != null and controller != null:
		controller.focus_world_position(unit.global_position)


func _focus_coord(coord: Vector2i) -> void:
	var tile := _get_tile_view(coord)
	var controller := _get_camera_controller()
	if tile != null and controller != null:
		controller.focus_world_position(tile.global_position)


func _set_display_active_player(
	player_id: StringName,
	round_number: int = -1,
	actions_remaining: int = -1
) -> void:
	_display_active_player_id = player_id
	if round_number >= 0:
		_display_round_number = round_number
	if actions_remaining >= 0:
		_display_actions_remaining = actions_remaining
	for key in _halo_by_player.keys():
		var halo := _halo_by_player.get(key, null) as MeshInstance3D
		if halo != null:
			halo.visible = StringName(key) == player_id
	_refresh_active_label()


func _sync_display_to_logical_active() -> void:
	var manager := phase_34.runtime.local_session.turn_manager
	var active := manager.get_active_player()
	if active != null:
		_set_display_active_player(
			active.player_id,
			manager.current_round,
			manager.actions_remaining
		)


func _refresh_active_label() -> void:
	if active_turn_label == null or phase_34 == null or phase_34.runtime == null:
		return
	var role: String = _long_player_role(_display_active_player_id)
	active_turn_label.text = "%s — TURNO | Ronda %d | acciones %d/2" % [
		role,
		_display_round_number,
		_display_actions_remaining
	]


func _refresh_public_hud() -> void:
	if phase_34 == null or phase_34.runtime == null:
		return
	_refresh_active_label()
	var lines: PackedStringArray = PackedStringArray()
	for player in phase_34.runtime.local_session.players:
		if player == null:
			continue
		var visual_coord: Vector2i = get_visual_coord(player.player_id)
		var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(
			phase_34.runtime.get_public_level(visual_coord)
		)
		var points: int = phase_34.runtime.local_session.get_player_legacy_points(player.player_id)
		var marker: String = "▶ " if player.player_id == _display_active_player_id else "   "
		lines.append("%s%s | %d PL | %s | %s" % [
			marker,
			_long_player_role(player.player_id),
			points,
			level_name,
			str(visual_coord)
		])
	participants_label.text = "\n".join(lines)

	var human_id: StringName = phase_34.runtime.human_player_id
	location_label.text = get_public_location_text_for_coord(get_visual_coord(human_id))
	status_label.text = "Presentacion Alpha %.1fx | gameplay F34 intacto | camara manual disponible" % presentation_speed_multiplier
	_set_controls_disabled(_presentation_busy)


func _set_controls_disabled(value: bool) -> void:
	if pass_human_button == null:
		return
	var active: KarmanyPlayerState = null
	if phase_34 != null and phase_34.runtime != null:
		active = phase_34.runtime.local_session.turn_manager.get_active_player()
	var human_active: bool = active != null and phase_34.runtime.ai_match_controller.is_human_player(active.player_id)
	var ai_active: bool = active != null and phase_34.runtime.ai_match_controller.is_ai_player(active.player_id)
	pass_human_button.disabled = value or not human_active
	run_ai_button.disabled = value or not ai_active
	run_all_ai_button.disabled = value or not ai_active
	center_human_button.disabled = value


func _build_feedback_text(
	player_id: StringName,
	action_label: String,
	destination: Vector2i
) -> String:
	var prefix: String = _short_player_id(player_id)
	var level_name: String = KarmanyCanonicalMap41Layout.get_level_short_name(
		phase_34.runtime.get_public_level(destination)
	)
	if action_label.begins_with("Explorar"):
		return "%s explora %s" % [prefix, level_name]
	if action_label.begins_with("Mover"):
		return "%s se mueve a %s" % [prefix, level_name]
	if action_label.begins_with("Interactuar"):
		return "%s interactua" % prefix
	if action_label.begins_with("Mejorar"):
		return "%s mejora su Libro" % prefix
	return "%s: %s" % [prefix, _compact_action_label(action_label)]


func _compact_action_label(action_label: String) -> String:
	if action_label.length() <= 52:
		return action_label
	return action_label.left(49) + "..."


func _short_player_id(player_id: StringName) -> String:
	var text: String = String(player_id)
	if text.begins_with("player_"):
		return "P%s" % text.trim_prefix("player_")
	return text


func _short_player_role(player_id: StringName) -> String:
	if phase_34.runtime.ai_match_controller.is_human_player(player_id):
		return "%s Humano" % _short_player_id(player_id)
	return "%s IA %s" % [
		_short_player_id(player_id),
		phase_34.runtime.ai_match_controller.get_ai_profile_name(player_id)
	]


func _long_player_role(player_id: StringName) -> String:
	if player_id == &"":
		return "Sin jugador"
	if phase_34.runtime.ai_match_controller.is_human_player(player_id):
		return "%s HUMANO" % _short_player_id(player_id)
	var profile: String = phase_34.runtime.ai_match_controller.get_ai_profile_name(player_id).to_upper()
	return "%s %s" % [_short_player_id(player_id), profile]


func _append_event(
	player_id: StringName,
	kind: String,
	text: String
) -> void:
	_presentation_events.append({
		"player_id": player_id,
		"kind": kind,
		"text": text
	})
	while _presentation_events.size() > EVENT_HISTORY_LIMIT:
		_presentation_events.pop_front()


func _is_human_logically_active() -> bool:
	var active := phase_34.runtime.local_session.turn_manager.get_active_player()
	return active != null and phase_34.runtime.ai_match_controller.is_human_player(active.player_id)


func _wait_presentation_delay(base_seconds: float) -> void:
	var duration: float = maxf(base_seconds / presentation_speed_multiplier, 0.0)
	if duration <= 0.0:
		return
	await get_tree().create_timer(duration).timeout


func _on_pass_human_pressed() -> void:
	pass_human_turn_presented()


func _on_run_ai_pressed() -> void:
	await run_current_ai_turn_presented()


func _on_run_all_ai_pressed() -> void:
	await run_all_ai_until_human_presented()


func _on_center_human_pressed() -> void:
	center_on_human()
