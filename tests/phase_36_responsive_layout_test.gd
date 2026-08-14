extends Node


const PHASE_36_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_36_match_ux_prototype.tscn"
)
const TEST_SIZES: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1280, 720)
]
const RECT_EPSILON: float = 2.0


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 36 RESPONSIVE LAYOUT TEST")
	print("================================")

	var original_size: Vector2i = get_window().size
	var ok: bool = true

	for requested_size in TEST_SIZES:
		get_window().size = requested_size
		await _wait_layout_frames(3)
		var size_ok: bool = await _validate_resolution(requested_size)
		ok = size_ok and ok

	get_window().size = original_size
	await _wait_layout_frames(2)

	print("")
	print("================================")
	if ok:
		print("FASE 36 RESPONSIVE OK - 1152x648 y 1280x720 mantienen HUD y controles operables.")
	else:
		push_error("FASE 36 RESPONSIVE ERROR - revisar el primer fallo de layout.")
	print("================================")


func _validate_resolution(requested_size: Vector2i) -> bool:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if (
		absf(viewport_size.x - float(requested_size.x)) > RECT_EPSILON
		or absf(viewport_size.y - float(requested_size.y)) > RECT_EPSILON
	):
		return _fail(
			"Viewport esperado %s pero Godot reporta %s."
			% [str(requested_size), str(viewport_size)]
		)

	var prototype := PHASE_36_SCENE.instantiate() as KarmanyPhase36MatchUxBridge
	if prototype == null:
		return _fail("No se pudo instanciar F36 en %s." % str(requested_size))
	add_child(prototype)
	await _wait_layout_frames(4)
	prototype.refresh_for_test()
	await _wait_layout_frames(2)

	if not prototype.setup_ok:
		prototype.queue_free()
		await _wait_layout_frames(2)
		return _fail("F36 no completo setup en %s." % str(requested_size))

	var ok: bool = true
	if prototype.phase_35.phase_34.trainer_units.size() != 4:
		ok = _fail("No siguen presentes los cuatro jugadores visuales en %s." % str(requested_size)) and ok

	if not prototype.get_turn_text().contains("RONDA"):
		ok = _fail("La barra superior perdio la ronda en %s." % str(requested_size)) and ok
	if not prototype.get_turn_text().contains("P1 HUMANO"):
		ok = _fail("La barra superior perdio el jugador activo en %s." % str(requested_size)) and ok
	if not prototype.get_turn_text().contains("ACCIONES"):
		ok = _fail("La barra superior perdio acciones restantes en %s." % str(requested_size)) and ok

	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	for control in prototype.get_critical_controls():
		if not _control_fully_inside(control, viewport_rect):
			ok = _fail(
				"Control critico fuera de viewport en %s: %s rect=%s"
				% [str(requested_size), control.name, str(control.get_global_rect())]
			) and ok

	if not _control_fully_inside(prototype.top_bar, viewport_rect):
		ok = _fail("Barra superior fuera del viewport en %s." % str(requested_size)) and ok
	if not _control_fully_inside(prototype.bottom_bar, viewport_rect):
		ok = _fail("Barra inferior fuera del viewport en %s." % str(requested_size)) and ok
	if not _control_fully_inside(prototype.right_panel, viewport_rect):
		ok = _fail("Panel derecho fuera del viewport en %s." % str(requested_size)) and ok

	# Fuerza una seleccion real para validar el caso de mayor altura del panel,
	# no solo el texto corto "SELECCION: ninguna".
	var runtime := prototype.get_runtime()
	var p1 := runtime.local_session.get_player_by_id(&"player_1")
	var phase_31 := prototype.phase_35.phase_34.phase_32.phase_31
	var selected_tile := phase_31.get_tile_view(p1.current_coord)
	if selected_tile == null:
		ok = _fail("No se pudo seleccionar la loseta actual de P1 en %s." % str(requested_size)) and ok
	else:
		selected_tile.tile_clicked.emit(selected_tile)
		await _wait_layout_frames(2)
		prototype.refresh_for_test()
		await _wait_layout_frames(2)

	prototype.right_scroll.scroll_vertical = 0
	prototype.set_alpha_tools_expanded(false)
	await _wait_layout_frames(2)
	var scroll_rect: Rect2 = prototype.right_scroll.get_global_rect()
	var required_right_controls: Array[Control] = [
		prototype.participants_label,
		prototype.location_label,
		prototype.selected_label,
		prototype.actions_label
	]
	for control in required_right_controls:
		if not _control_fully_inside(control, scroll_rect):
			ok = _fail(
				"Informacion principal requiere scroll inicial en %s: %s rect=%s clip=%s"
				% [str(requested_size), control.name, str(control.get_global_rect()), str(scroll_rect)]
			) and ok

	if prototype.board_space.size.x < viewport_size.x * 0.55:
		ok = _fail(
			"El tablero perdio prioridad horizontal en %s: %.1f px."
			% [str(requested_size), prototype.board_space.size.x]
		) and ok
	if prototype.board_space.size.y < viewport_size.y * 0.50:
		ok = _fail(
			"El tablero perdio prioridad vertical en %s: %.1f px."
			% [str(requested_size), prototype.board_space.size.y]
		) and ok
	if prototype.right_panel.size.x > viewport_size.x * 0.32:
		ok = _fail(
			"El panel derecho ocupa demasiado mapa en %s: %.1f px."
			% [str(requested_size), prototype.right_panel.size.x]
		) and ok

	prototype.set_alpha_tools_expanded(true)
	await _wait_layout_frames(2)
	var vertical_bar: VScrollBar = prototype.right_scroll.get_v_scroll_bar()
	var maximum_scroll: float = maxf(vertical_bar.max_value - vertical_bar.page, 0.0)
	if maximum_scroll > 1.0:
		prototype.right_scroll.scroll_vertical = int(maximum_scroll)
		await _wait_layout_frames(2)
		if prototype.right_scroll.scroll_vertical <= 0:
			ok = _fail("El panel derecho no permite desplazamiento en %s." % str(requested_size)) and ok
	else:
		var alpha_rect: Rect2 = prototype.alpha_tools_content.get_global_rect()
		if not _rect_inside(alpha_rect, scroll_rect):
			ok = _fail(
				"Herramientas Alpha no caben ni generan scroll en %s."
				% str(requested_size)
			) and ok

	prototype.set_alpha_tools_expanded(false)
	prototype.right_scroll.scroll_vertical = 0

	print(
		"Resolucion %dx%d | tablero %.0fx%.0f | panel %.0f px | controles criticos %d: %s"
		% [
			requested_size.x,
			requested_size.y,
			prototype.board_space.size.x,
			prototype.board_space.size.y,
			prototype.right_panel.size.x,
			prototype.get_critical_controls().size(),
			"OK" if ok else "ERROR"
		]
	)

	prototype.queue_free()
	await _wait_layout_frames(2)
	return ok


func _control_fully_inside(control: Control, outer_rect: Rect2) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	return _rect_inside(control.get_global_rect(), outer_rect)


func _rect_inside(inner_rect: Rect2, outer_rect: Rect2) -> bool:
	return (
		inner_rect.position.x >= outer_rect.position.x - RECT_EPSILON
		and inner_rect.position.y >= outer_rect.position.y - RECT_EPSILON
		and inner_rect.end.x <= outer_rect.end.x + RECT_EPSILON
		and inner_rect.end.y <= outer_rect.end.y + RECT_EPSILON
	)


func _wait_layout_frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame


func _fail(message: String) -> bool:
	push_error("FASE 36 RESPONSIVE TEST ERROR: %s" % message)
	return false
