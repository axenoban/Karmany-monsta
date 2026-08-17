class_name KarmanyBeastCombatContext
extends RefCounted


var turn_manager: KarmanyTurnManager = null
var action_cost: int = 1
var action_id: StringName = &"combat_beast"

var instinct_roll: int = 0
var risk_authorized: bool = false
var risk_roll: int = 0
var combat_modifiers: KarmanyCombatPowerModifiers = KarmanyCombatPowerModifiers.new()
var effect_context: KarmanyEffectContext = null

# F44.3: datos de preflight de Bestias. El nivel de Libro se resuelve desde el
# coordinador y los bloqueos de Riesgo quedan visibles para cualquier UI futura.
var book_level: int = 1
var beast_defense_bonus: int = 0
var risk_repeat_locked: bool = false
var risk_modify_locked: bool = false

var enter_after_victory: bool = false
var moving_unit_id: StringName = &""


func is_valid() -> bool:
	if instinct_roll < 1 or instinct_roll > 6:
		return false
	if combat_modifiers == null:
		return false
	if book_level < KarmanyBookProgressState.MIN_LEVEL or book_level > KarmanyBookProgressState.MAX_LEVEL:
		return false
	if beast_defense_bonus < 0:
		return false
	if action_cost < 0:
		return false
	if action_cost > 0:
		if turn_manager == null or action_id == &"":
			return false
	if risk_roll != 0:
		if not risk_authorized:
			return false
		if risk_roll < 1 or risk_roll > 6:
			return false
	if enter_after_victory and moving_unit_id == &"":
		return false
	return true
