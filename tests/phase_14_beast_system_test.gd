extends Node


const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const FLORAVIA: KarmanyData = preload("res://data/karmanys/k_05_floravia.tres")
const B01: KarmanyBeastData = preload("res://data/beasts/b_01_garravol.tres")
const B02: KarmanyBeastData = preload("res://data/beasts/b_02_picorroca.tres")
const B04: KarmanyBeastData = preload("res://data/beasts/b_04_murcielago_bruma.tres")
const B15: KarmanyBeastData = preload("res://data/beasts/b_15_vermis_de_cristal.tres")
const B22: KarmanyBeastData = preload("res://data/beasts/b_22_custodio_del_santuario.tres")
const R01: KarmanyResonanceData = preload("res://data/resonances/r_01_impulso_luminico.tres")
const R03: KarmanyResonanceData = preload("res://data/resonances/r_03_corte_de_bruma.tres")
const R04: KarmanyResonanceData = preload("res://data/resonances/r_04_embate_de_raiz.tres")
const R13: KarmanyResonanceData = preload("res://data/resonances/r_13_defensa_instintiva.tres")


const ORIGIN: Vector2i = Vector2i.ZERO
const TARGET: Vector2i = Vector2i(1, 0)
const TRAINER_UNIT_ID: StringName = &"trainer_player_1"


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 14 BEAST SYSTEM TEST")
	print("================================")

	var test_passed: bool = true
	test_passed = _test_beast_definitions() and test_passed
	test_passed = _test_spawn_block_and_single_beast() and test_passed
	test_passed = _test_defeat_keeps_beast_blocking() and test_passed
	test_passed = _test_victory_unblocks_enters_and_rewards() and test_passed
	test_passed = _test_effect_resolver_spawns_mandatory_beast() and test_passed
	test_passed = _test_resonance_reward_and_defeat_penalty() and test_passed
	test_passed = _test_non_initial_exhaustion_is_reported() and test_passed

	print("")
	print("================================")
	if test_passed:
		print("FASE 14 OK - Bestias, bloqueo, combate obligatorio y permanencia validados.")
	else:
		push_error("FASE 14 ERROR - Revisar sistema de Bestias.")
	print("================================")


func _test_beast_definitions() -> bool:
	var ok: bool = true
	for beast in [B01, B02, B04, B15, B22]:
		ok = _expect(
			beast.is_valid_definition(),
			"Definicion invalida: %s" % beast.display_name
		) and ok

	ok = _expect(B01.base_defense == 8 and B01.reward_legacy_points == 1, "B-01 debe ser Defensa 8 / 1 PL.") and ok
	ok = _expect(B02.tier == KarmanyBeastData.Tier.BASIC, "B-02 debe ser Basica.") and ok
	ok = _expect(B04.reward_effects.size() == 2, "B-04 debe robar 3 y pedir descarte 1 como recompensa.") and ok
	ok = _expect(B15.tier == KarmanyBeastData.Tier.COMPLEX and B15.base_defense == 18, "B-15 debe ser Compleja Defensa 18.") and ok
	ok = _expect(B22.is_boss() and B22.base_defense == 22, "B-22 debe ser Jefe Defensa 22.") and ok

	print("BeastData + fixtures v0.74: ", "OK" if ok else "ERROR")
	return ok


func _test_spawn_block_and_single_beast() -> bool:
	var player := _new_player(&"player_1")
	var opponent := _new_player(&"player_2")
	var manager := _make_turn_manager(player, opponent)
	var board := _make_two_cell_board(player)
	var deck := _make_basic_deck([B02, B04])
	var ok: bool = true

	var spawn := KarmanyBeastEncounterResolver.spawn_from_deck(
		board,
		TARGET,
		deck
	)
	ok = _expect(spawn.is_spawned(), "B-02 debe aparecer en la loseta destino.") and ok
	ok = _expect(spawn.beast_state.beast_data == B02, "El primer robo determinista debe ser B-02.") and ok
	ok = _expect(board.has_beast(TARGET), "BoardState debe registrar la Bestia.") and ok
	ok = _expect(board.is_blocked_by_beast(TARGET), "La loseta debe quedar bloqueada.") and ok

	var draw_count_before := deck.get_draw_count()
	var second_spawn := KarmanyBeastEncounterResolver.spawn_from_deck(
		board,
		TARGET,
		deck
	)
	ok = _expect(
		second_spawn.status == KarmanyBeastSpawnResult.Status.TILE_ALREADY_HAS_BEAST,
		"No debe revelarse una segunda Bestia en la misma loseta."
	) and ok
	ok = _expect(deck.get_draw_count() == draw_count_before, "Revelado rechazado no debe consumir otra carta.") and ok

	var move_validation := KarmanyMovementRules.validate_move(
		board,
		manager,
		player,
		TARGET
	)
	ok = _expect(
		move_validation == KarmanyMovementRules.MoveValidation.TARGET_BLOCKED_BY_BEAST,
		"Mover normal debe rechazar una loseta bloqueada por Bestia."
	) and ok

	print("Aparicion + 1 Bestia/loseta + bloqueo de Mover: ", "OK" if ok else "ERROR")
	return ok


func _test_defeat_keeps_beast_blocking() -> bool:
	var player := _new_player(&"player_1")
	var opponent := _new_player(&"player_2")
	var manager := _make_turn_manager(player, opponent)
	var board := _make_two_cell_board(player)
	var deck := _make_basic_deck([B02])
	var ok: bool = true

	ok = _expect(
		KarmanyBeastEncounterResolver.spawn_from_deck(board, TARGET, deck).is_spawned(),
		"No se pudo preparar Picorroca."
	) and ok

	var context := KarmanyBeastCombatContext.new()
	context.turn_manager = manager
	context.instinct_roll = 6
	context.enter_after_victory = true
	context.moving_unit_id = TRAINER_UNIT_ID

	var combat := KarmanyBeastEncounterResolver.resolve_combat(
		player,
		TERRAKOR,
		board,
		TARGET,
		deck,
		context
	)

	ok = _expect(combat.is_defeat(), "Terrakor 6 contra Defensa efectiva 10 debe perder.") and ok
	ok = _expect(combat.action_consumed, "Combatir debe consumir 1 accion.") and ok
	ok = _expect(manager.actions_remaining == 1, "Debe quedar 1 accion tras Combatir.") and ok
	ok = _expect(combat.remains_blocking and board.has_beast(TARGET), "La Bestia debe permanecer tras la derrota.") and ok
	ok = _expect(player.current_coord == ORIGIN, "El jugador debe permanecer/volver a su loseta previa.") and ok
	ok = _expect(combat.retreat_required, "Toda derrota contra Bestia debe reportar retroceso.") and ok
	ok = _expect(not combat.attacker_exhaustion_pending, "El Karmany inicial no debe agotarse por derrota.") and ok
	ok = _expect(deck.get_discard_count() == 0, "Una Bestia no derrotada no va al descarte.") and ok

	var still_blocked := KarmanyMovementRules.validate_move(
		board,
		manager,
		player,
		TARGET
	)
	ok = _expect(
		still_blocked == KarmanyMovementRules.MoveValidation.TARGET_BLOCKED_BY_BEAST,
		"Tras perder, la loseta debe continuar bloqueada."
	) and ok

	print("Derrota -> retroceso reportado + Bestia permanece: ", "OK" if ok else "ERROR")
	return ok


func _test_victory_unblocks_enters_and_rewards() -> bool:
	var player := _new_player(&"player_1")
	var opponent := _new_player(&"player_2")
	var manager := _make_turn_manager(player, opponent)
	var board := _make_two_cell_board(player, 1)
	var deck := _make_basic_deck([B02])
	var ok: bool = true

	ok = _expect(
		KarmanyBeastEncounterResolver.spawn_from_deck(board, TARGET, deck).is_spawned(),
		"No se pudo preparar Picorroca para victoria."
	) and ok

	var context := KarmanyBeastCombatContext.new()
	context.turn_manager = manager
	context.instinct_roll = 3
	context.enter_after_victory = true
	context.moving_unit_id = TRAINER_UNIT_ID
	context.combat_modifiers.other_power = 4

	var combat := KarmanyBeastEncounterResolver.resolve_combat(
		player,
		TERRAKOR,
		board,
		TARGET,
		deck,
		context
	)

	ok = _expect(combat.is_victory(), "Terrakor 6 +4 debe derrotar Defensa 8.") and ok
	ok = _expect(combat.beast_removed and not board.has_beast(TARGET), "La Bestia derrotada debe salir del tablero.") and ok
	ok = _expect(not board.is_blocked_by_beast(TARGET), "La loseta debe desbloquearse tras victoria.") and ok
	ok = _expect(combat.entered_tile_after_victory and player.current_coord == TARGET, "El jugador debe entrar tras derrotar la Bestia.") and ok
	ok = _expect(board.get_occupying_unit_id(TARGET) == TRAINER_UNIT_ID, "La ocupacion logica debe moverse a destino.") and ok
	ok = _expect(board.get_occupying_unit_id(ORIGIN) == &"", "La ocupacion de origen debe liberarse.") and ok
	ok = _expect(combat.entry_bonus_allowed, "La Bonificacion de entrada debe habilitarse solo tras victoria.") and ok
	ok = _expect(player.mn == 3, "La Entrada de prueba debe sumar +1 MN.") and ok
	ok = _expect(player.mr == 3, "Picorroca debe recompensar +2 MR.") and ok
	ok = _expect(combat.reward_legacy_points_pending == 1, "Picorroca debe reportar 1 PL pendiente para Fase 17.") and ok
	ok = _expect(deck.get_discard_count() == 1, "Bestia derrotada debe ir al descarte de su mazo.") and ok
	ok = _expect(manager.actions_remaining == 1, "Combatir debe consumir exactamente 1 accion.") and ok

	var recycled := deck.draw_card()
	ok = _expect(recycled == B02, "Al agotarse el mazo, la Bestia derrotada debe reciclarse desde descarte.") and ok

	print("Victoria -> entrada + Entry + recompensa + descarte: ", "OK" if ok else "ERROR")
	return ok


func _test_effect_resolver_spawns_mandatory_beast() -> bool:
	var player := _new_player(&"player_1")
	var board := _make_single_cell_board(player)
	var deck := _make_basic_deck([B04])
	var effect_context := KarmanyEffectContext.new()
	var adapter := KarmanyBeastEffectAdapter.new()
	var ok: bool = _expect(adapter.setup(board), "No se pudo preparar BeastEffectAdapter.")
	ok = _expect(adapter.register_deck(&"beast_basic", deck), "No se pudo registrar mazo Basico.") and ok
	ok = _expect(adapter.configure_context(effect_context), "No se conecto TRIGGER_ENCOUNTER.") and ok

	var effect := KarmanyEffectData.new()
	effect.effect_type = KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER
	effect.encounter_id = &"beast_basic"

	var applied := KarmanyEffectResolver.apply_effect(effect, player, effect_context)
	ok = _expect(applied.was_applied(), "TRIGGER_ENCOUNTER debe ser resuelto por el adaptador.") and ok
	ok = _expect(board.has_beast(ORIGIN), "La Bestia debe aparecer en la loseta actual.") and ok
	ok = _expect(adapter.last_spawn_result != null and adapter.last_spawn_result.requires_immediate_combat, "Una Bestia generada en la loseta actual debe marcar combate inmediato.") and ok

	var applied_again := KarmanyEffectResolver.apply_effect(effect, player, effect_context)
	ok = _expect(applied_again.was_applied(), "Un segundo efecto sobre loseta bloqueada debe resolverse sin otra Bestia.") and ok
	ok = _expect(deck.get_draw_count() == 0, "No debe consumirse una segunda Bestia inexistente.") and ok

	print("EffectResolver -> aparicion Bestia + combate inmediato: ", "OK" if ok else "ERROR")
	return ok


func _test_resonance_reward_and_defeat_penalty() -> bool:
	var ok: bool = true

	# Victoria: B-04 roba 3 Resonancias y exige descartar 1.
	var winner := _new_player(&"player_1")
	var winner_board := _make_single_cell_board(winner)
	var winner_beast_deck := _make_basic_deck([B04])
	ok = _expect(
		KarmanyBeastEncounterResolver.spawn_from_deck(
			winner_board,
			ORIGIN,
			winner_beast_deck,
			true
		).is_spawned(),
		"No se pudo preparar B-04 para recompensa."
	) and ok

	var resonance_deck := KarmanyResonanceDeck.new()
	var resonance_cards: Array[KarmanyResonanceData] = []
	resonance_cards.append(R01)
	resonance_cards.append(R03)
	resonance_cards.append(R04)
	resonance_cards.append(R13)
	ok = _expect(resonance_deck.setup(resonance_cards, false, 1401), "Mazo de Resonancias invalido.") and ok
	var reward_effect_context := KarmanyEffectContext.new()
	var resonance_adapter := KarmanyResonanceEffectAdapter.new()
	ok = _expect(resonance_adapter.setup(resonance_deck), "No se preparo adaptador de Resonancias.") and ok
	ok = _expect(resonance_adapter.configure_context(reward_effect_context), "No se conecto adaptador de Resonancias.") and ok

	var win_context := KarmanyBeastCombatContext.new()
	win_context.action_cost = 0
	win_context.instinct_roll = 3
	win_context.combat_modifiers.other_power = 4
	win_context.effect_context = reward_effect_context

	var victory := KarmanyBeastEncounterResolver.resolve_combat(
		winner,
		TERRAKOR,
		winner_board,
		ORIGIN,
		winner_beast_deck,
		win_context
	)
	ok = _expect(victory.is_victory(), "B-04 debe ser derrotada en el escenario de recompensa.") and ok
	ok = _expect(winner.get_resonance_count() == 3, "B-04 debe robar 3 Resonancias.") and ok
	ok = _expect(winner.resonance_hand.get_pending_discard_count() == 1, "B-04 debe exigir descartar 1 Resonancia elegida.") and ok
	ok = _expect(victory.reward_legacy_points_pending == 1, "B-04 debe reportar 1 PL pendiente.") and ok

	# Derrota: la Bestia permanece y exige descartar una Resonancia.
	var loser := _new_player(&"player_1")
	var loser_board := _make_single_cell_board(loser)
	var loser_beast_deck := _make_basic_deck([B04])
	ok = _expect(loser.resonance_hand.add_card(R01), "No se pudo preparar mano para derrota B-04.") and ok
	ok = _expect(
		KarmanyBeastEncounterResolver.spawn_from_deck(
			loser_board,
			ORIGIN,
			loser_beast_deck,
			true
		).is_spawned(),
		"No se pudo preparar B-04 para derrota."
	) and ok

	var loser_resonance_deck := KarmanyResonanceDeck.new()
	var loser_draw_cards: Array[KarmanyResonanceData] = []
	loser_draw_cards.append(R03)
	ok = _expect(loser_resonance_deck.setup(loser_draw_cards, false, 1402), "Mazo auxiliar de derrota invalido.") and ok
	var defeat_effect_context := KarmanyEffectContext.new()
	var loser_adapter := KarmanyResonanceEffectAdapter.new()
	ok = _expect(loser_adapter.setup(loser_resonance_deck), "No se preparo adaptador de derrota.") and ok
	ok = _expect(loser_adapter.configure_context(defeat_effect_context), "No se conecto descarte de derrota.") and ok

	var lose_context := KarmanyBeastCombatContext.new()
	lose_context.action_cost = 0
	lose_context.instinct_roll = 6
	lose_context.effect_context = defeat_effect_context

	var defeat := KarmanyBeastEncounterResolver.resolve_combat(
		loser,
		TERRAKOR,
		loser_board,
		ORIGIN,
		loser_beast_deck,
		lose_context
	)
	ok = _expect(defeat.is_defeat(), "Terrakor debe perder contra Defensa efectiva 10.") and ok
	ok = _expect(loser_board.has_beast(ORIGIN), "B-04 debe permanecer tras derrota.") and ok
	ok = _expect(loser.resonance_hand.get_pending_discard_count() == 1, "Derrota B-04 debe pedir descartar 1 Resonancia.") and ok

	print("Recompensa/derrota de Resonancias via EffectResolver: ", "OK" if ok else "ERROR")
	return ok


func _test_non_initial_exhaustion_is_reported() -> bool:
	var player := _new_player(&"player_1")
	var board := _make_single_cell_board(player)
	var deck := _make_basic_deck([B01])
	var ok: bool = _expect(
		KarmanyBeastEncounterResolver.spawn_from_deck(board, ORIGIN, deck, true).is_spawned(),
		"No se pudo preparar Garravol."
	)

	var context := KarmanyBeastCombatContext.new()
	context.action_cost = 0
	context.instinct_roll = 6

	var defeat := KarmanyBeastEncounterResolver.resolve_combat(
		player,
		FLORAVIA,
		board,
		ORIGIN,
		deck,
		context
	)
	ok = _expect(defeat.is_defeat(), "Floravia 5 debe perder contra Garravol Defensa efectiva 10.") and ok
	ok = _expect(defeat.attacker_exhaustion_pending, "Karmany no inicial derrotado debe reportar Agotado pendiente.") and ok
	ok = _expect(defeat.defeat_consequence_ids.has("discard_2_basic_resources_choice"), "Garravol debe conservar su penalizacion elegida en datos.") and ok

	print("Derrota de Karmany no inicial -> Agotado pendiente: ", "OK" if ok else "ERROR")
	return ok


func _make_two_cell_board(
	player: KarmanyPlayerState,
	entry_mn_bonus: int = 0
) -> KarmanyBoardState:
	var board := KarmanyBoardState.new()
	var origin_tile := KarmanyTileData.new()
	origin_tile.tile_id = "TEST-ORIGIN"
	origin_tile.display_name = "Origen de prueba"
	origin_tile.starts_revealed = true

	var target_tile := KarmanyTileData.new()
	target_tile.tile_id = "TEST-TARGET"
	target_tile.display_name = "Destino de Bestia"
	target_tile.level = KarmanyTileData.TileLevel.N1
	target_tile.starts_revealed = true

	if entry_mn_bonus > 0:
		var entry_effect := KarmanyEffectData.new()
		entry_effect.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
		entry_effect.resource_type = KarmanyEffectData.ResourceType.MN
		entry_effect.amount = entry_mn_bonus
		target_tile.entry_effects.append(entry_effect)

	board.add_cell(ORIGIN, origin_tile, true)
	board.add_cell(TARGET, target_tile, true)
	board.set_unit_occupant(ORIGIN, TRAINER_UNIT_ID)
	player.set_board_position(ORIGIN)
	return board


func _make_single_cell_board(player: KarmanyPlayerState) -> KarmanyBoardState:
	var board := KarmanyBoardState.new()
	var tile := KarmanyTileData.new()
	tile.tile_id = "TEST-CURRENT"
	tile.display_name = "Loseta actual de prueba"
	tile.starts_revealed = true
	board.add_cell(ORIGIN, tile, true)
	board.set_unit_occupant(ORIGIN, TRAINER_UNIT_ID)
	player.set_board_position(ORIGIN)
	return board


func _make_basic_deck(cards_source: Array) -> KarmanyBeastDeck:
	var cards: Array[KarmanyBeastData] = []
	for card in cards_source:
		cards.append(card as KarmanyBeastData)
	var deck := KarmanyBeastDeck.new()
	deck.setup(cards, false, 1400)
	return deck


func _new_player(player_id: StringName) -> KarmanyPlayerState:
	var player := KarmanyPlayerState.new()
	player.setup_new_game(player_id, ORIGIN)
	return player


func _make_turn_manager(
	p1: KarmanyPlayerState,
	p2: KarmanyPlayerState
) -> KarmanyTurnManager:
	var manager := KarmanyTurnManager.new()
	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	manager.setup_players(players)
	manager.start_match()
	return manager


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 14 ERROR: %s" % message)
	return false
