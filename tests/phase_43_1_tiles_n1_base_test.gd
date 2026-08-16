extends Node


const PENDING_PROFILE: StringName = &"pending_f44"
const PENDING_IDS: Array[String] = ["N1-05", "N1-06", "N1-07", "N1-08"]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.1A LOSETAS N1 BASE")
	print("================================")

	var ok: bool = true
	ok = _test_canonical_resources() and ok
	ok = _test_pending_content_is_not_in_runtime_pool() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 43.1A OK - N1-05..N1-08 materializadas canonicamente y aisladas del runtime hasta F44.")
	else:
		push_error("FASE 43.1A ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_canonical_resources() -> bool:
	var expected: Array[Dictionary] = [
		{
			"path": "res://data/tiles/canonical_pending/n1_05_sendero_verde.tres",
			"id": "N1-05",
			"name": "Sendero Verde",
			"on_explore": "Elige: revela 1 Bestia Basica y combatela; o recolecta 2 MN.",
			"entry": "Entrada: +1 Poder contra tu proxima Bestia este turno.",
			"later": "Enfrentar 1 Bestia Basica o moverte 1 loseta revelada adyacente.",
			"limit": "Si la Bestia no es derrotada, permanece bloqueando la loseta."
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_06_claro_de_resonancia.tres",
			"id": "N1-06",
			"name": "Claro de Resonancia",
			"on_explore": "Elige: roba 3 Resonancias y descarta 1; o recolecta 2 EK.",
			"entry": "Entrada: Roba 1 Resonancia y descarta 1.",
			"later": "Robar 1 Resonancia y descartar 1.",
			"limit": "-"
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_07_ruinas_del_eco.tres",
			"id": "N1-07",
			"name": "Ruinas del Eco",
			"on_explore": "Elige: revela 1 Bestia Basica y combatela; o recolecta 2 MR o 2 EK.",
			"entry": "Entrada: Obten 1 MR o 1 EK.",
			"later": "Enfrentar 1 Bestia Basica o recolectar 2 MR o 2 EK.",
			"limit": "Si la Bestia no es derrotada, permanece bloqueando la loseta."
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_08_puente_de_musgo.tres",
			"id": "N1-08",
			"name": "Puente de Musgo",
			"on_explore": "Mira 2 Karmany N1, elige 1 y dejalo visible aqui; el otro va al fondo. Alternativamente, mira una loseta N2 adyacente sin revelarla.",
			"entry": "Entrada: Mira la primera carta de Karmany N1; dejala arriba o abajo.",
			"later": "Vinculo guiado N1: mira 2 Karmany N1, elige 1 y puedes intentar vincularlo inmediatamente; si ya hay uno visible, puedes intentar vincular ese en su lugar.",
			"limit": "Vinculo guiado maximo 1 vez por turno."
		}
	]

	var seen: Dictionary = {}
	var service := KarmanyUniversalTileInteractionService.new()
	for row in expected:
		var path: String = String(row["path"])
		if not ResourceLoader.exists(path):
			return _fail("Falta Resource canónico pendiente: %s." % path)
		var tile := ResourceLoader.load(path) as KarmanyTileData
		if tile == null:
			return _fail("No se pudo cargar %s como KarmanyTileData." % path)
		if tile.tile_id != String(row["id"]):
			return _fail("ID incorrecto en %s: %s." % [path, tile.tile_id])
		if seen.has(tile.tile_id):
			return _fail("ID duplicado en el bloque F43.1A: %s." % tile.tile_id)
		seen[tile.tile_id] = true
		if tile.display_name != String(row["name"]):
			return _fail("Nombre no canónico en %s: %s." % [tile.tile_id, tile.display_name])
		if tile.level != KarmanyTileData.TileLevel.N1:
			return _fail("%s no está clasificada como N1." % tile.tile_id)
		if tile.on_explore_text != String(row["on_explore"]):
			return _fail("Al explorar difiere del maestro en %s." % tile.tile_id)
		if tile.entry_bonus_text != String(row["entry"]):
			return _fail("Bonificación de entrada difiere del maestro en %s." % tile.tile_id)
		if tile.later_use_text != String(row["later"]):
			return _fail("Uso posterior difiere del maestro en %s." % tile.tile_id)
		if tile.limit_text != String(row["limit"]):
			return _fail("Límite difiere del maestro en %s." % tile.tile_id)
		if tile.later_use_text.strip_edges().is_empty():
			return _fail("%s quedó sin Uso posterior / Interactuar." % tile.tile_id)
		if tile.interaction_profile_id != PENDING_PROFILE:
			return _fail("%s no está marcada explícitamente como automatización pendiente F44." % tile.tile_id)
		if not tile.later_use_effects.is_empty():
			return _fail("%s anuncia efectos estructurados que F43.1A no automatiza." % tile.tile_id)
		if service.is_tile_definition_valid(tile):
			return _fail("%s fue anunciada falsamente como ejecutable por F39." % tile.tile_id)
		if tile.starts_revealed:
			return _fail("%s no debe comenzar revelada." % tile.tile_id)

	if seen.size() != PENDING_IDS.size():
		return _fail("El bloque F43.1A no contiene exactamente 4 identidades.")
	return true


func _test_pending_content_is_not_in_runtime_pool() -> bool:
	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("No se pudieron cargar los pools runtime F32/F40.")

	var runtime_ids: Dictionary = {}
	for level in [
		KarmanyTileData.TileLevel.N1,
		KarmanyTileData.TileLevel.N2,
		KarmanyTileData.TileLevel.N3
	]:
		for tile in pools.get_pool(level):
			if tile != null:
				runtime_ids[tile.tile_id] = true

	for pending_id in PENDING_IDS:
		if runtime_ids.has(pending_id):
			return _fail("%s entró al pool runtime antes de tener automatización compatible." % pending_id)

	if pools.get_pool_size(KarmanyTileData.TileLevel.N1) != 4:
		return _fail("F43.1A alteró el pool N1 runtime; debía conservar el baseline seguro de 4 Resources.")
	return true


func _fail(message: String) -> bool:
	push_error("FASE 43.1A ERROR: %s" % message)
	return false
