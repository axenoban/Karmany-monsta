extends Node


@onready var prototype: KarmanyPhase23VisualDirectionBridge = $Phase23VisualDirectionPrototype


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 23 VISUAL DIRECTION TEST")
	print("================================")

	var ok: bool = true
	ok = _test_environment_and_lighting() and ok
	ok = _test_board_materials_and_legibility() and ok
	ok = _test_trainer_and_hud_direction() and ok
	ok = _test_no_gameplay_mutation_and_idempotence() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 23 OK - Direccion visual, materiales, iluminacion y HUD validados.")
	else:
		push_error("FASE 23 ERROR - Revisar direccion visual.")
	print("================================")


func _test_environment_and_lighting() -> bool:
	var ok: bool = true
	var controller: KarmanyVisualDirectionController = prototype.get_visual_direction_controller()
	ok = _expect(controller != null and controller.is_configured(), "VisualDirectionController no esta configurado.") and ok
	ok = _expect(controller != null and controller.is_applied(), "La direccion visual no fue aplicada.") and ok
	ok = _expect(prototype.world_environment.environment != null, "WorldEnvironment debe tener Environment.") and ok
	ok = _expect(prototype.key_light.light_energy > 1.0, "La key light debe estar activa.") and ok
	ok = _expect(prototype.fill_light.light_energy > 0.0, "La fill light jade debe estar activa.") and ok
	ok = _expect(prototype.rim_light.light_energy > 0.0, "La rim light violeta debe estar activa.") and ok

	if prototype.world_environment.environment != null and controller != null:
		ok = _expect(
			prototype.world_environment.environment.background_color == controller.get_palette_color(&"background"),
			"El fondo debe usar la paleta de Vael."
		) and ok

	print("Entorno + key/fill/rim lights: ", "OK" if ok else "ERROR")
	return ok


func _test_board_materials_and_legibility() -> bool:
	var ok: bool = true
	var controller: KarmanyVisualDirectionController = prototype.get_visual_direction_controller()
	var board_ux: KarmanyPhase20BoardUXBridge = prototype.board_ux
	ok = _expect(board_ux != null, "No existe BoardUX para comprobar materiales.") and ok
	if board_ux == null or controller == null:
		return false

	var ground := board_ux.board_prototype.get_node_or_null("Ground") as MeshInstance3D
	var ground_material := ground.material_override as StandardMaterial3D if ground != null else null
	ok = _expect(ground_material != null, "El suelo debe tener material dirigido.") and ok
	if ground_material != null:
		ok = _expect(
			ground_material.albedo_color == controller.get_palette_color(&"ground"),
			"El suelo debe abandonar el gris placeholder."
		) and ok

	var center_value: Variant = board_ux.board_prototype.call("get_tile_view", Vector2i.ZERO)
	var center := center_value as KarmanyHexTile3D
	var hidden_value: Variant = board_ux.board_prototype.call("get_tile_view", Vector2i(0, -1))
	var hidden := hidden_value as KarmanyHexTile3D
	ok = _expect(center != null and hidden != null, "Faltan hexagonos del sandbox.") and ok
	if center != null:
		ok = _expect(center.base_color == controller.get_palette_color(&"start"), "La inicial debe usar jade de Start.") and ok
		ok = _expect(center.selected_color == controller.get_palette_color(&"gold"), "Seleccion debe conservar acento dorado.") and ok
	if hidden != null:
		ok = _expect(hidden.base_color == controller.get_palette_color(&"hidden"), "Ocultas deben usar azul profundo.") and ok
		ok = _expect(hidden.explore_hint_color == controller.get_palette_color(&"explore"), "Explorar debe seguir siendo azul legible.") and ok

	ok = _expect(board_ux.get_move_highlights().size() == 2, "Direccion visual no debe cambiar destinos Mover.") and ok
	ok = _expect(board_ux.get_explore_highlights().size() == 3, "Direccion visual no debe cambiar destinos Explorar.") and ok

	print("Materiales del tablero + legibilidad UX: ", "OK" if ok else "ERROR")
	return ok


func _test_trainer_and_hud_direction() -> bool:
	var ok: bool = true
	var board_ux: KarmanyPhase20BoardUXBridge = prototype.board_ux
	if board_ux == null:
		return false

	var trainer_value: Variant = board_ux.board_prototype.get("trainer_unit")
	var trainer := trainer_value as KarmanyTrainerUnit3D
	ok = _expect(trainer != null, "No existe Entrenador visual.") and ok
	if trainer != null:
		ok = _expect(trainer.get_node_or_null("KarmicBase") != null, "Entrenador debe tener base karmica visual.") and ok
		var body := trainer.get_node_or_null("Body") as MeshInstance3D
		ok = _expect(body != null and body.material_override != null, "Entrenador debe abandonar material placeholder.") and ok

	var main_margin := prototype.hud.get_node_or_null("MainMargin") as Control
	var title := prototype.hud.get_node_or_null("MainMargin/Panel/Margin/VBox/TitleLabel") as Label
	ok = _expect(main_margin != null and main_margin.theme != null, "HUD debe tener Theme de Karmany.") and ok
	ok = _expect(title != null and title.text.contains("FORJA DE RESONANCIA"), "HUD debe mostrar identidad del juego.") and ok
	ok = _expect(prototype.hud.get_action_button_enabled(KarmanyGameHUD.ACTION_MOVE), "Mover debe seguir funcional tras tematizar HUD.") and ok
	ok = _expect(prototype.hud.get_action_button_enabled(KarmanyGameHUD.ACTION_EXPLORE), "Explorar debe seguir funcional tras tematizar HUD.") and ok

	print("Entrenador + HUD tematizado: ", "OK" if ok else "ERROR")
	return ok


func _test_no_gameplay_mutation_and_idempotence() -> bool:
	var ok: bool = true
	var board_ux: KarmanyPhase20BoardUXBridge = prototype.board_ux
	if board_ux == null:
		return false

	var player: KarmanyPlayerState = board_ux.board_prototype.player_state
	var manager: KarmanyTurnManager = board_ux.board_prototype.turn_manager
	var coord_before: Vector2i = player.current_coord
	var actions_before: int = manager.actions_remaining
	var mn_before: int = player.get_resource_amount(KarmanyEffectData.ResourceType.MN)
	var cell_count_before: int = board_ux.board_prototype.board_state.get_cell_count()

	var trainer_value: Variant = board_ux.board_prototype.get("trainer_unit")
	var trainer := trainer_value as KarmanyTrainerUnit3D
	var karmic_base_count_before: int = _count_named_children(trainer, "KarmicBase")

	prototype.refresh_visual_direction()
	await get_tree().process_frame

	ok = _expect(player.current_coord == coord_before, "Direccion visual no debe mover jugador.") and ok
	ok = _expect(manager.actions_remaining == actions_before, "Direccion visual no debe consumir acciones.") and ok
	ok = _expect(player.get_resource_amount(KarmanyEffectData.ResourceType.MN) == mn_before, "Direccion visual no debe cambiar recursos.") and ok
	ok = _expect(board_ux.board_prototype.board_state.get_cell_count() == cell_count_before, "Direccion visual no debe cambiar tablero logico.") and ok
	ok = _expect(_count_named_children(trainer, "KarmicBase") == karmic_base_count_before, "Reaplicar estilo no debe duplicar nodos visuales.") and ok

	print("Sin mutacion gameplay + reaplicacion idempotente: ", "OK" if ok else "ERROR")
	return ok


func _count_named_children(parent: Node, child_name: String) -> int:
	if parent == null:
		return 0
	var count: int = 0
	for child in parent.get_children():
		if child.name == child_name:
			count += 1
	return count


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 23 ERROR: %s" % message)
	return false
