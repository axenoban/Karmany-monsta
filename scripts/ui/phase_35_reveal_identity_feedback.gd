class_name KarmanyPhase35RevealIdentityFeedback
extends Node


@onready var visual_bridge: KarmanyPhase35FourPlayerVisualBridge = get_parent() as KarmanyPhase35FourPlayerVisualBridge


func _ready() -> void:
	if visual_bridge == null:
		return
	if not visual_bridge.visual_action_finished.is_connected(_on_visual_action_finished):
		visual_bridge.visual_action_finished.connect(_on_visual_action_finished)


func _on_visual_action_finished(
	player_id: StringName,
	action_text: String
) -> void:
	if visual_bridge == null or visual_bridge.phase_34 == null:
		return
	if not action_text.to_lower().contains("explora"):
		return

	var coord: Vector2i = visual_bridge.get_visual_coord(player_id)
	var public_tile: KarmanyTileData = visual_bridge.phase_34.runtime.get_public_tile_data(coord)
	if public_tile == null:
		return

	visual_bridge.action_feedback_label.text = "%s revela: %s" % [
		_short_player_id(player_id),
		public_tile.display_name
	]


func _short_player_id(player_id: StringName) -> String:
	var text: String = String(player_id)
	if text.begins_with("player_"):
		return "P%s" % text.trim_prefix("player_")
	return text
