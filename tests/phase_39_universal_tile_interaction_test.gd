extends Node


const MAP_SEEDS = [39001, 39017]
const FIXED_TILE_PATHS = [
	"res://data/tiles/i_01_refugio_valle_jade.tres",
	"res://data/tiles/i_02_campamento_rio_bruma.tres",
	"res://data/tiles/i_03_puesto_rocoso.tres",
	"res://data/tiles/i_04_sendero_primer_vinculo.tres",
	"res://data/tiles/l_01_santuario_de_aeterna.tres"
]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 39 UNIVERSAL TILE INTERACTION TEST")
	print("================================")

	var ok: bool = true
	ok = _test_content_definitions() and ok
	ok = _test_map41_seed_randomization_and_hidden_safety() and ok
	ok = _test_human_no_cost_interaction() and ok
	ok = _test_forge_cost_and_limit() and ok
	ok = _test_blocked_interaction_preview() and ok
	ok = _test_ai_selects_and_executes_interaction() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 39 OK - Uso posterior universal, preview, legalidad, humano e IA validados.")
	else:
		push_error("FASE 39 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_content_definitions() -> bool:
	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("No se pudieron cargar los pools N1/N2/N3.")

	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, MAP_SEEDS[0]):
		return _fail("No se pudo configurar runtime para auditar perfiles.")
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		return _fail("No se pudo configurar FullMatchSession para auditar perfiles.")
	var service := session.universal_tile_interactions
	if service == null or not service.is_configured():
		return _fail("Servicio universal F39 no configurado.")

	var audited: Dictionary = {}
	for path_value in FIXED_TILE_PATHS:
		var tile := ResourceLoader.load(String(path_value)) as KarmanyTileData
		if not _validate_tile_definition(tile, service, audited):
			return false
	for level in [
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3
	]:
		for tile in pools.get_pool(level):
			if not _validate_tile_definition(tile, service, audited):
				return false

	if audited.size() != 13:
		return _fail(
			"Se esperaban 13 identidades materializadas en los pools actuales; se auditaron %d."
			% audited.size()
		)
	return true


func _validate_tile_definition(
	tile: KarmanyTileData,
	service: KarmanyUniversalTileInteractionService,
	audited: Dictionary
) -> bool:
	if tile == null:
		return _fail("Se encontro un Resource de loseta nulo.")
	if tile.tile_id.strip_edges().is_empty():
		return _fail("Se encontro una loseta sin tile_id.")
	if tile.later_use_text.strip_edges().is_empty():
		return _fail("%s carece de later_use_text/Uso posterior." % tile.tile_id)
	if not tile.has_universal_interaction_definition():
		return _fail("%s carece de interaction_profile_id F39." % tile.tile_id)
	if not service.is_tile_definition_valid(tile):
		return _fail("%s usa un perfil F39 desconocido." % tile.tile_id)
	if audited.has(tile.tile_id):
		return _fail("tile_id duplicado en contenido materializado: %s." % tile.tile_id)
	audited[tile.tile_id] = true
	return true


func _test_map41_seed_randomization_and_hidden_safety() -> bool:
	var fingerprints: Dictionary = {}
	for seed_value in MAP_SEEDS:
		var runtime := KarmanyMultiAiAlphaRuntime.new()
		if not runtime.configure_new(4, seed_value):
			return _fail("Seed %d: runtime no pudo configurarse." % seed_value)
		var session := KarmanyFullMatchSession.new()
		if not session.configure(runtime):
			return _fail("Seed %d: FullMatchSession no pudo configurarse." % seed_value)
		if runtime.board_state.get_cell_count() != KarmanyCanonicalMap41Layout.TOTAL_CELL_COUNT:
			return _fail("Seed %d: mapa no contiene 41 posiciones." % seed_value)

		fingerprints[runtime.content_session.get_assignment_fingerprint()] = true
		var hidden_coord := _first_hidden_coord(runtime)
		if hidden_coord == Vector2i(999, 999):
			return _fail("Seed %d: no se encontro una loseta oculta." % seed_value)
		var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
		var hidden_preview := session.universal_tile_interactions.get_public_preview(
			human,
			hidden_coord
		)
		if bool(hidden_preview.get("visible", true)):
			return _fail("Seed %d: preview marco una loseta oculta como visible." % seed_value)
		if String(hidden_preview.get("interaction_text", "")) != "OCULTA":
			return _fail("Seed %d: preview oculto expuso Uso posterior." % seed_value)
		if hidden_preview.has("tile_id"):
			return _fail("Seed %d: preview oculto expuso tile_id." % seed_value)

		for coord in runtime.board_state.get_coords():
			if not runtime.board_state.is_revealed(coord):
				if not runtime.content_session.reveal_into_board_state(
					runtime.board_state,
					coord
				):
					return _fail("Seed %d: no se pudo revelar %s durante auditoria." % [seed_value, coord])
			var tile := runtime.get_public_tile_data(coord)
			if tile == null:
				return _fail("Seed %d: posicion revelada sin KarmanyTileData." % seed_value)
			if not session.universal_tile_interactions.is_tile_definition_valid(tile):
				return _fail("Seed %d: %s usada por mapa carece de Uso posterior universal." % [seed_value, tile.tile_id])

	if fingerprints.size() != MAP_SEEDS.size():
		return _fail("Las seeds F39 no produjeron distribuciones de mapa diferentes.")
	return true


func _test_human_no_cost_interaction() -> bool:
	var setup := _new_started_session(39101)
	if setup.is_empty():
		return false
	var session: KarmanyFullMatchSession = setup["session"]
	var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
	var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
	var candidates := session.universal_tile_interactions.build_legal_candidates(player)
	if candidates.is_empty():
		return _fail("P1 no recibio Interactuar en su loseta Inicial revelada.")
	var candidate: KarmanyAiActionCandidate = candidates[0]
	if candidate.option_index < 0:
		return _fail("La prueba sin coste esperaba un efecto estructurado de Inicial.")
	var tile := runtime.get_public_tile_data(player.current_coord)
	var effect: KarmanyEffectData = tile.later_use_effects[candidate.option_index]
	if effect == null or effect.effect_type != KarmanyEffectData.EffectType.ADD_RESOURCE:
		return _fail("La opcion Inicial no es la recoleccion sin coste esperada.")
	var before_resource: int = player.get_resource(effect.resource_type)
	var actions_before: int = runtime.local_session.turn_manager.actions_remaining
	var execution := KarmanyAiActionExecutor.execute(
		runtime.coordinator,
		player,
		candidate
	)
	if execution == null or not execution.was_executed():
		return _fail("P1 no pudo ejecutar Interactuar sin coste.")
	if player.get_resource(effect.resource_type) != before_resource + effect.amount:
		return _fail("Interactuar sin coste no aplico el recurso definido.")
	if runtime.local_session.turn_manager.actions_remaining != actions_before - 1:
		return _fail("Interactuar humano no consumio exactamente una accion.")
	return true


func _test_forge_cost_and_limit() -> bool:
	var setup := _new_started_session(39111)
	if setup.is_empty():
		return false
	var session: KarmanyFullMatchSession = setup["session"]
	var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
	var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
	var forge_coord := _reveal_and_find_tile(runtime, &"N3-02")
	if forge_coord == Vector2i(999, 999):
		return _fail("No se encontro N3-02 en la distribucion F39.")
	if not runtime._relocate_player(player, forge_coord):
		return _fail("No se pudo preparar P1 sobre N3-02 para la prueba.")

	var forge_candidate := _find_interact_label(
		session.universal_tile_interactions.build_legal_candidates(player),
		"Forja 2 comunes"
	)
	if forge_candidate == null:
		return _fail("N3-02 no ofrecio la conversion legal de Forja como Interactuar.")
	var basics_before := _basic_resource_total(player)
	var fa_before: int = player.fa
	var actions_before: int = runtime.local_session.turn_manager.actions_remaining
	var execution := KarmanyAiActionExecutor.execute(
		runtime.coordinator,
		player,
		forge_candidate
	)
	if execution == null or not execution.was_executed():
		return _fail("La conversion de Forja fue ofrecida pero el executor la rechazo.")
	if _basic_resource_total(player) != basics_before - 2 or player.fa != fa_before + 1:
		return _fail("La conversion de Forja no cobro 2 comunes y otorgo 1 FA.")
	if runtime.local_session.turn_manager.actions_remaining != actions_before - 1:
		return _fail("La conversion de Forja no consumio exactamente una accion.")
	if not runtime.coordinator.forge_controller.has_used_conversion(player.player_id):
		return _fail("La Forja no registro su limite por jugador.")

	var after_candidates := session.universal_tile_interactions.build_legal_candidates(player)
	if _find_interact_label(after_candidates, "Forja 2 comunes") != null:
		return _fail("F39 volvio a ofrecer la conversion de Forja despues de usarla.")
	return true

func _test_blocked_interaction_preview() -> bool:
	var setup := _new_started_session(39121)
	if setup.is_empty():
		return false

	var session: KarmanyFullMatchSession = setup["session"]
	var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
	var player := runtime.local_session.get_player_by_id(
		runtime.human_player_id
	)

	var target := _reveal_and_find_tile(runtime, &"N2-01")
	if target == Vector2i(999, 999):
		return _fail(
			"No se encontro N2-01 para prueba bloqueada."
		)

	if not runtime._relocate_player(player, target):
		return _fail(
			"No se pudo preparar P1 sobre N2-01."
		)

	# Fixture aislado:
	# B-07 existe y es Bestia Media, pero todavia no forma parte
	# del catalogo runtime ejecutable completo.
	var medium_beast := ResourceLoader.load(
		"res://data/beasts/b_07_terranuk.tres"
	) as KarmanyBeastData

	if medium_beast == null:
		return _fail(
			"No se pudo cargar B-07 Terranuk para la prueba."
		)

	if medium_beast.tier != KarmanyBeastData.Tier.MEDIUM:
		return _fail(
			"B-07 no esta configurada como Bestia Media."
		)

	var medium_cards: Array[KarmanyBeastData] = [
		medium_beast
	]

	var test_deck := KarmanyBeastDeck.new()

	if not test_deck.setup(
		medium_cards,
		false,
		39121
	):
		return _fail(
			"No se pudo preparar el mazo temporal de Bestia Media."
		)

	var spawn := runtime.coordinator.spawn_beast(
		target,
		test_deck,
		false
	)

	if spawn == null or not spawn.is_spawned():
		return _fail(
			"No se pudo colocar la Bestia Media de prueba sobre N2-01."
		)

	# Verificacion 1:
	# La Bestia debe existir realmente dentro del BoardState.
	if not runtime.board_state.has_beast(target):
		return _fail(
			"Spawn exitoso, pero BoardState no registra Bestia en N2-01."
		)

	# Verificacion 2:
	# La celda debe reconocerse como bloqueada.
	if not runtime.board_state.is_blocked_by_beast(target):
		return _fail(
			"BoardState contiene Bestia, pero N2-01 no figura bloqueada."
		)

	# Verificacion 3:
	# El resolver comun debe prohibir Interactuar.
	var common_validation := KarmanyTileInteractionResolver.validate_common(
		player,
		runtime.board_state,
		runtime.local_session.turn_manager
	)

	if common_validation.is_success():
		return _fail(
			"validate_common considero legal Interactuar pese al bloqueo por Bestia."
		)

	if not common_validation.message.contains("Bestia"):
		return _fail(
			"validate_common rechazo Interactuar, pero no identifico la Bestia como causa."
		)

	# Verificacion 4:
	# El preview debe seguir mostrando la informacion publica,
	# pero marcar la accion como ilegal.
	var preview := session.universal_tile_interactions.get_public_preview(
		player,
		target
	)

	if not bool(preview.get("visible", false)):
		return _fail(
			"N2-01 revelada dejo de ser visible en preview."
		)

	if String(
		preview.get("interaction_text", "")
	).strip_edges().is_empty():
		return _fail(
			"N2-01 bloqueada oculto su Uso posterior."
		)

	if bool(preview.get("legal_now", true)):
		return _fail(
			"Interactuar siguio legal mientras una Bestia bloqueaba la loseta."
		)

	if not String(
		preview.get("requirements_text", "")
	).contains("Bestia"):
		return _fail(
			"Preview bloqueado no explico que la Bestia impide Interactuar."
		)

	# Verificacion 5:
	# La IA tampoco debe recibir candidatos de Interactuar.
	if not session.universal_tile_interactions.build_legal_candidates(
		player
	).is_empty():
		return _fail(
			"La IA recibio Interactuar aunque la Bestia bloquea N2-01."
		)

	return true

func _test_ai_selects_and_executes_interaction() -> bool:
	var setup := _new_started_session(39131)
	if setup.is_empty():
		return false
	var session: KarmanyFullMatchSession = setup["session"]
	var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
	var manager := runtime.local_session.turn_manager
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)

	for _index in range(2):
		var human_candidates := session.universal_tile_interactions.build_legal_candidates(human)
		if human_candidates.is_empty():
			return _fail("No se pudo cerrar P1 mediante dos Interactuar legales.")
		var human_execution := KarmanyAiActionExecutor.execute(
			runtime.coordinator,
			human,
			human_candidates[0]
		)
		if human_execution == null or not human_execution.was_executed():
			return _fail("Fallo Interactuar legal de preparacion para P1.")
	if manager.actions_remaining != 0 or not session.finish_human_turn_if_ready():
		return _fail("No se pudo avanzar legalmente de P1 a P2.")

	var ai_player := manager.get_active_player()
	if ai_player == null or not runtime.ai_match_controller.is_ai_player(ai_player.player_id):
		return _fail("P2 IA no quedo activo tras P1.")
	var all_actions := session.build_full_legal_actions(ai_player)
	var interact_actions: Array[KarmanyAiActionCandidate] = []
	for candidate in all_actions:
		if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.INTERACT:
			interact_actions.append(candidate)
	if interact_actions.is_empty():
		return _fail("P2 IA no recibio candidato universal de Interactuar.")
	var controller := runtime.ai_match_controller.get_ai_controller(ai_player.player_id)
	if controller == null:
		return _fail("P2 IA no tiene controlador.")
	var chosen := controller.brain.choose_action(interact_actions)
	if chosen == null or chosen.action_type != KarmanyAiActionCandidate.ActionType.INTERACT:
		return _fail("El cerebro IA no selecciono una opcion Interactuar del conjunto legal.")
	var actions_before: int = manager.actions_remaining
	var execution := KarmanyAiActionExecutor.execute(
		runtime.coordinator,
		ai_player,
		chosen
	)
	if execution == null or not execution.was_executed():
		return _fail("La IA eligio un Interactuar que el executor rechazo.")
	if manager.actions_remaining != actions_before - 1:
		return _fail("Interactuar IA no consumio exactamente una accion.")
	return true


func _new_started_session(seed_value: int) -> Dictionary:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, seed_value):
		_fail("Seed %d: no se pudo crear runtime." % seed_value)
		return {}
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		_fail("Seed %d: no se pudo crear FullMatchSession: %s" % [seed_value, session.last_error])
		return {}
	if not session.start_playing():
		_fail("Seed %d: no se pudo entrar a PLAYING." % seed_value)
		return {}
	return {"runtime": runtime, "session": session}


func _first_hidden_coord(runtime: KarmanyMultiAiAlphaRuntime) -> Vector2i:
	for coord in runtime.board_state.get_coords():
		if not runtime.board_state.is_revealed(coord):
			return coord
	return Vector2i(999, 999)


func _reveal_and_find_tile(
	runtime: KarmanyMultiAiAlphaRuntime,
	tile_id: StringName
) -> Vector2i:
	for coord in runtime.board_state.get_coords():
		if not runtime.board_state.is_revealed(coord):
			if not runtime.content_session.reveal_into_board_state(
				runtime.board_state,
				coord
			):
				continue
		var tile := runtime.get_public_tile_data(coord)
		if tile != null and StringName(tile.tile_id) == tile_id:
			return coord
	return Vector2i(999, 999)


func _find_interact_label(
	candidates: Array[KarmanyAiActionCandidate],
	needle: String
) -> KarmanyAiActionCandidate:
	for candidate in candidates:
		if candidate != null and candidate.debug_label.contains(needle):
			return candidate
	return null


func _basic_resource_total(player: KarmanyPlayerState) -> int:
	return (
		player.mn
		+ player.mr
		+ player.ek
	)


func _fail(message: String) -> bool:
	push_error("FASE 39 TEST ERROR: %s" % message)
	return false
