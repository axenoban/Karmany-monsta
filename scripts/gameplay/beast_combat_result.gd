class_name KarmanyBeastCombatResult
extends RefCounted


enum Status {
	RESOLVED,
	INVALID_REQUEST,
	ACTION_NOT_AVAILABLE,
	ENTRY_FAILED
}


var status: Status = Status.INVALID_REQUEST
var message: String = ""
var beast_state: KarmanyBeastRuntimeState = null
var combat_result: KarmanyCombatResult = null

var action_consumed: bool = false
var beast_removed: bool = false
var remains_blocking: bool = false
var entered_tile_after_victory: bool = false
var entry_bonus_allowed: bool = false
var retreat_required: bool = false
var attacker_exhaustion_pending: bool = false

var reward_legacy_points_pending: int = 0
var reward_effect_results: Array[KarmanyEffectResult] = []
var defeat_effect_results: Array[KarmanyEffectResult] = []
var entry_effect_results: Array[KarmanyEffectResult] = []
var reward_consequence_ids: PackedStringArray = PackedStringArray()
var defeat_consequence_ids: PackedStringArray = PackedStringArray()

# F44.2B: consecuencia de perdida de recursos basicos estructurada. El caller
# conserva la eleccion concreta de MN/MR/EK; el runtime solo calcula cuantos
# recursos deben perderse despues de aplicar mitigaciones canonicas.
var basic_resource_loss_original: int = 0
var basic_resource_loss_pending: int = 0
var basic_resource_loss_reduction: int = 0
var basic_resource_loss_consequence_id: StringName = &""
var basic_resource_loss_mitigation_id: StringName = &""


func is_resolved() -> bool:
	return status == Status.RESOLVED and combat_result != null


func is_victory() -> bool:
	return is_resolved() and combat_result.is_victory()


func is_defeat() -> bool:
	return is_resolved() and combat_result.is_defeat()


func has_pending_basic_resource_loss() -> bool:
	return is_defeat() and basic_resource_loss_pending > 0
