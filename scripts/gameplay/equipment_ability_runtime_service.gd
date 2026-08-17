class_name KarmanyEquipmentAbilityRuntimeService
extends RefCounted


const STATUS_FULLY: StringName = &"FULLY_EXECUTABLE"
const STATUS_PARTIAL: StringName = &"PARTIAL"
const STATUS_DATA_ONLY: StringName = &"DATA_ONLY"
const STATUS_PENDING: StringName = &"PENDING"

# F44.4: contrato runtime explicito para los 36 Equipos materializados.
# Los 27 Resources bajo canonical_pending siguen aislados del runtime directo.
# Los Equipos directos solo se marcan FULLY cuando su regla completa ya tiene
# un camino ejecutable demostrado; no se infieren efectos desde rules_text.
const CONTRACTS: Dictionary = {
	&"EQ-01": {"status": STATUS_FULLY, "hook": &"automatic_beast_power", "excluded": false, "reason": ""},
	&"EQ-02": {"status": STATUS_PARTIAL, "hook": &"first_zero_resonance_round", "excluded": false, "reason": "modificador estructurado; falta seguimiento de primera Resonancia +0 por ronda"},
	&"EQ-03": {"status": STATUS_PARTIAL, "hook": &"after_explore_next_combat", "excluded": false, "reason": "modificador estructurado; falta ciclo de vida del trigger despues de Explorar"},
	&"EQ-04": {"status": STATUS_PARTIAL, "hook": &"after_pvp_draw_resonance", "excluded": false, "reason": "regla canonica directa; falta hook posterior a PvP para robar Resonancia"},
	&"EQ-05": {"status": STATUS_PARTIAL, "hook": &"before_combat_resonance_filter", "excluded": false, "reason": "regla canonica directa; falta selector roba 2/conserva 1 con limite por ronda"},
	&"EQ-06": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-07": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-08": {"status": STATUS_PARTIAL, "hook": &"resonance_played_power", "excluded": false, "reason": "modificador estructurado; falta propagar de forma canonica el trigger resonance_played al combate"},
	&"EQ-09": {"status": STATUS_PARTIAL, "hook": &"boss_legendary_power", "excluded": false, "reason": "modificador estructurado; rama Jefe conectada en F44.4, cobertura Legendaria permanece fuera de este resolver"},
	&"EQ-10": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-11": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-12": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-13": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-14": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-15": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-16": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-17": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-18": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-19": {"status": STATUS_PARTIAL, "hook": &"collect_mr_once_round", "excluded": false, "reason": "regla canonica directa; falta hook de Recolectar MR con seguimiento por ronda"},
	&"EQ-20": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-21": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-22": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-23": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-24": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-25": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-26": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-27": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-28": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-29": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-30": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-31": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-32": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-33": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-34": {"status": STATUS_PARTIAL, "hook": &"legendary_power", "excluded": false, "reason": "regla canonica directa; falta representacion estructurada y conexion al combate Legendario"},
	&"EQ-35": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"EQ-36": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
}


static func has_contract(equipment_id: StringName) -> bool:
	return CONTRACTS.has(equipment_id)


static func get_contract(equipment_id: StringName) -> Dictionary:
	var value: Variant = CONTRACTS.get(equipment_id, {})
	return value.duplicate(true) if value is Dictionary else {}


static func get_status(equipment_id: StringName) -> StringName:
	var contract := get_contract(equipment_id)
	return StringName(contract.get("status", STATUS_PENDING))


static func is_runtime_excluded(equipment_id: StringName) -> bool:
	var contract := get_contract(equipment_id)
	return bool(contract.get("excluded", true))


static func get_contract_counts() -> Dictionary:
	var result := {
		STATUS_FULLY: 0,
		STATUS_PARTIAL: 0,
		STATUS_DATA_ONLY: 0,
		STATUS_PENDING: 0,
	}
	for equipment_id in CONTRACTS.keys():
		var status := get_status(StringName(equipment_id))
		result[status] = int(result.get(status, 0)) + 1
	return result


static func resolve_beast_target_type(beast_data: KarmanyBeastData) -> int:
	if beast_data != null and beast_data.is_boss():
		return KarmanyCombatRequest.TargetType.BOSS
	return KarmanyCombatRequest.TargetType.BEAST
