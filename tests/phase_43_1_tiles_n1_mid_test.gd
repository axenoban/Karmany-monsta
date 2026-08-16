extends Node


const PENDING_PROFILE: StringName = &"pending_f44"
const PENDING_IDS: Array[String] = ["N1-13", "N1-14", "N1-15", "N1-16"]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.1C LOSETAS N1")
	print("================================")

	var ok: bool = true
	ok = _test_canonical_resources() and ok
	ok = _test_pending_content_is_not_in_runtime_pool() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 43.1C OK - N1-13..N1-16 materializadas canonicamente y aisladas del runtime hasta F44.")
	else:
		push_error("FASE 43.1C ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_canonical_resources() -> bool:
	var expected: Array[Dictionary] = [
		{
			"path": "res://data/tiles/canonical_pending/n1_13_refugio_menor.tres",
			"id": "N1-13",
			"name": "Refugio Menor",
			"function_tags": PackedStringArray(["Vinculo guiado N1", "refugio"]),
			"icon_tags": PackedStringArray(["Karmany", "MN"]),
			"on_explore": "Elige: mira 2 Karmany N1, deja 1 visible y devuelve el otro al fondo; o recolecta 2 MN.",
			"entry": "Entrada: Mira la primera carta de Karmany N1; dejala arriba o abajo.",
			"later": "Vinculo guiado N1: mira 2 Karmany N1, elige 1 y puedes intentar vincularlo inmediatamente; si ya hay uno visible, puedes intentar vincular ese. Tambien puedes recolectar 2 MN.",
			"limit": "Vinculo guiado maximo 1 vez por turno."
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_14_hierbas_de_vael.tres",
			"id": "N1-14",
			"name": "Hierbas de Vael",
			"function_tags": PackedStringArray(["Bestia Basica", "preparacion tactica"]),
			"icon_tags": PackedStringArray(["Bestia", "MN", "Resonancia"]),
			"on_explore": "Elige: revela 1 Bestia Basica y combatela; o recolecta 2 MN.",
			"entry": "Entrada: +1 Poder contra tu proxima Bestia este turno.",
			"later": "Enfrentar 1 Bestia Basica o robar 2 Resonancias y descartar 1.",
			"limit": "Si la Bestia no es derrotada, permanece bloqueando la loseta."
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_15_taller_improvisado.tres",
			"id": "N1-15",
			"name": "Taller Improvisado",
			"function_tags": PackedStringArray(["Interactuar: crafteo basico"]),
			"icon_tags": PackedStringArray(["Taller", "MN"]),
			"on_explore": "Elige: craftea 1 Equipo basico pagando costo normal; o recolecta 2 MN.",
			"entry": "Entrada: Mira 1 carta de Equipo del mazo; dejala arriba o abajo.",
			"later": "Craftear 1 Equipo basico o recolectar 2 MN.",
			"limit": "No permite Equipo avanzado ni ancestral."
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_16_fuente_serena.tres",
			"id": "N1-16",
			"name": "Fuente Serena",
			"function_tags": PackedStringArray(["Resonancia", "EK"]),
			"icon_tags": PackedStringArray(["EK", "Resonancia"]),
			"on_explore": "Elige: roba 2 Resonancias y descarta 1; o recolecta 2 EK.",
			"entry": "Entrada: Roba 1 Resonancia y descarta 1.",
			"later": "Recolectar 2 EK o robar 2 Resonancias y descartar 1.",
			"limit": "-"
		}
	]

	var seen: Dictionary = {}
	var service := KarmanyUniversalTileInteractionService.new()
	for row in expected:
		var path: String = String(row["path"])
		if not ResourceLoader.exists(path):
			return _fail("Falta Resource canonico pendiente: %s." % path)
		var tile := ResourceLoader.load(path) as KarmanyTileData
		if tile == null:
			return _fail("No se pudo cargar %s como KarmanyTileData." % path)
		if tile.tile_id != String(row["id"]):
			return _fail("ID incorrecto en %s: %s." % [path, tile.tile_id])
		if seen.has(tile.tile_id):
			return _fail("ID duplicado en el bloque F43.1C: %s." % tile.tile_id)
		seen[tile.tile_id] = true
		if tile.display_name != String(row["name"]):
			return _fail("Nombre no canonico en %s: %s." % [tile.tile_id, tile.display_name])
		if tile.level != KarmanyTileData.TileLevel.N1:
			return _fail("%s no esta clasificada como N1." % tile.tile_id)
		if tile.function_tags != (row["function_tags"] as PackedStringArray):
			return _fail("Funcion difiere del maestro en %s." % tile.tile_id)
		if tile.icon_tags != (row["icon_tags"] as PackedStringArray):
			return _fail("Iconos difieren del maestro en %s." % tile.tile_id)
		if tile.on_explore_text != String(row["on_explore"]):
			return _fail("Al explorar difiere del maestro en %s." % tile.tile_id)
		if tile.entry_bonus_text != String(row["entry"]):
			return _fail("Bonificacion de entrada difiere del maestro en %s." % tile.tile_id)
		if tile.later_use_text != String(row["later"]):
			return _fail("Uso posterior difiere del maestro en %s." % tile.tile_id)
		if tile.limit_text != String(row["limit"]):
			return _fail("Limite difiere del maestro en %s." % tile.tile_id)
		if tile.later_use_text.strip_edges().is_empty():
			return _fail("%s quedo sin Uso posterior / Interactuar." % tile.tile_id)
		if tile.interaction_profile_id != PENDING_PROFILE:
			return _fail("%s no esta marcada explicitamente como automatizacion pendiente F44." % tile.tile_id)
		if not tile.on_explore_effects.is_empty() or not tile.entry_effects.is_empty() or not tile.later_use_effects.is_empty():
			return _fail("%s anuncia efectos estructurados que F43.1C no automatiza." % tile.tile_id)
		if service.is_tile_definition_valid(tile):
			return _fail("%s fue anunciada falsamente como ejecutable por F39." % tile.tile_id)
		if tile.starts_revealed:
			return _fail("%s no debe comenzar revelada." % tile.tile_id)

	if seen.size() != PENDING_IDS.size():
		return _fail("El bloque F43.1C no contiene exactamente 4 identidades.")
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
			return _fail("%s entro al pool runtime antes de tener automatizacion compatible." % pending_id)

	if pools.get_pool_size(KarmanyTileData.TileLevel.N1) != 4:
		return _fail("F43.1C altero el pool N1 runtime; debia conservar el baseline seguro de 4 Resources.")
	return true


func _fail(message: String) -> bool:
	push_error("FASE 43.1C ERROR: %s" % message)
	return false
