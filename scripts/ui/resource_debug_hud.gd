class_name KarmanyResourceDebugHUD
extends CanvasLayer


@onready var resource_label: Label = (
	$PanelContainer/MarginContainer/VBoxContainer/ResourceLabel
)


var player_state: KarmanyPlayerState = null


func _ready() -> void:
	_refresh()


func bind_player(player: KarmanyPlayerState) -> void:
	_disconnect_current_player()
	player_state = player

	if player_state != null:
		var callback := Callable(
			self,
			"_on_resource_changed"
		)

		if not player_state.resource_inventory.resource_changed.is_connected(
			callback
		):
			player_state.resource_inventory.resource_changed.connect(
				callback
			)

	_refresh()


func get_display_text() -> String:
	if resource_label == null:
		return ""

	return resource_label.text


func _on_resource_changed(
	_resource_type: int,
	_previous_amount: int,
	_current_amount: int
) -> void:
	_refresh()


func _refresh() -> void:
	if resource_label == null:
		return

	if player_state == null:
		resource_label.text = "MN: - | MR: - | EK: - | FA: -"
		return

	resource_label.text = (
		player_state.resource_inventory.get_debug_summary()
	)


func _disconnect_current_player() -> void:
	if player_state == null:
		return

	var callback := Callable(
		self,
		"_on_resource_changed"
	)

	if player_state.resource_inventory.resource_changed.is_connected(
		callback
	):
		player_state.resource_inventory.resource_changed.disconnect(
			callback
		)


func _exit_tree() -> void:
	_disconnect_current_player()
