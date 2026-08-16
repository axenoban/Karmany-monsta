extends Node

const DIRECT_DIR := "res://data/karmanys"
const PENDING_DIR := "res://data/karmanys/canonical_pending"

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.2 KARMANY COMPLETOS")
	print("================================")
	var ok := _test_complete_catalog()
	ok = _test_pending_isolation() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 43.2 OK - 28/28 Karmany canonicos materializados; pendientes aislados del runtime hasta F44.")
	else:
		push_error("FASE 43.2 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")

func _test_complete_catalog() -> bool:
	var expected := _expected_rows()
	var resources := _load_all_karmanys()
	if resources.size() != 28:
		return _fail("Se esperaban exactamente 28 Resources Karmany y se cargaron %d." % resources.size())
	var by_id: Dictionary = {}
	for data in resources:
		if data == null or not data.is_valid_definition():
			return _fail("Existe un Karmany nulo o con definicion invalida.")
		if by_id.has(String(data.karmany_id)):
			return _fail("ID Karmany duplicado: %s." % String(data.karmany_id))
		by_id[String(data.karmany_id)] = data
	for row in expected:
		var id: String = String(row["id"])
		if not by_id.has(id):
			return _fail("Falta identidad canonica %s." % id)
		var data := by_id[id] as KarmanyData
		if data.display_name != String(row["name"]):
			return _fail("Nombre no canonico en %s: %s." % [id, data.display_name])
		if data.subtitle != String(row["subtitle"]):
			return _fail("Subtitulo no canonico en %s: %s." % [id, data.subtitle])
		if data.rank != int(row["rank"]) or data.power != int(row["power"]):
			return _fail("Nivel/Poder no canonico en %s." % id)
		if data.encounter_defense != int(row["defense"]):
			return _fail("Defensa de vinculo no canonica en %s." % id)
		if data.legacy_points != int(row["pl"]):
			return _fail("PL directo no canonico en %s." % id)
		if data.is_starting_karmany != bool(row["starting"]):
			return _fail("Estado inicial incorrecto en %s." % id)
		if data.abilities.size() != 1 or data.abilities[0] == null:
			return _fail("%s no conserva exactamente una Habilidad v0.74." % id)
		if _norm(data.abilities[0].rules_text) != _norm(String(row["ability"])):
			return _fail("Habilidad v0.74 difiere del maestro en %s." % id)
	var expected_initial := ["K-01", "K-02", "K-03", "K-04", "K-25", "K-26", "K-27", "K-28"]
	var actual_initial: Array[String] = []
	for data in resources:
		if data.is_starting_karmany:
			actual_initial.append(String(data.karmany_id))
	actual_initial.sort()
	expected_initial.sort()
	if actual_initial != expected_initial:
		return _fail("El conjunto de 8 Karmany iniciales no coincide con v0.74.")
	return true

func _test_pending_isolation() -> bool:
	var direct := KarmanyPhase37AlphaContentCatalog.load_category(&"karmanys")
	if direct.size() != 13:
		return _fail("El catalogo runtime directo cambio: se esperaban 13 Resources y hay %d." % direct.size())
	if KarmanyPhase37AlphaContentCatalog.get_starting_karmanys().size() != 8:
		return _fail("El setup dejo de exponer exactamente los 8 Karmany iniciales.")
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 15:
		return _fail("Se esperaban exactamente 15 Karmany pendientes F44.")
	for data in pending:
		if data.abilities.size() != 1:
			return _fail("%s no conserva una habilidad pendiente unica." % data.karmany_id)
		var ability := data.abilities[0]
		if ability.trigger_id != &"pending_f44":
			return _fail("%s no esta marcado como automatizacion pendiente F44." % data.karmany_id)
		if not ability.effects.is_empty():
			return _fail("%s contiene efectos ejecutables inventados antes de F44." % data.karmany_id)
	return true

func _load_all_karmanys() -> Array[KarmanyData]:
	var result := _load_dir(DIRECT_DIR)
	result.append_array(_load_dir(PENDING_DIR))
	return result

func _load_dir(path: String) -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var value := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyData
		if value != null:
			result.append(value)
	return result

func _norm(text: String) -> String:
	return text.strip_edges().trim_suffix(".").replace("  ", " ")

func _expected_rows() -> Array[Dictionary]:
	return [
		{"id":"K-01","name":"Terrakor","subtitle":"Coloso de Raices","rank":0,"power":6,"defense":-1,"pl":0,"starting":true,"ability":"Una vez por ronda, cuando combate contra una Bestia, gana +2 Poder. Este bono no puede aplicarse mas de una vez por ronda, aunque combata varias Bestias."},
		{"id":"K-02","name":"Aquaris","subtitle":"Guardian de Bruma","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"Si pierdes contra una Bestia, evita el retroceso o reduce en 2 recursos basicos la perdida de derrota."},
		{"id":"K-03","name":"Pyrox","subtitle":"Salamandra Ignea","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"Puedes lanzar el Dado de Riesgo 2.0 al combatir. Solo las caras 5-6 agregan Poder, pero el impacto es alto."},
		{"id":"K-04","name":"Lumirra","subtitle":"Cria de Luz","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"Una vez por combate, puedes descartar 1 Resonancia para robar 2 Resonancias y elegir 1 para ese combate; descarta la otra."},
		{"id":"K-05","name":"Floravia","subtitle":"Custodia Verde","rank":1,"power":5,"defense":8,"pl":0,"starting":false,"ability":"Una vez por ronda, cuando recolectes MN, obten +2 MN adicionales."},
		{"id":"K-06","name":"Brisu","subtitle":"Pequeno Veloz","rank":1,"power":5,"defense":8,"pl":0,"starting":false,"ability":"Despues de explorar una loseta Nivel 1, mira 1 loseta oculta adyacente."},
		{"id":"K-07","name":"Rocerno","subtitle":"Cria de Piedra","rank":1,"power":5,"defense":9,"pl":0,"starting":false,"ability":"La primera vez por ronda que una derrota te haga perder recursos basicos, pierde 2 recursos menos."},
		{"id":"K-08","name":"Mistolin","subtitle":"Eco de Niebla","rank":1,"power":5,"defense":8,"pl":0,"starting":false,"ability":"Una vez por ronda, cuando robes Resonancias, roba 1 adicional y descarta 1."},
		{"id":"K-09","name":"Verdan","subtitle":"Brote de Vael","rank":1,"power":6,"defense":9,"pl":0,"starting":false,"ability":"No tiene efecto adicional. Su valor esta en su Poder estable superior para Nivel 1."},
		{"id":"K-10","name":"Brumak","subtitle":"Rastreador de Niebla","rank":2,"power":8,"defense":12,"pl":0,"starting":false,"ability":"Contra Bestias en losetas Nivel 2, gana +2 Poder."},
		{"id":"K-11","name":"Rauk Colmillo","subtitle":"Depredador Salvaje","rank":2,"power":8,"defense":14,"pl":0,"starting":false,"ability":"Puede lanzar el Dado de Riesgo 2.0. Si obtiene 6 y gana, gana +1 PL adicional. Maximo una vez por partida."},
		{"id":"K-12","name":"Nimbara","subtitle":"Guardiana de Lluvia","rank":2,"power":7,"defense":12,"pl":0,"starting":false,"ability":"Cuando pierdas contra una Bestia media o compleja, pierde 2 recursos basicos menos."},
		{"id":"K-13","name":"Ferrak","subtitle":"Mandibula Runica","rank":2,"power":9,"defense":14,"pl":0,"starting":false,"ability":"Cuando combate contra Bestias medias, gana +2 Poder."},
		{"id":"K-14","name":"Selenix","subtitle":"Zorro de Resonancia","rank":2,"power":7,"defense":12,"pl":0,"starting":false,"ability":"Una vez por ronda, despues de ganar un combate, roba 1 Resonancia."},
		{"id":"K-15","name":"Lignar","subtitle":"Guardabosque Viejo","rank":2,"power":7,"defense":12,"pl":0,"starting":false,"ability":"Cuando recolectes mediante Interactuar con loseta, puedes convertir 1 recurso basico obtenido en otro recurso basico."},
		{"id":"K-16","name":"Volcrin","subtitle":"Ala de Ceniza","rank":2,"power":8,"defense":14,"pl":0,"starting":false,"ability":"Puedes lanzar el Dado de Riesgo 2.0. Si sale 1, ademas de la penalizacion del dado, descarta 1 Resonancia."},
		{"id":"K-17","name":"Orial","subtitle":"Ciervo Luminico","rank":2,"power":8,"defense":12,"pl":0,"starting":false,"ability":"Cuando defiendes en PvP, gana +2 Poder."},
		{"id":"K-18","name":"Torkal","subtitle":"Tortuga de Ruinas","rank":2,"power":7,"defense":14,"pl":0,"starting":false,"ability":"Si pierdes contra Bestia, puedes descartar 1 Resonancia en lugar de perder recursos basicos."},
		{"id":"K-19","name":"Velkar","subtitle":"Acechador de Ruinas","rank":3,"power":11,"defense":16,"pl":0,"starting":false,"ability":"En PvP, el rival debe jugar o declarar su Resonancia antes que tu. Tu decides despues de verla."},
		{"id":"K-20","name":"Dravok","subtitle":"Colmillo de Obsidiana","rank":3,"power":12,"defense":18,"pl":0,"starting":false,"ability":"Puede lanzar el Dado de Riesgo 2.0. Si gana con resultado 6, obten 2 recursos basicos."},
		{"id":"K-21","name":"Celestia","subtitle":"Guardiana del Santuario","rank":3,"power":11,"defense":16,"pl":0,"starting":false,"ability":"La primera vez en cada ronda que pierdas un combate, no pierdes recursos basicos por esa derrota."},
		{"id":"K-22","name":"Runakar","subtitle":"Titan de Cristal","rank":3,"power":13,"defense":20,"pl":0,"starting":false,"ability":"Gana +2 Poder contra Bestias complejas, Jefes o Legendarias."},
		{"id":"K-23","name":"Eryndra","subtitle":"Ave de Resonancia","rank":3,"power":11,"defense":16,"pl":0,"starting":false,"ability":"Una Resonancia +0 que uses en combate puede valer +4 Poder. Maximo una vez por combate."},
		{"id":"K-24","name":"Aeterna Draconis","subtitle":"Guardian de Memoria","rank":4,"power":18,"defense":26,"pl":8,"starting":false,"ability":"Una vez por partida, puedes repetir una carta de Resonancia usada en combate. No entra al mercado normal. Cuenta como Karmany Legendario."},
		{"id":"K-25","name":"Zephyr","subtitle":"Cria de Viento Bruma","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"Despues de explorar una loseta oculta, gana +2 Poder en tu proximo combate esta ronda. Si no combates este turno, roba 1 Resonancia al final del turno."},
		{"id":"K-26","name":"Umbrio","subtitle":"Sombra del Primer Eco","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"Una vez por ronda, cuando una Bestia o rival te obligue a descartar una carta, puedes gastar 1 recurso basico para evitar ese descarte."},
		{"id":"K-27","name":"Gemmir","subtitle":"Topo de Cristal Tierno","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"La primera vez por ronda que recolectes MN o MR, puedes convertir 1 recurso basico obtenido en otro recurso basico."},
		{"id":"K-28","name":"Vulkai","subtitle":"Chispa Salvaje Menor","rank":0,"power":5,"defense":-1,"pl":0,"starting":true,"ability":"Puede lanzar el Dado de Riesgo solo contra Bestias. Si gana con resultado 5 o 6, obten +1 recurso basico."}
	]

func _fail(message: String) -> bool:
	push_error("FASE 43.2 ERROR: %s" % message)
	return false
