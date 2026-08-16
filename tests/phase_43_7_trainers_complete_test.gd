extends Node

const TRAINER_DIR := "res://data/trainers"

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 43.7 ENTRENADORES")
	print("================================")
	var ok := _run_test()
	print("")
	print("================================")
	if ok:
		print("FASE 43.7 OK - 8/8 Entrenadores canonicos alineados; 3 parciales y 5 data-only hasta F44.")
	else:
		push_error("FASE 43.7 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")

func _run_test() -> bool:
	var trainers := _load_trainers()
	if trainers.size() != 8:
		return _fail("Se esperaban exactamente 8 Entrenadores directos y hay %d." % trainers.size())
	var by_card: Dictionary = {}
	var trainer_ids: Dictionary = {}
	for data in trainers:
		if data == null or not data.is_valid_definition():
			return _fail("Existe un Resource de Entrenador invalido.")
		var card := String(data.card_id)
		var trainer_id := String(data.trainer_id)
		if by_card.has(card):
			return _fail("ID de carta duplicado: %s." % card)
		if trainer_ids.has(trainer_id):
			return _fail("trainer_id duplicado: %s." % trainer_id)
		by_card[card] = data
		trainer_ids[trainer_id] = true

	var partial_count := 0
	var data_only_count := 0
	var executable_count := 0
	for row in _rows():
		var id: String = row["card"]
		if not by_card.has(id):
			return _fail("Falta Entrenador canonico %s." % id)
		var data := by_card[id] as KarmanyTrainerData
		if data.trainer_id != StringName(row["trainer_id"]):
			return _fail("trainer_id incorrecto en %s." % id)
		if data.display_name != row["name"] or data.title != row["title"]:
			return _fail("Identidad no canonica en %s." % id)
		if data.strategic_style != row["style"] or data.difficulty_label != row["difficulty"]:
			return _fail("Estilo/dificultad no canonicos en %s." % id)
		if data.passive_text != row["passive"]:
			return _fail("Pasiva no canonica en %s." % id)
		if data.active_text != row["active"]:
			return _fail("Activa no canonica en %s." % id)
		if data.setup_bonus_text != row["setup"]:
			return _fail("Setup no canonico en %s." % id)
		if data.balance_text != row["balance"]:
			return _fail("Nota de balance no canonica en %s." % id)
		if data.automation_status != row["status"]:
			return _fail("automation_status incorrecto en %s." % id)
		match data.automation_status:
			KarmanyTrainerData.AutomationStatus.DATA_ONLY:
				data_only_count += 1
			KarmanyTrainerData.AutomationStatus.PARTIAL:
				partial_count += 1
			KarmanyTrainerData.AutomationStatus.EXECUTABLE:
				executable_count += 1

	if partial_count != 3 or data_only_count != 5 or executable_count != 0:
		return _fail("Cobertura esperada 3 PARTIAL / 5 DATA_ONLY / 0 EXECUTABLE; actual %d/%d/%d." % [partial_count, data_only_count, executable_count])
	return true

func _load_trainers() -> Array[KarmanyTrainerData]:
	var result: Array[KarmanyTrainerData] = []
	var dir := DirAccess.open(TRAINER_DIR)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var value := load("%s/%s" % [TRAINER_DIR, file_name]) as KarmanyTrainerData
		if value != null:
			result.append(value)
	return result

func _rows() -> Array[Dictionary]:
	return [
		{"card":"E-01","trainer_id":"alderion","name":"Alderion","title":"Explorador Errante","style":"Exploracion / posicionamiento","difficulty":"Media","passive":"La primera vez que explores en cada ronda, mira 1 loseta oculta adyacente adicional del mismo nivel antes de elegir. Si revelas una loseta que miraste, despues de resolverla obten 1 recurso basico a eleccion. La primera vez que reveles una loseta Nivel 2 o superior en cada ronda, elige: obten 1 recurso basico adicional o roba 1 Resonancia.","active":"Una vez por ronda, despues de explorar una loseta oculta, roba 2 Resonancias y descarta 1.","setup":"Mira 1 loseta Nivel 1 adyacente antes de tu primera exploracion.","balance":"Reduce azar y convierte exploracion en progreso. Mejora su cierre sin dar PL directo.","status":KarmanyTrainerData.AutomationStatus.DATA_ONLY},
		{"card":"E-02","trainer_id":"lyra","name":"Lyra","title":"Guardiana de Vinculo","style":"Karmany / vinculo","difficulty":"Media-alta","passive":"La primera vez en cada ronda que intentes vincular, mira 1 Karmany adicional o reduce el costo en 1 recurso comun. No reduce FA. Tu primer vinculo de la partida: roba 2 Resonancias y descarta 1.","active":"Una vez por ronda, cuando uses Llamar Karmany, puedes intentar Vincular inmediatamente al elegido dentro de esa misma accion.","setup":"Mira la primera carta del mazo de Karmany; puedes dejarla arriba o ponerla al fondo.","balance":"Especialista de tempo: ahorra una accion al buscar y vincular. La loseta de Vinculo guiado sigue siendo util, pero Lyra depende menos de ella.","status":KarmanyTrainerData.AutomationStatus.DATA_ONLY},
		{"card":"E-03","trainer_id":"dorian","name":"Dorian","title":"Duelista de Vael","style":"PvP / presion","difficulty":"Media","passive":"Cuando ganas un PvP, roba 2 Resonancias y descarta 1.","active":"Una vez por ronda desde ronda 2, puedes iniciar PvP contra un rival en tu loseta o adyacente con igual o mas PL, aunque la loseta no lo habilite. En tu primer PvP de la ronda ganas +3 Poder. Tregua se aplica normalmente.","setup":"Roba 1 Resonancia adicional durante la preparacion.","balance":"Duelista de catch-up: encuentra enfrentamientos relevantes sin perseguir al jugador mas debil.","status":KarmanyTrainerData.AutomationStatus.PARTIAL},
		{"card":"E-04","trainer_id":"nara","name":"Nara","title":"Forjadora Karmica","style":"Crafteo / Equipo","difficulty":"Baja-media","passive":"La primera vez que craftees en cada ronda, reduce el costo en 1 recurso comun. Nunca reduce FA.","active":"Una vez por ronda, puedes crear 1 Equipo Basico visible del mercado desde cualquier loseta revelada. Si estas en N2 o N3, puedes crear 1 Equipo Avanzado visible. Equipo Ancestral requiere Forja o efecto especifico.","setup":"Mira la primera carta del mazo de Equipo; puedes dejarla arriba o ponerla al fondo.","balance":"Especialista de Equipo: 3 Equipos y un Ancestral son metas reales si invierte bien; no ignora la progresion hacia N3.","status":KarmanyTrainerData.AutomationStatus.DATA_ONLY},
		{"card":"E-05","trainer_id":"maelis","name":"Maelis","title":"Tejedora de Resonancia","style":"Resonancia / control de mano","difficulty":"Media","passive":"La primera vez en cada ronda que juegues una Resonancia +0, roba 1 Resonancia.","active":"Una vez por ronda, una Resonancia +0 que juegues en combate obtiene +4 Poder.","setup":"Roba 1 Resonancia adicional y luego descarta 1 Resonancia.","balance":"Convierte cartas +0 en breakpoints reales de combate sin mantener estados permanentes.","status":KarmanyTrainerData.AutomationStatus.PARTIAL},
		{"card":"E-06","trainer_id":"kael","name":"Kael","title":"Cazador del Umbral","style":"Bestias / PvE","difficulty":"Baja-media","passive":"La primera vez que combatas contra una Bestia media, compleja, jefe o legendaria en cada ronda, gana +2 Poder si no has iniciado PvP esta ronda. Contra Bestias basicas gana +1.","active":"Una vez por ronda, despues de derrotar una Bestia, elige: obten +2 recursos basicos del tipo de la recompensa, o mira la primera carta de Bestia del mazo correspondiente.","setup":"Mira la primera carta del mazo de Bestias basicas y dejala arriba o ponla al fondo.","balance":"Especialista PvE: conserva control temprano y obtiene ventaja real contra Aeterna sin asegurar la victoria.","status":KarmanyTrainerData.AutomationStatus.DATA_ONLY},
		{"card":"E-07","trainer_id":"saira","name":"Saira","title":"Cartografa de Terrenos","style":"Posicionamiento / exploracion","difficulty":"Media-alta","passive":"La primera vez que entres en una loseta revelada nueva para ti en cada ronda, elige: obten 1 recurso basico o gana +1 Poder en tu proximo combate esta ronda. La primera vez que entres en una loseta de un nivel que no habias visitado esta partida, roba 1 Resonancia u obten 1 recurso basico.","active":"Una vez por ronda, despues de moverte, puedes mirar una loseta oculta N2/N3 adyacente o moverte 1 loseta revelada adicional.","setup":"Mira 1 loseta Nivel 1 adyacente antes de tu primera exploracion.","balance":"Gran movilidad y lectura del mapa sin rutas. Convierte visitar niveles nuevos en tempo real.","status":KarmanyTrainerData.AutomationStatus.DATA_ONLY},
		{"card":"E-08","trainer_id":"oryn","name":"Oryn","title":"Apostador del Eco","style":"Riesgo / dado","difficulty":"Alta","passive":"La primera vez que lances Dado de Riesgo en cada ronda: con 3-4 roba 1 Resonancia; con 5-6, si ganas, gana +1 PL. Maximo 2 PL por partida por esta pasiva.","active":"Una vez por ronda, permite que un Karmany no Salvaje lance Dado de Riesgo. Si ese lanzamiento sale 1 o 2, puedes tratarlo como 3.","setup":"Roba 1 Resonancia adicional durante la preparacion.","balance":"Especialista de riesgo: mantiene picos altos, pero puede neutralizar un fallo por ronda.","status":KarmanyTrainerData.AutomationStatus.PARTIAL}
	]

func _fail(message: String) -> bool:
	push_error("FASE 43.7 TEST ERROR: %s" % message)
	return false
