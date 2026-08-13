class_name KarmanyPhase30AlphaBridge
extends Node3D

@onready var slice: KarmanyPhase28VerticalSliceBridge = $Phase28VerticalSlicePrototype
@onready var status_label: Label = $AlphaOverlay/Panel/Margin/VBox/StatusLabel
@onready var onboarding_label: Label = $AlphaOverlay/Panel/Margin/VBox/OnboardingLabel
@onready var checklist_label: Label = $AlphaOverlay/Panel/Margin/VBox/ChecklistLabel
@onready var gameplay_label: Label = $AlphaOverlay/Panel/Margin/VBox/GameplayLabel
@onready var balance_label: Label = $AlphaOverlay/Panel/Margin/VBox/BalanceLabel
@onready var runtime_label: Label = $AlphaOverlay/Panel/Margin/VBox/RuntimeLabel
@onready var log_label: Label = $AlphaOverlay/Panel/Margin/VBox/LogLabel

var telemetry: KarmanyAlphaTelemetry = KarmanyAlphaTelemetry.new()
var setup_ok: bool = false

func _ready() -> void:
	if slice == null or not slice.setup_ok:
		push_error("FASE 30 ERROR: Vertical Slice no disponible para Alpha.")
		_refresh()
		return
	setup_ok = telemetry.configure(slice.session)
	if not setup_ok:
		push_error("FASE 30 ERROR: Telemetria Alpha no pudo configurarse.")
		_refresh()
		return
	telemetry.updated.connect(_refresh)
	_refresh()
	print("FASE 30 ALPHA OK - telemetria, UX y onboarding conectados.")

func get_telemetry() -> KarmanyAlphaTelemetry:
	return telemetry

func get_onboarding_text() -> String:
	if not setup_ok:
		return "Alpha no disponible."
	return KarmanyAlphaOnboarding.get_text(slice.session)

func _refresh() -> void:
	if not setup_ok:
		status_label.text = "ALPHA · NO DISPONIBLE"
		onboarding_label.text = "Revisa el primer error en Salida."
		return
	var session: KarmanyVerticalSliceSession = slice.session
	var state_text: String = "FINALIZADA" if session.coordinator.is_finished else "EN CURSO"
	status_label.text = "ALPHA · %s · Ronda %d · Acciones %d" % [state_text, session.turn_manager.current_round, session.turn_manager.actions_remaining]
	onboarding_label.text = KarmanyAlphaOnboarding.get_text(session)
	checklist_label.text = KarmanyAlphaOnboarding.get_checklist(session)
	gameplay_label.text = "GAMEPLAY\n" + telemetry.get_gameplay_summary()
	balance_label.text = "BALANCE PRELIMINAR\n" + telemetry.get_balance_summary()
	runtime_label.text = "RENDIMIENTO\n" + telemetry.get_runtime_summary()
	log_label.text = "ULTIMOS EVENTOS\n" + telemetry.get_recent_log()
