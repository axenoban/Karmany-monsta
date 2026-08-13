extends Node


@onready var prototype: KarmanyPhase22FeedbackBridge = $Phase22FeedbackPrototype


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 22 FEEDBACK TEST")
	print("================================")

	var feedback: KarmanyPresentationFeedbackController = prototype.get_feedback_controller()
	feedback.set_duration_scale(0.0)

	var ok: bool = true
	ok = _test_feedback_is_presentation_only() and ok
	ok = _test_move_and_reveal_feedback() and ok
	ok = _test_hit_damage_appearance_transition() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 22 OK - Movimiento visual, revelacion, golpe, dano, aparicion y transicion validados.")
	else:
		push_error("FASE 22 ERROR - Revisar capa de animaciones/feedback.")
	print("================================")


func _test_feedback_is_presentation_only() -> bool:
	var ok: bool = true
	var board_ux: KarmanyPhase20BoardUXBridge = prototype.board_ux
	var player: KarmanyPlayerState = board_ux.board_prototype.player_state
	var trainer_value: Variant = board_ux.board_prototype.get("trainer_unit")
	var trainer := trainer_value as KarmanyTrainerUnit3D
	var center_tile_value: Variant = board_ux.board_prototype.call("get_tile_view", Vector2i.ZERO)
	var center_tile := center_tile_value as KarmanyHexTile3D

	ok = _expect(trainer != null, "No existe Entrenador visual para probar feedback.") and ok
	ok = _expect(center_tile != null, "No existe loseta central para feedback.") and ok
	if trainer == null or center_tile == null:
		return false

	var coord_before: Vector2i = player.current_coord
	var actions_before: int = board_ux.board_prototype.turn_manager.actions_remaining
	var resources_before: String = player.resource_inventory.get_debug_summary()

	prototype.feedback.animate_selection(center_tile)
	prototype.feedback.play_hit_feedback(trainer)
	prototype.feedback.play_damage_feedback(trainer, 3)
	prototype.feedback.play_transition("TEST")

	ok = _expect(player.current_coord == coord_before, "Feedback directo no debe mover logicamente al jugador.") and ok
	ok = _expect(board_ux.board_prototype.turn_manager.actions_remaining == actions_before, "Feedback directo no debe gastar acciones.") and ok
	ok = _expect(player.resource_inventory.get_debug_summary() == resources_before, "Feedback directo no debe alterar recursos.") and ok
	ok = _expect(prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_SELECTION) >= 1, "Debe registrarse feedback de seleccion.") and ok
	ok = _expect(prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_HIT) >= 1, "Debe registrarse feedback de golpe.") and ok
	ok = _expect(prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_DAMAGE) >= 1, "Debe registrarse feedback de dano.") and ok
	ok = _expect(prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_TRANSITION) >= 1, "Debe registrarse feedback de transicion.") and ok

	print("Feedback directo no altera gameplay: ", "OK" if ok else "ERROR")
	return ok


func _test_move_and_reveal_feedback() -> bool:
	var ok: bool = true
	var board_ux: KarmanyPhase20BoardUXBridge = prototype.board_ux
	var move_coords: Array[Vector2i] = board_ux.get_move_highlights()
	ok = _expect(not move_coords.is_empty(), "Fase 22 necesita un destino legal de Mover.") and ok
	if move_coords.is_empty():
		return false

	var move_tile_value: Variant = board_ux.board_prototype.call("get_tile_view", move_coords[0])
	var move_tile := move_tile_value as KarmanyHexTile3D
	ok = _expect(move_tile != null, "No se encontro loseta para Mover.") and ok
	if move_tile == null:
		return false

	var move_feedback_before: int = prototype.feedback.get_feedback_count(
		KarmanyPresentationFeedbackController.FEEDBACK_MOVE
	)
	move_tile.tile_clicked.emit(move_tile)
	board_ux.hud.move_button.pressed.emit()

	ok = _expect(
		prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_MOVE) == move_feedback_before + 1,
		"Mover resuelto debe disparar una animacion visual de unidad."
	) and ok
	ok = _expect(board_ux.board_prototype.turn_manager.actions_remaining == 1, "Mover debe conservar su coste logico de 1 accion.") and ok

	var explore_coords: Array[Vector2i] = board_ux.get_explore_highlights()
	ok = _expect(not explore_coords.is_empty(), "Tras Mover debe existir destino legal de Explorar.") and ok
	if explore_coords.is_empty():
		return false

	var explore_coord: Vector2i = explore_coords[0]
	var explore_tile_value: Variant = board_ux.board_prototype.call("get_tile_view", explore_coord)
	var explore_tile := explore_tile_value as KarmanyHexTile3D
	ok = _expect(explore_tile != null, "No se encontro loseta para Explorar.") and ok
	if explore_tile == null:
		return false

	var reveal_feedback_before: int = prototype.feedback.get_feedback_count(
		KarmanyPresentationFeedbackController.FEEDBACK_REVEAL
	)
	explore_tile.tile_clicked.emit(explore_tile)
	board_ux.hud.explore_button.pressed.emit()

	ok = _expect(board_ux.board_prototype.board_state.is_revealed(explore_coord), "Explorar debe seguir revelando logicamente la loseta.") and ok
	ok = _expect(
		prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_REVEAL) == reveal_feedback_before + 1,
		"Explorar resuelto debe disparar feedback visual de revelacion."
	) and ok
	ok = _expect(board_ux.board_prototype.turn_manager.actions_remaining == 0, "Mover+Explorar deben seguir consumiendo exactamente 2 acciones.") and ok

	print("Mover + revelar: logica primero, animacion despues: ", "OK" if ok else "ERROR")
	return ok


func _test_hit_damage_appearance_transition() -> bool:
	var ok: bool = true
	var board_ux: KarmanyPhase20BoardUXBridge = prototype.board_ux
	var actions_before: int = board_ux.board_prototype.turn_manager.actions_remaining
	var player: KarmanyPlayerState = board_ux.board_prototype.player_state
	var coord_before: Vector2i = player.current_coord

	var hit_before: int = prototype.feedback.get_feedback_count(
		KarmanyPresentationFeedbackController.FEEDBACK_HIT
	)
	var damage_before: int = prototype.feedback.get_feedback_count(
		KarmanyPresentationFeedbackController.FEEDBACK_DAMAGE
	)
	ok = _expect(prototype.play_hit_demo(4), "No se pudo reproducir golpe/dano demo.") and ok
	ok = _expect(
		prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_HIT) == hit_before + 1,
		"Golpe demo debe producir destello."
	) and ok
	ok = _expect(
		prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_DAMAGE) == damage_before + 1,
		"Golpe demo debe producir numero de dano."
	) and ok

	var appearance_before: int = prototype.feedback.get_feedback_count(
		KarmanyPresentationFeedbackController.FEEDBACK_APPEARANCE
	)
	ok = _expect(prototype.play_karmany_appearance_demo(), "No se pudo reproducir aparicion Karmany demo.") and ok
	ok = _expect(
		prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_APPEARANCE) == appearance_before + 1,
		"Aparicion demo debe usar feedback Karmany."
	) and ok
	ok = _expect(prototype.feedback_root.get_child_count() >= 1, "Debe quedar visible el placeholder Karmany demo.") and ok

	var transition_before: int = prototype.feedback.get_feedback_count(
		KarmanyPresentationFeedbackController.FEEDBACK_TRANSITION
	)
	ok = _expect(prototype.play_transition_demo("CAMBIO DE FASE"), "No se pudo reproducir transicion demo.") and ok
	ok = _expect(
		prototype.feedback.get_feedback_count(KarmanyPresentationFeedbackController.FEEDBACK_TRANSITION) == transition_before + 1,
		"Debe registrarse transicion de presentacion."
	) and ok

	ok = _expect(board_ux.board_prototype.turn_manager.actions_remaining == actions_before, "Demos de feedback no deben gastar acciones.") and ok
	ok = _expect(player.current_coord == coord_before, "Demos de feedback no deben alterar posicion logica.") and ok

	print("Golpe/dano + aparicion Karmany + transicion sin gameplay: ", "OK" if ok else "ERROR")
	return ok


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 22 ERROR: %s" % message)
	return false
