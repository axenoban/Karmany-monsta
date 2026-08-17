class_name KarmanyTrainerAbilityRuntimeService
extends RefCounted


const STATUS_FULLY: StringName = &"FULLY_EXECUTABLE"
const STATUS_PARTIAL: StringName = &"PARTIAL"
const STATUS_DATA_ONLY: StringName = &"DATA_ONLY"
const STATUS_PENDING: StringName = &"PENDING"

# F44.7: contrato runtime por Entrenador sobre los Resources v0.74 reales.
# Cada passive_id/active_id/setup_bonus_id debe aparecer exactamente en una de
# estas categorias: implemented, partial o excluded. Asi ninguna regla textual
# puede parecer ejecutable por accidente.
const CONTRACTS: Dictionary = {
	&"alderion": {
		"status": STATUS_DATA_ONLY,
		"implemented": [],
		"partial": [],
		"excluded": ["alderion_exploration_passive", "alderion_resonance_after_explore", "alderion_setup_peek"],
		"reason": "Requiere mirar losetas ocultas y elecciones de recompensa/orden que el runtime humano aun no representa."
	},
	&"lyra": {
		"status": STATUS_DATA_ONLY,
		"implemented": [],
		"partial": [],
		"excluded": ["lyra_bond_passive", "lyra_call_and_bond", "lyra_setup_karmany_peek"],
		"reason": "Requiere elegir descuento o carta extra, encadenar Vincular dentro de Llamar Karmany y manipular la cima del mazo."
	},
	&"dorian": {
		"status": STATUS_PARTIAL,
		"implemented": ["dorian_setup_resonance"],
		"partial": [],
		"excluded": ["dorian_pvp_win_draw", "dorian_catchup_pvp"],
		"reason": "El setup roba exactamente 1 Resonancia; la pasiva requiere descarte elegido y la activa una autorizacion PvP propia con comparacion de PL."
	},
	&"nara": {
		"status": STATUS_DATA_ONLY,
		"implemented": [],
		"partial": [],
		"excluded": ["nara_craft_discount", "nara_remote_craft", "nara_setup_equipment_peek"],
		"reason": "Descuento y crafteo remoto necesitan seleccionar recurso/carta y ampliar legalidad; el setup requiere inspeccion privada del mazo."
	},
	&"maelis": {
		"status": STATUS_PARTIAL,
		"implemented": [],
		"partial": ["maelis_setup_filter"],
		"excluded": ["maelis_zero_draw", "maelis_zero_to_four"],
		"reason": "El setup Alpha roba y descarta 1, pero automatiza cual se descarta; las ventanas de Resonancia +0 aun no estan conectadas."
	},
	&"kael": {
		"status": STATUS_DATA_ONLY,
		"implemented": [],
		"partial": [],
		"excluded": ["kael_beast_power", "kael_beast_reward_choice", "kael_setup_beast_peek"],
		"reason": "La pasiva depende del historial PvP y categoria del primer combate; activa/setup requieren eleccion e inspeccion de Pila de Bestias."
	},
	&"saira": {
		"status": STATUS_DATA_ONLY,
		"implemented": [],
		"partial": [],
		"excluded": ["saira_new_tile_bonus", "saira_move_followup", "saira_setup_peek"],
		"reason": "Pasiva y activa contienen elecciones de recurso/Poder/mirada/movimiento; setup requiere informacion oculta."
	},
	&"oryn": {
		"status": STATUS_PARTIAL,
		"implemented": ["oryn_setup_resonance"],
		"partial": [],
		"excluded": ["oryn_risk_passive", "oryn_risk_authorization"],
		"reason": "El setup roba exactamente 1 Resonancia; pasiva/activa necesitan una ventana canonica completa del Dado de Riesgo y su limite de PL."
	},
}


static func has_contract(trainer_id: StringName) -> bool:
	return CONTRACTS.has(trainer_id)


static func get_contract(trainer_id: StringName) -> Dictionary:
	var value: Variant = CONTRACTS.get(trainer_id, {})
	return value.duplicate(true) if value is Dictionary else {}


static func get_status(trainer_id: StringName) -> StringName:
	var contract := get_contract(trainer_id)
	return StringName(contract.get("status", STATUS_PENDING))


static func get_contract_counts() -> Dictionary:
	var result := {
		STATUS_FULLY: 0,
		STATUS_PARTIAL: 0,
		STATUS_DATA_ONLY: 0,
		STATUS_PENDING: 0,
	}
	for trainer_id in CONTRACTS.keys():
		var status := get_status(StringName(trainer_id))
		result[status] = int(result.get(status, 0)) + 1
	return result


static func get_implemented_clauses(trainer_id: StringName) -> Array:
	return _get_clause_array(trainer_id, "implemented")


static func get_partial_clauses(trainer_id: StringName) -> Array:
	return _get_clause_array(trainer_id, "partial")


static func get_excluded_clauses(trainer_id: StringName) -> Array:
	return _get_clause_array(trainer_id, "excluded")


static func get_clause_coverage(trainer_id: StringName, clause_id: StringName) -> StringName:
	var text := String(clause_id)
	if get_implemented_clauses(trainer_id).has(text):
		return &"implemented"
	if get_partial_clauses(trainer_id).has(text):
		return &"partial"
	if get_excluded_clauses(trainer_id).has(text):
		return &"excluded"
	return &"missing"


static func _get_clause_array(trainer_id: StringName, key: String) -> Array:
	var contract := get_contract(trainer_id)
	var value: Variant = contract.get(key, [])
	return value.duplicate() if value is Array else []
