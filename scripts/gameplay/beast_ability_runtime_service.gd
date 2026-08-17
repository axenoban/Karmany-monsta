class_name KarmanyBeastAbilityRuntimeService
extends RefCounted


const STATUS_FULLY: StringName = &"FULLY_EXECUTABLE"
const STATUS_PARTIAL: StringName = &"PARTIAL"
const STATUS_DATA_ONLY: StringName = &"DATA_ONLY"
const STATUS_PENDING: StringName = &"PENDING"

# F44.3: contrato runtime explicito para las 24 Bestias materializadas.
# Los Resources bajo canonical_pending permanecen aislados fisicamente hasta
# que sus efectos textuales tengan representacion estructurada completa.
const CONTRACTS: Dictionary = {
	&"B-01": {"status": STATUS_PARTIAL, "hook": &"generic_reward_defeat_choice", "excluded": false, "reason": "falta selector runtime para descartar 2 recursos basicos a eleccion"},
	&"B-02": {"status": STATUS_FULLY, "hook": &"risk_used_plus_2_power", "excluded": false, "reason": ""},
	&"B-03": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-04": {"status": STATUS_FULLY, "hook": &"generic_resonance_reward", "excluded": false, "reason": ""},
	&"B-05": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-06": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-07": {"status": STATUS_PARTIAL, "hook": &"stable_win_plus_2_mn", "excluded": false, "reason": "bono Estable ejecutable; falta selector runtime de descarte de recursos en derrota"},
	&"B-08": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-09": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-10": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-11": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-12": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-13": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-14": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-15": {"status": STATUS_PARTIAL, "hook": &"generic_reward_defeat_choice", "excluded": false, "reason": "falta selector runtime para recursos basicos y carta a descartar en derrota"},
	&"B-16": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-17": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-18": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-19": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-20": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-21": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
	&"B-22": {"status": STATUS_PARTIAL, "hook": &"requires_book_2_or_higher", "excluded": false, "reason": "restriccion de Libro ejecutable; falta selector runtime para descarte de 3 recursos basicos"},
	&"B-23": {"status": STATUS_PARTIAL, "hook": &"risk_lock_equipment_choice", "excluded": false, "reason": "bloqueo de Riesgo ejecutable; falta seleccion de Equipo ancestral y descartes de derrota"},
	&"B-24": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; reglas aun no estructuradas para runtime"},
}


static func has_contract(beast_id: StringName) -> bool:
	return CONTRACTS.has(beast_id)


static func get_contract(beast_id: StringName) -> Dictionary:
	var value: Variant = CONTRACTS.get(beast_id, {})
	return value.duplicate(true) if value is Dictionary else {}


static func get_status(beast_id: StringName) -> StringName:
	var contract := get_contract(beast_id)
	return StringName(contract.get("status", STATUS_PENDING))


static func is_runtime_excluded(beast_id: StringName) -> bool:
	var contract := get_contract(beast_id)
	return bool(contract.get("excluded", true))


static func get_contract_counts() -> Dictionary:
	var result := {
		STATUS_FULLY: 0,
		STATUS_PARTIAL: 0,
		STATUS_DATA_ONLY: 0,
		STATUS_PENDING: 0,
	}
	for beast_id in CONTRACTS.keys():
		var status := get_status(StringName(beast_id))
		result[status] = int(result.get(status, 0)) + 1
	return result


static func validate_combat_preflight(
	beast_data: KarmanyBeastData,
	context: KarmanyBeastCombatContext
) -> String:
	if beast_data == null or context == null:
		return "Bestia o contexto invalido para reglas F44.3."
	if is_runtime_excluded(beast_data.beast_id):
		return "La Bestia %s permanece excluida del runtime F44.3." % String(beast_data.beast_id)
	if beast_data.beast_id == &"B-22" and context.book_level < 2:
		return "B-22 Custodio del Santuario requiere Libro II o superior."
	return ""


static func apply_combat_preflight(
	beast_data: KarmanyBeastData,
	context: KarmanyBeastCombatContext
) -> Dictionary:
	var token: Dictionary = {
		"beast_id": &"",
		"beast_defense_bonus": 0,
		"risk_repeat_locked": false,
		"risk_modify_locked": false,
	}
	if beast_data == null or context == null or is_runtime_excluded(beast_data.beast_id):
		return token

	context.beast_defense_bonus = 0
	context.risk_repeat_locked = false
	context.risk_modify_locked = false
	token["beast_id"] = beast_data.beast_id

	match beast_data.beast_id:
		&"B-02":
			if context.risk_roll != 0:
				context.beast_defense_bonus = 2
				token["beast_defense_bonus"] = 2
		&"B-23":
			context.risk_repeat_locked = true
			context.risk_modify_locked = true
			token["risk_repeat_locked"] = true
			token["risk_modify_locked"] = true

	return token


static func apply_victory_specials(
	beast_data: KarmanyBeastData,
	attacker_karmany: KarmanyData,
	player: KarmanyPlayerState
) -> PackedStringArray:
	var applied := PackedStringArray()
	if beast_data == null or attacker_karmany == null or player == null:
		return applied
	if is_runtime_excluded(beast_data.beast_id):
		return applied

	if (
		beast_data.beast_id == &"B-07"
		and attacker_karmany.primary_type == KarmanyData.StrategicType.STABLE
		and player.gain_resource(KarmanyEffectData.ResourceType.MN, 2)
	):
		applied.append("stable_win_plus_2_mn")
	return applied
