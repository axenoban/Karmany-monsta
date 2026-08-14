class_name KarmanyPlayerControllerType
extends RefCounted


enum Kind {
	HUMAN,
	AI
}


static func get_display_name(kind: int) -> String:
	match kind:
		Kind.HUMAN:
			return "HUMANO"
		Kind.AI:
			return "IA"
	return "DESCONOCIDO"
