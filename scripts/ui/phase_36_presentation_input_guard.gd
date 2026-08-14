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

	# La logica ya puede haber preparado al siguiente jugador mientras F35
	# todavia reproduce el turno anterior. Ningun boton debe iniciar otra
	# accion durante esa ventana de presentacion.
	ux.move_button.disabled = true
	ux.explore_button.disabled = true
	ux.interact_button.disabled = true
	ux.improve_button.disabled = true
	ux.pass_button.disabled = true
	ux.ai_button.disabled = true
	ux.all_ai_button.disabled = true
	ux.actions_label.text = "PRESENTANDO TURNO · espera a que termine la animacion"
	ux.action_reason_label.text = "Los controles se habilitan al sincronizar presentacion y TurnManager."
