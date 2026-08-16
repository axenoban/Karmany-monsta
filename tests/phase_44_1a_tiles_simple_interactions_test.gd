extends Node


const TILE_SPECS: Array[Dictionary] = [
	{
		"id": "N1-06",
		"path": "res://data/tiles/canonical_pending/n1_06_claro_de_resonancia.tres",
		"profile": &"effect",
		"types": [KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS],
		"execute_index": 0,
	},
	{
		"id": "N1-10",
		"path": "res://data/tiles/canonical_pending/n1_10_pozo_de_bruma.tres",
		"profile": &"effect",
		"types": [KarmanyEffectData.EffectType.ADD_RESOURCE, KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS],
		"execute_index": 1,
	},
	{
		"id": "N1-11",
		"path": "res://data/tiles/canonical_pending/n1_11_rocas_del_alba.tres",
		"profile": &"effect",
		"types": [KarmanyEffectData.EffectType.ADD_RESOURCE],
		"execute_index": 0,
	},
	{
		"id": "N1-16",
		"path": "res://data/tiles/canonical_pending/n1_16_fuente_serena.tres",
		"profile": &"effect",
		"types": [KarmanyEffectData.EffectType.ADD_RESOURCE, KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS],
		"execute_index": 1,
	},
	{
		"id": "N1-18",
		"path": "res://data/tiles/canonical_pending/n1_18_cruce_de_raices.tres",
		"profile": &"effect",
		"types": [KarmanyEffectData.EffectType.ADD_RESOURCE],
		"execute_index": 0,
	},
	{
		"id": "N2-03",
		"path": "res://data/tiles/canonical_pending/n2_03_ruinas_del_eco.tres",
		"profile": &"beast_medium",
		"types": [KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS],
		"execute_index": 0,
	},
	{
		"id": "N2-07",
		"path": "res://data/tiles/canonical_pending/n2_07_garganta_del_aullido.tres",
		"profile": &"beast_medium",
		"types": [KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS],
		"execute_index": 0,
	},
	{
		"id": "N2-11",
		"path": "res://data/tiles/canonical_pending/n2_11_nido_salvaje.tres",
		"profile": &"beast_medium",
		"types": [KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS],
		"execute_index": 0,
	},
]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 44.1A TILE INTERACTIONS")
	print("================================")
	var ok: bool = true
	ok = _test_definitions() and ok
	ok = _test_runtime_resolution() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 44.1A OK - 8 losetas con Uso posterior simple/resonante ejecutable sin promover aun Al explorar/Entrada.")
	else:
		push_error("FASE 44.1A ERROR - revisar el primer fallo real.")
	print("================================")


func _test_definitions() -> bool:
	var setup := _new_started_session(44101)
	if setup.is_empty():
		return false
	var session: KarmanyFullMatchSession = setup["session"]
	var service := session.universal_tile_interactions
	if service == null or not service.is_configured():
		return _fail("Servicio universal F39 no disponible para validar F44.1A.")

	for spec in TILE_SPECS:
		var tile := ResourceLoader.load(String(spec["path"])) as KarmanyTileData
		if tile == null:
			return _fail("No se pudo cargar %s." % String(spec["id"]))
		if tile.tile_id != String(spec["id"]):
			return _fail("%s cargo con tile_id inesperado %s." % [String(spec["id"]), tile.tile_id])
		if tile.interaction_profile_id != StringName(spec["profile"]):
			return _fail("%s no usa el perfil F44.1A esperado." % tile.tile_id)
		if tile.interaction_profile_id == &"pending_f44":
			return _fail("%s sigue marcado pending_f44 en Uso posterior." % tile.tile_id)
		if not tile.has_universal_interaction_definition():
			return _fail("%s no satisface el contrato universal de Interactuar." % tile.tile_id)
		if not service.is_tile_definition_valid(tile):
			return _fail("%s usa un perfil no reconocido por F39." % tile.tile_id)

		var expected_types: Array = spec["types"]
		if tile.later_use_effects.size() != expected_types.size():
			return _fail("%s esperaba %d opciones estructuradas y tiene %d." % [tile.tile_id, expected_types.size(), tile.later_use_effects.size()])
		for index in range(expected_types.size()):
			var effect: KarmanyEffectData = tile.later_use_effects[index]
			if effect == null or effect.effect_type != int(expected_types[index]):
				return _fail("%s opcion %d no coincide con su efecto canonico F44.1A." % [tile.tile_id, index])
			if effect.effect_type == KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS:
				if effect.card_source_id != KarmanyResonanceEffectAdapter.CARD_SOURCE_ID:
					return _fail("%s robo/descarte no apunta al mazo de Resonancias." % tile.tile_id)
				if effect.amount <= 0 or effect.secondary_amount <= 0:
					return _fail("%s robo/descarte carece de cantidades validas." % tile.tile_id)
	print("F44.1A DEFINICIONES | 8/8 losetas con Interactuar estructurado.")
	return true


func _test_runtime_resolution() -> bool:
	for index in range(TILE_SPECS.size()):
		var spec: Dictionary = TILE_SPECS[index]
		var setup := _new_started_session(44200 + index)
		if setup.is_empty():
			return false
		var runtime: KarmanyMultiAiAlphaRuntime = setup["runtime"]
		var player := runtime.local_session.get_player_by_id(runtime.human_player_id)
		var manager := runtime.local_session.turn_manager
		var tile := ResourceLoader.load(String(spec["path"])) as KarmanyTileData
		if player == null or manager == null or tile == null:
			return _fail("%s no pudo preparar contexto runtime." % String(spec["id"]))

		var fixture := KarmanyBoardState.new()
		if not fixture.add_cell(player.current_coord, tile, true, int(tile.level)):
			return _fail("%s no pudo crear celda de prueba." % tile.tile_id)

		var option_index: int = int(spec["execute_index"])
		var effect: KarmanyEffectData = tile.later_use_effects[option_index]
		var actions_before: int = manager.actions_remaining
		var resource_before: int = player.get_resource(effect.resource_type)
		var hand_before: int = player.resonance_hand.get_count()
		var pending_before: int = player.resonance_hand.get_pending_discard_count()

		var result := KarmanyTileInteractionResolver.interact_effect_option(
			player,
			fixture,
			manager,
			option_index,
			runtime.coordinator.effect_context
		)
		if result == null or not result.is_success():
			return _fail("%s rechazo su opcion estructurada: %s" % [tile.tile_id, result.message if result != null else "resultado nulo"])
		if manager.actions_remaining != actions_before - 1:
			return _fail("%s no consumio exactamente 1 accion." % tile.tile_id)

		if effect.effect_type == KarmanyEffectData.EffectType.ADD_RESOURCE:
			if player.get_resource(effect.resource_type) != resource_before + effect.amount:
				return _fail("%s no aplico el recurso esperado." % tile.tile_id)
		elif effect.effect_type == KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS:
			if player.resonance_hand.get_count() != hand_before + effect.amount:
				return _fail("%s no robo %d Resonancias." % [tile.tile_id, effect.amount])
			if player.resonance_hand.get_pending_discard_count() != pending_before + effect.secondary_amount:
				return _fail("%s no genero el descarte pendiente canonico." % tile.tile_id)

		print("F44.1A RUNTIME | %s opcion %d OK" % [tile.tile_id, option_index])
	return true


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
	push_error("FASE 44.1A TEST ERROR: %s" % message)
	return false
