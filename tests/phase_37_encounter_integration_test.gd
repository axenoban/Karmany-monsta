extends Node


const TEST_SEED: int = 37301
const COMPLEX_TILE_PATH: String = "res://data/tiles/n3_03_cueva_de_cristal_ancestral.tres"


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 37 ENCOUNTER INTEGRATION TEST")
	print("================================")

	var ok: bool = true
	ok = _test_real_karmany_call_from_revealed_n1() and ok
	ok = _test_real_beast_spawn_from_public_tile_tags() and ok
	ok = _test_resonance_draw_uses_real_effect_context() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 37 ENCOUNTERS OK - Karmany, Bestia y Resonancias delegan a sistemas reales.")
	else:
		push_error("FASE 37 ENCOUNTERS ERROR - revisar el primer fallo de integracion.")
	print("================================")


func _test_real_karmany_call_from_revealed_n1() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED):
		return _fail("No se pudo configurar runtime para encuentro Karmany.")
	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	if p1 == null:
		return _fail("P1 no existe.")

	var explore_candidate: KarmanyAiActionCandidate = null
	for candidate in KarmanyAiLegalActionGenerator.build_legal_actions(runtime.coordinator, p1):
		if candidate != null and candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE:
			explore_candidate = candidate
			break
	if explore_candidate == null:
		return _fail("No existe N1 legal para preparar Llamar Karmany.")

	var exploration := KarmanyAiActionExecutor.execute(
		runtime.coordinator,
		p1,
		explore_candidate
	)
	if exploration == null or not exploration.was_executed():
		return _fail("Explorar N1 real fue rechazado.")
	if runtime.get_public_level(p1.current_coord) != KarmanyTileData.TileLevel.N1:
		return _fail("P1 no termino sobre N1 publica.")

	var candidates: Array[KarmanyData] = runtime.build_random_karmany_call_candidates(p1)
	if candidates.size() != 2:
		return _fail("Pool real no produjo exactamente 2 candidatos N1 para Llamar.")
	for data in candidates:
		if data == null or data.is_starting_karmany or data.rank != KarmanyData.Rank.N1:
			return _fail("Llamar recibio un Karmany incompatible con N1.")

	var call_result := runtime.call_random_karmany(p1, 0)
	if call_result == null or not call_result.is_success():
		return _fail("El encuentro Karmany real no pudo crearse via MatchCoordinator.")
	if call_result.encounter == null:
		return _fail("Llamar no dejo un Karmany visible real.")
	if call_result.encounter.source_coord != p1.current_coord:
		return _fail("Encuentro Karmany aparecio en una coordenada guionizada distinta al jugador.")
	if runtime.local_session.turn_manager.actions_remaining != 0:
		return _fail("Explorar + Llamar no consumieron exactamente las 2 acciones.")

	print("Karmany: N1 revelada -> 2 candidatos del pool -> encuentro visible sin coordenada fija: OK")
	return true


func _test_real_beast_spawn_from_public_tile_tags() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED + 1):
		return _fail("No se pudo configurar runtime para Bestia.")
	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	if p1 == null:
		return _fail("P1 no existe para Bestia.")

	var complex_tile := load(COMPLEX_TILE_PATH) as KarmanyTileData
	if complex_tile == null:
		return _fail("No se pudo cargar la loseta real de Bestia Compleja.")
	if not complex_tile.function_tags.has("Bestia Compleja"):
		return _fail("La loseta de prueba no declara Bestia Compleja en sus datos publicos.")
	var complex_deck := runtime.get_beast_deck_for_tier(KarmanyBeastData.Tier.COMPLEX)
	if complex_deck == null or complex_deck.is_empty():
		return _fail("No existe mazo seguro de Bestias Complejas.")

	# Preparacion exclusiva del test: se coloca un Resource real y revelado
	# bajo P1 para comprobar el adaptador contenido -> tier -> BeastDeck.
	# Produccion nunca fija esta coordenada ni esta Bestia.
	if not runtime.board_state.set_tile_data(p1.current_coord, complex_tile):
		return _fail("No se pudo colocar la loseta real en el probe de Bestia.")
	runtime.board_state.set_revealed(p1.current_coord, true)

	var spawn_result := runtime.spawn_beast_from_current_tile(p1, true)
	if spawn_result == null or not spawn_result.is_spawned():
		return _fail("Bestia no pudo aparecer desde function_tags + BeastDeck real.")
	if spawn_result.beast_state == null or spawn_result.beast_state.beast_data == null:
		return _fail("Spawn no contiene KarmanyBeastData real.")
	if spawn_result.beast_state.beast_data.tier != KarmanyBeastData.Tier.COMPLEX:
		return _fail("La Bestia aparecida no respeta el tier de contenido publico.")
	if not runtime.board_state.is_blocked_by_beast(p1.current_coord):
		return _fail("BoardState no refleja el bloqueo de la Bestia aparecida.")
	if not spawn_result.requires_immediate_combat:
		return _fail("El probe de entrada obligatoria no conservo requires_immediate_combat.")

	print("Bestia: function_tags publicos -> deck Complejo -> spawn/bloqueo real sin Bestia fija: OK")
	return true


func _test_resonance_draw_uses_real_effect_context() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, TEST_SEED + 2):
		return _fail("No se pudo configurar runtime para Resonancias.")
	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	if p1 == null:
		return _fail("P1 no existe para Resonancias.")

	var draw_effect: KarmanyEffectData = null
	for beast in KarmanyPhase37AlphaContentCatalog.get_runtime_beasts():
		for effect in beast.reward_effects:
			if (
				effect != null
				and effect.effect_type == KarmanyEffectData.EffectType.DRAW_CARDS
				and effect.card_source_id == KarmanyResonanceEffectAdapter.CARD_SOURCE_ID
			):
				draw_effect = effect
				break
		if draw_effect != null:
			break
	if draw_effect == null:
		return _fail("Catalogo seguro no contiene un efecto real de robo de Resonancias.")

	var hand_before: int = p1.get_resonance_count()
	var deck_before: int = runtime.resonance_deck.get_draw_count()
	var result := KarmanyEffectResolver.apply_effect(
		draw_effect,
		p1,
		runtime.coordinator.effect_context
	)
	if result == null or not result.was_applied():
		return _fail("EffectResolver no pudo delegar robo al ResonanceEffectAdapter.")
	if p1.get_resonance_count() - hand_before != draw_effect.amount:
		return _fail("La mano no recibio la cantidad indicada por el KarmanyEffectData.")
	if deck_before - runtime.resonance_deck.get_draw_count() != draw_effect.amount:
		return _fail("El mazo real no consumio las Resonancias robadas.")

	print("Resonancias: KarmanyEffectData -> EffectResolver -> EffectContext -> mazo real: OK")
	return true


func _fail(message: String) -> bool:
	push_error("FASE 37 ENCOUNTER TEST ERROR: %s" % message)
	return false
