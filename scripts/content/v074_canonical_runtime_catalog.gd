class_name KarmanyV074CanonicalRuntimeCatalog
extends RefCounted

const CANONICAL_COUNTS: Dictionary = {
	"trainers": 8,
	"tiles": 41,
	"karmanys": 28,
	"beasts": 24,
	"equipment": 36,
	"resonances": 40,
	"objectives": 12,
	"missions": 16,
}

static var TRAINER_IDS: PackedStringArray = PackedStringArray([
	"E-01",
	"E-02",
	"E-03",
	"E-04",
	"E-05",
	"E-06",
	"E-07",
	"E-08",
])

static var TILE_IDS: PackedStringArray = PackedStringArray([
	"I-01",
	"I-02",
	"I-03",
	"I-04",
	"N1-01",
	"N1-02",
	"N1-03",
	"N1-04",
	"N1-05",
	"N1-06",
	"N1-07",
	"N1-08",
	"N1-09",
	"N1-10",
	"N1-11",
	"N1-12",
	"N1-13",
	"N1-14",
	"N1-15",
	"N1-16",
	"N1-17",
	"N1-18",
	"N2-01",
	"N2-02",
	"N2-03",
	"N2-04",
	"N2-05",
	"N2-06",
	"N2-07",
	"N2-08",
	"N2-09",
	"N2-10",
	"N2-11",
	"N2-12",
	"N3-01",
	"N3-02",
	"N3-03",
	"L-01",
	"N3-04",
	"N3-05",
	"N3-06",
])

static var KARMANY_IDS: PackedStringArray = PackedStringArray([
	"K-01",
	"K-02",
	"K-03",
	"K-04",
	"K-05",
	"K-06",
	"K-07",
	"K-08",
	"K-09",
	"K-10",
	"K-11",
	"K-12",
	"K-13",
	"K-14",
	"K-15",
	"K-16",
	"K-17",
	"K-18",
	"K-19",
	"K-20",
	"K-21",
	"K-22",
	"K-23",
	"K-24",
	"K-25",
	"K-26",
	"K-27",
	"K-28",
])

static var BEAST_IDS: PackedStringArray = PackedStringArray([
	"B-01",
	"B-02",
	"B-03",
	"B-04",
	"B-05",
	"B-06",
	"B-07",
	"B-08",
	"B-09",
	"B-10",
	"B-11",
	"B-12",
	"B-13",
	"B-14",
	"B-15",
	"B-16",
	"B-17",
	"B-18",
	"B-19",
	"B-20",
	"B-21",
	"B-22",
	"B-23",
	"B-24",
])

static var EQUIPMENT_IDS: PackedStringArray = PackedStringArray([
	"EQ-01",
	"EQ-02",
	"EQ-03",
	"EQ-04",
	"EQ-05",
	"EQ-06",
	"EQ-07",
	"EQ-08",
	"EQ-09",
	"EQ-10",
	"EQ-11",
	"EQ-12",
	"EQ-13",
	"EQ-14",
	"EQ-15",
	"EQ-16",
	"EQ-17",
	"EQ-18",
	"EQ-19",
	"EQ-20",
	"EQ-21",
	"EQ-22",
	"EQ-23",
	"EQ-24",
	"EQ-25",
	"EQ-26",
	"EQ-27",
	"EQ-28",
	"EQ-29",
	"EQ-30",
	"EQ-31",
	"EQ-32",
	"EQ-33",
	"EQ-34",
	"EQ-35",
	"EQ-36",
])

static var RESONANCE_IDS: PackedStringArray = PackedStringArray([
	"R-01",
	"R-02",
	"R-03",
	"R-04",
	"R-05",
	"R-06",
	"R-07",
	"R-08",
	"R-09",
	"R-10",
	"R-11",
	"R-12",
	"R-13",
	"R-14",
	"R-15",
	"R-16",
	"R-17",
	"R-18",
	"R-19",
	"R-20",
	"R-21",
	"R-22",
	"R-23",
	"R-24",
	"R-25",
	"R-26",
	"R-27",
	"R-28",
	"R-29",
	"R-30",
	"R-31",
	"R-32",
	"R-33",
	"R-34",
	"R-35",
	"R-36",
	"R-37",
	"R-38",
	"R-39",
	"R-40",
])

static var OBJECTIVE_IDS: PackedStringArray = PackedStringArray([
	"OP-E01",
	"OP-E02",
	"OP-E03",
	"OP-D01",
	"OP-D02",
	"OP-D03",
	"OP-C01",
	"OP-C02",
	"OP-C03",
	"OP-A01",
	"OP-A02",
	"OP-A03",
])

static var MISSION_IDS: PackedStringArray = PackedStringArray([
	"ME-A1",
	"ME-A2",
	"ME-L1",
	"ME-L2",
	"ME-D1",
	"ME-D2",
	"ME-N1",
	"ME-N2",
	"ME-M1",
	"ME-M2",
	"ME-K1",
	"ME-K2",
	"ME-S1",
	"ME-S2",
	"ME-O1",
	"ME-O2",
])

static var AUTOMATED_RESONANCE_IDS: PackedStringArray = PackedStringArray([
	"R-01",
	"R-02",
	"R-03",
	"R-04",
	"R-05",
	"R-06",
	"R-07",
	"R-08",
	"R-09",
	"R-13",
	"R-20",
	"R-22",
	"R-37",
])

static var RESONANCE_DEFINITIONS: Array[Dictionary] = [
	{
		"id": &"R-01", "name": "Impulso Luminico", "type": 0, "power": 4,
		"use_text": "Combate", "effect_text": "Si ganas, recupera 2 EK.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-02", "name": "Golpe Salvaje", "type": 0, "power": 6,
		"use_text": "Combate", "effect_text": "Despues del combate, descarta 1 carta de tu mano. Si tu Karmany no usa Dado de Riesgo, puedes lanzar el Dado de Riesgo 2.0; aplica resultados 1-6 completos. Ese dado no puede repetirse ni modificarse por otro efecto.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-03", "name": "Corte de Bruma", "type": 0, "power": 4,
		"use_text": "Combate", "effect_text": "Si estas en una loseta revelada o explorada este turno, roba 2 Resonancias y descarta 1.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-04", "name": "Embate de Raiz", "type": 0, "power": 3,
		"use_text": "Combate", "effect_text": "Si combates contra Bestia, gana +2 Poder adicional.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-05", "name": "Furia Controlada", "type": 0, "power": 6,
		"use_text": "PvP", "effect_text": "Solo PvP legal. Si pierdes, descarta 1 Resonancia adicional de tu mano si tienes. Puedes lanzar Dado de Riesgo 2.0 aunque tu Karmany no sea Salvaje; aplica resultados 1-6 completos. No puede combinarse con otro efecto que permita Dado en este PvP.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-06", "name": "Chispa del Libro", "type": 0, "power": 3,
		"use_text": "Combate", "effect_text": "Si tienes Libro II o III, roba 2 Resonancias y descarta 1.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-07", "name": "Golpe Certero", "type": 0, "power": 4,
		"use_text": "Combate", "effect_text": "Carta segura de buen valor. Si esta carta te hace igualar exactamente la Defensa, roba 1 Resonancia.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-08", "name": "Resonancia Creciente", "type": 0, "power": 3,
		"use_text": "Combate", "effect_text": "Si usas Karmany Estable, gana +2 Poder adicional.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-09", "name": "Ruptura Runica", "type": 0, "power": 4,
		"use_text": "Combate", "effect_text": "Si ganas contra Bestia, obten +2 MR.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-10", "name": "Pulso de Batalla", "type": 0, "power": 4,
		"use_text": "Combate", "effect_text": "En PvP, si el rival jugo una Resonancia en este combate, gana +2 Poder adicional; si no jugo Resonancia, gana +1 Poder adicional.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-11", "name": "Destello Final", "type": 0, "power": 8,
		"use_text": "Combate", "effect_text": "Solo puedes usarla en ronda 6 o 7. No puede usarse contra Aeterna. Despues descarta 2 recursos basicos.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-12", "name": "Ira del Santuario", "type": 0, "power": 5,
		"use_text": "Combate", "effect_text": "Contra Jefes o Legendario, gana +3 Poder adicional.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-13", "name": "Defensa Instintiva", "type": 1, "power": 3,
		"use_text": "Combate", "effect_text": "Si pierdes, no retrocedes.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-14", "name": "Guardia de Raiz", "type": 1, "power": 0,
		"use_text": "Reaccion", "effect_text": "Si pierdes contra Bestia, no pierdes recursos basicos. Si evita al menos 1 recurso perdido, roba 1 Resonancia.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-15", "name": "Reflejo Karmico", "type": 1, "power": 3,
		"use_text": "Combate", "effect_text": "Si pierdes PvP, el rival no puede robar carta ni asimilar carta. Si pierdes el PvP, roba 1 Resonancia.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-16", "name": "Escudo Breve", "type": 1, "power": 4,
		"use_text": "Combate", "effect_text": "Si pierdes, reduce la penalizacion en hasta 2 recursos basicos.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-17", "name": "Paso Cubierto", "type": 1, "power": 0,
		"use_text": "Reaccion", "effect_text": "Juega al sufrir un retroceso: evita ese retroceso y despues puedes moverte 1 loseta revelada adyacente.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-18", "name": "Calma Interior", "type": 1, "power": 0,
		"use_text": "Reaccion", "effect_text": "Cancela el descarte de 1 Resonancia provocado por derrota. Si cancelas ese descarte, roba 1 Resonancia y descarta 1.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-19", "name": "Piel de Bruma", "type": 1, "power": 0,
		"use_text": "Reaccion", "effect_text": "Juega cuando pierdas un combate: no retrocedes.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-20", "name": "Ultima Defensa", "type": 1, "power": 5,
		"use_text": "Combate", "effect_text": "Si pierdes de todos modos, roba 2 Resonancias y descarta 1.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-21", "name": "Paso Silencioso", "type": 2, "power": 0,
		"use_text": "Reaccion", "effect_text": "Juega antes de un combate obligatorio contra Bestia para evitarlo. No funciona contra Jefes ni Legendarios.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-22", "name": "Mirada del Sendero", "type": 2, "power": 0,
		"use_text": "Exploracion", "effect_text": "Mira 1 loseta oculta adyacente antes de explorar. Si es Nivel 1, puedes mirar otra Nivel 1 adyacente. Despues roba 1 Resonancia y descarta 1.",
		"windows": PackedStringArray(["exploration"])
	},
	{
		"id": &"R-23", "name": "Visita Segura", "type": 2, "power": 0,
		"use_text": "Movimiento", "effect_text": "Despues de usar Mover para entrar en una loseta revelada nueva para ti, roba 2 Resonancias y descarta 1.",
		"windows": PackedStringArray(["movement"])
	},
	{
		"id": &"R-24", "name": "Avance Ligero", "type": 2, "power": 0,
		"use_text": "Movimiento", "effect_text": "Muevete 1 loseta revelada adicional. Si terminas en una loseta Nivel 2 o superior, roba 1 Resonancia.",
		"windows": PackedStringArray(["movement"])
	},
	{
		"id": &"R-25", "name": "Rastreo de Vael", "type": 2, "power": 2,
		"use_text": "Exploracion", "effect_text": "Si revelas Nivel 2, puedes mirar la primera Bestia antes de combatir. Si combates esa Bestia, gana +2 Poder.",
		"windows": PackedStringArray(["exploration"])
	},
	{
		"id": &"R-26", "name": "Eco del Bosque", "type": 2, "power": 0,
		"use_text": "Exploracion", "effect_text": "Al explorar Nivel 1, recolecta 2 MN adicionales. Si ya estas en Nivel 2 o superior, puedes ganar 1 EK en vez de esos MN.",
		"windows": PackedStringArray(["exploration"])
	},
	{
		"id": &"R-27", "name": "Brujula Espiritual", "type": 2, "power": 0,
		"use_text": "Exploracion", "effect_text": "Antes de Explorar, mira una loseta Nivel 3 oculta adyacente. Si es Santuario, roba 1 Resonancia; si no, roba 1 Resonancia y descarta 1.",
		"windows": PackedStringArray(["exploration"])
	},
	{
		"id": &"R-28", "name": "Camino Abierto", "type": 2, "power": 2,
		"use_text": "Exploracion", "effect_text": "Despues de explorar, puedes moverte a una loseta revelada adyacente.",
		"windows": PackedStringArray(["exploration"])
	},
	{
		"id": &"R-29", "name": "Pulso de Vinculo", "type": 3, "power": 2,
		"use_text": "Combate/Vinculo", "effect_text": "Si usas esta carta al derrotar un Karmany, paga 1 EK menos para vincularlo.",
		"windows": PackedStringArray(["combat", "bond"])
	},
	{
		"id": &"R-30", "name": "Llamado Sereno", "type": 3, "power": 0,
		"use_text": "Vinculo", "effect_text": "Mira 3 Karmany del mazo compatible con tu nivel actual; revela 1 y devuelve los otros abajo. Si no revelas o no puedes revelar un Karmany, gana 1 EK.",
		"windows": PackedStringArray(["bond"])
	},
	{
		"id": &"R-31", "name": "Cambio de Guardia", "type": 3, "power": 0,
		"use_text": "Reaccion", "effect_text": "Antes de combatir, cambia tu Karmany activo por uno en reserva sin gastar accion. El nuevo Karmany gana +1 Poder en este combate.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-32", "name": "Resonancia Compartida", "type": 3, "power": 2,
		"use_text": "Combate", "effect_text": "Si tu Karmany fue vinculado esta ronda, gana +2 Poder adicional.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-33", "name": "Marca de Confianza", "type": 3, "power": 0,
		"use_text": "Vinculo", "effect_text": "Al vincular un Karmany, paga 1 recurso comun menos. No reduce FA. Despues roba 1 Resonancia.",
		"windows": PackedStringArray(["bond"])
	},
	{
		"id": &"R-34", "name": "Eco de Compania", "type": 3, "power": 0,
		"use_text": "Final de turno", "effect_text": "Si tienes 2 o mas Karmany, roba 2 Resonancias y descarta 1.",
		"windows": PackedStringArray(["end_turn"])
	},
	{
		"id": &"R-35", "name": "Contraimpulso", "type": 4, "power": 2,
		"use_text": "Reaccion PvP", "effect_text": "Despues de que el rival juegue Resonancia, juega esta carta y gana +2 Poder adicional.",
		"windows": PackedStringArray(["combat", "reaction"])
	},
	{
		"id": &"R-36", "name": "Mano Rapida", "type": 4, "power": 0,
		"use_text": "Reaccion", "effect_text": "Cuando un rival intente robar carta de tu mano o asimilar carta, descarta esta carta para cancelar ese efecto. Si cancelas el efecto, roba 1 Resonancia.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-37", "name": "Instinto de Caza", "type": 4, "power": 0,
		"use_text": "Combate", "effect_text": "En un combate contra Bestia, gana +2 Poder.",
		"windows": PackedStringArray(["combat"])
	},
	{
		"id": &"R-38", "name": "Reserva Oculta", "type": 4, "power": 0,
		"use_text": "Reaccion", "effect_text": "Despues de descartar recursos basicos por una derrota, roba 1 Resonancia y descarta 1.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-39", "name": "Destino Cambiante", "type": 4, "power": 0,
		"use_text": "Reaccion", "effect_text": "Despues de lanzar Dado de Riesgo 2.0, repite el dado, convierte un resultado 1 en 3, o cancela el descarte de la cara 2. Si repites, debes quedarte con el nuevo resultado. No puede combinarse con Anillo del Eco en el mismo combate.",
		"windows": PackedStringArray(["reaction"])
	},
	{
		"id": &"R-40", "name": "Ultimo Aliento", "type": 4, "power": 4,
		"use_text": "Reaccion", "effect_text": "Si estas perdiendo un combate por 4 o menos, juega esta carta para sumar +4 Poder. Alternativamente, puedes lanzar Dado de Riesgo 2.0 aunque tu Karmany no sea Salvaje; ese dado no puede repetirse ni modificarse por otro efecto.",
		"windows": PackedStringArray(["reaction"])
	},
]


static func build_full_resonance_pool(
	existing_cards: Array[KarmanyResonanceData]
) -> Array[KarmanyResonanceData]:
	var by_id: Dictionary = {}
	for card in existing_cards:
		if card != null and card.is_valid_definition():
			by_id[card.resonance_id] = card

	var result: Array[KarmanyResonanceData] = []
	for definition in RESONANCE_DEFINITIONS:
		var resonance_id: StringName = StringName(definition.get("id", ""))
		var card: KarmanyResonanceData = by_id.get(resonance_id, null) as KarmanyResonanceData
		if card == null:
			card = _build_text_only_resonance(definition)
		if card != null and card.is_valid_definition():
			result.append(card)
	return result


static func is_resonance_automated(resonance_id: StringName) -> bool:
	return AUTOMATED_RESONANCE_IDS.has(String(resonance_id))


static func build_runtime_missions(
	existing_missions: Array[KarmanyMissionData]
) -> Array[KarmanyMissionData]:
	var result: Array[KarmanyMissionData] = []
	var seen: Dictionary = {}
	for mission in existing_missions:
		if mission == null or not mission.is_valid_definition():
			continue
		result.append(mission)
		seen[mission.mission_id] = true

	if not seen.has(&"ME-M1"):
		result.append(_build_maelis_first_mission())
	if not seen.has(&"ME-S1"):
		result.append(_build_saira_first_mission())
	return result


static func _build_text_only_resonance(definition: Dictionary) -> KarmanyResonanceData:
	var card := KarmanyResonanceData.new()
	card.resonance_id = StringName(definition.get("id", ""))
	card.display_name = String(definition.get("name", ""))
	card.resonance_type = int(definition.get("type", KarmanyResonanceData.ResonanceType.REACTION))
	card.printed_power = int(definition.get("power", 0))
	var windows_value: Variant = definition.get("windows", PackedStringArray())
	if windows_value is PackedStringArray:
		card.use_windows = PackedStringArray(windows_value)
	card.rules_text = "%s: %s" % [
		String(definition.get("use_text", "")),
		String(definition.get("effect_text", ""))
	]
	card.tags = PackedStringArray([
		"canonical_v074",
		"text_only_secondary_effect"
	])
	return card


static func _new_condition(
	condition_type: int,
	event_id: StringName,
	threshold: int,
	field_id: StringName = &""
) -> KarmanyProgressConditionData:
	var condition := KarmanyProgressConditionData.new()
	condition.condition_type = condition_type
	condition.event_id = event_id
	condition.threshold = threshold
	condition.field_id = field_id
	return condition


static func _mission_reward_fa() -> KarmanyEffectData:
	var effect := KarmanyEffectData.new()
	effect.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	effect.amount = 1
	effect.resource_type = KarmanyEffectData.ResourceType.FA
	effect.description = "Mision completada: +1 FA."
	return effect


static func _build_maelis_first_mission() -> KarmanyMissionData:
	var mission := KarmanyMissionData.new()
	mission.mission_id = &"ME-M1"
	mission.trainer_id = &"maelis"
	mission.trainer_display_name = "Maelis"
	mission.display_name = "Resonancia Decisiva"
	mission.recommended_first_game = true
	mission.condition_text = "Gana 2 combates en los que hayas jugado una Resonancia."
	var condition := _new_condition(
		KarmanyProgressConditionData.ConditionType.EVENT_COUNT,
		&"phase38_combat_won_with_resonance",
		2
	)
	condition.description = "Ganar 2 combates usando Resonancia."
	var mission_conditions: Array[KarmanyProgressConditionData] = [condition]
	var mission_rewards: Array[KarmanyEffectData] = [_mission_reward_fa()]
	mission.conditions = mission_conditions
	mission.reward_effects = mission_rewards
	return mission


static func _build_saira_first_mission() -> KarmanyMissionData:
	var mission := KarmanyMissionData.new()
	mission.mission_id = &"ME-S1"
	mission.trainer_id = &"saira"
	mission.trainer_display_name = "Saira"
	mission.display_name = "Cartografia Viva"
	mission.recommended_first_game = true
	mission.condition_text = "Visita 5 losetas distintas e incluye al menos una N2 y una N3."
	var distinct := _new_condition(
		KarmanyProgressConditionData.ConditionType.DISTINCT_FIELD_COUNT,
		&"tile_visited",
		5,
		&"coord_key"
	)
	distinct.description = "Visitar 5 losetas distintas."
	var entered_n2 := _new_condition(
		KarmanyProgressConditionData.ConditionType.EVENT_EXISTS,
		&"phase38_entered_n2",
		1
	)
	entered_n2.description = "Entrar en una loseta N2."
	var entered_n3 := _new_condition(
		KarmanyProgressConditionData.ConditionType.EVENT_EXISTS,
		&"phase38_entered_n3",
		1
	)
	entered_n3.description = "Entrar en una loseta N3."
	var mission_conditions: Array[KarmanyProgressConditionData] = [
		distinct,
		entered_n2,
		entered_n3
	]
	var mission_rewards: Array[KarmanyEffectData] = [_mission_reward_fa()]
	mission.conditions = mission_conditions
	mission.reward_effects = mission_rewards
	return mission
