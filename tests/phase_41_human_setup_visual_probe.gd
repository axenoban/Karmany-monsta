extends Node


@onready var prototype: KarmanyPhase41HumanSetupBridge = $Phase41HumanSetupPrototype


func _enter_tree() -> void:
	get_window().size = Vector2i(1152, 648)


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 41 VISUAL PROBE")
	print("================================")
	print("Ventana inicial: 1152x648")
	print("1 = 1152x648 | 2 = 1280x720")
	print("Flujo: comparar 3 -> seleccionar -> confirmar -> revisar Entrenador/Mision/Mano -> iniciar Ronda 1")
	if prototype == null or not prototype.setup_ok:
		push_error("FASE 41 VISUAL ERROR - el prototipo no completo su setup.")
		return
	print("FASE 41 VISUAL LISTA - setup privado visible y tablero bloqueado logicamente.")


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_1:
		_apply_size(Vector2i(1152, 648))
	elif event.keycode == KEY_2:
		_apply_size(Vector2i(1280, 720))


func _apply_size(value: Vector2i) -> void:
	get_window().size = value
	print("FASE 41 VISUAL -> ventana %dx%d" % [value.x, value.y])
