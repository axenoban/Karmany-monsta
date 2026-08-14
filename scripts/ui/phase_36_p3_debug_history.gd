class_name KarmanyPhase36P3DebugHistory
extends Node


@onready var ux: KarmanyPhase36MatchUxBridge = get_parent() as KarmanyPhase36MatchUxBridge

var _last_rendered_signature: String = ""


func _process(_delta: float) -> void:
	if ux == null or not ux.setup_ok:
		return
	var runtime := ux.get_runtime()
	if runtime == null or runtime.ai_match_controller == null:
		return
	var ai_control := runtime.ai_match_controller
	if ai_control.last_turn_player_id != &"player_3":
		return
	if ai_control.last_turn_diagnostics.is_empty():
		return

	var signature: String = ""
	for diagnostic in ai_control.last_turn_diagnostics:
		signature += "%s|%.3f|%s;" % [
			String(diagnostic.get("action_label", "")),
			float(diagnostic.get("score", 0.0)),
			str(diagnostic.get("resources_after", {}))
		]
	if signature == _last_rendered_signature:
		return
	_last_rendered_signature = signature
	_render(ai_control.last_turn_diagnostics)


func _render(diagnostics: Array[Dictionary]) -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("DEBUG P3 OPORTUNISTA · ultimas decisiones")
	var start_index: int = maxi(diagnostics.size() - 2, 0)
	for index in range(start_index, diagnostics.size()):
		var diagnostic: Dictionary = diagnostics[index]
		if not bool(diagnostic.get("success", false)):
			continue
		var before_value: Variant = diagnostic.get("resources_before", {})
		var after_value: Variant = diagnostic.get("resources_after", {})
		var before: Dictionary = before_value if before_value is Dictionary else {}
		var after: Dictionary = after_value if after_value is Dictionary else {}
		var mr_before: int = int(before.get(KarmanyEffectData.ResourceType.MR, 0))
		var mr_after: int = int(after.get(KarmanyEffectData.ResourceType.MR, 0))
		var marginal_text: String = "-"
		var utility_value: Variant = diagnostic.get("resource_utility", {})
		if utility_value is Dictionary:
			var utility: Dictionary = utility_value
			var details_value: Variant = utility.get("resource_details", [])
			if details_value is Array:
				var details: Array = details_value
				if not details.is_empty() and details[0] is Dictionary:
					var detail: Dictionary = details[0]
					marginal_text = "%.2f/obj.%d" % [
						float(detail.get("value", 0.0)),
						int(detail.get("target", 0))
					]
		lines.append("%s" % String(diagnostic.get("action_label", "accion")))
		lines.append(" score %.2f | rep -%.2f | MR %d→%d | marginal %s" % [
			float(diagnostic.get("score", 0.0)),
			float(diagnostic.get("repetition_penalty", 0.0)),
			mr_before,
			mr_after,
			marginal_text
		])
	ux.p3_debug_label.text = "\n".join(lines)
