class_name KarmanyAeternaResult
extends RefCounted


enum Status {
	RESOLVED,
	INVALID_REQUEST,
	NOT_AT_SANCTUARY,
	TOO_EARLY,
	BOOK_LEVEL_REQUIRED,
	FA_REQUIRED,
	NO_ACTIVE_KARMANY,
	ALREADY_DEFEATED,
	ACTION_NOT_AVAILABLE,
	ATTUNEMENT_NOT_AVAILABLE,
	ALREADY_USED,
	REWARD_NOT_AVAILABLE
}

enum Outcome {
	NONE,
	SANCTUARY_ATTUNEMENT,
	AETERNA_SYNC,
	COMBAT_VICTORY,
	COMBAT_DEFEAT,
	POST_DEFEAT_EK
}

enum RewardChoice {
	NONE,
	ANCESTRAL_EQUIPMENT,
	RESONANCES
}


var status: Status = Status.INVALID_REQUEST
var outcome: Outcome = Outcome.NONE
var message: String = ""

var action_consumed: bool = false
var fa_spent: int = 0
var combat_result: KarmanyCombatResult = null
var legacy_award_result: KarmanyLegacyPointsAwardResult = null

var reward_choice_required: bool = false
var reward_choice: RewardChoice = RewardChoice.NONE
var reward_resolved: bool = false
var ancestral_equipment_id: StringName = &""
var replaced_equipment_id: StringName = &""
var resonance_cards_drawn: int = 0
var resonance_discard_pending: int = 0

var basic_resources_discard_pending: int = 0
var retreat_required: bool = false
var post_defeat_ek_gained: int = 0


func is_resolved() -> bool:
	return status == Status.RESOLVED


func is_victory() -> bool:
	return is_resolved() and outcome == Outcome.COMBAT_VICTORY


func is_defeat() -> bool:
	return is_resolved() and outcome == Outcome.COMBAT_DEFEAT
