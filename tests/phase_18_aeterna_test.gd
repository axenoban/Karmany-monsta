extends Node


const AETERNA: KarmanyData = preload("res://data/karmanys/k_24_aeterna_draconis.tres")
const SANCTUARY: KarmanyTileData = preload("res://data/tiles/l_01_santuario_de_aeterna.tres")
const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const EQ09: KarmanyEquipmentData = preload("res://data/equipment/eq_09_catalizador_de_aeterna.tres")
const R01: KarmanyResonanceData = preload("res://data/resonances/r_01_impulso_luminico.tres")
const R03: KarmanyResonanceData = preload("res://data/resonances/r_03_corte_de_bruma.tres")
const R04: KarmanyResonanceData = preload("res://data/resonances/r_04_embate_de_raiz.tres")
const R13: KarmanyResonanceData = preload("res://data/resonances/r_13_defensa_instintiva.tres")
const R22: KarmanyResonanceData = preload("res://data/resonances/r_22_mirada_del_sendero.tres")
const R37: KarmanyResonanceData = preload("res://data/resonances/r_37_instinto_de_caza.tres")


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 18 AETERNA TEST")
	print("================================")

	var ok: bool = true
	ok = _test_canonical_data_and_round_gate() and ok
	ok = _test_sanctuary_attunement_and_sync() and ok
	ok = _test_defeat_consequences() and ok
	ok = _test_victory_legacy_and_resonance_reward() and ok
	ok = _test_ancestral_equipment_reward_and_post_defeat_ek() and ok

	print("")
	print("================================")
	if ok:
		print("FASE 18 OK - Aeterna, Santuario, combate, PL y recompensas validados.")
	else:
		push_error("FASE 18 ERROR - Revisar sistema Aeterna Draconis.")
	print("================================")


func _test_canonical_data_and_round_gate() -> bool:
	var ok: bool = true
	ok = _expect(AETERNA != null and AETERNA.is_valid_definition(), "K-24 AeternaData invalido.") and ok
	ok = _expect(AETERNA.rank == KarmanyData.Rank.LEGENDARY, "K-24 debe ser Legendaria.") and ok
	ok = _expect(AETERNA.power == 18 and AETERNA.encounter_defense == 26, "K-24 debe tener Poder 18 / Defensa 26.") and ok
	ok = _expect(AETERNA.legacy_points == 8, "Aeterna debe valer 8 PL.") and ok
	ok = _expect(SANCTUARY != null and SANCTUARY.tile_id == "L-01", "L-01 Santuario ausente.") and ok
	ok = _expect(SANCTUARY.level == KarmanyTileData.TileLevel.SANCTUARY, "L-01 debe ser nivel SANCTUARY.") and ok
	ok = _expect(KarmanyAeternaResolver.get_minimum_round(KarmanyLegacyModeConfig.MapFormat.MAP_22) == 6, "Mapa 22 debe habilitar Aeterna desde ronda 6.") and ok
	ok = _expect(KarmanyAeternaResolver.get_minimum_round(KarmanyLegacyModeConfig.MapFormat.MAP_41) == 8, "Mapa 41 debe habilitar Aeterna desde ronda 8.") and ok

	var setup := _new_setup(KarmanyLegacyModeConfig.MapFormat.MAP_22, 5, 3, 1)
	var early := KarmanyAeternaResolver.resolve_combat(setup.p1, setup.context)
	ok = _expect(early.status == KarmanyAeternaResult.Status.TOO_EARLY, "Ronda 5 debe bloquear el intento en mapa 22.") and ok
	ok = _expect(setup.turn.actions_remaining == 2 and setup.p1.fa == 1, "Intento demasiado temprano no debe gastar accion ni FA.") and ok

	print("Datos K-24/L-01 + puerta temporal 6/8: ", "OK" if ok else "ERROR")
	return ok


func _test_sanctuary_attunement_and_sync() -> bool:
	var attune_setup := _new_setup(KarmanyLegacyModeConfig.MapFormat.MAP_22, 2, 1, 0)
	var ok: bool = true
	var attune := KarmanyAeternaResolver.resolve_sanctuary_attunement(
		attune_setup.p1,
		attune_setup.context,
		KarmanyAeternaResolver.PREPARATION_GAIN_FA
	)
	ok = _expect(attune.is_resolved(), "Sintonia del Santuario debe resolverse sin requisitos de Aeterna.") and ok
	ok = _expect(attune_setup.p1.fa == 1, "Sintonia opcion A debe dar +1 FA.") and ok
	ok = _expect(attune_setup.turn.actions_remaining == 2, "Sintonia del Santuario no cuesta accion.") and ok
	var repeated := KarmanyAeternaResolver.resolve_sanctuary_attunement(
		attune_setup.p1,
		attune_setup.context,
		KarmanyAeternaResolver.PREPARATION_GAIN_FA
	)
	ok = _expect(repeated.status == KarmanyAeternaResult.Status.ALREADY_USED, "Sintonia del Santuario solo puede usarse una vez por jugador.") and ok

	var sync_setup := _new_setup(KarmanyLegacyModeConfig.MapFormat.MAP_22, 2, 1, 0)
	var sync := KarmanyAeternaResolver.resolve_aeterna_sync(sync_setup.p1, sync_setup.context)
	ok = _expect(sync.is_resolved(), "Sintonizar con Aeterna debe estar disponible en Santuario.") and ok
	ok = _expect(sync.action_consumed and sync_setup.turn.actions_remaining == 1, "Sintonizar debe consumir 1 accion.") and ok
	ok = _expect(sync.resonance_cards_drawn == 3 and sync.resonance_discard_pending == 2, "Sintonizar debe robar 3 y conservar 1.") and ok
	ok = _expect(sync_setup.p1.resonance_hand.get_pending_discard_count() == 2, "La eleccion de 2 descartes debe quedar pendiente.") and ok
	var sync_repeat := KarmanyAeternaResolver.resolve_aeterna_sync(sync_setup.p1, sync_setup.context)
	ok = _expect(sync_repeat.status == KarmanyAeternaResult.Status.ALREADY_USED, "Sintonizar solo puede usarse una vez por partida por jugador.") and ok

	print("Sintonia gratuita + Sintonizar 1 accion / una vez: ", "OK" if ok else "ERROR")
	return ok


func _test_defeat_consequences() -> bool:
	var setup := _new_setup(KarmanyLegacyModeConfig.MapFormat.MAP_22, 6, 3, 1)
	var ok: bool = true
	setup.context.instinct_roll = 6
	var hand_seeded := setup.deck.draw_to_hand(setup.p1.resonance_hand, 1)
	ok = _expect(hand_seeded == 1, "No se pudo preparar Resonancia para penalizacion.") and ok

	var result := KarmanyAeternaResolver.resolve_combat(setup.p1, setup.context)
	ok = _expect(result.is_defeat(), "Terrakor sin modificadores debe perder contra Aeterna 28 efectiva.") and ok
	ok = _expect(result.action_consumed and result.fa_spent == 1 and setup.p1.fa == 0, "La derrota debe consumir accion y el FA del intento.") and ok
	ok = _expect(result.basic_resources_discard_pending == 2, "Derrota debe pedir 2 recursos basicos.") and ok
	ok = _expect(result.resonance_discard_pending == 1, "Derrota debe pedir descartar 1 Resonancia.") and ok
	ok = _expect(result.retreat_required, "Derrota contra Aeterna debe requerir retroceso.") and ok
	ok = _expect(not setup.aeterna_state.defeated, "Aeterna debe permanecer disponible tras derrota del jugador.") and ok
	ok = _expect(setup.legacy.get_total(setup.p1.player_id) == 0, "Derrota no debe otorgar PL.") and ok

	print("Derrota: FA + 2 basicos + 1 Resonancia + retroceso: ", "OK" if ok else "ERROR")
	return ok


func _test_victory_legacy_and_resonance_reward() -> bool:
	var setup := _new_setup(KarmanyLegacyModeConfig.MapFormat.MAP_22, 6, 3, 1)
	var ok: bool = true
	setup.context.instinct_roll = 6
	setup.context.modifiers.other_power = 30

	var result := KarmanyAeternaResolver.resolve_combat(setup.p1, setup.context)
	ok = _expect(result.is_victory(), "Poder suficiente debe derrotar Aeterna.") and ok
	ok = _expect(result.combat_result.effective_defense == 28, "Instinto 6 debe llevar Defensa 26 a 28.") and ok
	ok = _expect(setup.aeterna_state.defeated, "Aeterna debe marcarse derrotada globalmente.") and ok
	ok = _expect(setup.legacy.get_total(setup.p1.player_id) == 8, "Victoria debe registrar 8 PL centralizados.") and ok
	ok = _expect(result.reward_choice_required, "Victoria debe exigir elegir recompensa final.") and ok

	var reward_ok := KarmanyAeternaResolver.resolve_victory_resonance_reward(setup.p1, setup.context, result)
	ok = _expect(reward_ok, "Debe poder elegirse recompensa de Resonancias.") and ok
	ok = _expect(result.reward_resolved and result.reward_choice == KarmanyAeternaResult.RewardChoice.RESONANCES, "La ruta de Resonancias debe quedar registrada.") and ok
	ok = _expect(result.resonance_cards_drawn == 3 and result.resonance_discard_pending == 1, "Recompensa debe robar 3 y conservar 2.") and ok

	var second_attempt := KarmanyAeternaResolver.resolve_combat(setup.p1, setup.context)
	ok = _expect(second_attempt.status == KarmanyAeternaResult.Status.ALREADY_DEFEATED, "Aeterna solo puede ser derrotada una vez.") and ok
	ok = _expect(setup.legacy.get_total(setup.p1.player_id) == 8, "Segundo intento no puede duplicar los 8 PL.") and ok

	print("Victoria: Instinto + 8 PL + recompensa Resonancias + unica derrota: ", "OK" if ok else "ERROR")
	return ok


func _test_ancestral_equipment_reward_and_post_defeat_ek() -> bool:
	var setup := _new_setup(KarmanyLegacyModeConfig.MapFormat.MAP_22, 6, 3, 1)
	var ok: bool = true
	setup.context.instinct_roll = 1
	setup.context.modifiers.other_power = 25
	var result := KarmanyAeternaResolver.resolve_combat(setup.p1, setup.context)
	ok = _expect(result.is_victory(), "No se pudo preparar segunda victoria Aeterna de test.") and ok
	ok = _expect(
		KarmanyAeternaResolver.resolve_victory_equipment_reward(setup.p1, result, EQ09),
		"Debe poder elegirse 1 Equipo Ancestral como recompensa."
	) and ok
	ok = _expect(setup.p1.equipment_inventory.has_equipment_id(&"EQ-09"), "EQ-09 debe quedar equipado.") and ok
	ok = _expect(result.reward_choice == KarmanyAeternaResult.RewardChoice.ANCESTRAL_EQUIPMENT, "La ruta Equipo Ancestral debe quedar registrada.") and ok

	var ek_before: int = setup.p1.ek
	var post := KarmanyAeternaResolver.collect_post_defeat_ek(setup.p1, setup.context)
	ok = _expect(post.is_resolved() and post.post_defeat_ek_gained == 2, "Santuario post-derrota debe otorgar +2 EK.") and ok
	ok = _expect(setup.p1.ek == ek_before + 2, "Los 2 EK deben entrar al inventario.") and ok
	var repeated := KarmanyAeternaResolver.collect_post_defeat_ek(setup.p1, setup.context)
	ok = _expect(repeated.status == KarmanyAeternaResult.Status.ALREADY_USED, "Los 2 EK post-Aeterna son maximo una vez por ronda.") and ok

	print("Equipo Ancestral + Santuario post-derrota 2 EK/ronda: ", "OK" if ok else "ERROR")
	return ok


func _new_setup(
	map_format: int,
	round_number: int,
	book_level: int,
	fa_amount: int
) -> Dictionary:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", Vector2i.ZERO)
	p2.setup_new_game(&"player_2", Vector2i(1, 0))
	p1.fa = fa_amount

	var runtime := KarmanyRuntimeState.new()
	runtime.configure(TERRAKOR, &"terrakor_phase18")
	runtime.set_owner_player_id(p1.player_id)
	runtime.set_bond_state(KarmanyRuntimeState.BondState.LINKED)
	p1.add_linked_karmany(runtime)

	var board := KarmanyBoardState.new()
	board.add_cell(Vector2i.ZERO, SANCTUARY, true)
	board.add_cell(Vector2i(1, 0), null, true)
	board.set_unit_occupant(Vector2i.ZERO, p1.player_id)
	board.set_unit_occupant(Vector2i(1, 0), p2.player_id)

	var players: Array[KarmanyPlayerState] = [p1, p2]
	var turn := KarmanyTurnManager.new()
	turn.setup_players(players)
	turn.start_match()
	turn.current_round = round_number

	var mode := KarmanyLegacyModeConfig.new()
	mode.configure_standard(map_format)
	var legacy := KarmanyLegacyPointsController.new()
	legacy.configure(players, mode)

	var cards: Array[KarmanyResonanceData] = [R01, R03, R04, R13, R22, R37]
	var deck := KarmanyResonanceDeck.new()
	deck.setup(cards, false)

	var aeterna_state := KarmanyAeternaState.new()
	var context := KarmanyAeternaContext.new()
	context.board_state = board
	context.turn_manager = turn
	context.legacy_points_controller = legacy
	context.resonance_deck = deck
	context.aeterna_state = aeterna_state
	context.map_format = map_format
	context.book_level = book_level

	return {
		"p1": p1,
		"p2": p2,
		"board": board,
		"turn": turn,
		"legacy": legacy,
		"deck": deck,
		"aeterna_state": aeterna_state,
		"context": context
	}


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 18 ERROR: %s" % message)
	return false
