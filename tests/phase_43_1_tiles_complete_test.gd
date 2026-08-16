extends Node


const PENDING_PROFILE: StringName = &"pending_f44"
const EXPECTED_PENDING_COUNT: int = 28
const EXPECTED_TOTAL_COUNT: int = 41


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.1 LOSETAS COMPLETAS")
	print("================================")

	var ok: bool = true
	ok = _test_remaining_canonical_fields() and ok
	ok = _test_all_41_materialized_once() and ok
	ok = _test_pending_tiles_are_not_runtime_executable() and ok
	ok = _test_runtime_pools_remain_safe() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 43.1 OK - 41/41 losetas canónicas materializadas; contenido pendiente aislado del runtime hasta F44.")
	else:
		push_error("FASE 43.1 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _test_remaining_canonical_fields() -> bool:
	var expected: Array[Dictionary] = [
		_row("n1_17_colina_de_guardia.tres", "N1-17", "Colina de Guardia", KarmanyTileData.TileLevel.N1, "Elige: revela 1 Bestia Basica y combatela; o mira una loseta Nivel 2 adyacente sin revelarla.", "Entrada: Mira 1 loseta oculta adyacente.", "Enfrentar 1 Bestia Basica o recolectar 2 MR.", "Si la Bestia no es derrotada, permanece bloqueando la loseta."),
		_row("n1_18_cruce_de_raices.tres", "N1-18", "Cruce de Raices", KarmanyTileData.TileLevel.N1, "Elige: recolecta 2 MN, 2 MR o 2 EK.", "Entrada: Obten 1 recurso comun a eleccion.", "Recolectar 2 MN.", "Uso posterior solo da MN; Al explorar y Entrada permiten recurso flexible."),
		_row("n2_02_bosque_de_vinculo.tres", "N2-02", "Bosque de Vinculo", KarmanyTileData.TileLevel.N2, "Elige: mira 2 Karmany N2, deja 1 visible y devuelve el otro al fondo; o recolecta 2 EK.", "Entrada: Mira la primera carta de Karmany N2; dejala arriba o abajo.", "Vinculo guiado N2: mira 2 Karmany N2, elige 1 y puedes intentar vincularlo inmediatamente; si ya hay uno visible, puedes intentar vincular ese. Tambien puedes recolectar 2 EK.", "Vinculo guiado maximo 1 vez por turno."),
		_row("n2_03_ruinas_del_eco.tres", "N2-03", "Ruinas del Eco", KarmanyTileData.TileLevel.N2, "Elige: revela 1 Bestia Media y combatela; si la derrotas, roba 2 Resonancias y conserva 1; o recolecta 2 EK.", "Entrada: Roba 1 Resonancia y descarta 1.", "Enfrentar 1 Bestia Media o robar 2 Resonancias y conservar 1; descarta la otra.", "Si la Bestia no es derrotada, permanece bloqueando la loseta."),
		_row("n2_04_atalaya_exterior.tres", "N2-04", "Atalaya Exterior", KarmanyTileData.TileLevel.N2, "Elige: roba 1 Resonancia y mira una loseta N3 adyacente; o si hay jugador adyacente, puedes iniciar Duelo.", "Entrada: +1 Poder en tu proximo PvP este turno; si no hay rival legal, roba 1 y descarta 1 Resonancia.", "Mirar una loseta oculta adyacente o iniciar Duelo contra jugador en la misma loseta o adyacente.", "-"),
		_row("n2_06_santuario_quebrado.tres", "N2-06", "Santuario Quebrado", KarmanyTileData.TileLevel.N2, "Elige: mira 2 Karmany N2, deja 1 visible y devuelve el otro al fondo; o recolecta 2 EK.", "Entrada: Mira la primera carta de Karmany N2; dejala arriba o abajo.", "Vinculo guiado N2: mira 2 Karmany N2, elige 1 y puedes intentar vincularlo inmediatamente; si ya hay uno visible, puedes intentar vincular ese. Tambien puedes recolectar 2 EK.", "Vinculo guiado maximo 1 vez por turno."),
		_row("n2_07_garganta_del_aullido.tres", "N2-07", "Garganta del Aullido", KarmanyTileData.TileLevel.N2, "Elige: revela 1 Bestia Media y combatela; o roba 2 Resonancias y descarta 1.", "Entrada: +1 Poder contra tu proxima Bestia Media o superior este turno.", "Enfrentar 1 Bestia Media o robar 2 Resonancias y descartar 1.", "Si la Bestia no es derrotada, permanece bloqueando la loseta."),
		_row("n2_08_refugio_de_karmany.tres", "N2-08", "Refugio de Karmany", KarmanyTileData.TileLevel.N2, "Elige: mira 2 Karmany N2, deja 1 visible y devuelve el otro al fondo; o recolecta 2 EK.", "Entrada: Mira la primera carta de Karmany N2; dejala arriba o abajo.", "Vinculo guiado N2: mira 2 Karmany N2, elige 1 y puedes intentar vincularlo inmediatamente; si ya hay uno visible, puedes intentar vincular ese. Tambien puedes recolectar 2 EK.", "Vinculo guiado maximo 1 vez por turno; no reduce FA."),
		_row("n2_09_mercado_de_ruinas.tres", "N2-09", "Mercado de Ruinas", KarmanyTileData.TileLevel.N2, "Elige: mira 2 cartas de Equipo, deja 1 visible; o craftea 1 Equipo basico.", "Entrada: Mira 1 carta de Equipo del mazo; dejala arriba o abajo.", "Craftear 1 Equipo basico o renovar 1 carta del mercado de Equipo.", "Solo 1 crafteo por turno."),
		_row("n2_10_puente_de_atalaya.tres", "N2-10", "Puente de Atalaya", KarmanyTileData.TileLevel.N2, "Elige: muevete 1 loseta revelada; o mira una loseta Nivel 3 adyacente.", "Entrada: Mira 1 loseta N3 oculta adyacente.", "Moverte 1 loseta revelada o mirar una loseta oculta adyacente.", "-"),
		_row("n2_11_nido_salvaje.tres", "N2-11", "Nido Salvaje", KarmanyTileData.TileLevel.N2, "Elige: revela 1 Bestia Media y combatela; o roba 2 Resonancias y descarta 1.", "Entrada: +1 Poder contra tu proxima Bestia Media o superior este turno.", "Enfrentar 1 Bestia Media o robar 2 Resonancias y descartar 1.", "Si la Bestia no es derrotada, permanece bloqueando la loseta."),
		_row("n2_12_obelisco_menor.tres", "N2-12", "Obelisco Menor", KarmanyTileData.TileLevel.N2, "Elige: recolecta 2 EK; o mejora tu Libro pagando su costo normal.", "Entrada: Obten 1 EK.", "Recolectar 2 EK o mejorar Libro.", "-"),
		_row("n3_01_arena_de_ruinas.tres", "N3-01", "Arena de Ruinas", KarmanyTileData.TileLevel.N3, "Elige: inicia Duelo contra un jugador en la misma loseta o adyacente; o roba 3 Resonancias, conserva 2 y descarta 1.", "Entrada: Roba 1 Resonancia y descarta 1.", "Iniciar Duelo contra jugador en la misma loseta o adyacente; o robar 2 Resonancias, conservar 1 y descartar 1.", "Si pierdes un Duelo iniciado desde esta loseta, el ganador puede elegir recompensa PvP normal y ademas hacerte retroceder 1 loseta."),
		_row("n3_04_puerta_del_santuario.tres", "N3-04", "Puerta del Santuario", KarmanyTileData.TileLevel.N3, "Roba 3 Resonancias, conserva 2 y descarta 1.", "Entrada: Roba 1 Resonancia y descarta 1.", "Roba 2 Resonancias, conserva 1 y descarta 1.", "-"),
		_row("n3_05_santuario_del_eco_ancestral.tres", "N3-05", "Santuario del Eco Ancestral", KarmanyTileData.TileLevel.N3, "Mira 2 Karmany N3, elige 1 y dejalo visible aqui; el otro va al fondo.", "Entrada: Mira la primera carta de Karmany N3; dejala arriba o abajo.", "Vinculo guiado N3: mira 2 Karmany N3, elige 1 y puedes intentar vincularlo inmediatamente; si ya hay uno visible, puedes intentar vincular ese.", "Vinculo guiado maximo 1 vez por turno."),
		_row("n3_06_fisura_ancestral.tres", "N3-06", "Fisura Ancestral", KarmanyTileData.TileLevel.N3, "Elige: revela 1 Bestia Compleja y combatela; o recolecta 1 FA descartando 2 cartas de tu mano.", "Entrada: +1 Poder contra tu proxima Bestia Compleja, Jefe o Legendaria este turno.", "Enfrentar 1 Bestia Compleja o recolectar 1 FA descartando 2 cartas.", "Maximo 1 FA por jugador por ronda desde esta loseta.")
	]

	for row in expected:
		var path: String = "res://data/tiles/canonical_pending/%s" % String(row["file"])
		if not ResourceLoader.exists(path):
			return _fail("Falta Resource canonico: %s." % path)
		var tile := ResourceLoader.load(path) as KarmanyTileData
		if tile == null:
			return _fail("No se pudo cargar %s como KarmanyTileData." % path)
		if tile.tile_id != String(row["id"]) or tile.display_name != String(row["name"]):
			return _fail("Identidad no canonica en %s." % path)
		if tile.level != int(row["level"]):
			return _fail("Nivel incorrecto en %s." % tile.tile_id)
		if tile.on_explore_text != String(row["on_explore"]):
			return _fail("Al explorar difiere del maestro en %s." % tile.tile_id)
		if tile.entry_bonus_text != String(row["entry"]):
			return _fail("Bonificacion de entrada difiere del maestro en %s." % tile.tile_id)
		if tile.later_use_text != String(row["later"]):
			return _fail("Uso posterior difiere del maestro en %s." % tile.tile_id)
		if tile.limit_text != String(row["limit"]):
			return _fail("Limite difiere del maestro en %s." % tile.tile_id)
	return true


func _test_all_41_materialized_once() -> bool:
	var seen: Dictionary = {}
	var level_counts: Dictionary = {}
	for path in _all_tile_paths():
		var tile := ResourceLoader.load(path) as KarmanyTileData
		if tile == null:
			return _fail("No se pudo cargar loseta materializada: %s." % path)
		if seen.has(tile.tile_id):
			return _fail("tile_id materializado duplicado: %s." % tile.tile_id)
		seen[tile.tile_id] = true
		level_counts[tile.level] = int(level_counts.get(tile.level, 0)) + 1

	if seen.size() != EXPECTED_TOTAL_COUNT:
		return _fail("La cobertura fisica no es 41/41; obtenida=%d." % seen.size())
	if KarmanyV074CanonicalRuntimeCatalog.TILE_IDS.size() != EXPECTED_TOTAL_COUNT:
		return _fail("El catalogo canonico no declara 41 IDs.")
	for canonical_id in KarmanyV074CanonicalRuntimeCatalog.TILE_IDS:
		if not seen.has(String(canonical_id)):
			return _fail("Falta identidad canonica materializada: %s." % String(canonical_id))
	if int(level_counts.get(KarmanyTileData.TileLevel.START, 0)) != 4:
		return _fail("Conteo START distinto de 4.")
	if int(level_counts.get(KarmanyTileData.TileLevel.N1, 0)) != 18:
		return _fail("Conteo N1 distinto de 18.")
	if int(level_counts.get(KarmanyTileData.TileLevel.N2, 0)) != 12:
		return _fail("Conteo N2 distinto de 12.")
	if int(level_counts.get(KarmanyTileData.TileLevel.N3, 0)) != 6:
		return _fail("Conteo N3 distinto de 6.")
	if int(level_counts.get(KarmanyTileData.TileLevel.SANCTUARY, 0)) != 1:
		return _fail("Conteo Legendaria distinto de 1.")
	return true


func _test_pending_tiles_are_not_runtime_executable() -> bool:
	var pending_paths: Array[String] = _tile_paths_in("res://data/tiles/canonical_pending")
	if pending_paths.size() != EXPECTED_PENDING_COUNT:
		return _fail("canonical_pending debe contener 28 Resources .tres; obtenidos=%d." % pending_paths.size())
	var service := KarmanyUniversalTileInteractionService.new()
	for path in pending_paths:
		var tile := ResourceLoader.load(path) as KarmanyTileData
		if tile == null:
			return _fail("Pendiente no cargable: %s." % path)
		if tile.interaction_profile_id != PENDING_PROFILE:
			return _fail("%s no usa pending_f44." % tile.tile_id)
		if not tile.on_explore_effects.is_empty() or not tile.entry_effects.is_empty() or not tile.later_use_effects.is_empty():
			return _fail("%s contiene automatizacion estructurada no aprobada en F43.1." % tile.tile_id)
		if service.is_tile_definition_valid(tile):
			return _fail("%s fue anunciada falsamente como ejecutable por F39." % tile.tile_id)
	return true


func _test_runtime_pools_remain_safe() -> bool:
	var pools := KarmanyMap41TilePools.new()
	if not pools.load_from_project():
		return _fail("No se pudieron cargar los pools runtime.")
	if pools.get_pool_size(KarmanyTileData.TileLevel.N1) != 4:
		return _fail("Pool runtime N1 cambio; se esperaban 4 Resources seguros.")
	if pools.get_pool_size(KarmanyTileData.TileLevel.N2) != 2:
		return _fail("Pool runtime N2 cambio; se esperaban 2 Resources seguros.")
	if pools.get_pool_size(KarmanyTileData.TileLevel.N3) != 2:
		return _fail("Pool runtime N3 cambio; se esperaban 2 Resources seguros.")
	return true


func _all_tile_paths() -> Array[String]:
	var result: Array[String] = []
	result.append_array(_tile_paths_in("res://data/tiles"))
	result.append_array(_tile_paths_in("res://data/tiles/canonical_pending"))
	return result


func _tile_paths_in(directory: String) -> Array[String]:
	var result: Array[String] = []
	for file_name in DirAccess.get_files_at(directory):
		if String(file_name).get_extension().to_lower() == "tres":
			result.append("%s/%s" % [directory, String(file_name)])
	result.sort()
	return result


func _row(file_name: String, id: String, display_name: String, level: int, on_explore: String, entry: String, later: String, limit: String) -> Dictionary:
	return {
		"file": file_name,
		"id": id,
		"name": display_name,
		"level": level,
		"on_explore": on_explore,
		"entry": entry,
		"later": later,
		"limit": limit
	}


func _fail(message: String) -> bool:
	push_error("FASE 43.1 ERROR: %s" % message)
	return false
