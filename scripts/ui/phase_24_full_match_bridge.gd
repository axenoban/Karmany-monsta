class_name KarmanyPhase24FullMatchBridge
extends Node3D


const P1_START: Vector2i = Vector2i.ZERO
const P2_START: Vector2i = Vector2i(0, 1)
const TILE_MR: Vector2i = Vector2i(1, 0)
const TILE_EK: Vector2i = Vector2i(1, -1)
const TILE_N2: Vector2i = Vector2i(0, -1)
const TILE_N3: Vector2i = Vector2i(-1, 0)
const TILE_AETERNA: Vector2i = Vector2i(-1, 1)
const P2_UNIT_ID: StringName = &"trainer_player_2"
const DEMO_RACE_TARGET: int = 16

const TILE_I02: KarmanyTileData = preload("res://data/tiles/i_02_campamento_rio_bruma.tres")
const TILE_I04: KarmanyTileData = preload("res://data/tiles/i_04_sendero_primer_vinculo.tres")
const TILE_N102: KarmanyTileData = preload("res://data/tiles/n1_02_mina_pequena.tres")
const TILE_N103: KarmanyTileData = preload("res://data/tiles/n1_03_arroyo_karmico.tres")
const TILE_N205: KarmanyTileData = preload("res://data/tiles/n2_05_paso_de_cristal.tres")
const TILE_N302: KarmanyTileData = preload("res://data/tiles/n3_02_forja_antigua.tres")
const TILE_L01: KarmanyTileData = preload("res://data/tiles/l_01_santuario_de_aeterna.tres")

const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const BRUMAK: KarmanyData = preload("res://data/karmanys/k_10_brumak.tres")
const RAUK: KarmanyData = preload("res://data/karmanys/k_11_rauk.tres")
const B01: KarmanyBeastData = preload("res://data/beasts/b_01_garravol.tres")

const EQ02: KarmanyEquipmentData = preload("res://data/equipment/eq_02_guante_runico.tres")
const EQ03: KarmanyEquipmentData = preload("res://data/equipment/eq_03_baculo_de_bruma.tres")
const EQ01: KarmanyEquipmentData = preload("res://data/equipment/eq_01_cristal_de_crecimiento.tres")
const EQ05: KarmanyEquipmentData = preload("res://data/equipment/eq_05_nucleo_luminico.tres")
const EQ08: KarmanyEquipmentData = preload("res://data/equipment/eq_08_prisma_ancestral.tres")
const EQ09: KarmanyEquipmentData = preload("res://data/equipment/eq_09_catalizador_de_aeterna.tres")

const R01: KarmanyResonanceData = preload("res://data/resonances/r_01_impulso_luminico.tres")
const R02: KarmanyResonanceData = preload("res://data/resonances/r_02_golpe_salvaje.tres")
const R03: KarmanyResonanceData = preload("res://data/resonances/r_03_corte_de_bruma.tres")
const R04: KarmanyResonanceData = preload("res://data/resonances/r_04_embate_de_raiz.tres")
const R05: KarmanyResonanceData = preload("res://data/resonances/r_05_furia_controlada.tres")
const R06: KarmanyResonanceData = preload("res://data/resonances/r_06_eco_del_libro.tres")
const R07: KarmanyResonanceData = preload("res://data/resonances/r_07_filo_exacto.tres")
const R08: KarmanyResonanceData = preload("res://data/resonances/r_08_resonancia_creciente.tres")
const R13: KarmanyResonanceData = preload("res://data/resonances/r_13_defensa_instintiva.tres")
const R22: KarmanyResonanceData = preload("res://data/resonances/r_22_mirada_del_sendero.tres")
const R37: KarmanyResonanceData = preload("res://data/resonances/r_37_instinto_de_caza.tres")

const OP_E01: KarmanyObjectiveData = preload("res://data/objectives/op_e01_cartografo_experto.tres")
const OP_D02: KarmanyObjectiveData = preload("res://data/objectives/op_d02_forja_consistente.tres")
const OP_C03: KarmanyObjectiveData = preload("res://data/objectives/op_c03_duelista_del_eco.tres")
const ME_A1: KarmanyMissionData = preload("res://data/missions/me_a1_cartografo_del_primer_eco.tres")
const ME_D1: KarmanyMissionData = preload("res://data/missions/me_d1_rival_de_vael.tres")


@onready var phase_23: KarmanyPhase23VisualDirectionBridge = $Phase23VisualDirectionPrototype
@onready var status_label: Label = $Phase24Overlay/Panel/Margin/VBox/StatusLabel
@onready var log_label: Label = $Phase24Overlay/Panel/Margin/VBox/LogLabel
@onready var run_button: Button = $Phase24Overlay/Panel/Margin/VBox/RunButton

var board_ux: KarmanyPhase20BoardUXBridge = null
var board_prototype: Node = null
var hud: KarmanyGameHUD = null
var player_1: KarmanyPlayerState = null
var player_2: KarmanyPlayerState = null
var turn_manager: KarmanyTurnManager = null
var legacy_points: KarmanyLegacyPointsController = null

var objectives_missions: KarmanyObjectiveMissionManager = KarmanyObjectiveMissionManager.new()
var resonance_deck: KarmanyResonanceDeck = KarmanyResonanceDeck.new()
var equipment_market: KarmanyEquipmentMarket = KarmanyEquipmentMarket.new()
var beast_deck: KarmanyBeastDeck = KarmanyBeastDeck.new()
var coordinator: KarmanyMatchCoordinator = KarmanyMatchCoordinator.new()

var setup_ok: bool = false
var last_demo_success: bool = false
var last_demo_message: String = ""
var _demo_started: bool = false
var _log_lines: Array[String] = []


func _ready() -> void:
	setup_ok = setup_integration_match()
	if run_button != null:
		run_button.disabled = not setup_ok
		if not run_button.pressed.is_connected(_on_run_button_pressed):
			run_button.pressed.connect(_on_run_button_pressed)
	_update_status()


func setup_integration_match() -> bool:
	if phase_23 == null or phase_23.board_ux == null:
		return _setup_error("No se encontro la escena visual validada de Fase 23.")
	board_ux = phase_23.board_ux
	board_prototype = board_ux.board_prototype
	hud = board_ux.hud
	if board_prototype == null or hud == null:
		return _setup_error("Faltan Board3DPrototype o GameHUD.")

	turn_manager = board_prototype.turn_manager
	player_1 = board_prototype.player_state
	player_2 = board_prototype.prototype_second_player_state
	legacy_points = board_ux.legacy_points_controller
	if turn_manager == null or player_1 == null or player_2 == null or legacy_points == null:
		return _setup_error("No se encontraron los sistemas base del tablero.")
	if not turn_manager.is_running or turn_manager.current_round != 1 or turn_manager.get_active_player() != player_1:
		return _setup_error("Fase 24 requiere una instancia limpia iniciada en ronda 1 / player_1.")

	player_1.setup_new_game(&"player_1", P1_START)
	player_2.setup_new_game(&"player_2", P2_START)
	if not _add_starter(player_1, &"phase24_starter_p1"):
		return _setup_error("No se pudo preparar Terrakor para player_1.")
	if not _add_starter(player_2, &"phase24_starter_p2"):
		return _setup_error("No se pudo preparar Terrakor para player_2.")
	if not _configure_board_layout():
		return _setup_error("No se pudo configurar el tablero compacto de integracion.")
	if not _configure_decks_and_market():
		return _setup_error("No se pudieron configurar Resonancias, Equipos o Bestias.")
	if not _configure_progress_and_points():
		return _setup_error("No se pudieron configurar Objetivos, Misiones o PL.")

	if not coordinator.configure(
		board_prototype.board_state,
		turn_manager,
		legacy_points,
		objectives_missions,
		resonance_deck,
		equipment_market,
		Callable(self, "_move_executor"),
		Callable(self, "_explore_executor"),
		Callable(self, "_retreat_executor")
	):
		return _setup_error("KarmanyMatchCoordinator no pudo configurarse.")

	coordinator.integration_event.connect(_on_integration_event)
	coordinator.match_finished.connect(_on_match_finished)
	_record_initial_visit(player_1)
	_record_initial_visit(player_2)
	board_ux.refresh_board_ux()
	phase_23.refresh_visual_direction()
	_log("SETUP OK — sandbox de partida completa listo; Carrera de Legado a %d PL." % DEMO_RACE_TARGET)
	return true


func run_complete_match_fast() -> bool:
	if not setup_ok or _demo_started:
		return false
	_demo_started = true
	if run_button != null:
		run_button.disabled = true

	var ok: bool = true
	ok = _validate_initial_guardrails() and ok
	ok = _run_round_1() and ok
	ok = _run_round_2() and ok
	ok = _run_round_3() and ok
	ok = _run_round_4() and ok
	ok = _run_round_5() and ok
	ok = _run_round_6() and ok
	ok = _run_round_7() and ok
	ok = _run_round_8() and ok
	ok = _run_round_9() and ok
	ok = _run_round_10() and ok
	ok = _run_round_11() and ok
	ok = _run_round_12() and ok

	last_demo_success = ok and coordinator.is_finished and coordinator.final_evaluation != null
	if last_demo_success:
		last_demo_message = "PARTIDA COMPLETA OK — final legal en ronda 12."
		_log(last_demo_message)
	else:
		last_demo_message = "PARTIDA COMPLETA ERROR — revisar el primer paso fallido del log."
		_log(last_demo_message)
	_update_status()
	return last_demo_success


func _validate_initial_guardrails() -> bool:
	var actions_before: int = turn_manager.actions_remaining
	var out_of_turn_move: bool = coordinator.move_player(player_2, P1_START)
	if out_of_turn_move or turn_manager.actions_remaining != actions_before:
		return _step_error("Una accion fuera de turno fue aceptada o consumio acciones.")
	var occupied_validation: int = KarmanyMovementRules.validate_move(
		board_prototype.board_state, turn_manager, player_1, P2_START
	)
	if occupied_validation != KarmanyMovementRules.MoveValidation.TARGET_OCCUPIED:
		return _step_error("Movimiento hacia unidad rival no fue marcado TARGET_OCCUPIED.")
	if turn_manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _step_error("Las validaciones iniciales alteraron el presupuesto de acciones.")
	_log("Guardrails OK — fuera de turno y ocupacion rechazados sin coste.")
	return true


func _run_round_1() -> bool:
	if not _require_turn(1, player_1): return false
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R1 P1 Interactuar #1 fallo.")
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R1 P1 Interactuar #2 fallo.")
	if not _finish_turn(&"R-02"): return false
	if not _require_turn(1, player_2): return false
	var spawn := coordinator.spawn_beast(P2_START, beast_deck, false)
	if not spawn.is_spawned(): return _step_error("R1 no pudo aparecer Garravol.")
	var context := KarmanyBeastCombatContext.new()
	context.turn_manager = turn_manager
	context.effect_context = coordinator.effect_context
	context.instinct_roll = 1
	context.action_cost = 1
	var beast_result := coordinator.fight_beast(player_2, P2_START, beast_deck, context)
	if not beast_result.is_victory(): return _step_error("R1 player_2 no derroto Garravol.")
	if not coordinator.interact_effect_option(player_2, 1).is_success(): return _step_error("R1 P2 Interactuar fallo.")
	return _finish_turn()


func _run_round_2() -> bool:
	if not _require_turn(2, player_1): return false
	if not coordinator.explore_player(player_1, TILE_MR): return _step_error("R2 P1 Explorar N1-02 fallo.")
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R2 P1 +2 MR fallo.")
	if not _finish_turn(&"R-02"): return false
	if not _require_turn(2, player_2): return false
	var auth := KarmanyPvpAuthorizationContext.new()
	auth.source_id = &"phase24_legal_pvp_source"
	auth.range_mode = KarmanyPvpAuthorizationContext.RangeMode.ADJACENT
	var pvp := coordinator.resolve_pvp(player_2, player_1, auth, &"R-01")
	if not pvp.is_resolved() or pvp.winner_player_id != player_2.player_id:
		return _step_error("R2 PvP no fue resuelto legalmente a favor de player_2.")
	if player_1.current_coord != P1_START:
		return _step_error("R2 PvP no aplico el retroceso de player_1.")
	if not coordinator.interact_effect_option(player_2, 1).is_success(): return _step_error("R2 P2 segunda accion fallo.")
	return _finish_turn()


func _run_round_3() -> bool:
	if not _require_turn(3, player_1): return false
	var book := coordinator.improve_book(player_1)
	if not book.is_success() or book.new_level != 2: return _step_error("R3 Libro II fallo.")
	if not coordinator.explore_player(player_1, TILE_EK): return _step_error("R3 Explorar N1-03 fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(3)


func _run_round_4() -> bool:
	if not _require_turn(4, player_1): return false
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R4 +2 EK #1 fallo.")
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R4 +2 EK #2 fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(4)


func _run_round_5() -> bool:
	if not _require_turn(5, player_1): return false
	if not coordinator.explore_player(player_1, TILE_N2): return _step_error("R5 Explorar N2-05 fallo.")
	var candidates: Array[KarmanyData] = [BRUMAK, RAUK]
	var call_result := coordinator.call_karmany(player_1, candidates, 0, KarmanyData.Rank.N2)
	if not call_result.is_success(): return _step_error("R5 Llamar Karmany N2 fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(5)


func _run_round_6() -> bool:
	if not _require_turn(6, player_1): return false
	var bond := coordinator.bond_visible_by_payment(player_1)
	if not bond.is_success() or bond.linked_karmany == null: return _step_error("R6 Vincular Brumak fallo.")
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R6 N2 +2 MR fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(6)


func _run_round_7() -> bool:
	if not _require_turn(7, player_1): return false
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R7 N2 +2 MR fallo.")
	var craft_context := KarmanyEquipmentCraftContext.new()
	craft_context.source_id = &"N2-05"
	craft_context.allow_basic = true
	craft_context.allow_advanced = true
	var craft := coordinator.craft_from_market(player_1, 0, craft_context)
	if not craft.is_success() or craft.equipment != EQ02: return _step_error("R7 crafteo EQ-02 fallo.")
	if equipment_market.get_visible_count() != KarmanyEquipmentMarket.MARKET_SIZE:
		return _step_error("R7 el mercado no se repuso a 4 Equipos.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(7)


func _run_round_8() -> bool:
	if not _require_turn(8, player_1): return false
	if not coordinator.interact_effect_option(player_1, 0).is_success(): return _step_error("R8 N2 +2 MR fallo.")
	if not coordinator.explore_player(player_1, TILE_N3): return _step_error("R8 Explorar Forja Antigua fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(8)


func _run_round_9() -> bool:
	if not _require_turn(9, player_1): return false
	var forge := coordinator.forge_common_to_fa(
		player_1, KarmanyEffectData.ResourceType.MR, KarmanyEffectData.ResourceType.MR
	)
	if not forge.is_success(): return _step_error("R9 conversion Forja -> FA fallo.")
	if not coordinator.move_player(player_1, P1_START): return _step_error("R9 retorno al centro fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(9)


func _run_round_10() -> bool:
	if not _require_turn(10, player_1): return false
	if not coordinator.move_player(player_1, TILE_EK): return _step_error("R10 Mover a N1-03 fallo.")
	var book := coordinator.improve_book(player_1)
	if not book.is_success() or book.new_level != 3: return _step_error("R10 Libro III fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(10)


func _run_round_11() -> bool:
	if not _require_turn(11, player_1): return false
	if not coordinator.move_player(player_1, P1_START): return _step_error("R11 Mover al centro fallo.")
	if not coordinator.explore_player(player_1, TILE_AETERNA): return _step_error("R11 Explorar Santuario fallo.")
	var attune := coordinator.resolve_sanctuary_attunement_gain_fa(player_1)
	if not attune.is_resolved() or player_1.fa != 1: return _step_error("R11 Sintonia gratuita +1 FA fallo.")
	if not _finish_turn(&"R-02"): return false
	return _run_p2_double_interact(11)


func _run_round_12() -> bool:
	if not _require_turn(12, player_1): return false
	var aeterna := coordinator.resolve_aeterna_combat(player_1, &"R-02", 1, 6)
	if not aeterna.is_victory() or aeterna.combat_result == null: return _step_error("R12 Aeterna no fue derrotada.")
	if not KarmanyCombatConsequenceResolver.resolve_risk_win_basic_resources(
		player_1,
		aeterna.combat_result,
		KarmanyEffectData.ResourceType.MN,
		KarmanyEffectData.ResourceType.MN
	):
		return _step_error("R12 recompensa del Dado de Riesgo 6 no fue resuelta.")
	if not coordinator.resolve_aeterna_equipment_reward(player_1, aeterna, EQ09):
		return _step_error("R12 recompensa Equipo Ancestral fallo.")
	if not _resolve_pending_discard(player_1, &""): return false
	var post := coordinator.collect_aeterna_post_defeat_ek(player_1)
	if not post.is_resolved() or post.post_defeat_ek_gained != 2:
		return _step_error("R12 Uso posterior Santuario +2 EK fallo.")
	if not _finish_turn(): return false
	if not _run_p2_double_interact(12): return false
	if not coordinator.is_finished or coordinator.final_evaluation == null:
		return _step_error("La Carrera de Legado no termino al cierre de ronda 12.")
	if not coordinator.final_evaluation.leader_player_ids.has(player_1.player_id):
		return _step_error("player_1 no figura como lider final.")
	if legacy_points.get_points(player_1.player_id) < DEMO_RACE_TARGET:
		return _step_error("player_1 no alcanzo la meta de PL.")
	return true


func _run_p2_double_interact(round_number: int) -> bool:
	if not _require_turn(round_number, player_2): return false
	if not coordinator.interact_effect_option(player_2, 1).is_success(): return _step_error("R%d P2 Interactuar #1 fallo." % round_number)
	if not coordinator.interact_effect_option(player_2, 1).is_success(): return _step_error("R%d P2 Interactuar #2 fallo." % round_number)
	return _finish_turn()


func _finish_turn(protected_resonance_id: StringName = &"") -> bool:
	var player: KarmanyPlayerState = turn_manager.get_active_player()
	if player == null:
		return _step_error("No existe jugador activo para cerrar turno.")
	if turn_manager.actions_remaining != 0:
		return _step_error("Se intento terminar turno sin consumir exactamente 2 acciones.")
	if not _resolve_pending_discard(player, protected_resonance_id):
		return false
	if not coordinator.end_turn():
		return _step_error("TurnManager rechazo un cierre de turno valido.")
	_update_status()
	return true


func _resolve_pending_discard(
	player: KarmanyPlayerState,
	protected_resonance_id: StringName
) -> bool:
	if player == null:
		return false
	if player.resonance_hand.get_pending_discard_count() == 0:
		player.request_end_turn_resonance_discard()
	var pending: int = player.resonance_hand.get_pending_discard_count()
	if pending <= 0:
		return true
	var selected: Array[StringName] = []
	for card in player.get_resonance_hand():
		if selected.size() >= pending: break
		if card.resonance_id == protected_resonance_id: continue
		selected.append(card.resonance_id)
	if selected.size() < pending and protected_resonance_id != &"":
		for card in player.get_resonance_hand():
			if selected.size() >= pending: break
			if card.resonance_id == protected_resonance_id: selected.append(card.resonance_id)
	if selected.size() != pending:
		return _step_error("No se pudieron seleccionar los descartes pendientes de Resonancia.")
	if not coordinator.resolve_pending_resonance_discard(player, selected):
		return _step_error("No se pudo resolver el descarte pendiente de Resonancia.")
	return true


func _configure_board_layout() -> bool:
	var board: KarmanyBoardState = board_prototype.board_state
	board.clear()
	var layout: Dictionary = {
		P1_START: [TILE_I02, true], P2_START: [TILE_I04, true],
		TILE_MR: [TILE_N102, false], TILE_EK: [TILE_N103, false],
		TILE_N2: [TILE_N205, false], TILE_N3: [TILE_N302, false],
		TILE_AETERNA: [TILE_L01, false]
	}
	for coord_value in layout.keys():
		var coord: Vector2i = coord_value
		var entry: Array = layout[coord]
		var tile_data: KarmanyTileData = entry[0]
		var revealed: bool = bool(entry[1])
		if not board.add_cell(coord, tile_data, revealed): return false
		board_prototype.call("_refresh_tile_view_from_state", coord)
	if not board_prototype.place_trainer_at(P1_START): return false
	player_2.set_board_position(P2_START)
	if not board.set_unit_occupant(P2_START, P2_UNIT_ID): return false
	return true


func _configure_decks_and_market() -> bool:
	var resonance_cards: Array[KarmanyResonanceData] = [R02, R03, R04, R13, R22, R01, R05, R06, R07, R37, R08]
	if not resonance_deck.setup(resonance_cards, false): return false
	if not resonance_deck.deal_initial_hand(player_1): return false
	if not resonance_deck.deal_initial_hand(player_2): return false
	var equipment_cards: Array[KarmanyEquipmentData] = [EQ02, EQ01, EQ05, EQ08, EQ03]
	if not equipment_market.setup(equipment_cards, false): return false
	var beasts: Array[KarmanyBeastData] = [B01]
	return beast_deck.setup(beasts, false)


func _configure_progress_and_points() -> bool:
	var mode := KarmanyLegacyModeConfig.new()
	if not mode.configure_legacy_race(KarmanyLegacyModeConfig.MapFormat.MAP_22, DEMO_RACE_TARGET): return false
	var players: Array[KarmanyPlayerState] = [player_1, player_2]
	if not legacy_points.configure(players, mode): return false
	var objectives: Array[KarmanyObjectiveData] = [OP_E01, OP_D02, OP_C03]
	if not objectives_missions.configure(turn_manager, objectives): return false
	if not objectives_missions.assign_secret_mission(player_1, &"alderion", ME_A1): return false
	if not objectives_missions.assign_secret_mission(player_2, &"dorian", ME_D1): return false
	return true


func _record_initial_visit(player: KarmanyPlayerState) -> void:
	objectives_missions.record_event(player, KarmanyMatchCoordinator.EVENT_TILE_VISITED, {"coord_key": "%d,%d" % [player.current_coord.x, player.current_coord.y]})


func _add_starter(player: KarmanyPlayerState, instance_id: StringName) -> bool:
	var runtime := KarmanyRuntimeState.new()
	if not runtime.configure(TERRAKOR, instance_id): return false
	runtime.set_owner_player_id(player.player_id)
	if not runtime.set_bond_state(KarmanyRuntimeState.BondState.LINKED): return false
	return player.add_linked_karmany(runtime)


func _move_executor(player: KarmanyPlayerState, target_coord: Vector2i) -> bool:
	if player != player_1: return false
	return bool(board_prototype.call("try_move_trainer_to", target_coord))


func _explore_executor(player: KarmanyPlayerState, target_coord: Vector2i) -> bool:
	if player != player_1: return false
	return bool(board_prototype.call("try_explore_trainer_to", target_coord))


func _retreat_executor(player: KarmanyPlayerState, target_coord: Vector2i) -> bool:
	if player == null or not board_prototype.board_state.has_coord(target_coord): return false
	if player == player_1: return bool(board_prototype.call("place_trainer_at", target_coord))
	var origin: Vector2i = player.current_coord
	if board_prototype.board_state.get_occupying_unit_id(origin) == P2_UNIT_ID:
		board_prototype.board_state.clear_unit_occupant(origin)
	if board_prototype.board_state.is_occupied(target_coord): return false
	if not board_prototype.board_state.set_unit_occupant(target_coord, P2_UNIT_ID): return false
	player.set_board_position(target_coord)
	return true


func _require_turn(round_number: int, player: KarmanyPlayerState) -> bool:
	if not turn_manager.is_running: return _step_error("La partida se detuvo antes de la ronda %d." % round_number)
	if turn_manager.current_round != round_number: return _step_error("Ronda esperada %d, actual %d." % [round_number, turn_manager.current_round])
	if turn_manager.get_active_player() != player: return _step_error("Jugador activo incorrecto en ronda %d." % round_number)
	if turn_manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN: return _step_error("El turno no inicio con 2 acciones en ronda %d." % round_number)
	return true


func _on_match_finished(evaluation: KarmanyLegacyMatchEvaluation) -> void:
	if turn_manager != null and turn_manager.is_running: turn_manager.stop_match()
	_log("MATCH FINISHED — lideres %s, %d PL." % [str(evaluation.leader_player_ids), evaluation.leading_score])
	_update_status()


func _on_integration_event(message: String) -> void:
	_log(message)
	_update_status()


func _on_run_button_pressed() -> void:
	run_complete_match_fast()


func _update_status() -> void:
	if status_label == null or player_1 == null or player_2 == null: return
	var active_text: String = "FINALIZADA"
	if turn_manager != null and turn_manager.is_running and turn_manager.get_active_player() != null:
		active_text = String(turn_manager.get_active_player().player_id)
	var p1_state := coordinator.get_book_state(player_1.player_id)
	var p2_state := coordinator.get_book_state(player_2.player_id)
	var p1_book: int = p1_state.level if p1_state != null else 0
	var p2_book: int = p2_state.level if p2_state != null else 0
	status_label.text = "FASE 24 · PARTIDA INTEGRADA\nRonda: %d | Activo: %s | Acciones: %d\nP1: %d PL | Libro %d | %s\nP2: %d PL | Libro %d | %s\nAeterna: %s | Meta demo: %d PL" % [turn_manager.current_round, active_text, turn_manager.actions_remaining, legacy_points.get_points(player_1.player_id), p1_book, str(player_1.current_coord), legacy_points.get_points(player_2.player_id), p2_book, str(player_2.current_coord), "DERROTADA" if coordinator.aeterna_state.defeated else "activa", DEMO_RACE_TARGET]


func _log(message: String) -> void:
	if message.is_empty(): return
	if _log_lines.is_empty() or _log_lines.back() != message: _log_lines.append(message)
	while _log_lines.size() > 16: _log_lines.pop_front()
	if log_label != null: log_label.text = "\n".join(_log_lines)
	print("FASE 24 UI: ", message)


func _setup_error(message: String) -> bool:
	last_demo_message = message
	push_error("FASE 24 SETUP ERROR: %s" % message)
	_log(message)
	return false


func _step_error(message: String) -> bool:
	last_demo_message = message
	push_error("FASE 24 STEP ERROR: %s" % message)
	_log("ERROR: " + message)
	return false
