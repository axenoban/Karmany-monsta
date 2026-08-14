class_name KarmanyAiActionCandidate
extends RefCounted


enum ActionType {
	MOVE,
	EXPLORE,
	INTERACT,
	IMPROVE_BOOK,
	BOND_PAYMENT,
	CRAFT_EQUIPMENT,
	FORGE,
	FIGHT_BEAST,
	PVP,
	AETERNA,
	CALL_KARMANY,
	BOND_COMBAT
}


var action_type: int = -1
var target_coord: Vector2i = Vector2i.ZERO
var option_index: int = -1
var payload: Dictionary = {}
var debug_label: String = ""

# Valores abstractos que los perfiles ponderan de manera diferente.
# No son reglas del juego ni modifican el resultado de una accion.
var exploration_value: float = 0.0
var economy_value: float = 0.0
var aggression_value: float = 0.0
var opportunity_value: float = 0.0
var progress_value: float = 0.0
var risk_value: float = 0.0
var base_utility: float = 0.0


func is_valid() -> bool:
	return (
		action_type >= ActionType.MOVE
		and action_type <= ActionType.BOND_COMBAT
		and not debug_label.is_empty()
	)


func get_action_name() -> String:
	match action_type:
		ActionType.MOVE:
			return "Mover"
		ActionType.EXPLORE:
			return "Explorar"
		ActionType.INTERACT:
			return "Interactuar"
		ActionType.IMPROVE_BOOK:
			return "Mejorar Libro"
		ActionType.BOND_PAYMENT:
			return "Vincular"
		ActionType.CRAFT_EQUIPMENT:
			return "Craftear Equipo"
		ActionType.FORGE:
			return "Usar Forja"
		ActionType.FIGHT_BEAST:
			return "Combatir Bestia"
		ActionType.PVP:
			return "PvP"
		ActionType.AETERNA:
			return "Aeterna"
		ActionType.CALL_KARMANY:
			return "Llamar Karmany"
		ActionType.BOND_COMBAT:
			return "Vincular por combate"
	return "Accion IA"
