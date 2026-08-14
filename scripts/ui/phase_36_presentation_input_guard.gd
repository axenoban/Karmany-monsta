class_name KarmanyPhase36PresentationInputGuard
extends Node


@onready var ux: KarmanyPhase36MatchUxBridge = get_parent() as KarmanyPhase36MatchUxBridge


func _process(_delta: float) -> void:
	if ux == null or not ux.setup_ok:
		return
	var runtime := ux.get_runtime()
	if runtime == null or runtime.local_session == null:
		return
	var active := runtime.local_session.turn_manager.get_active_player()
	if active == null:
		return
	var display_id: StringName = ux.phase_35.get_display_active_player_id()
	if display_id == &"" or display_id == active.player_id:
		return

	# La lógica ya puede haber preparado al siguiente jugador mientras F35
	# todavía reproduce el turno anterior. Ningún botón debe iniciar otra
	# acción durante esa ventana de presentación.
	ux.move_button.disabled = true
	ux.explore_button.disabled = true
	ux.interact_button.disabled = true
	ux.improve_button.disabled = true
	ux.pass_button.disabled = true
	ux.ai_button.disabled = true
	ux.all_ai_button.disabled = true
	ux.actions_label.text = "PRESENTANDO: %s" % ux.phase_35.get_public_participants_text().split("\n")[0] if not ux.phase_35.get_public_participants_text().is_empty() else "PRESENTANDO TURNO"
	ux.action_reason_label.text = "Espera a que termine la animacion antes de iniciar otra accion."
