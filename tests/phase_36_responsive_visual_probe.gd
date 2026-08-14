extends Node3D


const SIZE_COMPACT: Vector2i = Vector2i(1152, 648)
const SIZE_HD: Vector2i = Vector2i(1280, 720)

@onready var phase_36: KarmanyPhase36MatchUxBridge = $Phase36MatchUxPrototype


func _ready() -> void:
	_apply_size(SIZE_COMPACT)
	await get_tree().process_frame
	await get_tree().process_frame
	if phase_36 == null or not phase_36.setup_ok:
		push_error("FASE 36 RESPONSIVE VISUAL ERROR: F36 no completo setup.")
		return
	print("")
	print("================================")
	print("FASE 36 RESPONSIVE VISUAL PROBE")
	print("1 = 1152x648 | 2 = 1280x720")
	print("Comprueba barra superior, panel derecho con scroll y barra inferior fija.")
	print("FASE 36 RESPONSIVE VISUAL LISTA")
	print("================================")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_apply_size(SIZE_COMPACT)
		KEY_2:
			_apply_size(SIZE_HD)


func _apply_size(value: Vector2i) -> void:
	get_window().size = value
	print("FASE 36 RESPONSIVE -> ventana %dx%d" % [value.x, value.y])
