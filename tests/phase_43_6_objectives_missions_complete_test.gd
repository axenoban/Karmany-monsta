extends Node

const OBJECTIVE_DIRECT_DIR := "res://data/objectives"
const OBJECTIVE_PENDING_DIR := "res://data/objectives/canonical_pending"
const MISSION_DIRECT_DIR := "res://data/missions"
const MISSION_PENDING_DIR := "res://data/missions/canonical_pending"

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.6 OBJETIVOS Y MISIONES")
	print("================================")
	var ok := _test_objectives()
	ok = _test_missions() and ok
	ok = _test_runtime_isolation() and ok
	print("")
	print("================================")
	if ok:
		print("FASE 43.6 OK - 12/12 Objetivos y 16/16 Misiones canonicos materializados; pendientes aislados hasta F44.")
	else:
		push_error("FASE 43.6 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")

func _test_objectives() -> bool:
	var direct := _load_objectives(OBJECTIVE_DIRECT_DIR)
	var pending := _load_objectives(OBJECTIVE_PENDING_DIR)
	if direct.size() != 8:
		return _fail("Se esperaban 8 Objetivos directos y hay %d." % direct.size())
	if pending.size() != 4:
		return _fail("Se esperaban 4 Objetivos canonical_pending y hay %d." % pending.size())
	var all := direct.duplicate()
	all.append_array(pending)
	if all.size() != 12:
		return _fail("Se esperaban 12 Objetivos materializados.")
	var by_id: Dictionary = {}
	for data in all:
		if by_id.has(String(data.objective_id)):
			return _fail("ID Objetivo duplicado: %s." % String(data.objective_id))
		by_id[String(data.objective_id)] = data
	for row in _objective_rows():
		var id: String = row["id"]
		if not by_id.has(id):
			return _fail("Falta Objetivo canonico %s." % id)
		var data := by_id[id] as KarmanyObjectiveData
		if data.display_name != row["name"] or data.family != row["family"]:
			return _fail("Identidad/familia no canonica en %s." % id)
		if data.condition_text != row["condition"] or data.reward_legacy_points != row["reward"]:
			return _fail("Condicion/recompensa no canonica en %s." % id)
		if data.map_41_only != row["map41"]:
			return _fail("map_41_only incorrecto en %s." % id)
	for data in direct:
		if not data.is_valid_definition():
			return _fail("Objetivo directo invalido: %s." % data.objective_id)
	for data in pending:
		if not data.conditions.is_empty():
			return _fail("%s contiene automatizacion inventada antes de F44." % data.objective_id)
		if data.is_valid_definition():
			return _fail("%s no debe declararse runtime-valido antes de F44." % data.objective_id)
	return true

func _test_missions() -> bool:
	var direct := _load_missions(MISSION_DIRECT_DIR)
	var pending := _load_missions(MISSION_PENDING_DIR)
	if direct.size() != 9:
		return _fail("Se esperaban 9 Misiones directas y hay %d." % direct.size())
	if pending.size() != 7:
		return _fail("Se esperaban 7 Misiones canonical_pending y hay %d." % pending.size())
	var all := direct.duplicate()
	all.append_array(pending)
	if all.size() != 16:
		return _fail("Se esperaban 16 Misiones materializadas.")
	var by_id: Dictionary = {}
	for data in all:
		if by_id.has(String(data.mission_id)):
			return _fail("ID Mision duplicado: %s." % String(data.mission_id))
		by_id[String(data.mission_id)] = data
	for row in _mission_rows():
		var id: String = row["id"]
		if not by_id.has(id):
			return _fail("Falta Mision canonica %s." % id)
		var data := by_id[id] as KarmanyMissionData
		if String(data.trainer_id) != row["trainer_id"] or data.trainer_display_name != row["trainer"]:
			return _fail("Entrenador no canonico en %s." % id)
		if data.display_name != row["name"] or data.condition_text != row["condition"]:
			return _fail("Nombre/condicion no canonicos en %s." % id)
		if data.recommended_first_game != row["recommended"]:
			return _fail("Marca de primera partida incorrecta en %s." % id)
		if data.reward_legacy_points != 4 or not _has_fa_reward(data):
			return _fail("Recompensa 4 PL + 1 FA no materializada en %s." % id)
	for data in direct:
		if not data.is_valid_definition():
			return _fail("Mision directa invalida: %s." % data.mission_id)
	for data in pending:
		if not data.conditions.is_empty():
			return _fail("%s contiene condiciones ejecutables inventadas antes de F44." % data.mission_id)
		if data.is_valid_definition():
			return _fail("%s no debe declararse runtime-valida antes de F44." % data.mission_id)
	return true

func _test_runtime_isolation() -> bool:
	var direct_objectives := KarmanyPhase37AlphaContentCatalog.load_category(&"objectives")
	var direct_missions := KarmanyPhase37AlphaContentCatalog.load_category(&"missions")
	if direct_objectives.size() != 8:
		return _fail("El catalogo runtime directo de Objetivos cambio durante F43.6.")
	if direct_missions.size() != 9:
		return _fail("El catalogo runtime directo de Misiones cambio durante F43.6.")
	if KarmanyPhase37AlphaContentCatalog.get_runtime_objectives().size() != 8:
		return _fail("El conjunto runtime-safe de Objetivos cambio durante F43.6.")
	if KarmanyPhase37AlphaContentCatalog.get_runtime_missions().size() != 9:
		return _fail("El conjunto runtime-safe directo de Misiones cambio durante F43.6.")
	var runtime_missions := KarmanyV074CanonicalRuntimeCatalog.build_runtime_missions(
		KarmanyPhase37AlphaContentCatalog.get_runtime_missions()
	)
	if runtime_missions.size() != 11:
		return _fail("El runtime canonico debe conservar 11 Misiones mediante los fallbacks M1/S1.")
	var by_id: Dictionary = {}
	for mission in runtime_missions:
		by_id[String(mission.mission_id)] = mission
	if not by_id.has("ME-M1") or not by_id.has("ME-S1"):
		return _fail("Faltan los fallbacks runtime ME-M1/ME-S1.")
	if (by_id["ME-M1"] as KarmanyMissionData).display_name != "Resonancia Decisiva":
		return _fail("Fallback ME-M1 no fue alineado al maestro v0.74.")
	if (by_id["ME-S1"] as KarmanyMissionData).display_name != "Cartografia Viva":
		return _fail("Fallback ME-S1 no fue alineado al maestro v0.74.")
	return true

func _load_objectives(path: String) -> Array[KarmanyObjectiveData]:
	var result: Array[KarmanyObjectiveData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyObjectiveData
		if data != null:
			result.append(data)
	return result

func _load_missions(path: String) -> Array[KarmanyMissionData]:
	var result: Array[KarmanyMissionData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyMissionData
		if data != null:
			result.append(data)
	return result

func _has_fa_reward(data: KarmanyMissionData) -> bool:
	for effect in data.reward_effects:
		if (
			effect != null
			and effect.effect_type == KarmanyEffectData.EffectType.ADD_RESOURCE
			and effect.amount == 1
			and effect.resource_type == KarmanyEffectData.ResourceType.FA
		):
			return true
	return false

func _objective_rows() -> Array[Dictionary]:
	return [
		{"id":"OP-E01","name":"Cartografo Experto","family":0,"condition":"Ser el primer jugador en visitar 5 losetas distintas.","reward":3,"map41":false},
		{"id":"OP-E02","name":"Explorador de Ruinas","family":0,"condition":"Ser el primer jugador en revelar 4 losetas durante la partida.","reward":3,"map41":false},
		{"id":"OP-E03","name":"Caminante de Vael","family":0,"condition":"Ser el primer jugador en entrar mediante Mover en 3 losetas reveladas distintas.","reward":3,"map41":false},
		{"id":"OP-D01","name":"Primer Vinculo","family":1,"condition":"Ser el primer jugador en vincular 1 Karmany no inicial.","reward":3,"map41":false},
		{"id":"OP-D02","name":"Forja Consistente","family":1,"condition":"Ser el primer jugador con 3 Equipos equipados.","reward":4,"map41":false},
		{"id":"OP-D03","name":"Libro Despierto","family":1,"condition":"Ser el primer jugador en mejorar a Libro II y tener 1 Karmany en reserva.","reward":4,"map41":false},
		{"id":"OP-C01","name":"Cazador de Bruma","family":2,"condition":"Ser el primer jugador en derrotar 3 Bestias.","reward":4,"map41":false},
		{"id":"OP-C02","name":"Mano Resonante","family":2,"condition":"Ser el primer jugador en jugar 3 Resonancias en combates distintos.","reward":4,"map41":false},
		{"id":"OP-C03","name":"Duelista del Eco","family":2,"condition":"Ser el primer jugador en ganar 1 PvP desde ronda 2 o posterior.","reward":4,"map41":false},
		{"id":"OP-A01","name":"Dominio Territorial","family":3,"condition":"Ser el primer jugador en entrar a 2 losetas Nivel 3 distintas.","reward":5,"map41":true},
		{"id":"OP-A02","name":"Rumbo al Santuario","family":3,"condition":"Ser el primer jugador en llegar al Santuario con Libro II o superior.","reward":4,"map41":true},
		{"id":"OP-A03","name":"Preparacion Final","family":3,"condition":"Ser el primer jugador en terminar su turno con Libro II o superior, 2 Equipos y 1 FA.","reward":5,"map41":true}
	]

func _mission_rows() -> Array[Dictionary]:
	return [
		{"id":"ME-A1","trainer_id":"alderion","trainer":"Alderion","name":"Cartografo del Primer Eco","recommended":true,"condition":"Revela 3 losetas y entra al menos una vez en Nivel 2 o superior."},
		{"id":"ME-A2","trainer_id":"alderion","trainer":"Alderion","name":"Mapa de Legado","recommended":false,"condition":"Revela 2 losetas y mejora tu Libro a Nivel II."},
		{"id":"ME-L1","trainer_id":"lyra","trainer":"Lyra","name":"Vinculos del Camino","recommended":true,"condition":"Vincula 2 Karmany no iniciales."},
		{"id":"ME-L2","trainer_id":"lyra","trainer":"Lyra","name":"Guardian de Dos Ecos","recommended":false,"condition":"Vincula al menos 1 Karmany Nivel 2 y mejora tu Libro a Nivel II."},
		{"id":"ME-D1","trainer_id":"dorian","trainer":"Dorian","name":"Rival de Vael","recommended":true,"condition":"Gana 1 PvP y derrota 1 Bestia en rondas distintas."},
		{"id":"ME-D2","trainer_id":"dorian","trainer":"Dorian","name":"Duelo Preparado","recommended":false,"condition":"Gana 1 PvP y termina un turno con Libro II o superior."},
		{"id":"ME-N1","trainer_id":"nara","trainer":"Nara","name":"Forja Personal","recommended":true,"condition":"Termina tu turno con 2 Equipos equipados y Libro II o superior."},
		{"id":"ME-N2","trainer_id":"nara","trainer":"Nara","name":"Arsenal Escalonado","recommended":false,"condition":"Crea al menos 1 Equipo Basico y 1 Equipo Avanzado durante la partida."},
		{"id":"ME-M1","trainer_id":"maelis","trainer":"Maelis","name":"Resonancia Decisiva","recommended":true,"condition":"Gana 2 combates en los que hayas jugado una Resonancia."},
		{"id":"ME-M2","trainer_id":"maelis","trainer":"Maelis","name":"Eco Transformado","recommended":false,"condition":"Gana 1 combate usando una Resonancia +0 modificada por un efecto y mejora tu Libro a Nivel II."},
		{"id":"ME-K1","trainer_id":"kael","trainer":"Kael","name":"Cazador del Umbral","recommended":true,"condition":"Derrota 2 Bestias; al menos una debe ser Media o superior."},
		{"id":"ME-K2","trainer_id":"kael","trainer":"Kael","name":"Camino del Cazador","recommended":false,"condition":"Derrota 1 Bestia Media o superior y entra a una loseta Nivel 3."},
		{"id":"ME-S1","trainer_id":"saira","trainer":"Saira","name":"Cartografia Viva","recommended":true,"condition":"Visita 5 losetas distintas e incluye al menos una N2 y una N3."},
		{"id":"ME-S2","trainer_id":"saira","trainer":"Saira","name":"Ruta al Centro","recommended":false,"condition":"Explora 2 losetas y entra al Santuario de Aeterna."},
		{"id":"ME-O1","trainer_id":"oryn","trainer":"Oryn","name":"Apuesta Victoriosa","recommended":true,"condition":"Gana 2 combates en los que hayas lanzado el Dado de Riesgo."},
		{"id":"ME-O2","trainer_id":"oryn","trainer":"Oryn","name":"Riesgo Calculado","recommended":false,"condition":"Lanza el Dado de Riesgo en 3 combates y mejora tu Libro a Nivel II."}
	]

func _fail(message: String) -> bool:
	push_error("FASE 43.6 ERROR: %s" % message)
	return false
