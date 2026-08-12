class_name KarmanyEffectContext
extends RefCounted


var draw_cards_handler: Callable = Callable()
var modify_state_handler: Callable = Callable()
var activate_condition_handler: Callable = Callable()
var trigger_encounter_handler: Callable = Callable()


func has_draw_cards_handler() -> bool:
	return draw_cards_handler.is_valid()


func has_modify_state_handler() -> bool:
	return modify_state_handler.is_valid()


func has_activate_condition_handler() -> bool:
	return activate_condition_handler.is_valid()


func has_trigger_encounter_handler() -> bool:
	return trigger_encounter_handler.is_valid()
