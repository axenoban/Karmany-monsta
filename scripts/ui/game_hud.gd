class_name KarmanyGameHUD
extends CanvasLayer


signal action_requested(action_id: StringName)


const ACTION_MOVE: StringName = &"move"
const ACTION_EXPLORE: StringName = &"explore"
const ACTION_INTERACT: StringName = &"interact"
const ACTION_COMBAT: StringName = &"combat"
const ACTION_CALL_BOND: StringName = &"call_bond"
const ACTION_IMPROVE_BOOK: StringName = &"improve_book"
const ACTION_END_TURN: StringName = &"end_turn"


@onready var player_label: Label = $MainMargin/Panel/Margin/VBox/PlayerLabel
@onready var round_label: Label = $MainMargin/Panel/Margin/VBox/RoundLabel
@onready var actions_label: Label = $MainMargin/Panel/Margin/VBox/ActionsLabel
@onready var resources_label: Label = $MainMargin/Panel/Margin/VBox/ResourcesLabel
@onready var active_karmany_label: Label = $MainMargin/Panel/Margin/VBox/ActiveKarmanyLabel
@onready var reserve_label: Label = $MainMargin/Panel/Margin/VBox/ReserveLabel
@onready var cards_label: Label = $MainMargin/Panel/Margin/VBox/CardsLabel
@onready var legacy_points_label: Label = $MainMargin/Panel/Margin/VBox/LegacyPointsLabel
@onready var action_context_label: Label = $MainMargin/Panel/Margin/VBox/ActionContextLabel

@onready var move_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/MoveButton
@onready var explore_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/ExploreButton
@onready var interact_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/InteractButton
@onready var combat_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/CombatButton
@onready var call_bond_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/CallBondButton
@onready var improve_book_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/ImproveBookButton
@onready var end_turn_button: Button = $MainMargin/Panel/Margin/VBox/ActionGrid/EndTurnButton


var turn_manager: KarmanyTurnManager = null
var legacy_points_controller: KarmanyLegacyPointsController = null
var observed_player: KarmanyPlayerState = null

var _action_buttons: Dictionary = {}
var _action_states: Dictionary = {}


func _ready() -> void:
	_action_buttons = {
		ACTION_MOVE: move_button,
		ACTION_EXPLORE: explore_button,
		ACTION_INTERACT: interact_button,
		ACTION_COMBAT: combat_button,
		ACTION_CALL_BOND: call_bond_button,
		ACTION_IMPROVE_BOOK: improve_book_button,
		ACTION_END_TURN: end_turn_button
	}

	for action_id in _action_buttons.keys():
		var button: Button = _action_buttons[action_id]
		button.pressed.connect(_on_action_button_pressed.bind(action_id))
		_action_states[action_id] = {
			"enabled": false,
			"context": "Accion no disponible en el contexto actual."
		}

	_refresh()


func bind_turn_manager(manager: KarmanyTurnManager) -> void:
	_disconnect_turn_manager()
	turn_manager = manager
	if turn_manager != null:
		turn_manager.turn_started.connect(_on_turn_started)
		turn_manager.action_spent.connect(_on_action_spent)
		turn_manager.round_started.connect(_on_round_started)
		_observe_player(turn_manager.get_active_player())
	else:
		_observe_player(null)
	_refresh()


func bind_legacy_points_controller(
	controller: KarmanyLegacyPointsController
) -> void:
	_disconnect_legacy_points_controller()
	legacy_points_controller = controller
	if legacy_points_controller != null:
		legacy_points_controller.points_awarded.connect(_on_points_awarded)
	_refresh()


func set_action_state(
	action_id: StringName,
	enabled: bool,
	context_text: String = ""
) -> bool:
	if not _action_buttons.has(action_id):
		return false
	_action_states[action_id] = {
		"enabled": enabled,
		"context": context_text
	}
	_apply_action_button_state(action_id)
	return true


func set_action_context_text(text: String) -> void:
	if action_context_label != null:
		action_context_label.text = text


func get_action_button_enabled(action_id: StringName) -> bool:
	if not _action_buttons.has(action_id):
		return false
	var button: Button = _action_buttons[action_id]
	return not button.disabled


func get_snapshot() -> Dictionary:
	return {
		"player": player_label.text,
		"round": round_label.text,
		"actions": actions_label.text,
		"resources": resources_label.text,
		"active_karmany": active_karmany_label.text,
		"reserve": reserve_label.text,
		"cards": cards_label.text,
		"legacy_points": legacy_points_label.text,
		"action_context": action_context_label.text
	}


func _on_turn_started(
	player: KarmanyPlayerState,
	_round_number: int,
	_actions_available: int
) -> void:
	_observe_player(player)
	_refresh()


func _on_action_spent(
	_player: KarmanyPlayerState,
	_cost: int,
	_actions_remaining: int
) -> void:
	_refresh()


func _on_round_started(_round_number: int) -> void:
	_refresh()


func _on_resource_changed(
	_resource_type: int,
	_previous_amount: int,
	_current_amount: int
) -> void:
	_refresh()


func _on_karmany_added(_karmany: KarmanyRuntimeState) -> void:
	_refresh()


func _on_active_karmany_changed(_karmany: KarmanyRuntimeState) -> void:
	_refresh()


func _on_equipment_changed(_equipment: KarmanyEquipmentData) -> void:
	_refresh()


func _on_hand_changed() -> void:
	_refresh()


func _on_points_awarded(
	player_id: StringName,
	_points: int,
	_total_after: int,
	_source_type: int,
	_source_id: StringName
) -> void:
	if observed_player != null and observed_player.player_id == player_id:
		_refresh()


func _on_action_button_pressed(action_id: StringName) -> void:
	if not get_action_button_enabled(action_id):
		return
	var state: Dictionary = _action_states.get(action_id, {})
	var context_text: String = String(state.get("context", ""))
	if not context_text.is_empty():
		set_action_context_text(context_text)
	action_requested.emit(action_id)


func _observe_player(player: KarmanyPlayerState) -> void:
	_disconnect_observed_player()
	observed_player = player
	if observed_player == null:
		return

	observed_player.resource_inventory.resource_changed.connect(_on_resource_changed)
	observed_player.karmany_roster.karmany_added.connect(_on_karmany_added)
	observed_player.karmany_roster.active_karmany_changed.connect(_on_active_karmany_changed)
	observed_player.equipment_inventory.equipment_added.connect(_on_equipment_changed)
	observed_player.equipment_inventory.equipment_removed.connect(_on_equipment_changed)
	observed_player.resonance_hand.hand_changed.connect(_on_hand_changed)


func _disconnect_observed_player() -> void:
	if observed_player == null:
		return
	if observed_player.resource_inventory.resource_changed.is_connected(_on_resource_changed):
		observed_player.resource_inventory.resource_changed.disconnect(_on_resource_changed)
	if observed_player.karmany_roster.karmany_added.is_connected(_on_karmany_added):
		observed_player.karmany_roster.karmany_added.disconnect(_on_karmany_added)
	if observed_player.karmany_roster.active_karmany_changed.is_connected(_on_active_karmany_changed):
		observed_player.karmany_roster.active_karmany_changed.disconnect(_on_active_karmany_changed)
	if observed_player.equipment_inventory.equipment_added.is_connected(_on_equipment_changed):
		observed_player.equipment_inventory.equipment_added.disconnect(_on_equipment_changed)
	if observed_player.equipment_inventory.equipment_removed.is_connected(_on_equipment_changed):
		observed_player.equipment_inventory.equipment_removed.disconnect(_on_equipment_changed)
	if observed_player.resonance_hand.hand_changed.is_connected(_on_hand_changed):
		observed_player.resonance_hand.hand_changed.disconnect(_on_hand_changed)


func _disconnect_turn_manager() -> void:
	if turn_manager == null:
		return
	if turn_manager.turn_started.is_connected(_on_turn_started):
		turn_manager.turn_started.disconnect(_on_turn_started)
	if turn_manager.action_spent.is_connected(_on_action_spent):
		turn_manager.action_spent.disconnect(_on_action_spent)
	if turn_manager.round_started.is_connected(_on_round_started):
		turn_manager.round_started.disconnect(_on_round_started)


func _disconnect_legacy_points_controller() -> void:
	if legacy_points_controller == null:
		return
	if legacy_points_controller.points_awarded.is_connected(_on_points_awarded):
		legacy_points_controller.points_awarded.disconnect(_on_points_awarded)


func _refresh() -> void:
	if player_label == null:
		return

	var active_player := observed_player
	if turn_manager != null and turn_manager.is_running:
		active_player = turn_manager.get_active_player()
		if active_player != observed_player:
			_observe_player(active_player)

	if active_player == null:
		player_label.text = "Jugador activo: -"
		round_label.text = "Ronda: -"
		actions_label.text = "Acciones: - / 2"
		resources_label.text = "Recursos: MN - | MR - | EK - | FA -"
		active_karmany_label.text = "Karmany activo: -"
		reserve_label.text = "Reserva: -"
		cards_label.text = "Cartas: Resonancias - | Equipos -"
		legacy_points_label.text = "PL: -"
		_apply_all_action_states()
		return

	player_label.text = "Jugador activo: %s" % String(active_player.player_id)
	var round_number: int = turn_manager.current_round if turn_manager != null else 0
	round_label.text = "Ronda: %d" % round_number
	var remaining: int = turn_manager.actions_remaining if turn_manager != null else 0
	actions_label.text = "Acciones: %d / %d" % [remaining, KarmanyTurnManager.ACTIONS_PER_TURN]
	resources_label.text = "Recursos: %s" % active_player.resource_inventory.get_debug_summary()

	var active := active_player.get_active_karmany()
	if active == null or active.karmany_data == null:
		active_karmany_label.text = "Karmany activo: -"
	else:
		active_karmany_label.text = "Karmany activo: %s | Poder %d" % [
			active.karmany_data.display_name,
			active.karmany_data.power
		]

	var reserve_names: PackedStringArray = PackedStringArray()
	for runtime in active_player.get_linked_karmanys():
		if runtime == null or runtime.karmany_data == null:
			continue
		if active != null and runtime.instance_id == active.instance_id:
			continue
		reserve_names.append(runtime.karmany_data.display_name)
	reserve_label.text = "Reserva: %s" % (
		", ".join(reserve_names) if not reserve_names.is_empty() else "-"
	)

	cards_label.text = "Cartas: Resonancias %d | Equipos %d" % [
		active_player.get_resonance_count(),
		active_player.get_equipment_count()
	]
	var pending_discard: int = active_player.resonance_hand.get_pending_discard_count()
	if pending_discard > 0:
		cards_label.text += " | Descarta %d pendiente" % pending_discard

	var legacy_points: int = 0
	if legacy_points_controller != null:
		legacy_points = legacy_points_controller.get_total(active_player.player_id)
	legacy_points_label.text = "PL: %d" % legacy_points

	_apply_all_action_states()


func _apply_all_action_states() -> void:
	for action_id in _action_buttons.keys():
		_apply_action_button_state(action_id)


func _apply_action_button_state(action_id: StringName) -> void:
	if not _action_buttons.has(action_id):
		return
	var button: Button = _action_buttons[action_id]
	var state: Dictionary = _action_states.get(action_id, {})
	var enabled: bool = bool(state.get("enabled", false))

	if turn_manager != null:
		if action_id == ACTION_END_TURN:
			enabled = enabled and turn_manager.can_end_turn()
		else:
			enabled = enabled and turn_manager.is_running and turn_manager.actions_remaining > 0

	button.disabled = not enabled


func _exit_tree() -> void:
	_disconnect_observed_player()
	_disconnect_turn_manager()
	_disconnect_legacy_points_controller()
