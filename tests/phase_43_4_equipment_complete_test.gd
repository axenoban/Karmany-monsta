extends Node

const DIRECT_DIR := "res://data/equipment"
const PENDING_DIR := "res://data/equipment/canonical_pending"

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.4 EQUIPO COMPLETO")
	print("================================")
	var ok := _test_complete_catalog()
	ok = _test_pending_isolation() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 43.4 OK - 36/36 Equipos canonicos materializados; pendientes aislados del runtime hasta F44.")
	else:
		push_error("FASE 43.4 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")

func _test_complete_catalog() -> bool:
	var expected := _expected_rows()
	var resources := _load_all_equipment()
	if resources.size() != 36:
		return _fail("Se esperaban exactamente 36 Resources Equipo y se cargaron %d." % resources.size())
	var by_id: Dictionary = {}
	for data in resources:
		if data == null or not data.is_valid_definition():
			return _fail("Existe un Equipo nulo o con definicion invalida.")
		if by_id.has(String(data.equipment_id)):
			return _fail("ID Equipo duplicado: %s." % String(data.equipment_id))
		by_id[String(data.equipment_id)] = data
	for row in expected:
		var id: String = String(row["id"])
		if not by_id.has(id):
			return _fail("Falta identidad canonica %s." % id)
		var data := by_id[id] as KarmanyEquipmentData
		if data.display_name != String(row["name"]):
			return _fail("Nombre no canonico en %s: %s." % [id, data.display_name])
		if data.rarity != int(row["rarity"]):
			return _fail("Rareza no canonica en %s." % id)
		if data.get_cost() != row["cost"]:
			return _fail("Costo v0.74 difiere del maestro en %s." % id)
		if _norm(data.rules_text) != _norm(String(row["rules"])):
			return _fail("Efecto v0.74 difiere del maestro en %s." % id)
	return true

func _test_pending_isolation() -> bool:
	var direct := KarmanyPhase37AlphaContentCatalog.load_category(&"equipment")
	if direct.size() != 9:
		return _fail("El catalogo directo cambio: se esperaban 9 Resources y hay %d." % direct.size())
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 27:
		return _fail("Se esperaban exactamente 27 Equipos pendientes F44.")
	for data in pending:
		if not data.trigger_tags.has("pending_f44"):
			return _fail("%s no esta marcado como automatizacion pendiente F44." % data.equipment_id)
		if not data.modifiers.is_empty():
			return _fail("%s contiene modificadores ejecutables inventados antes de F44." % data.equipment_id)
	var runtime := KarmanyPhase37AlphaContentCatalog.get_runtime_equipment()
	var actual_ids: Array[String] = []
	for data in runtime:
		actual_ids.append(String(data.equipment_id))
	actual_ids.sort()
	var expected_ids: Array[String] = ["EQ-01", "EQ-02", "EQ-03", "EQ-05", "EQ-08", "EQ-09"]
	expected_ids.sort()
	if actual_ids != expected_ids:
		return _fail("El pool runtime seguro de Equipo cambio durante F43.4.")
	return true

func _load_all_equipment() -> Array[KarmanyEquipmentData]:
	var result := _load_dir(DIRECT_DIR)
	result.append_array(_load_dir(PENDING_DIR))
	return result

func _load_dir(path: String) -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var value := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyEquipmentData
		if value != null:
			result.append(value)
	return result

func _norm(text: String) -> String:
	return text.strip_edges().trim_suffix(".").replace("  ", " ")

func _expected_rows() -> Array[Dictionary]:
	return [
		{"id":"EQ-01","name":"Cristal de Crecimiento","rarity":0,"cost":{0: 2, 2: 1},"rules":"Tu Karmany gana +2 Poder contra Bestias."},
		{"id":"EQ-02","name":"Guante Runico","rarity":0,"cost":{1: 2, 2: 1},"rules":"La primera Resonancia +0 que juegues en cada ronda gana +2 Poder."},
		{"id":"EQ-03","name":"Baculo de Bruma","rarity":0,"cost":{0: 2, 1: 1},"rules":"Despues de Explorar, gana +2 Poder en tu proximo combate de ese turno."},
		{"id":"EQ-04","name":"Daga de Resonancia","rarity":0,"cost":{1: 2},"rules":"Despues de un PvP, roba 1 Resonancia."},
		{"id":"EQ-05","name":"Nucleo Luminico","rarity":1,"cost":{2: 2, 1: 2},"rules":"Una vez por ronda, antes de combatir, roba 2 Resonancias y conserva 1; descarta la otra."},
		{"id":"EQ-06","name":"Sello de Impacto","rarity":1,"cost":{1: 2, 2: 2},"rules":"La primera vez por ronda que derrotes una Bestia media o compleja, gana +1 PL."},
		{"id":"EQ-07","name":"Anillo del Eco","rarity":1,"cost":{1: 2, 2: 2},"rules":"Una vez por ronda, repite un Dado de Riesgo. Debes conservar el nuevo resultado."},
		{"id":"EQ-08","name":"Prisma Ancestral","rarity":2,"cost":{3: 1, 2: 2},"rules":"La Resonancia que juegues en combate gana +2 Poder."},
		{"id":"EQ-09","name":"Catalizador de Aeterna","rarity":2,"cost":{3: 1, 1: 2, 2: 1},"rules":"Contra Jefes o Legendarios, gana +4 Poder."},
		{"id":"EQ-10","name":"Armadura de Terracota","rarity":0,"cost":{1: 2, 0: 1},"rules":"La primera vez por ronda que pierdas contra una Bestia, pierde 2 recursos basicos menos."},
		{"id":"EQ-11","name":"Capa de Bruma","rarity":0,"cost":{0: 2, 2: 1},"rules":"La primera vez por ronda que pierdas contra una Bestia, no retrocedes."},
		{"id":"EQ-12","name":"Escudo de Raiz","rarity":0,"cost":{0: 3},"rules":"Cuando defiendes en PvP, gana +2 Poder."},
		{"id":"EQ-13","name":"Brazal de Piedra","rarity":0,"cost":{1: 2},"rules":"La primera vez por ronda que perderias MN o MR, evita hasta 2 de esos recursos."},
		{"id":"EQ-14","name":"Manto de Serenidad","rarity":1,"cost":{2: 2, 0: 1},"rules":"La primera vez por ronda que una Bestia te obligue a descartar una Resonancia, ignora ese descarte."},
		{"id":"EQ-15","name":"Coraza Runica","rarity":1,"cost":{1: 2, 2: 2},"rules":"Una vez por ronda, ignora el efecto negativo de una cara 1 o 2 del Dado de Riesgo."},
		{"id":"EQ-16","name":"Guardia del Libro","rarity":1,"cost":{1: 2, 2: 2},"rules":"Una vez por ronda, despues de perder un combate, roba 2 Resonancias y conserva 1; descarta la otra."},
		{"id":"EQ-17","name":"Placa Ancestral","rarity":2,"cost":{3: 1, 1: 2},"rules":"La primera vez por ronda que pierdas contra una Bestia compleja o jefe, no pierdes recursos."},
		{"id":"EQ-18","name":"Velo de Aeterna","rarity":2,"cost":{3: 1, 2: 2},"rules":"Contra Jefes o Legendarios, puedes jugar hasta 2 Resonancias en ese combate. Este efecto es una excepcion al limite normal de 1 Resonancia por jugador por combate."},
		{"id":"EQ-19","name":"Pico Runico","rarity":0,"cost":{0: 2, 1: 1},"rules":"Cuando recolectes MR, obten +2 MR adicionales. Maximo una vez por ronda."},
		{"id":"EQ-20","name":"Botas Ligeras","rarity":0,"cost":{0: 3},"rules":"Una vez por ronda, si llegas a una loseta Nivel 2 o superior, puedes moverte 1 loseta revelada adyacente adicional sin gastar accion."},
		{"id":"EQ-21","name":"Brujula de Vael","rarity":0,"cost":{0: 2, 2: 1},"rules":"Antes de Explorar, mira 1 loseta oculta adyacente."},
		{"id":"EQ-22","name":"Mochila Reforzada","rarity":0,"cost":{0: 2},"rules":"Tu limite de mano aumenta a 7."},
		{"id":"EQ-23","name":"Lampara de Ruinas","rarity":1,"cost":{1: 2, 0: 1},"rules":"La primera vez por ronda que explores una loseta Nivel 2, mira la primera carta del mazo de Bestias y puedes dejarla arriba o ponerla al fondo."},
		{"id":"EQ-24","name":"Cuerda de Atalaya","rarity":1,"cost":{0: 2, 2: 1},"rules":"Una vez por ronda, despues de resolver una loseta, puedes moverte 1 loseta revelada adyacente."},
		{"id":"EQ-25","name":"Kit de Artesano","rarity":1,"cost":{0: 2, 1: 1},"rules":"Tu primer Equipo basico que craftees cada ronda cuesta 1 recurso comun menos."},
		{"id":"EQ-26","name":"Taladro de Cristal","rarity":2,"cost":{1: 3, 2: 1},"rules":"Una vez por partida, la primera vez que obtengas FA mediante una loseta o al derrotar una Bestia despues de crear este Equipo, obten +1 FA adicional. No se activa con Mision ni Sintonia."},
		{"id":"EQ-27","name":"Mapa de las Derivas","rarity":2,"cost":{3: 1, 0: 2},"rules":"Antes de Explorar una loseta Nivel 3, mira hasta 2 losetas Nivel 3 ocultas adyacentes y elige cual explorar."},
		{"id":"EQ-28","name":"Colgante de Armonia","rarity":0,"cost":{2: 2, 1: 1},"rules":"Tu primer vinculo de cada ronda cuesta 1 recurso comun menos. No reduce FA."},
		{"id":"EQ-29","name":"Piedra de Calma","rarity":0,"cost":{2: 2},"rules":"Despues de perder un PvP, roba 1 Resonancia."},
		{"id":"EQ-30","name":"Amuleto de Raiz","rarity":0,"cost":{0: 2, 2: 1},"rules":"Al final de tu turno, si no combatiste, roba 1 Resonancia."},
		{"id":"EQ-31","name":"Medallon del Eco","rarity":0,"cost":{1: 2},"rules":"La primera vez por ronda que juegues una Resonancia +0, roba 1 Resonancia y descarta 1."},
		{"id":"EQ-32","name":"Reliquia de Vinculo","rarity":1,"cost":{2: 2, 0: 1},"rules":"Tu primer Karmany Nivel 2 vinculado cada ronda cuesta 1 recurso comun menos. No reduce FA."},
		{"id":"EQ-33","name":"Totem del Guardian","rarity":1,"cost":{2: 2, 1: 2},"rules":"Si tienes un Karmany Defensivo activo, gana +2 Poder contra Bestias."},
		{"id":"EQ-34","name":"Sello del Santuario","rarity":1,"cost":{3: 1, 2: 2},"rules":"Contra Legendarios, gana +4 Poder."},
		{"id":"EQ-35","name":"Fragmento del Libro","rarity":2,"cost":{3: 1, 2: 2},"rules":"Una vez por partida, despues de usar una Resonancia, devuelvela a tu mano en vez de descartarla."},
		{"id":"EQ-36","name":"Corona de Resonancia","rarity":2,"cost":{3: 1, 2: 2, 1: 1},"rules":"Al final de la partida, si tienes Libro III, gana +3 PL."}
	]

func _fail(message: String) -> bool:
	push_error("FASE 43.4 ERROR: %s" % message)
	return false
