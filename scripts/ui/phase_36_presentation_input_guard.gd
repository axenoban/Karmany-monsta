class_name KarmanyPhase36PresentationInputGuard
extends Node


@onready var ux: KarmanyPhase36MatchUxBridge = get_parent() as KarmanyPhase36MatchUxBridge


func _process(_delta: float) -> void:
	if ux == null or not ux.setup_ok:
		return
	var runtime := ux.get_runtime()
	if runtime == null or runtime.local_session == null:
		return
	var manager := runtime.local_session.turn_manager
	var active := manager.get_active_player()
	if active == null:
		return
	var display_id: StringName = ux.phase_35.get_display_active_player_id()
	if display_id == &"" or display_id == active.player_id:
		# Cuando presentacion y logica coinciden, el contador real del
		# TurnManager es la fuente de verdad incluso para Interactuar/Libro,
		# acciones que no desplazan una unidad visual.
		ux.turn_label.text = "RONDA %d  ·  %s  ·  ACCIONES %d/%d" % [
			manager.current_round,
			_role_for(runtime, active.player_id),
			manager.actions_remaining,
			KarmanyTurnManager.ACTIONS_PER_TURN
		]
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


func _role_for(runtime: KarmanyMultiAiAlphaRuntime, player_id: StringName) -> String:
	var text: String = String(player_id)
	var short_id: String = text
	if text.begins_with("player_"):
		short_id = "P%s" % text.trim_prefix("player_")
	if runtime.ai_match_controller.is_human_player(player_id):
		return "%s HUMANO" % short_id
	return "%s %s" % [
		short_id,
		runtime.ai_match_controller.get_ai_profile_name(player_id).to_upper()
	]
