extends Node


const PHASE_34_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_34_multi_ai_prototype.tscn"
)
const TEST_SEEDS: Array[int] = [
	34001,
	34002,
	34017,
	34119,
	34999
]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 34 MULTI AI TEST")
	print("================================")

	var ok: bool = true
	ok = _test_phase_31_32_regression() and ok
	ok = _test_controller_layouts() and ok
	ok = _test_independent_ai_state() and ok
	ok = _test_out_of_turn_guard() and ok
	ok = _test_hidden_information_contract() and ok
	ok = _test_no_legal_action_safety() and ok
	ok = _test_multi_seed_stability() and ok
	var visual_ok: bool = await _test_visual_probe()
	ok = visual_ok and ok

	print("")
	print("================================")
	if ok:
		print("FASE 34 OK - 1 humano + hasta 3 IA legales, reproducibles y sin informacion oculta.")
	else:
		push_error("FASE 34 ERROR - Revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_phase_31_32_regression() -> bool:
	if not KarmanyCanonicalMap41Layout.is_fully_connected():
		return _fail("F31 ya no confirma conectividad mediante is_fully_connected().")

	var runtime_a := KarmanyMultiAiAlphaRuntime.new()
	var runtime_b := KarmanyMultiAiAlphaRuntime.new()
	if not runtime_a.configure_new(4, 34001):
		return _fail("No se pudo crear runtime F34 sobre F31/F32.")
	if not runtime_b.configure_new(4, 34001):
		return _fail("No se pudo repetir runtime con la misma seed.")

	if runtime_a.board_state.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
		return _fail("F34 altero las 41 posiciones canonicas.")
	if (
		runtime_a.content_session.get_assignment_fingerprint()
		!= runtime_b.content_session.get_assignment_fingerprint()
	):
		return _fail("La misma seed dejo de producir la misma distribucion F32.")

	var levels := KarmanyCanonicalMap41Layout.build_level_map()
	for coord_value in levels.keys():
		var coord: Vector2i = coord_value
		if runtime_a.board_state.get_structural_level(coord) != int(levels[coord]):
			return _fail("BoardState perdio el nivel estructural publico en %s." % coord)
		var level: int = int(levels[coord])
		if (
			level == KarmanyTileData.TileLevel.N1
			or level == KarmanyTileData.TileLevel.N2
			or level == KarmanyTileData.TileLevel.N3
		):
			if runtime_a.board_state.is_revealed(coord):
				return _fail("Una posicion N1/N2/N3 comenzo revelada.")
			if runtime_a.board_state.get_tile_data(coord) != null:
				return _fail("F34 expuso KarmanyTileData oculto antes de explorar.")

	print("Regresion F31/F32: 41 posiciones, conectividad, seed y ocultamiento: OK")
	return true


func _test_controller_layouts() -> bool:
	for player_count in [2, 3, 4]:
		var runtime := KarmanyMultiAiAlphaRuntime.new()
		if not runtime.configure_new(player_count, 34030 + player_count):
			return _fail("No se pudo configurar %dP para control humano/IA." % player_count)

		var ai_control := runtime.ai_match_controller
		if ai_control == null:
			return _fail("%dP no creo KarmanyMultiAiMatchController." % player_count)
		if ai_control.get_ai_controller_count() != player_count - 1:
			return _fail("%dP no contiene exactamente %d IA." % [player_count, player_count - 1])
		if not ai_control.is_human_player(&"player_1"):
			return _fail("%dP no identifica explicitamente P1 como HUMANO." % player_count)

		var expected_profiles: Array[int] = [
			KarmanyAiProfile.ProfileType.EXPLORER,
			KarmanyAiProfile.ProfileType.OPPORTUNIST,
			KarmanyAiProfile.ProfileType.AGGRESSIVE
		]
		var ai_ids := ai_control.get_ai_player_ids()
		if ai_ids.size() != player_count - 1:
			return _fail("%dP perdio IDs de jugadores IA." % player_count)

		for index in range(ai_ids.size()):
			var player_id: StringName = ai_ids[index]
			if not ai_control.is_ai_player(player_id):
				return _fail("%s no esta marcado explicitamente como IA." % player_id)
			if ai_control.get_ai_profile_type(player_id) != expected_profiles[index]:
				return _fail("Perfil IA inesperado para %s." % player_id)
			if ai_control.get_ai_controller(player_id) == null:
				return _fail("%s no posee controlador IA propio." % player_id)

	var alternate_human_runtime := KarmanyMultiAiAlphaRuntime.new()
	if not alternate_human_runtime.configure_new(3, 34039, &"player_2"):
		return _fail("La arquitectura no permite identificar un humano distinto de P1.")
	if not alternate_human_runtime.ai_match_controller.is_human_player(&"player_2"):
		return _fail("player_2 no pudo registrarse explicitamente como HUMANO.")
	if not alternate_human_runtime.ai_match_controller.is_ai_player(&"player_1"):
		return _fail("El tipo de control sigue dependiendo rigidamente de player_1.")

	print("Layouts 2P/3P/4P: HUMANO/IA explicitos y perfiles correctos: OK")
	return true


func _test_independent_ai_state() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, 34044):
		return _fail("No se pudo preparar 4P para independencia IA.")

	var ai_ids := runtime.ai_match_controller.get_ai_player_ids()
	var controllers: Array[KarmanyAiTurnController] = []
	for player_id in ai_ids:
		var controller := runtime.ai_match_controller.get_ai_controller(player_id)
		if controller == null:
			return _fail("Controlador IA nulo para %s." % player_id)
		controllers.append(controller)

	for first_index in range(controllers.size()):
		for second_index in range(first_index + 1, controllers.size()):
			var first := controllers[first_index]
			var second := controllers[second_index]
			if first == second:
				return _fail("Dos jugadores IA comparten KarmanyAiTurnController.")
			if first.brain == second.brain:
				return _fail("Dos jugadores IA comparten KarmanyAiBrain.")
			if first.brain.profile == second.brain.profile:
				return _fail("Dos jugadores IA comparten KarmanyAiProfile.")
			if first.brain.rng == second.brain.rng:
				return _fail("Dos jugadores IA comparten RNG mutable.")

	for player_id in ai_ids:
		var player := runtime.local_session.get_player_by_id(player_id)
		if player == null:
			return _fail("No existe PlayerState para %s." % player_id)
		if runtime.local_session.turn_manager.get_player_by_id(player_id) != player:
			return _fail("%s no usa el mismo PlayerState registrado en TurnManager." % player_id)

	print("IA independientes: PlayerState, Controller, Brain, Profile y RNG: OK")
	return true


func _test_out_of_turn_guard() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, 34055):
		return _fail("No se pudo preparar guard de turno.")

	var manager := runtime.local_session.turn_manager
	if manager.get_active_player().player_id != &"player_1":
		return _fail("La prueba de guard no inicio con el humano.")
	var actions_before: int = manager.actions_remaining

	if runtime.ai_match_controller.run_current_ai_turn():
		return _fail("Una IA pudo apropiarse del turno de P1.")
	if manager.get_active_player().player_id != &"player_1":
		return _fail("Intento IA fuera de turno altero jugador activo.")
	if manager.actions_remaining != actions_before:
		return _fail("Intento IA fuera de turno consumio acciones.")

	var player_2 := runtime.local_session.get_player_by_id(&"player_2")
	var legal := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		player_2
	)
	if not legal.is_empty():
		return _fail("Generador IA expuso acciones para un jugador fuera de turno.")

	print("Guard de turno: IA solo puede decidir y actuar durante su propio turno: OK")
	return true


func _test_hidden_information_contract() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(2, 34101):
		return _fail("No se pudo preparar test de informacion oculta.")
	if not runtime.simulate_human_probe_turn():
		return _fail("No se pudo entregar el turno a la IA en test oculto.")

	var manager := runtime.local_session.turn_manager
	var ai_player := manager.get_active_player()
	if ai_player == null or ai_player.player_id != &"player_2":
		return _fail("2P no entrego el turno a player_2 IA.")

	var legal := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		ai_player
	)
	var explore_candidate: KarmanyAiActionCandidate = null
	for candidate in legal:
		if (
			candidate != null
			and candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE
		):
			explore_candidate = candidate
			break

	if explore_candidate == null:
		return _fail("La IA no recibio posiciones explorables en mapa F32.")

	var target: Vector2i = explore_candidate.target_coord
	var public_level: int = int(
		explore_candidate.payload.get(
			"public_level",
			-1
		)
	)
	if (
		public_level != KarmanyTileData.TileLevel.N1
		and public_level != KarmanyTileData.TileLevel.N2
		and public_level != KarmanyTileData.TileLevel.N3
	):
		return _fail("La IA no recibio un nivel estructural publico valido.")
	if explore_candidate.payload.has("tile_id"):
		return _fail("La accion IA filtro tile_id de una posicion oculta.")
	if explore_candidate.payload.has("display_name"):
		return _fail("La accion IA filtro display_name de una posicion oculta.")

	var before_snapshot := runtime.get_public_ai_snapshot(target)
	if bool(before_snapshot.get("revealed", true)):
		return _fail("Snapshot IA marco revelada una posicion oculta.")
	if before_snapshot.has("tile_id") or before_snapshot.has("display_name"):
		return _fail("Snapshot publico expuso identidad antes de explorar.")
	if runtime.board_state.get_tile_data(target) != null:
		return _fail("BoardState expuso KarmanyTileData oculto a la IA.")

	var execution := KarmanyAiActionExecutor.execute(
		runtime.coordinator,
		ai_player,
		explore_candidate
	)
	if not execution.was_executed():
		return _fail("Explorar legal fue rechazado durante test de informacion oculta.")

	var after_snapshot := runtime.get_public_ai_snapshot(target)
	if not bool(after_snapshot.get("revealed", false)):
		return _fail("La loseta no quedo publica despues de Explorar.")
	if not after_snapshot.has("tile_id") or not after_snapshot.has("display_name"):
		return _fail("La identidad no se hizo publica despues de Explorar.")
	var public_tile := runtime.get_public_tile_data(target)
	if public_tile == null or int(public_tile.level) != public_level:
		return _fail("La loseta revelada no coincide con su nivel estructural publico.")

	print("Informacion oculta: nivel visible, identidad oculta hasta Explorar: OK")
	return true


func _test_no_legal_action_safety() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(2, 34155):
		return _fail("No se pudo preparar test de IA sin acciones legales.")
	if not runtime.simulate_human_probe_turn():
		return _fail("No se pudo entregar turno a P2 para test sin acciones.")

	var manager := runtime.local_session.turn_manager
	var ai_player := manager.get_active_player()
	if ai_player == null or ai_player.player_id != &"player_2":
		return _fail("Test sin acciones no llego a P2.")

	# Este bloqueo pertenece solo al test: elimina interaccion de la Inicial y
	# ocupa sus vecinos para verificar la salida segura del controlador.
	runtime.board_state.set_tile_data(ai_player.current_coord, null)
	ai_player.mn = 0
	ai_player.mr = 0
	ai_player.ek = 0
	ai_player.fa = 0
	var blocker_index: int = 0
	for neighbor in runtime.board_state.get_existing_neighbors(ai_player.current_coord):
		if runtime.board_state.get_occupying_unit_id(neighbor) != &"":
			continue
		runtime.board_state.set_unit_occupant(
			neighbor,
			StringName("phase34_blocker_%d" % blocker_index)
		)
		blocker_index += 1

	var legal := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		ai_player
	)
	if not legal.is_empty():
		return _fail("El escenario bloqueado aun expone acciones legales.")

	if not runtime.ai_match_controller.run_current_ai_turn():
		return _fail("IA sin acciones legales no pudo finalizar de forma segura.")
	if not runtime.ai_match_controller.last_turn_had_budget_relinquish:
		return _fail("IA sin acciones no registro renuncia controlada de presupuesto.")
	if not runtime.ai_match_controller.last_turn_executions.is_empty():
		return _fail("IA sin acciones invento una accion ejecutable.")
	if manager.get_active_player() == null or manager.get_active_player().player_id != &"player_1":
		return _fail("IA sin acciones dejo el turno bloqueado.")
	if manager.current_round != 2:
		return _fail("IA sin acciones no permitio el cambio de ronda.")

	print("Sin acciones legales: salida acotada, motivo registrado y turno finalizado: OK")
	return true


func _test_multi_seed_stability() -> bool:
	for seed_value in TEST_SEEDS:
		var runtime := KarmanyMultiAiAlphaRuntime.new()
		if not runtime.configure_new(4, seed_value):
			return _fail("No se pudo configurar seed %d." % seed_value)

		var manager := runtime.local_session.turn_manager
		for cycle_index in range(3):
			if manager.get_active_player() == null:
				return _fail("Seed %d perdio jugador activo." % seed_value)
			if manager.get_active_player().player_id != &"player_1":
				return _fail("Seed %d no regreso al humano antes del ciclo." % seed_value)

			var round_before: int = manager.current_round
			if not runtime.simulate_human_probe_turn():
				return _fail("Seed %d no pudo cerrar P1 simulado." % seed_value)

			var expected_ai_ids: Array[StringName] = [
				&"player_2",
				&"player_3",
				&"player_4"
			]
			for expected_id in expected_ai_ids:
				var active := manager.get_active_player()
				if active == null or active.player_id != expected_id:
					return _fail(
						"Seed %d rompio secuencia antes de %s."
						% [seed_value, String(expected_id)]
					)
				if manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
					return _fail("%s no recibio 2 acciones." % expected_id)

				if not runtime.ai_match_controller.run_current_ai_turn():
					return _fail(
						"Seed %d dejo atrapado el turno de %s."
						% [seed_value, String(expected_id)]
					)

				if runtime.ai_match_controller.last_turn_executions.size() > 2:
					return _fail("%s intento ejecutar mas de 2 acciones." % expected_id)
				if (
					runtime.ai_match_controller.last_turn_decision_attempts
					> KarmanyTurnManager.ACTIONS_PER_TURN
					* KarmanyMultiAiMatchController.MAX_DECISION_ATTEMPTS_PER_ACTION
				):
					return _fail("%s excedio limite interno de decisiones." % expected_id)

				for execution in runtime.ai_match_controller.last_turn_executions:
					if execution == null or not execution.was_executed():
						return _fail("%s registro una accion ilegal/rechazada como turno valido." % expected_id)
					if execution.actions_before - execution.actions_after != 1:
						return _fail("%s consumio presupuesto de accion incorrecto." % expected_id)

			if manager.current_round != round_before + 1:
				return _fail("Seed %d no avanzo de ronda tras P4." % seed_value)
			if manager.get_active_player() == null or manager.get_active_player().player_id != &"player_1":
				return _fail("Seed %d no devolvio control a P1." % seed_value)

		print(
			"Seed %d: 3 rondas cortas sin deadlock, secuencia P1/P2/P3/P4: OK"
			% seed_value
		)

	return true


func _test_visual_probe() -> bool:
	var prototype := PHASE_34_SCENE.instantiate() as KarmanyPhase34MultiAiBridge
	if prototype == null:
		return _fail("No se pudo instanciar escena visual F34.")
	add_child(prototype)
	await get_tree().process_frame
	await get_tree().process_frame

	var ok: bool = true
	if not prototype.setup_ok:
		ok = _fail("Escena F34 no completo setup 4P.")
	elif prototype.runtime == null:
		ok = _fail("Escena F34 no expone runtime.")
	elif prototype.runtime.ai_match_controller.get_ai_controller_count() != 3:
		ok = _fail("Escena F34 no contiene tres controladores IA.")
	elif prototype.get_active_player_id() != &"player_1":
		ok = _fail("Escena F34 no inicia visualmente en P1 HUMANO.")

	if ok and not prototype.pass_human_turn():
		ok = _fail("Escena F34 no pudo cerrar turno humano de prueba.")
	if ok and prototype.get_active_player_id() != &"player_2":
		ok = _fail("Escena F34 no entrego visualmente el turno a P2.")
	if ok and not prototype.run_all_ai_until_human():
		ok = _fail("Escena F34 no pudo ejecutar P2/P3/P4 automaticamente.")
	if ok and prototype.get_active_player_id() != &"player_1":
		ok = _fail("Escena F34 no regreso visualmente a P1.")
	if ok and prototype.get_current_round() != 2:
		ok = _fail("Escena F34 no muestra ronda 2 tras P4.")

	prototype.queue_free()
	await get_tree().process_frame
	if ok:
		print("Probe F6: P1 humano + P2/P3/P4 IA + retorno a ronda 2: OK")
	return ok


func _fail(message: String) -> bool:
	push_error("FASE 34 ERROR: %s" % message)
	return false
