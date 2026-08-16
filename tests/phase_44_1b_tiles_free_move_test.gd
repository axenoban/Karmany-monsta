extends Node


const TILE_SPECS: Array[Dictionary] = [
	{
		"id": "N1-05",
		"path": "res://data/tiles/canonical_pending/n1_05_sendero_verde.tres",
	},
	{
		"id": "N1-09",
		"path": "res://data/tiles/canonical_pending/n1_09_pradera_de_luma.tres",
	},
	{
		"id": "N1-12",
		"path": "res://data/tiles/canonical_pending/n1_12_sendero_partido.tres",
	},
]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 44.1B FREE MOVE")
	print("================================")
	var ok: bool = true
	ok = _test_definitions() and ok
	ok = _test_move_candidate_contract() and ok
	ok = _test_runtime_move_cost() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 44.1B OK - N1-05/N1-09/N1-12 reutilizan Mover para desplazamiento gratuito por Interactuar con exactamente 1 accion total.")
	else:
		push_error("FASE 44.1B ERROR - revisar el primer fallo real.")
	print("================================")


func _test_definitions() -> bool:
	var setup := _new_started_session(44310)
	if setup.is_empty():
		return false
	var session: KarmanyFullMatchSession = setup["session"]
	var service := session.universal_tile_interactions
	if service == null or not service.is_configured():
		return _fail("Servicio universal F39 no disponible.")

	for spec in TILE_SPECS:
		var tile := ResourceLoader.load(String(spec["path"])) as KarmanyTileData
		if tile == null:
			return _fail("No se pudo cargar %s." % String(spec["id"]))
		if tile.tile_id != String(spec["id"]):
			return _fail("%s cargo con tile_id inesperado." % String(spec["id"]))
		if tile.interaction_profile_id != KarmanyUniversalTileInteractionService.PROFILE_FREE_MOVE:
			return _fail("%s no usa el perfil free_move de F44.1B." % tile.tile_id)
		if not tile.resource_path.contains("/canonical_pending/"):
			return _fail("%s fue promovida fisicamente antes de completar sus otras clausulas." % tile.tile_id)
		if not tile.has_universal_interaction_definition():
			return _fail("%s no satisface el contrato universal F39." % tile.tile_id)
		if not service.is_tile_definition_valid(tile):
			return _fail("%s usa un perfil no reconocido por F39/F44." % tile.tile_id)
	print("F44.1B DEFINICIONES | 3/3 losetas con perfil free_move y canonical_pending preservado.")
	return true


func _test_move_candidate_contract() -> bool:
	var setup := _new_started_session(44320)
	if setup.is_empty():
		return false
	var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
	var session: KarmanyFullMatchSession = setup["session"]
	var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if player == null:
		return _fail("No se encontro P1 para validar candidatos de movimiento.")

	var hidden_neighbors: Array[Vector2i] = []
	for coord in runtime.board_state.get_existing_neighbors(player.current_coord):
		if not runtime.board_state.is_revealed(coord):
			hidden_neighbors.append(coord)
	var candidates := KarmanyAiLegalActionGenerator.build_legal_move_candidates(
		runtime.coordinator,
		player
	)
	for candidate in candidates:
		if candidate == null or candidate.action_type != KarmanyAiActionCandidate.ActionType.MOVE:
			return _fail("El builder F44.1B devolvio un candidato que no es Mover.")
		if hidden_neighbors.has(candidate.target_coord):
			return _fail("El builder F44.1B filtro incorrectamente una loseta oculta como destino.")
		if runtime.board_state.get_occupying_unit_id(candidate.target_coord) != &"":
			return _fail("El builder F44.1B ofrecio una posicion ocupada.")
		if not session.universal_tile_interactions._candidate_matches_profile(
			candidate,
			KarmanyUniversalTileInteractionService.PROFILE_FREE_MOVE
		):
			return _fail("El servicio universal no reconoce Mover bajo free_move.")
	print("F44.1B CANDIDATOS | ocultas/ocupadas excluidas y MOVE reconocido por el perfil universal.")
	return true


func _test_runtime_move_cost() -> bool:
	# Cada intento usa una sesion limpia. Primero Explorar revela sin desplazar;
	# luego el mismo candidato MOVE que envuelve Interactuar debe gastar solo
	# una accion adicional. Si la loseta revelada queda bloqueada por una
	# Bestia, se prueba otra seed sin falsear la legalidad normal.
	for attempt in range(8):
		var setup := _new_started_session(44400 + attempt)
		if setup.is_empty():
			continue
		var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
		var session: KarmanyFullMatchSession = setup["session"]
		var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
		var manager := runtime.local_session.turn_manager
		if player == null or manager == null:
			continue
		var origin: Vector2i = player.current_coord
		var target: Vector2i = Vector2i.ZERO
		var found_hidden: bool = false
		for coord in runtime.board_state.get_existing_neighbors(origin):
			if not runtime.board_state.is_revealed(coord):
				target = coord
				found_hidden = true
				break
		if not found_hidden:
			continue
		if not session._full_explore_executor(player, target):
			continue
		if player.current_coord != origin:
			return _fail("Explorar movio al jugador; F44.1B depende de la separacion Explorar/Mover.")
		if not runtime.board_state.is_revealed(target):
			return _fail("Explorar no revelo el destino de prueba.")

		var move_candidates := KarmanyAiLegalActionGenerator.build_legal_move_candidates(
			runtime.coordinator,
			player
		)
		var selected: KarmanyAiActionCandidate = null
		for candidate in move_candidates:
			if candidate != null and candidate.target_coord == target:
				selected = candidate
				break
		if selected == null:
			continue

		var actions_before: int = manager.actions_remaining
		if actions_before != 1:
			return _fail("Fixture inesperada: tras Explorar se esperaba 1 accion restante.")
		if not session._execute_candidate(player, selected):
			return _fail("El executor normal rechazo el MOVE subyacente de F44.1B.")
		if player.current_coord != target:
			return _fail("El MOVE subyacente no actualizo la posicion del jugador.")
		if manager.actions_remaining != actions_before - 1:
			return _fail("El movimiento especial no consumio exactamente 1 accion total.")
		if runtime.board_state.get_occupying_unit_id(origin) != &"":
			return _fail("La posicion anterior no quedo liberada.")
		if runtime.board_state.get_occupying_unit_id(target) == &"":
			return _fail("La nueva posicion no quedo ocupada.")
		print("F44.1B RUNTIME | movimiento legal %s -> %s consume 1 accion: OK" % [str(origin), str(target)])
		return true
	return _fail("No se encontro una seed de prueba con destino revelado legal sin bloqueo para validar el MOVE subyacente.")


func _new_started_session(seed_value: int) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_fail("Seed %d: no se pudo crear runtime." % seed_value)
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_fail("Seed %d: no se pudo configurar FullMatchSession: %s" % [seed_value, session.last_error])
		return {}
	if not session.start_playing():
		_fail("Seed %d: no se pudo entrar a PLAYING." % seed_value)
		return {}
	return {"runtime": runtime, "session": session}


func _fail(message: String) -> bool:
	push_error("FASE 44.1B TEST ERROR: %s" % message)
	return false
