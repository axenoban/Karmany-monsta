class_name KarmanyPhase33MultiplayerBridge
extends Node3D


const TRAINER_UNIT_SCENE: PackedScene = preload("res://scenes/trainers/trainer_unit_3d.tscn")
const PLAYER_TINTS: Array[Color] = [
	Color(0.22, 0.58, 0.95, 1.0),
	Color(0.95, 0.55, 0.22, 1.0),
	Color(0.35, 0.78, 0.38, 1.0),
	Color(0.72, 0.38, 0.88, 1.0)
]


@onready var phase_32: KarmanyPhase32RandomMapBridge = $Phase32RandomMapPrototype
@onready var two_player_button: Button = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/SetupRow/TwoPlayerButton
@onready var three_player_button: Button = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/SetupRow/ThreePlayerButton
@onready var four_player_button: Button = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/SetupRow/FourPlayerButton
@onready var spend_action_button: Button = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/TurnRow/SpendActionButton
@onready var end_turn_button: Button = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/TurnRow/EndTurnButton
@onready var status_label: Label = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/StatusLabel
@onready var participants_label: Label = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/ParticipantsLabel
@onready var turn_label: Label = $Phase33Overlay/MainMargin/Panel/InnerMargin/VBox/TurnLabel


var multiplayer_session: KarmanyLocalMultiplayerSession = null
var trainer_units: Array[KarmanyTrainerUnit3D] = []
var setup_ok: bool = false


func _ready() -> void:
	if phase_32 == null or not phase_32.setup_ok or phase_32.phase_31 == null:
		push_error("FASE 33 ERROR: Fase 32/Fase 31 no esta disponible.")
		return

	var phase_32_overlay := phase_32.get_node_or_null("Phase32Overlay") as CanvasLayer
	if phase_32_overlay != null:
		phase_32_overlay.visible = false

	_remove_phase_31_prototype_trainer()
	_connect_controls()
	setup_ok = setup_player_count(4)
	if setup_ok:
		print("FASE 33 VISUAL OK - infraestructura local 2P/3P/4P activa.")
	else:
		push_error("FASE 33 ERROR: No se pudo preparar el setup visual inicial de 4 jugadores.")


func setup_player_count(player_count: int) -> bool:
	if phase_32 == null or phase_32.phase_31 == null:
		return false

	_clear_current_multiplayer_setup()

	var new_session := KarmanyLocalMultiplayerSession.new()
	if not new_session.setup_local_players(player_count):
		return false

	var board_state := phase_32.phase_31.board_state
	if not new_session.register_initial_occupancy(board_state):
		return false

	multiplayer_session = new_session
	if not _spawn_trainer_units():
		multiplayer_session.clear_registered_occupancy(board_state)
		_clear_trainer_units()
		multiplayer_session = null
		return false

	if not multiplayer_session.start_match():
		multiplayer_session.clear_registered_occupancy(board_state)
		_clear_trainer_units()
		multiplayer_session = null
		return false

	_refresh_overlay()
	return true


func consume_action() -> bool:
	if multiplayer_session == null or multiplayer_session.turn_manager == null:
		return false
	var spent: bool = multiplayer_session.turn_manager.spend_action()
	_refresh_overlay()
	return spent


func finish_turn() -> bool:
	if multiplayer_session == null or multiplayer_session.turn_manager == null:
		return false
	var ended: bool = multiplayer_session.turn_manager.end_turn()
	_refresh_overlay()
	return ended


func get_participant_count() -> int:
	if multiplayer_session == null:
		return 0
	return multiplayer_session.get_player_count()


func get_active_player_id() -> StringName:
	if multiplayer_session == null or multiplayer_session.turn_manager == null:
		return &""
	var active_player := multiplayer_session.turn_manager.get_active_player()
	if active_player == null:
		return &""
	return active_player.player_id


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


func _clear_current_multiplayer_setup() -> void:
	if multiplayer_session != null and phase_32 != null and phase_32.phase_31 != null:
		multiplayer_session.clear_registered_occupancy(phase_32.phase_31.board_state)
	_clear_trainer_units()
	multiplayer_session = null


func _clear_trainer_units() -> void:
	for unit in trainer_units:
		if unit != null and is_instance_valid(unit):
			unit.free()
	trainer_units.clear()


func _spawn_trainer_units() -> bool:
	if multiplayer_session == null:
		return false
	var phase_31 := phase_32.phase_31
	for index in range(multiplayer_session.players.size()):
		var player: KarmanyPlayerState = multiplayer_session.players[index]
		var coord: Vector2i = multiplayer_session.starting_coords[index]
		var tile := phase_31.get_tile_view(coord)
		if tile == null:
			return false
		var anchor := tile.get_node_or_null("UnitAnchor") as Marker3D
		if anchor == null:
			return false

		var unit := TRAINER_UNIT_SCENE.instantiate() as KarmanyTrainerUnit3D
		if unit == null:
			return false
		unit.configure(player, multiplayer_session.unit_ids[index])
		phase_31.units.add_child(unit)
		_apply_placeholder_tint(unit, index)
		if not unit.place_at(anchor, coord):
			unit.free()
			return false
		trainer_units.append(unit)
	return trainer_units.size() == multiplayer_session.players.size()


func _apply_placeholder_tint(unit: KarmanyTrainerUnit3D, player_index: int) -> void:
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


func _connect_controls() -> void:
	if not two_player_button.pressed.is_connected(_on_two_player_pressed):
		two_player_button.pressed.connect(_on_two_player_pressed)
	if not three_player_button.pressed.is_connected(_on_three_player_pressed):
		three_player_button.pressed.connect(_on_three_player_pressed)
	if not four_player_button.pressed.is_connected(_on_four_player_pressed):
		four_player_button.pressed.connect(_on_four_player_pressed)
	if not spend_action_button.pressed.is_connected(_on_spend_action_pressed):
		spend_action_button.pressed.connect(_on_spend_action_pressed)
	if not end_turn_button.pressed.is_connected(_on_end_turn_pressed):
		end_turn_button.pressed.connect(_on_end_turn_pressed)


func _on_two_player_pressed() -> void:
	if not setup_player_count(2):
		status_label.text = "No se pudo preparar 2P."


func _on_three_player_pressed() -> void:
	if not setup_player_count(3):
		status_label.text = "No se pudo preparar 3P."


func _on_four_player_pressed() -> void:
	if not setup_player_count(4):
		status_label.text = "No se pudo preparar 4P."


func _on_spend_action_pressed() -> void:
	if not consume_action():
		status_label.text = "No hay una accion legal disponible para gastar."


func _on_end_turn_pressed() -> void:
	if not finish_turn():
		status_label.text = "Debes consumir las 2 acciones antes de finalizar el turno."


func _refresh_overlay() -> void:
	if multiplayer_session == null or multiplayer_session.turn_manager == null:
		status_label.text = "Sin setup multijugador."
		participants_label.text = ""
		turn_label.text = ""
		return

	var manager := multiplayer_session.turn_manager
	status_label.text = "%dP | mapa 41 y seed F32 conservados | ocupacion inicial exclusiva" % multiplayer_session.get_player_count()

	var participant_lines: PackedStringArray = PackedStringArray()
	for index in range(multiplayer_session.players.size()):
		var player: KarmanyPlayerState = multiplayer_session.players[index]
		participant_lines.append(
			"P%d  %s  inicio=%s  unidad=%s  PL=%d" % [
				index + 1,
				String(player.player_id),
				str(player.current_coord),
				String(multiplayer_session.unit_ids[index]),
				multiplayer_session.get_player_legacy_points(player.player_id)
			]
		)
	participants_label.text = "\n".join(participant_lines)

	var active_player := manager.get_active_player()
	var active_id: String = "ninguno"
	if active_player != null:
		active_id = String(active_player.player_id)
	turn_label.text = "Ronda %d | turno: %s | acciones restantes: %d/2" % [
		manager.current_round,
		active_id,
		manager.actions_remaining
	]
	spend_action_button.disabled = not manager.can_spend_action(1)
	end_turn_button.disabled = not manager.can_end_turn()
