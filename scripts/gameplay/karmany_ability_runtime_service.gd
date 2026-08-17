class_name KarmanyAbilityRuntimeService
extends RefCounted


const STATUS_FULLY: StringName = &"FULLY_EXECUTABLE"
const STATUS_PARTIAL: StringName = &"PARTIAL"
const STATUS_DATA_ONLY: StringName = &"DATA_ONLY"
const STATUS_PENDING: StringName = &"PENDING"

const CONSEQUENCE_DISCARD_2_BASIC: StringName = &"discard_2_basic_resources_choice"
const CONSEQUENCE_DISCARD_3_BASIC: StringName = &"discard_3_basic_resources_choice"

# F44.2: contrato explicito para los 28 Karmany canonicos v0.74.
# PARTIAL significa que el Resource conserva la regla canonica, pero el flujo
# indicado en reason aun no posee un punto de integracion seguro en runtime.
# Esos casos NO se promueven silenciosamente como ejecutables.
const CONTRACTS: Dictionary = {
	&"K-01": {"status": STATUS_FULLY, "hook": &"beast_combat", "reason": ""},
	&"K-02": {"status": STATUS_PARTIAL, "hook": &"beast_defeat_choice", "reason": "falta selector de evitar retroceso o reducir perdida"},
	&"K-03": {"status": STATUS_PARTIAL, "hook": &"beast_combat_risk", "reason": "autoriza Riesgo, pero falta decision de lanzamiento en controlador"},
	&"K-04": {"status": STATUS_PARTIAL, "hook": &"combat_resonance_filter", "reason": "falta flujo de descartar/robar/elegir Resonancia en combate"},
	&"K-05": {"status": STATUS_PARTIAL, "hook": &"collect_mn", "reason": "efecto estructurado existe; falta evento central de recoleccion Karmany"},
	&"K-06": {"status": STATUS_PARTIAL, "hook": &"after_explore_n1", "reason": "falta selector privado de loseta oculta adyacente"},
	&"K-07": {"status": STATUS_PARTIAL, "hook": &"defeat_resource_loss", "reason": "mitigacion estructurada contra derrota de Bestia cubierta; falta extender el trigger generico a otras derrotas"},
	&"K-08": {"status": STATUS_PARTIAL, "hook": &"resonance_draw", "reason": "falta evento central robar+descartar Resonancia"},
	&"K-09": {"status": STATUS_FULLY, "hook": &"passive_none", "reason": ""},
	&"K-10": {"status": STATUS_FULLY, "hook": &"beast_combat_n2", "reason": ""},
	&"K-11": {"status": STATUS_PARTIAL, "hook": &"beast_combat_risk", "reason": "falta recompensa PL unica y decision de Riesgo"},
	&"K-12": {"status": STATUS_PARTIAL, "hook": &"defeat_beast_resource_loss", "reason": "mitigacion para consecuencias estructuradas cubierta; faltan Bestias canonical_pending sin consequence IDs ejecutables"},
	&"K-13": {"status": STATUS_FULLY, "hook": &"beast_combat_medium", "reason": ""},
	&"K-14": {"status": STATUS_PARTIAL, "hook": &"combat_won", "reason": "falta evento post-combate para robo de Resonancia"},
	&"K-15": {"status": STATUS_PARTIAL, "hook": &"tile_collect_conversion", "reason": "requiere eleccion de recurso obtenido y destino"},
	&"K-16": {"status": STATUS_PARTIAL, "hook": &"beast_combat_risk", "reason": "autoriza Riesgo; falta descarte adicional de Resonancia en cara 1"},
	&"K-17": {"status": STATUS_FULLY, "hook": &"pvp_defense", "reason": ""},
	&"K-18": {"status": STATUS_PARTIAL, "hook": &"beast_defeat_choice", "reason": "requiere elegir descarte de Resonancia en lugar de recursos"},
	&"K-19": {"status": STATUS_PARTIAL, "hook": &"pvp_resonance_order", "reason": "falta ventana PvP secuencial de declaracion"},
	&"K-20": {"status": STATUS_PARTIAL, "hook": &"beast_combat_risk", "reason": "autoriza Riesgo; falta eleccion/aplicacion de 2 recursos al ganar con 6"},
	&"K-21": {"status": STATUS_PARTIAL, "hook": &"combat_loss", "reason": "la mitigacion contra Bestia y el consumo de la primera derrota PvP estan integrados; faltan Aeterna y combate contra Karmany sin vincular"},
	&"K-22": {"status": STATUS_FULLY, "hook": &"high_tier_combat", "reason": ""},
	&"K-23": {"status": STATUS_PARTIAL, "hook": &"combat_resonance_zero", "reason": "falta adaptador de Resonancia +0 a +4 una vez por combate"},
	&"K-24": {"status": STATUS_PARTIAL, "hook": &"combat_resonance_replay", "reason": "falta replay seguro de Resonancia usada una vez por partida"},
	&"K-25": {"status": STATUS_PARTIAL, "hook": &"after_explore", "reason": "falta estado temporal +2 proximo combate / robo fin de turno"},
	&"K-26": {"status": STATUS_PARTIAL, "hook": &"forced_discard", "reason": "falta ventana de pago para cancelar descarte forzado"},
	&"K-27": {"status": STATUS_PARTIAL, "hook": &"collect_conversion", "reason": "requiere eleccion de conversion en primera recoleccion MN/MR"},
	&"K-28": {"status": STATUS_PARTIAL, "hook": &"beast_combat_risk", "reason": "autoriza Riesgo solo contra Bestias; falta eleccion de recurso de victoria"},
}

static var _used_round_keys: Dictionary = {}


static func has_contract(karmany_id: StringName) -> bool:
	return CONTRACTS.has(karmany_id)


static func get_contract(karmany_id: StringName) -> Dictionary:
	var value: Variant = CONTRACTS.get(karmany_id, {})
	return value.duplicate(true) if value is Dictionary else {}


static func get_status(karmany_id: StringName) -> StringName:
	var contract := get_contract(karmany_id)
	return StringName(contract.get("status", STATUS_PENDING))


static func get_contract_counts() -> Dictionary:
	var result := {
		STATUS_FULLY: 0,
		STATUS_PARTIAL: 0,
		STATUS_DATA_ONLY: 0,
		STATUS_PENDING: 0,
	}
	for karmany_id in CONTRACTS.keys():
		var status := get_status(StringName(karmany_id))
		result[status] = int(result.get(status, 0)) + 1
	return result


static func clear_test_tracking() -> void:
	_used_round_keys.clear()


static func apply_beast_combat_preflight(
	karmany_data: KarmanyData,
	beast_data: KarmanyBeastData,
	target_tile: KarmanyTileData,
	round_number: int,
	match_scope_id: int,
	context: KarmanyBeastCombatContext
) -> Dictionary:
	var token: Dictionary = {
		"karmany_id": &"",
		"power_bonus": 0,
		"risk_authorized": false,
		"usage_key": "",
	}
	if karmany_data == null or beast_data == null or context == null:
		return token
	var karmany_id: StringName = karmany_data.karmany_id
	if not has_contract(karmany_id):
		return token
	token["karmany_id"] = karmany_id

	var power_bonus: int = 0
	match karmany_id:
		&"K-01":
			var usage_key := "%d:%s:r%d:beast_power" % [match_scope_id, String(karmany_id), round_number]
			if not _used_round_keys.has(usage_key):
				power_bonus = 2
				token["usage_key"] = usage_key
		&"K-10":
			if target_tile != null and target_tile.level == KarmanyTileData.TileLevel.N2:
				power_bonus = 2
		&"K-13":
			if beast_data.tier == KarmanyBeastData.Tier.MEDIUM:
				power_bonus = 2
		&"K-22":
			if beast_data.tier in [KarmanyBeastData.Tier.COMPLEX, KarmanyBeastData.Tier.BOSS]:
				power_bonus = 2

	if karmany_id in [&"K-03", &"K-11", &"K-16", &"K-20", &"K-28"]:
		context.risk_authorized = true
		token["risk_authorized"] = true

	if power_bonus != 0:
		context.combat_modifiers.other_power += power_bonus
		token["power_bonus"] = power_bonus
	return token


static func commit_beast_combat(token: Dictionary, combat_resolved: bool) -> void:
	if not combat_resolved:
		return
	var usage_key: String = String(token.get("usage_key", ""))
	if not usage_key.is_empty():
		_used_round_keys[usage_key] = true


static func get_pvp_defender_power_bonus(karmany_data: KarmanyData) -> int:
	if karmany_data == null or karmany_data.karmany_id != &"K-17":
		return 0
	return 2


static func get_legendary_combat_power_bonus(
	karmany_data: KarmanyData,
	target_type: int
) -> int:
	if karmany_data == null or karmany_data.karmany_id != &"K-22":
		return 0
	if target_type != KarmanyCombatRequest.TargetType.LEGENDARY:
		return 0
	return 2


static func commit_combat_loss(
	karmany_data: KarmanyData,
	player_id: StringName,
	round_number: int,
	match_scope_id: int,
	combat_defeat_resolved: bool
) -> bool:
	if not combat_defeat_resolved or karmany_data == null:
		return false
	if player_id == &"" or round_number <= 0 or match_scope_id <= 0:
		return false
	if karmany_data.karmany_id != &"K-21":
		return false
	var usage_key := "%d:%s:%s:r%d:first_combat_loss" % [
		match_scope_id,
		String(player_id),
		String(karmany_data.karmany_id),
		round_number,
	]
	if _used_round_keys.has(usage_key):
		return false
	_used_round_keys[usage_key] = true
	return true


static func apply_beast_defeat_resource_policy(
	karmany_data: KarmanyData,
	beast_data: KarmanyBeastData,
	player_id: StringName,
	round_number: int,
	match_scope_id: int,
	consequence_ids: PackedStringArray
) -> Dictionary:
	var consequence_id: StringName = _find_basic_resource_loss_consequence(consequence_ids)
	var original_amount: int = _basic_resource_loss_amount(consequence_id)
	var policy: Dictionary = {
		"karmany_id": &"",
		"consequence_id": consequence_id,
		"original_amount": original_amount,
		"effective_amount": original_amount,
		"reduction": 0,
		"usage_key": "",
	}
	if karmany_data == null or beast_data == null:
		return policy
	if player_id == &"" or round_number <= 0:
		return policy
	var karmany_id: StringName = karmany_data.karmany_id
	policy["karmany_id"] = karmany_id
	if not has_contract(karmany_id):
		return policy

	var effective_amount: int = original_amount
	var reduction: int = 0
	var usage_key: String = ""
	match karmany_id:
		&"K-07":
			if original_amount > 0:
				usage_key = "%d:%s:%s:r%d:defeat_resource_loss" % [
					match_scope_id,
					String(player_id),
					String(karmany_id),
					round_number,
				]
				if not _used_round_keys.has(usage_key):
					reduction = mini(2, original_amount)
					effective_amount = original_amount - reduction
				else:
					usage_key = ""
		&"K-12":
			if (
				original_amount > 0
				and beast_data.tier in [KarmanyBeastData.Tier.MEDIUM, KarmanyBeastData.Tier.COMPLEX]
			):
				reduction = mini(2, original_amount)
				effective_amount = original_amount - reduction
		&"K-21":
			usage_key = "%d:%s:%s:r%d:first_combat_loss" % [
				match_scope_id,
				String(player_id),
				String(karmany_id),
				round_number,
			]
			if not _used_round_keys.has(usage_key):
				reduction = original_amount
				effective_amount = 0
			else:
				usage_key = ""

	policy["effective_amount"] = effective_amount
	policy["reduction"] = reduction
	policy["usage_key"] = usage_key
	return policy


static func commit_beast_defeat_resource_policy(policy: Dictionary, combat_defeat_resolved: bool) -> void:
	if not combat_defeat_resolved:
		return
	var usage_key: String = String(policy.get("usage_key", ""))
	if not usage_key.is_empty():
		_used_round_keys[usage_key] = true


static func _find_basic_resource_loss_consequence(consequence_ids: PackedStringArray) -> StringName:
	for consequence_value in consequence_ids:
		var consequence_id := StringName(consequence_value)
		if _basic_resource_loss_amount(consequence_id) > 0:
			return consequence_id
	return &""


static func _basic_resource_loss_amount(consequence_id: StringName) -> int:
	match consequence_id:
		CONSEQUENCE_DISCARD_2_BASIC:
			return 2
		CONSEQUENCE_DISCARD_3_BASIC:
			return 3
	return 0
