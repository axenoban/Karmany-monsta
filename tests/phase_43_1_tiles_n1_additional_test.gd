extends Node


const PENDING_PROFILE: StringName = &"pending_f44"
const PENDING_IDS: Array[String] = ["N1-09", "N1-10", "N1-11", "N1-12"]


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.1B LOSETAS N1 ADICIONALES")
	print("================================")

	var ok: bool = true
	ok = _test_canonical_resources() and ok
	ok = _test_pending_content_is_not_in_runtime_pool() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 43.1B OK - N1-09..N1-12 materializadas canonicamente y aisladas del runtime hasta F44.")
	else:
		push_error("FASE 43.1B ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_canonical_resources() -> bool:
	var expected: Array[Dictionary] = [
		{
			"path": "res://data/tiles/canonical_pending/n1_09_pradera_de_luma.tres",
			"id": "N1-09",
			"name": "Pradera de Luma",
			"function_tags": PackedStringArray(["Movimiento", "informacion"]),
			"icon_tags": PackedStringArray(["Movimiento", "Ojo"]),
			"on_explore": "Elige: muevete 1 loseta revelada adyacente; o mira una loseta Nivel 2 adyacente sin revelarla.",
			"entry": "Entrada: Mira 1 loseta oculta adyacente.",
			"later": "Moverte 1 loseta revelada o mirar una loseta oculta adyacente.",
			"limit": "-"
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_10_pozo_de_bruma.tres",
			"id": "N1-10",
			"name": "Pozo de Bruma",
			"function_tags": PackedStringArray(["Resonancia", "EK"]),
			"icon_tags": PackedStringArray(["EK", "Resonancia"]),
			"on_explore": "Elige: recolecta 2 EK; o roba 2 Resonancias y descarta 1.",
			"entry": "Entrada: Roba 1 Resonancia y descarta 1.",
			"later": "Recolectar 2 EK o robar 1 Resonancia y descartar 1.",
			"limit": "-"
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_11_rocas_del_alba.tres",
			"id": "N1-11",
			"name": "Rocas del Alba",
			"function_tags": PackedStringArray(["Mineral", "conversion"]),
			"icon_tags": PackedStringArray(["MR"]),
			"on_explore": "Elige: recolecta 2 MR; o cambia 2 MN por 2 MR.",
			"entry": "Entrada: Obten 1 MR.",
			"later": "Recolectar 2 MR.",
			"limit": "-"
		},
		{
			"path": "res://data/tiles/canonical_pending/n1_12_sendero_partido.tres",
			"id": "N1-12",
			"name": "Sendero Partido",
			"function_tags": PackedStringArray(["Movimiento", "informacion"]),
			"icon_tags": PackedStringArray(["Movimiento", "Ojo"]),
			"on_explore": "Elige: muevete a una loseta revelada adyacente; o mira una loseta Nivel 2 adyacente.",
			"entry": "Entrada: Mira 1 loseta oculta adyacente.",
			"later": "Moverte 1 loseta revelada o mirar una loseta oculta adyacente.",
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
			return _fail("ID duplicado en el bloque F43.1B: %s." % tile.tile_id)
		seen[tile.tile_id] = true
		if tile.display_name != String(row["name"]):
			return _fail("Nombre no canonico en %s: %s." % [tile.tile_id, tile.display_name])
		if tile.level != KarmanyTileData.TileLevel.N1:
			return _fail("%s no esta clasificada como N1." % tile.tile_id)
		var expected_function_tags: PackedStringArray = row["function_tags"]
		var expected_icon_tags: PackedStringArray = row["icon_tags"]
		if tile.function_tags != expected_function_tags:
			return _fail("Funcion difiere del maestro en %s." % tile.tile_id)
		if tile.icon_tags != expected_icon_tags:
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
			return _fail("%s anuncia efectos estructurados que F43.1B no automatiza." % tile.tile_id)
		if service.is_tile_definition_valid(tile):
			return _fail("%s fue anunciada falsamente como ejecutable por F39." % tile.tile_id)
		if tile.starts_revealed:
			return _fail("%s no debe comenzar revelada." % tile.tile_id)

	if seen.size() != PENDING_IDS.size():
		return _fail("El bloque F43.1B no contiene exactamente 4 identidades.")
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
		return _fail("F43.1B altero el pool N1 runtime; debia conservar el baseline seguro de 4 Resources.")
	return true


func _fail(message: String) -> bool:
	push_error("FASE 43.1B ERROR: %s" % message)
	return false
