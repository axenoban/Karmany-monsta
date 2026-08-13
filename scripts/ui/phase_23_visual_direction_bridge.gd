class_name KarmanyPhase23VisualDirectionBridge
extends Node3D


@onready var phase_22: KarmanyPhase22FeedbackBridge = $Phase22FeedbackPrototype
@onready var visual_direction: KarmanyVisualDirectionController = $VisualDirectionController
@onready var world_environment: WorldEnvironment = $VisualDirectionRoot/WorldEnvironment
@onready var key_light: DirectionalLight3D = $VisualDirectionRoot/KeyLight
@onready var fill_light: OmniLight3D = $VisualDirectionRoot/FillLight
@onready var rim_light: DirectionalLight3D = $VisualDirectionRoot/RimLight


var board_ux: KarmanyPhase20BoardUXBridge = null
var hud: KarmanyGameHUD = null


func _ready() -> void:
	if phase_22 == null or visual_direction == null:
		push_error("FASE 23 ERROR: No se pudo conectar Fase 22 y direccion visual.")
		return

	if phase_22.phase_21 == null or phase_22.phase_21.board_ux == null:
		push_error("FASE 23 ERROR: No se encontro la UX de tablero validada.")
		return

	board_ux = phase_22.phase_21.board_ux
	hud = board_ux.hud
	if hud == null:
		push_error("FASE 23 ERROR: No se encontro GameHUD.")
		return

	if not visual_direction.configure(
		board_ux,
		hud,
		world_environment,
		key_light,
		fill_light,
		rim_light
	):
		push_error("FASE 23 ERROR: No se pudo aplicar direccion visual.")
		return

	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 23 DIRECCION VISUAL")
	print("================================")
	print("Paleta Vael: jade, ambar, bosque, bruma y violeta karmico.")
	print("Iluminacion: key calida + fill jade + rim violeta.")
	print("HUD tematizado sin perder estados funcionales.")
	print("Los placeholders finales de arte siguen siendo reemplazables.")
	print("================================")


func refresh_visual_direction() -> void:
	if visual_direction != null:
		visual_direction.refresh_visual_direction()


func get_visual_direction_controller() -> KarmanyVisualDirectionController:
	return visual_direction
