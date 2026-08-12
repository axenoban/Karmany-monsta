class_name KarmanyPvpCombatContext
extends RefCounted


const ACTION_ID_PVP: StringName = &"combat_pvp"


var turn_manager: KarmanyTurnManager = null
var board_state: KarmanyBoardState = null
var authorization: KarmanyPvpAuthorizationContext = null
var truce_tracker: KarmanyPvpTruceTracker = null

var resonance_deck: KarmanyResonanceDeck = null
var resonance_usage_tracker: KarmanyResonanceUsageTracker = null
var effect_context: KarmanyEffectContext = null
var combat_id: StringName = &""

var attacker_modifiers: KarmanyCombatPowerModifiers = KarmanyCombatPowerModifiers.new()
var defender_modifiers: KarmanyCombatPowerModifiers = KarmanyCombatPowerModifiers.new()

var attacker_risk_authorized: bool = false
var attacker_risk_roll: int = 0
var defender_risk_authorized: bool = false
var defender_risk_roll: int = 0

var action_cost: int = 1
var reward_legacy_points: int = 2


func is_valid() -> bool:
	if turn_manager == null or board_state == null:
		return false
	if authorization == null or not authorization.is_valid():
		return false
	if truce_tracker == null:
		return false
	if resonance_deck == null or resonance_usage_tracker == null:
		return false
	if combat_id == &"":
		return false
	if attacker_modifiers == null or defender_modifiers == null:
		return false
	if action_cost <= 0 or reward_legacy_points < 0:
		return false
	return true
