extends Node

const DIRECT_DIR := "res://data/beasts"
const PENDING_DIR := "res://data/beasts/canonical_pending"

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.3 BESTIAS COMPLETAS")
	print("================================")
	var ok := _test_complete_catalog()
	ok = _test_pending_isolation() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 43.3 OK - 24/24 Bestias canonicas materializadas; pendientes aisladas del runtime hasta F44.")
	else:
		push_error("FASE 43.3 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")

func _test_complete_catalog() -> bool:
	var expected := _expected_rows()
	var resources := _load_all_beasts()
	if resources.size() != 24:
		return _fail("Se esperaban exactamente 24 Resources Bestia y se cargaron %d." % resources.size())
	var by_id: Dictionary = {}
	for data in resources:
		if data == null or not data.is_valid_definition():
			return _fail("Existe una Bestia nula o con definicion invalida.")
		if by_id.has(String(data.beast_id)):
			return _fail("ID Bestia duplicado: %s." % String(data.beast_id))
		by_id[String(data.beast_id)] = data
	for row in expected:
		var id: String = String(row["id"])
		if not by_id.has(id):
			return _fail("Falta identidad canonica %s." % id)
		var data := by_id[id] as KarmanyBeastData
		if data.display_name != String(row["name"]):
			return _fail("Nombre no canonico en %s: %s." % [id, data.display_name])
		if data.classification != String(row["classification"]):
			return _fail("Clasificacion no canonica en %s." % id)
		if data.tier != int(row["tier"]) or data.base_defense != int(row["defense"]):
			return _fail("Nivel/Defensa no canonicos en %s." % id)
		if data.reward_legacy_points != int(row["pl"]):
			return _fail("PL de recompensa no canonicos en %s." % id)
		if _norm(data.reward_text) != _norm(String(row["reward"])):
			return _fail("Recompensa v0.74 difiere del maestro en %s." % id)
		if _norm(data.defeat_text) != _norm(String(row["defeat"])):
			return _fail("Derrota v0.74 difiere del maestro en %s." % id)
		if _norm(data.rules_text) != _norm(String(row["rules"])):
			return _fail("Efecto v0.74 difiere del maestro en %s." % id)
	return true

func _test_pending_isolation() -> bool:
	var direct := KarmanyPhase37AlphaContentCatalog.load_category(&"beasts")
	if direct.size() != 7:
		return _fail("El catalogo directo cambio: se esperaban 7 Resources y hay %d." % direct.size())
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 17:
		return _fail("Se esperaban exactamente 17 Bestias pendientes F44.")
	for data in pending:
		if not data.special_rule_ids.has(&"pending_f44"):
			return _fail("%s no esta marcada como automatizacion pendiente F44." % data.beast_id)
		if not data.reward_effects.is_empty() or not data.defeat_effects.is_empty():
			return _fail("%s contiene efectos ejecutables inventados antes de F44." % data.beast_id)
	var runtime := KarmanyPhase37AlphaContentCatalog.get_runtime_beasts()
	var actual_ids: Array[String] = []
	for data in runtime:
		actual_ids.append(String(data.beast_id))
	actual_ids.sort()
	var expected_ids: Array[String] = ["B-01", "B-02", "B-04", "B-15", "B-22"]
	expected_ids.sort()
	if actual_ids != expected_ids:
		return _fail("El pool runtime seguro de Bestias cambio durante F43.3.")
	return true

func _load_all_beasts() -> Array[KarmanyBeastData]:
	var result := _load_dir(DIRECT_DIR)
	result.append_array(_load_dir(PENDING_DIR))
	return result

func _load_dir(path: String) -> Array[KarmanyBeastData]:
	var result: Array[KarmanyBeastData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var value := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyBeastData
		if value != null:
			result.append(value)
	return result

func _norm(text: String) -> String:
	return text.strip_edges().trim_suffix(".").replace("  ", " ")

func _expected_rows() -> Array[Dictionary]:
	return [
		{"id":"B-01","name":"Garravol","classification":"Depredador de Valle","tier":0,"defense":8,"pl":1,"reward":"1 PL + 2 MN","defeat":"Descarta 2 recursos basicos de tu eleccion.","rules":"Ninguno."},
		{"id":"B-02","name":"Picorroca","classification":"Ave de Penasco","tier":0,"defense":8,"pl":1,"reward":"1 PL + 2 MR","defeat":"Retrocede 1 loseta.","rules":"Si usaste Dado de Riesgo 2.0, gana +2 Poder."},
		{"id":"B-03","name":"Raicillo Feral","classification":"Brote Salvaje","tier":0,"defense":9,"pl":1,"reward":"1 PL + 2 MN","defeat":"Pierdes 2 MN si tienes; si no, 2 recursos basicos de tu eleccion.","rules":"Si tu Karmany es Recolector, gana +2 Poder en este combate."},
		{"id":"B-04","name":"Murcielago Bruma","classification":"Criatura de Niebla","tier":0,"defense":8,"pl":1,"reward":"1 PL + roba 3 Resonancias y descarta 1","defeat":"Descarta 1 Resonancia.","rules":"Ninguno."},
		{"id":"B-05","name":"Cuernillo Verde","classification":"Herbivoro Agresivo","tier":0,"defense":9,"pl":1,"reward":"1 PL + 2 MN o 2 EK","defeat":"Descarta 2 recursos basicos de tu eleccion.","rules":"No puede ser evitada con cartas de movimiento."},
		{"id":"B-06","name":"Limo de Runa","classification":"Masa Karmica Menor","tier":0,"defense":9,"pl":1,"reward":"1 PL + 2 EK","defeat":"Retrocede 1 loseta.","rules":"Las Resonancias +0 no suman efectos contra esta Bestia."},
		{"id":"B-07","name":"Terranuk","classification":"Bestia de Roca","tier":1,"defense":12,"pl":2,"reward":"2 PL + 2 MR","defeat":"Descarta 2 recursos basicos de tu eleccion y retrocedes 1 loseta.","rules":"Si lo derrotas con Karmany Estable, obtienes +2 MN."},
		{"id":"B-08","name":"Brumacerno","classification":"Bestia de Niebla","tier":1,"defense":14,"pl":2,"reward":"2 PL + 2 EK","defeat":"Retrocede 1 loseta y descarta 1 Resonancia.","rules":"Las Resonancias +0 no pueden usarse contra esta Bestia."},
		{"id":"B-09","name":"Garraespina","classification":"Depredador de Bosque","tier":1,"defense":12,"pl":2,"reward":"2 PL + 2 MN + roba 3 Resonancias y descarta 1","defeat":"Descarta 2 recursos basicos de tu eleccion.","rules":"Si pierdes, no puedes recolectar en tu siguiente accion."},
		{"id":"B-10","name":"Vigia de Atalaya","classification":"Guardian Salvaje","tier":1,"defense":14,"pl":2,"reward":"2 PL + mira una loseta oculta adyacente","defeat":"Retrocede 1 loseta.","rules":"-"},
		{"id":"B-11","name":"Escarabajo Runico","classification":"Insecto Mineral","tier":1,"defense":12,"pl":2,"reward":"2 PL + 2 MR","defeat":"Pierdes 2 MR si tienes; si no, 2 recursos basicos de tu eleccion.","rules":"Si ganas con Catalizador equipado, gana +1 PL."},
		{"id":"B-12","name":"Aullador de Bruma","classification":"Cazador Sonoro","tier":1,"defense":14,"pl":2,"reward":"2 PL + 2 EK","defeat":"Descarta 1 carta de tu mano.","rules":"Antes del combate, debes jugar tu Resonancia boca abajo."},
		{"id":"B-13","name":"Raptor de Ruinas","classification":"Depredador Antiguo","tier":1,"defense":14,"pl":2,"reward":"2 PL + puedes renovar 1 carta de Equipo del mercado","defeat":"Pierdes 2 recursos basicos y retrocedes.","rules":"Si usas Herramienta equipada, gana +2 Poder contra esta Bestia."},
		{"id":"B-14","name":"Feraluz","classification":"Criatura de Resonancia","tier":1,"defense":12,"pl":2,"reward":"2 PL + roba 3 Resonancias y descarta 1","defeat":"Descarta 1 Resonancia si tienes.","rules":"Si no jugaste Resonancia en este combate, esta Bestia gana +1 Defensa."},
		{"id":"B-15","name":"Vermis de Cristal","classification":"Criatura Subterranea","tier":2,"defense":18,"pl":3,"reward":"3 PL + 1 FA","defeat":"Descarta 2 recursos basicos de tu eleccion y 1 carta de la mano.","rules":"Permanece si no es derrotada."},
		{"id":"B-16","name":"Colmillo de Ceniza","classification":"Bestia Ignea","tier":2,"defense":16,"pl":3,"reward":"3 PL + 2 MR + 2 EK","defeat":"Descarta 3 recursos basicos de tu eleccion.","rules":"Si usas Dado de Riesgo 2.0 y sacas 1, descarta tambien 1 Resonancia."},
		{"id":"B-17","name":"Guardian del Umbral","classification":"Protector de Santuario","tier":2,"defense":20,"pl":3,"reward":"3 PL + 1 FA","defeat":"Retrocede 1 loseta y descarta 1 Resonancia.","rules":"Solo puede enfrentarse si tienes Libro II o superior."},
		{"id":"B-18","name":"Cervix de Obsidiana","classification":"Bestia de Cristal Negro","tier":2,"defense":18,"pl":3,"reward":"3 PL + roba 2 Equipo y conserva 1 del mazo; puedes dejarlo en mercado","defeat":"Pierdes 2 MR y retrocedes.","rules":"Los efectos de Proteccion no evitan el retroceso contra esta Bestia."},
		{"id":"B-19","name":"Brumagor","classification":"Titan de Niebla","tier":2,"defense":16,"pl":3,"reward":"3 PL + 2 EK + roba 3 Resonancias y descarta 1","defeat":"Descarta 2 Resonancias.","rules":"Si ganas usando carta +3 o mayor, gana +1 PL."},
		{"id":"B-20","name":"Raiz Devora","classification":"Planta Karmica Salvaje","tier":2,"defense":18,"pl":3,"reward":"3 PL + 2 MN + 1 FA","defeat":"Pierdes 1 recurso y no puedes moverte en tu siguiente accion.","rules":"Si tu Karmany es Recolector, esta Bestia gana +1 Defensa."},
		{"id":"B-21","name":"Centinela Runico","classification":"Armadura Viva","tier":2,"defense":20,"pl":3,"reward":"3 PL + 2 MR + roba 1 Resonancia","defeat":"Descarta 1 Equipo equipado de tu eleccion si tienes; si no, descarta 1 recurso basico de tu eleccion.","rules":"Permanece si no es derrotada."},
		{"id":"B-22","name":"Custodio del Santuario","classification":"Guardian Ancestral","tier":3,"defense":22,"pl":5,"reward":"5 PL + 1 FA","defeat":"Descarta 3 recursos basicos de tu eleccion y retrocedes 1 loseta.","rules":"Solo puede enfrentarse con Libro II o superior."},
		{"id":"B-23","name":"Drakmaw","classification":"Falso Dragon de Ruinas","tier":3,"defense":24,"pl":6,"reward":"6 PL + 2 FA + roba 2 Equipo y conserva 1 ancestral si esta disponible","defeat":"Pierdes 2 recursos basicos, 1 Resonancia y retrocedes 1 loseta.","rules":"Durante este combate no puedes repetir ni modificar el Dado de Riesgo."},
		{"id":"B-24","name":"Eco de Aeterna","classification":"Sombra de Memoria","tier":3,"defense":23,"pl":5,"reward":"5 PL + roba 2 Resonancias y conserva 1","defeat":"Descarta 1 Resonancia y pierde 2 EK.","rules":"Si tienes Libro III, gana +2 Poder contra esta Bestia."}
	]

func _fail(message: String) -> bool:
	push_error("FASE 43.3 ERROR: %s" % message)
	return false
