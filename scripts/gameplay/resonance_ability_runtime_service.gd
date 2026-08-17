class_name KarmanyResonanceAbilityRuntimeService
extends RefCounted


const STATUS_FULLY: StringName = &"FULLY_EXECUTABLE"
const STATUS_PARTIAL: StringName = &"PARTIAL"
const STATUS_DATA_ONLY: StringName = &"DATA_ONLY"
const STATUS_PENDING: StringName = &"PENDING"

# F44.5: contrato runtime explicito para las 40 Resonancias materializadas.
# Las 27 Resources de canonical_pending siguen aisladas. Las cartas directas
# solo se promueven a FULLY cuando toda su regla tiene un camino ejecutable.
const CONTRACTS: Dictionary = {
	&"R-01": {"status": STATUS_FULLY, "hook": &"combat_power_win_ek", "excluded": false, "reason": ""},
	&"R-02": {"status": STATUS_PARTIAL, "hook": &"risk_authorization_discard", "excluded": false, "reason": "Poder y descarte estan estructurados; falta cerrar bloqueo de repeticion/modificacion del Dado de Riesgo en todos los combates"},
	&"R-03": {"status": STATUS_PARTIAL, "hook": &"tile_recent_draw_filter", "excluded": false, "reason": "Poder y robo/descarte estan estructurados; falta propagar de forma universal el estado de loseta revelada/explorada este turno"},
	&"R-04": {"status": STATUS_FULLY, "hook": &"beast_bonus_power", "excluded": false, "reason": ""},
	&"R-05": {"status": STATUS_PARTIAL, "hook": &"pvp_risk_authorization", "excluded": false, "reason": "Restriccion PvP y descarte estan estructurados; falta cerrar autorizacion y exclusividad del Dado de Riesgo en el flujo PvP"},
	&"R-06": {"status": STATUS_PARTIAL, "hook": &"book_draw_filter", "excluded": false, "reason": "Poder base ejecutable; robo 2/descarta 1 con Libro II-III aun no esta estructurado en el Resource"},
	&"R-07": {"status": STATUS_PARTIAL, "hook": &"exact_defense_draw", "excluded": false, "reason": "Poder base ejecutable; falta comprobar causalmente que esta carta produjo la igualdad exacta para habilitar el robo"},
	&"R-08": {"status": STATUS_FULLY, "hook": &"stable_karmany_power", "excluded": false, "reason": ""},
	&"R-09": {"status": STATUS_FULLY, "hook": &"beast_win_mr", "excluded": false, "reason": ""},
	&"R-10": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-11": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-12": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-13": {"status": STATUS_PARTIAL, "hook": &"prevent_retreat_on_loss", "excluded": false, "reason": "La condicion de prevencion se emite; falta consumirla en las rutas reales de retroceso de Bestia/PvP/Legendario"},
	&"R-14": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-15": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-16": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-17": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-18": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-19": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-20": {"status": STATUS_FULLY, "hook": &"loss_draw_filter", "excluded": false, "reason": ""},
	&"R-21": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-22": {"status": STATUS_PARTIAL, "hook": &"exploration_peek_filter", "excluded": false, "reason": "Robo/descarte y condicion de mirar estan estructurados; falta resolver la seleccion real de loseta y la segunda mirada condicional de Nivel 1"},
	&"R-23": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-24": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-25": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-26": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-27": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-28": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-29": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-30": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-31": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-32": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-33": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-34": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-35": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-36": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-37": {"status": STATUS_FULLY, "hook": &"beast_only_power", "excluded": false, "reason": ""},
	&"R-38": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-39": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
	&"R-40": {"status": STATUS_PARTIAL, "hook": &"canonical_pending", "excluded": true, "reason": "Resource aislado en canonical_pending; regla aun no promovida a runtime directo"},
}


static func has_contract(resonance_id: StringName) -> bool:
	return CONTRACTS.has(resonance_id)


static func get_contract(resonance_id: StringName) -> Dictionary:
	var value: Variant = CONTRACTS.get(resonance_id, {})
	return value.duplicate(true) if value is Dictionary else {}


static func get_status(resonance_id: StringName) -> StringName:
	var contract := get_contract(resonance_id)
	return StringName(contract.get("status", STATUS_PENDING))


static func is_runtime_excluded(resonance_id: StringName) -> bool:
	var contract := get_contract(resonance_id)
	return bool(contract.get("excluded", false))


static func get_contract_counts() -> Dictionary:
	var result := {
		STATUS_FULLY: 0,
		STATUS_PARTIAL: 0,
		STATUS_DATA_ONLY: 0,
		STATUS_PENDING: 0,
	}
	for resonance_id in CONTRACTS.keys():
		var status := get_status(StringName(resonance_id))
		result[status] = int(result.get(status, 0)) + 1
	return result


static func enrich_combat_context_tags(
	base_tags: PackedStringArray,
	active_karmany: KarmanyData
) -> PackedStringArray:
	var result: PackedStringArray = base_tags.duplicate()
	if (
		active_karmany != null
		and active_karmany.primary_type == KarmanyData.StrategicType.STABLE
		and not result.has("stable_karmany")
	):
		result.append("stable_karmany")
	return result


static func validate_play_context(
	card: KarmanyResonanceData,
	context_tags: PackedStringArray
) -> String:
	if card == null:
		return "Resonancia invalida para F44.5."
	if has_contract(card.resonance_id) and is_runtime_excluded(card.resonance_id):
		return "La Resonancia %s permanece excluida del runtime F44.5." % String(card.resonance_id)
	if card.resonance_id == &"R-37" and not context_tags.has("target_beast"):
		return "R-37 Instinto de Caza solo puede jugarse contra Bestia."
	return ""
