extends Node


const VISUAL_SCENE: PackedScene = preload(
	"res://scenes/ui/phase_19_hud_board_prototype.tscn"
)


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 19 VISUAL INTEGRATION TEST")
	print("================================")

	var instance := VISUAL_SCENE.instantiate()
	if instance == null:
		push_error("FASE 19 VISUAL ERROR: No se pudo instanciar la escena compuesta.")
		return

	add_child(instance)
	await get_tree().process_frame

	var board_root := instance.get_node_or_null("Board3DPrototype") as Node3D
	var tiles_root := instance.get_node_or_null("Board3DPrototype/Board") as Node3D
	var camera := instance.get_node_or_null("Board3DPrototype/Camera3D") as Camera3D
	var hud := instance.get_node_or_null("GameHUD") as KarmanyGameHUD

	var ok: bool = true
	ok = _expect(board_root != null, "Falta Board3DPrototype en la escena compuesta.") and ok
	ok = _expect(tiles_root != null, "Falta el contenedor Board de las losetas.") and ok
	ok = _expect(camera != null, "Falta Camera3D del tablero.") and ok
	ok = _expect(hud != null, "Falta GameHUD en la escena compuesta.") and ok

	if tiles_root != null:
		ok = _expect(
			tiles_root.get_child_count() == 7,
			"El sandbox visual debe generar exactamente 7 losetas 3D."
		) and ok

	if camera != null:
		ok = _expect(camera.is_current(), "La camara del Board3DPrototype debe quedar activa.") and ok

	if board_root != null:
		ok = _expect(board_root.visible, "La rama 3D del tablero debe estar visible.") and ok

	print("")
	print("================================")
	if ok:
		print("FASE 19 VISUAL OK - Tablero, 7 losetas, camara y HUD integrados.")
	else:
		push_error("FASE 19 VISUAL ERROR - Revisar integracion Board3DPrototype + GameHUD.")
	print("================================")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 19 VISUAL ERROR: %s" % message)
	return false
