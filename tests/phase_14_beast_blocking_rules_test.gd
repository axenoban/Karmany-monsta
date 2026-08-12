extends Node


const B01: KarmanyBeastData = preload("res://data/beasts/b_01_garravol.tres")
const ORIGIN: Vector2i = Vector2i.ZERO
const MOVE_TARGET: Vector2i = Vector2i(1, 0)
const EXPLORE_TARGET: Vector2i = Vector2i(0, -1)


func _ready() -> void:
	var p1 := KarmanyPlayerState.new()
	var p2 := KarmanyPlayerState.new()
	p1.setup_new_game(&"player_1", ORIGIN)
	p2.setup_new_game(&"player_2", ORIGIN)

	var players: Array[KarmanyPlayerState] = []
	players.append(p1)
	players.append(p2)
	var manager := KarmanyTurnManager.new()
	manager.setup_players(players)
	manager.start_match()

	var board := KarmanyBoardState.new()
	var revealed_tile := KarmanyTileData.new()
	revealed_tile.tile_id = "BLOCK-REVEALED"
	revealed_tile.display_name = "Revelada"
	var hidden_tile := KarmanyTileData.new()
	hidden_tile.tile_id = "BLOCK-HIDDEN"
	hidden_tile.display_name = "Oculta"
	hidden_tile.level = KarmanyTileData.TileLevel.N1

	board.add_cell(ORIGIN, revealed_tile, true)
	board.add_cell(MOVE_TARGET, revealed_tile, true)
	board.add_cell(EXPLORE_TARGET, hidden_tile, false)
	board.set_unit_occupant(ORIGIN, &"trainer_player_1")

	var beast_cards: Array[KarmanyBeastData] = []
	beast_cards.append(B01)
	var deck := KarmanyBeastDeck.new()
	var ok: bool = deck.setup(beast_cards, false, 1414)
	var spawn := KarmanyBeastEncounterResolver.spawn_from_deck(
		board,
		ORIGIN,
		deck,
		true
	)
	ok = _expect(spawn.is_spawned(), "No aparecio la Bestia en la loseta actual.") and ok

	var move_validation := KarmanyMovementRules.validate_move(
		board,
		manager,
		p1,
		MOVE_TARGET
	)
	ok = _expect(
		move_validation == KarmanyMovementRules.MoveValidation.ORIGIN_BLOCKED_BY_BEAST,
		"Mover no debe permitir huir de un combate obligatorio sin resolver."
	) and ok

	var explore_validation := KarmanyExplorationRules.validate_exploration(
		board,
		manager,
		p1,
		EXPLORE_TARGET
	)
	ok = _expect(
		explore_validation == KarmanyExplorationRules.ExplorationValidation.ORIGIN_BLOCKED_BY_BEAST,
		"Explorar no debe permitir huir de un combate obligatorio sin resolver."
	) and ok
	ok = _expect(manager.actions_remaining == 2, "Acciones ilegales no deben gastar acciones.") and ok

	print("")
	print("================================")
	if ok:
		print("FASE 14 BLOQUEO OK - Bestia sin resolver impide Mover y Explorar.")
	else:
		push_error("FASE 14 BLOQUEO ERROR")
	print("================================")


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 14 BLOQUEO ERROR: %s" % message)
	return false
