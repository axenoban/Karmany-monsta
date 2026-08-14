extends Node3D


const COMPACT_SIZE: Vector2i = Vector2i(1152, 648)

@onready var phase_37: KarmanyPhase37ContentPreviewBridge = $Phase37ContentPreviewPrototype


func _ready() -> void:
	get_window().size = COMPACT_SIZE
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if phase_37 == null or not phase_37.setup_ok:
		push_error("FASE 37 VISUAL ERROR: no se pudo preparar la partida Alpha.")
		return

	print("")
	print("================================")
	print("FASE 37 VISUAL LISTA - 4P / 1152x648")
	print("Selecciona una N oculta: solo debe mostrar OCULTA + nivel.")
	print("Explorala: despues deben aparecer Nombre / ENTRADA / INTERACTUAR / LIMITACION.")
	print("Usa Interactuar o Mover y compara el resultado con CONSECUENCIAS.")
	print("P2 -> P4 permite observar varias rondas sin depender del log tecnico.")
	print("================================")
