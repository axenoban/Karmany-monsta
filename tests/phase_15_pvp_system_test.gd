extends Node


const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const FLORAVIA: KarmanyData = preload("res://data/karmanys/k_05_floravia.tres")

const R01: KarmanyResonanceData = preload("res://data/resonances/r_01_impulso_luminico.tres")
const R03: KarmanyResonanceData = preload("res://data/resonances/r_03_corte_de_bruma.tres")
const R04: KarmanyResonanceData = preload("res://data/resonances/r_04_embate_de_raiz.tres")
const R13: KarmanyResonanceData = preload("res://data/resonances/r_13_defensa_instintiva.tres")
const R22: KarmanyResonanceData = preload("res://data/resonances/r_22_mirada_del_sendero.tres")
const R37: KarmanyResonanceData = preload("res://data/resonances/r_37_instinto_de_caza.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 15 PVP TEST")
	print("================================")

	var ok: bool = true
	ok = _test_round_one_is_forbidden() and ok
	ok = _test_authorization_range_and_active_karmany() and ok
	ok = _test_pvp_with_resonances_cross_reward_and_truce() and ok
	ok = _test_tie_goes_to_defender() and ok
	ok = _test_risk_validation_and_pending_consequence() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 15 OK - PvP, empate, Resonancia Cruzada, recompensa y Tregua validados.")
	else:
		push_error("FASE 15 ERROR - Revisar sistema PvP.")
	print("================================")


func _test_round_one_is_forbidden() -> bool:
	var setup := _make_setup(TERRAKOR, FLORAVIA, false)
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var manager: KarmanyTurnManager = setup.manager
	var context := _make_context(setup, &"PVP-R1")

	var before_actions: int = manager.actions_remaining
	var result := KarmanyPvpResolver.resolve(p1, p2, context)

	var ok: bool = true
	ok = _expect(
		result.status == KarmanyPvpCombatResult.Status.PVP_FORBIDDEN_ROUND_ONE,
		"PvP debe estar prohibido en ronda 1."
	) and ok
	ok = _expect(
		manager.actions_remaining == before_actions,
		"PvP rechazado en ronda 1 no debe consumir accion."
	) and ok
	ok = _expect(
		not context.truce_tracker.has_truce(p1.player_id, p2.player_id, 1),
		"Un PvP rechazado no debe crear Tregua."
	) and ok

	print("Ronda 1 prohibida sin coste: ", "OK" if ok else "ERROR")
	return ok


func _test_authorization_range_and_active_karmany() -> bool:
	var setup := _make_setup(TERRAKOR, FLORAVIA, true)
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var manager: KarmanyTurnManager = setup.manager
	var context := _make_context(setup, &"PVP-AUTH")

	context.authorization.source_id = &""
	var unauthorized := KarmanyPvpResolver.resolve(p1, p2, context)
	var ok: bool = _expect(
		unauthorized.status == KarmanyPvpCombatResult.Status.PVP_NOT_AUTHORIZED,
		"PvP requiere una fuente explicita que lo habilite."
	)
	ok = _expect(manager.actions_remaining == 2, "PvP no autorizado no consume accion.") and ok

	context.authorization.source_id = &"test_tile_pvp"
	p2.set_board_position(Vector2i(2, 0))
	var out_of_range := KarmanyPvpResolver.resolve(p1, p2, context)
	ok = _expect(
		out_of_range.status == KarmanyPvpCombatResult.Status.OUT_OF_RANGE,
		"Un rival fuera del alcance legal debe rechazarse."
	) and ok
	ok = _expect(manager.actions_remaining == 2, "Fuera de alcance no consume accion.") and ok

	var setup_no_active := _make_setup(TERRAKOR, null, true)
	var no_active_context := _make_context(setup_no_active, &"PVP-NO-ACTIVE")
	var no_active := KarmanyPvpResolver.resolve(
		setup_no_active.p1,
		setup_no_active.p2,
		no_active_context
	)
	ok = _expect(
		no_active.status == KarmanyPvpCombatResult.Status.NO_ACTIVE_KARMANY,
		"No se puede iniciar PvP contra un jugador sin Karmany activo."
	) and ok

	print("Autorizacion + alcance + Karmany activo: ", "OK" if ok else "ERROR")
	return ok


func _test_pvp_with_resonances_cross_reward_and_truce() -> bool:
	var setup := _make_setup(TERRAKOR, FLORAVIA, true)
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var context := _make_context(setup, &"PVP-MAIN")
	var deck: KarmanyResonanceDeck = context.resonance_deck
	var tracker: KarmanyResonanceUsageTracker = context.resonance_usage_tracker
	var manager: KarmanyTurnManager = setup.manager

	var ok: bool = true
	ok = _expect(p1.resonance_hand.add_card(R01), "No se pudo dar R-01 al atacante.") and ok
	ok = _expect(p2.resonance_hand.add_card(R04), "No se pudo dar R-04 al defensor.") and ok

	var attacker_use := KarmanyResonanceUseContext.new()
	attacker_use.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	attacker_use.context_tags = PackedStringArray(["combat", "pvp"])
	attacker_use.combat_id = context.combat_id
	attacker_use.combat_modifiers = context.attacker_modifiers
	attacker_use.effect_context = context.effect_context
	attacker_use.usage_tracker = tracker

	var defender_use := KarmanyResonanceUseContext.new()
	defender_use.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	defender_use.context_tags = PackedStringArray(["combat", "pvp"])
	defender_use.combat_id = context.combat_id
	defender_use.combat_modifiers = context.defender_modifiers
	defender_use.effect_context = context.effect_context
	defender_use.usage_tracker = tracker

	var attacker_play := KarmanyResonanceResolver.play_from_hand(
		p1,
		&"R-01",
		deck,
		attacker_use
	)
	var defender_play := KarmanyResonanceResolver.play_from_hand(
		p2,
		&"R-04",
		deck,
		defender_use
	)
	ok = _expect(attacker_play.is_success(), "Atacante debe poder jugar R-01.") and ok
	ok = _expect(defender_play.is_success(), "Defensor debe poder jugar R-04.") and ok
	ok = _expect(
		context.attacker_modifiers.resonance_power == 4,
		"R-01 debe aportar +4 Poder."
	) and ok
	ok = _expect(
		context.defender_modifiers.resonance_power == 3,
		"R-04 debe aportar +3 en PvP; su +2 extra es solo contra Bestia."
	) and ok

	var ek_before: int = p1.ek
	var result := KarmanyPvpResolver.resolve(p1, p2, context)

	ok = _expect(result.is_resolved(), "PvP principal debe resolverse.") and ok
	ok = _expect(result.did_attacker_win(), "Terrakor + R-01 debe superar Floravia + R-04.") and ok
	ok = _expect(result.attacker_power == 10, "Poder atacante esperado: 6 + 4 = 10.") and ok
	ok = _expect(result.defender_power == 8, "Poder defensor esperado: 5 + 3 = 8.") and ok
	ok = _expect(result.action_consumed and manager.actions_remaining == 1, "PvP debe consumir 1 accion.") and ok
	ok = _expect(result.reward_legacy_points_pending == 2, "Recompensa base PvP debe quedar en 2 PL pendientes.") and ok
	ok = _expect(result.loser_player_id == p2.player_id and result.loser_retreat_required, "El perdedor debe quedar marcado para retroceso.") and ok
	ok = _expect(result.truce_applied, "Todo PvP resuelto debe aplicar Tregua.") and ok
	ok = _expect(
		context.truce_tracker.has_truce(p1.player_id, p2.player_id, manager.current_round),
		"La Tregua debe registrar atacante -> defensor durante la ronda."
	) and ok
	ok = _expect(
		context.truce_tracker.can_attack(p2.player_id, p1.player_id, manager.current_round),
		"La Tregua no debe bloquear automaticamente el ataque inverso."
	) and ok
	ok = _expect(result.resonance_cross_attacker_drawn == 1, "Resonancia Cruzada debe dar 1 carta al atacante.") and ok
	ok = _expect(result.resonance_cross_defender_drawn == 1, "Resonancia Cruzada debe dar 1 carta al defensor.") and ok
	ok = _expect(result.combat_resonances_discarded == 2, "Las dos Resonancias jugadas deben ir al descarte.") and ok
	ok = _expect(p1.ek == ek_before + 2, "R-01 debe recuperar 2 EK tras ganar el PvP.") and ok

	var repeat_context := _make_context(
		setup,
		&"PVP-REPEAT",
		context.truce_tracker,
		deck,
		tracker
	)
	var before_repeat_actions: int = manager.actions_remaining
	var repeated := KarmanyPvpResolver.resolve(p1, p2, repeat_context)
	ok = _expect(
		repeated.status == KarmanyPvpCombatResult.Status.TRUCE_BLOCKED,
		"El mismo atacante no puede atacar al mismo defensor dos veces en la ronda."
	) and ok
	ok = _expect(
		manager.actions_remaining == before_repeat_actions,
		"Tregua rechazada no debe gastar la accion restante."
	) and ok
	ok = _expect(
		context.truce_tracker.can_attack(p1.player_id, p2.player_id, manager.current_round + 1),
		"La Tregua debe expirar en la ronda siguiente."
	) and ok

	print("PvP + Resonancias + 2 PL pendientes + Tregua: ", "OK" if ok else "ERROR")
	return ok


func _test_tie_goes_to_defender() -> bool:
	var setup := _make_setup(TERRAKOR, TERRAKOR, true)
	var p1: KarmanyPlayerState = setup.p1
	var p2: KarmanyPlayerState = setup.p2
	var context := _make_context(setup, &"PVP-TIE")
	var result := KarmanyPvpResolver.resolve(p1, p2, context)

	var ok: bool = true
	ok = _expect(result.is_resolved(), "El empate debe resolverse.") and ok
	ok = _expect(result.was_tie, "Debe registrarse el empate de Poder.") and ok
	ok = _expect(result.defender_won_tie, "En empate debe ganar quien no inicio el PvP.") and ok
	ok = _expect(result.did_defender_win(), "El defensor debe ser el ganador del empate.") and ok
	ok = _expect(result.reward_legacy_points_pending == 2, "El ganador del PvP conserva recompensa base de 2 PL.") and ok
	ok = _expect(result.loser_player_id == p1.player_id, "En empate el atacante debe ser el perdedor.") and ok
	ok = _expect(result.resonance_cross_attacker_drawn == 1 and result.resonance_cross_defender_drawn == 1, "Resonancia Cruzada debe ocurrir tambien en empate resuelto.") and ok

	print("Empate -> defensor + Resonancia Cruzada: ", "OK" if ok else "ERROR")
	return ok


func _test_risk_validation_and_pending_consequence() -> bool:
	var invalid_setup := _make_setup(TERRAKOR, TERRAKOR, true)
	var invalid_context := _make_context(invalid_setup, &"PVP-RISK-BAD")
	invalid_context.attacker_risk_roll = 5
	invalid_context.attacker_risk_authorized = false
	var invalid := KarmanyPvpResolver.resolve(
		invalid_setup.p1,
		invalid_setup.p2,
		invalid_context
	)

	var ok: bool = _expect(
		invalid.status == KarmanyPvpCombatResult.Status.INVALID_REQUEST,
		"Dado de Riesgo no autorizado debe rechazarse en PvP."
	)
	ok = _expect(invalid_setup.manager.actions_remaining == 2, "Riesgo invalido no consume accion.") and ok

	var valid_setup := _make_setup(TERRAKOR, TERRAKOR, true)
	var valid_context := _make_context(valid_setup, &"PVP-RISK-GOOD")
	valid_context.attacker_risk_authorized = true
	valid_context.attacker_risk_roll = 6
	var valid := KarmanyPvpResolver.resolve(
		valid_setup.p1,
		valid_setup.p2,
		valid_context
	)
	ok = _expect(valid.did_attacker_win(), "Riesgo 6 autorizado debe aportar +10 Poder al atacante.") and ok
	ok = _expect(valid.attacker_risk_adjustment == 10, "La cara 6 debe valer +10 Poder.") and ok
	ok = _expect(
		valid.attacker_pending_consequences.has(KarmanyPvpResolver.CONSEQUENCE_RISK_WIN_REWARD),
		"Victoria con Riesgo 6 debe conservar la eleccion +1 PL o +2 recursos como consecuencia pendiente."
	) and ok

	print("Dado de Riesgo PvP autorizado/invalidado: ", "OK" if ok else "ERROR")
	return ok


func _make_setup(
	p1_karmany: KarmanyData,
	p2_karmany: KarmanyData,
	advance_to_round_two: bool
) -> Dictionary:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i(0, 0))
	p2.setup_new_game(&"player_2", Vector2i(1, 0))

	if p1_karmany != null:
		_add_active_karmany(p1, p1_karmany, &"p1-active")
	if p2_karmany != null:
		_add_active_karmany(p2, p2_karmany, &"p2-active")

	var board := KarmanyBoardState.new()
	board.add_cell(Vector2i(0, 0), null, true)
	board.add_cell(Vector2i(1, 0), null, true)
	board.add_cell(Vector2i(2, 0), null, true)

	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()

	if advance_to_round_two:
		manager.spend_action(2)
		manager.end_turn()
		manager.spend_action(2)
		manager.end_turn()

	return {
		"p1": p1,
		"p2": p2,
		"board": board,
		"manager": manager
	}


func _make_context(
	setup: Dictionary,
	combat_id: StringName,
	shared_truce: KarmanyPvpTruceTracker = null,
	shared_deck: KarmanyResonanceDeck = null,
	shared_usage: KarmanyResonanceUsageTracker = null
) -> KarmanyPvpCombatContext:
	var context := KarmanyPvpCombatContext.new()
	context.turn_manager = setup.manager
	context.board_state = setup.board

	context.authorization = KarmanyPvpAuthorizationContext.new()
	context.authorization.source_id = &"test_pvp_source"
	context.authorization.range_mode = KarmanyPvpAuthorizationContext.RangeMode.SAME_OR_ADJACENT

	context.truce_tracker = shared_truce if shared_truce != null else KarmanyPvpTruceTracker.new()
	context.resonance_usage_tracker = shared_usage if shared_usage != null else KarmanyResonanceUsageTracker.new()
	context.resonance_deck = shared_deck if shared_deck != null else _make_deck()
	context.effect_context = KarmanyEffectContext.new()
	context.combat_id = combat_id
	return context


func _make_deck() -> KarmanyResonanceDeck:
	var deck := KarmanyResonanceDeck.new()
	var cards: Array[KarmanyResonanceData] = []
	cards.append(R03)
	cards.append(R13)
	cards.append(R22)
	cards.append(R37)
	deck.setup(cards, false, 1501)
	return deck


func _add_active_karmany(
	player: KarmanyPlayerState,
	data: KarmanyData,
	instance_id: StringName
) -> bool:
	var runtime := KarmanyRuntimeState.new()
	if not runtime.configure(data, instance_id):
		return false
	runtime.set_owner_player_id(player.player_id)
	if not runtime.set_bond_state(KarmanyRuntimeState.BondState.LINKED):
		return false
	if not player.add_linked_karmany(runtime):
		return false
	return player.get_active_karmany() == runtime


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 15 ERROR: %s" % message)
	return false
