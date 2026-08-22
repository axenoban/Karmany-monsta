class_name KarmanyPhase46FeedbackPresenter
extends Node


var controller: KarmanyPhase46AlphaHudController = null
var feedback_label: Label = null


func _ready() -> void:
	call_deferred("_attach")


func _attach() -> void:
	controller = get_parent() as KarmanyPhase46AlphaHudController
	if controller == null or controller.hud_root == null or controller.phase_38 == null:
		push_error("FASE 46 ERROR: feedback presenter no encontro HUD/controller.")
		return

	# El Control raiz ocupa toda la pantalla solo para ordenar la capa F46.
	# Debe ignorar el mouse para que las zonas transparentes nunca intercepten
	# clicks destinados al tablero 3D. Los PanelContainer/Button hijos conservan
	# su propio mouse_filter y siguen siendo interactivos.
	controller.hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.name = "FeedbackBanner"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-350, 56)
	panel.size = Vector2(700, 34)
	controller.hud_root.add_child(panel)
	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.text = "Listo para jugar."
	panel.add_child(feedback_label)

	var session := controller.phase_38.full_session
	if session == null:
		return
	if not session.full_action_resolved.is_connected(_on_action_resolved):
		session.full_action_resolved.connect(_on_action_resolved)
	if not session.alpha_log_event.is_connected(_on_log_event):
		session.alpha_log_event.connect(_on_log_event)


func _on_action_resolved(
	_player_id: StringName,
	action_label: String,
	success: bool
) -> void:
	if feedback_label == null:
		return
	feedback_label.text = (
		"ACCION RESUELTA · %s" % action_label
		if success
		else "ACCION RECHAZADA · %s" % action_label
	)


func _on_log_event(message: String) -> void:
	if feedback_label == null or message.strip_edges().is_empty():
		return
	var upper := message.to_upper()
	if (
		upper.contains("AETERNA")
		or upper.contains("COMBAT")
		or upper.contains("BESTIA")
		or upper.contains("PVP")
		or upper.contains("VICTORY")
		or upper.contains("DEFEAT")
		or upper.contains("DERROTA")
	):
		feedback_label.text = message
