class_name KarmanyResonanceUseContext
extends RefCounted


const WINDOW_COMBAT: StringName = &"combat"
const WINDOW_EXPLORATION: StringName = &"exploration"
const WINDOW_MOVEMENT: StringName = &"movement"
const WINDOW_BOND: StringName = &"bond"
const WINDOW_REACTION: StringName = &"reaction"
const WINDOW_END_TURN: StringName = &"end_turn"


var window_id: StringName = &""
var context_tags: PackedStringArray = PackedStringArray()
var combat_id: StringName = &""
var combat_modifiers: KarmanyCombatPowerModifiers = null
var effect_context: KarmanyEffectContext = null
var usage_tracker: KarmanyResonanceUsageTracker = null


func is_valid() -> bool:
	if window_id == &"":
		return false

	if window_id == WINDOW_COMBAT:
		if combat_id == &"" or usage_tracker == null:
			return false

	return true


func is_combat_window() -> bool:
	return window_id == WINDOW_COMBAT
