extends Node


const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const FLORAVIA: KarmanyData = preload("res://data/karmanys/k_05_floravia.tres")
const R01: KarmanyResonanceData = preload("res://data/resonances/r_01_impulso_luminico.tres")
const R03: KarmanyResonanceData = preload("res://data/resonances/r_03_corte_de_bruma.tres")
const EQ09: KarmanyEquipmentData = preload("res://data/equipment/eq_09_catalizador_de_aeterna.tres")


@onready var hud: KarmanyGameHUD = $GameHUD

var requested_actions: Array[StringName] = []


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 19 HUD TEST")
	print("================================")

	var ok: bool = _run_hud_test()

	print("")
	print("================================")
	if ok:
		print("FASE 19 OK - HUD funcional, reactivo y desacoplado validado.")
	else:
		push_error("FASE 19 ERROR - Revisar HUD funcional.")
	print("================================")


func _run_hud_test() -> bool:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i(1, 0))

	var terrakor := _make_linked(TERRAKOR, &"terrakor_hud", p1.player_id)
	var floravia := _make_linked(FLORAVIA, &"floravia_hud", p1.player_id)
	var ok: bool = true
	ok = _expect(terrakor != null and p1.add_linked_karmany(terrakor), "No se pudo agregar Terrakor activo.") and ok
	ok = _expect(floravia != null and p1.add_linked_karmany(floravia), "No se pudo agregar Floravia a reserva.") and ok
	ok = _expect(p1.add_equipment(EQ09), "No se pudo agregar Equipo de prueba.") and ok
	ok = _expect(p1.resonance_hand.add_card(R01), "No se pudo agregar R-01 a mano.") and ok
	ok = _expect(p1.resonance_hand.add_card(R03), "No se pudo agregar R-03 a mano.") and ok

	var players: Array[KarmanyPlayerState] = [p1, p2]
	var turn_manager := KarmanyTurnManager.new()
	ok = _expect(turn_manager.setup_players(players), "No se pudo configurar TurnManager.") and ok
	ok = _expect(turn_manager.start_match(), "No se pudo iniciar partida de prueba.") and ok

	var mode := KarmanyLegacyModeConfig.new()
	mode.configure_standard(KarmanyLegacyModeConfig.MapFormat.MAP_22)
	var legacy := KarmanyLegacyPointsController.new()
	ok = _expect(legacy.configure(players, mode), "No se pudo configurar PL para HUD.") and ok
	ok = _expect(
		legacy.award_points(
			p1.player_id,
			KarmanyLegacyPointsEntry.SourceType.OTHER,
			&"hud_seed",
			5,
			1,
			&"hud_seed"
		).was_applied(),
		"No se pudieron preparar 5 PL."
	) and ok

	hud.bind_turn_manager(turn_manager)
	hud.bind_legacy_points_controller(legacy)
	hud.action_requested.connect(_on_action_requested)
	hud.set_action_state(KarmanyGameHUD.ACTION_MOVE, true, "Mover disponible.")
	hud.set_action_state(KarmanyGameHUD.ACTION_EXPLORE, true, "Explorar disponible.")
	hud.set_action_state(KarmanyGameHUD.ACTION_END_TURN, true, "Finalizar cuando queden 0 acciones.")

	var snapshot := hud.get_snapshot()
	ok = _expect(String(snapshot.player).contains("player_1"), "HUD debe mostrar jugador activo.") and ok
	ok = _expect(String(snapshot.round).contains("1"), "HUD debe mostrar ronda 1.") and ok
	ok = _expect(String(snapshot.actions).contains("2 / 2"), "HUD debe mostrar 2 acciones.") and ok
	ok = _expect(String(snapshot.resources).contains("MN: 2"), "HUD debe mostrar recursos reales.") and ok
	ok = _expect(String(snapshot.active_karmany).contains("Terrakor"), "HUD debe mostrar Karmany activo.") and ok
	ok = _expect(String(snapshot.reserve).contains("Floravia"), "HUD debe mostrar reserva derivada del roster.") and ok
	ok = _expect(String(snapshot.cards).contains("Resonancias 2"), "HUD debe mostrar cartas de Resonancia.") and ok
	ok = _expect(String(snapshot.cards).contains("Equipos 1"), "HUD debe mostrar Equipos.") and ok
	ok = _expect(String(snapshot.legacy_points).contains("5"), "HUD debe mostrar PL centralizados.") and ok
	ok = _expect(hud.get_action_button_enabled(KarmanyGameHUD.ACTION_MOVE), "Mover debe estar habilitado con acciones.") and ok
	ok = _expect(not hud.get_action_button_enabled(KarmanyGameHUD.ACTION_END_TURN), "Finalizar turno no debe habilitarse con acciones restantes.") and ok
	print("Estado completo inicial del jugador activo: ", "OK" if ok else "ERROR")

	p1.gain_resource(KarmanyEffectData.ResourceType.MN, 3)
	legacy.award_points(
		p1.player_id,
		KarmanyLegacyPointsEntry.SourceType.OTHER,
		&"hud_live_award",
		2,
		1,
		&"hud_live_award"
	)
	snapshot = hud.get_snapshot()
	ok = _expect(String(snapshot.resources).contains("MN: 5"), "HUD debe reaccionar a cambio de recursos.") and ok
	ok = _expect(String(snapshot.legacy_points).contains("7"), "HUD debe reaccionar a PL sin polling externo.") and ok
	print("Actualizacion reactiva Recursos + PL: ", "OK" if ok else "ERROR")

	hud.move_button.pressed.emit()
	ok = _expect(requested_actions.has(KarmanyGameHUD.ACTION_MOVE), "Boton Mover debe emitir action_requested.") and ok
	ok = _expect(String(hud.get_snapshot().action_context).contains("Mover disponible"), "Boton debe actualizar contexto de accion.") and ok

	ok = _expect(turn_manager.spend_action_for(&"hud_test_1", 1), "No se pudo gastar accion 1.") and ok
	ok = _expect(turn_manager.spend_action_for(&"hud_test_2", 1), "No se pudo gastar accion 2.") and ok
	snapshot = hud.get_snapshot()
	ok = _expect(String(snapshot.actions).contains("0 / 2"), "HUD debe mostrar 0 acciones tras gastar dos.") and ok
	ok = _expect(not hud.get_action_button_enabled(KarmanyGameHUD.ACTION_MOVE), "Mover debe deshabilitarse con 0 acciones.") and ok
	ok = _expect(hud.get_action_button_enabled(KarmanyGameHUD.ACTION_END_TURN), "Finalizar turno debe habilitarse con 0 acciones.") and ok
	print("Botones + presupuesto de 2 acciones: ", "OK" if ok else "ERROR")

	ok = _expect(turn_manager.end_turn(), "No se pudo terminar turno de player_1.") and ok
	snapshot = hud.get_snapshot()
	ok = _expect(String(snapshot.player).contains("player_2"), "HUD debe cambiar al nuevo jugador activo.") and ok
	ok = _expect(String(snapshot.actions).contains("2 / 2"), "Nuevo jugador debe mostrar 2 acciones.") and ok
	ok = _expect(String(snapshot.resources).contains("MN: 2"), "HUD debe observar recursos de player_2, no de player_1.") and ok
	ok = _expect(String(snapshot.active_karmany).ends_with("-"), "player_2 sin Karmany debe mostrarse claramente.") and ok
	print("Cambio de jugador activo y rebinding automatico: ", "OK" if ok else "ERROR")

	return ok


func _make_linked(
	data: KarmanyData,
	instance_id: StringName,
	owner_id: StringName
) -> KarmanyRuntimeState:
	var runtime := KarmanyRuntimeState.new()
	if not runtime.configure(data, instance_id):
		return null
	runtime.set_owner_player_id(owner_id)
	if not runtime.set_bond_state(KarmanyRuntimeState.BondState.LINKED):
		return null
	return runtime


func _on_action_requested(action_id: StringName) -> void:
	requested_actions.append(action_id)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 19 ERROR: %s" % message)
	return false
