class_name KarmanySaveGameContext
extends RefCounted


var board_state: KarmanyBoardState = null
var turn_manager: KarmanyTurnManager = null
var players: Array[KarmanyPlayerState] = []
var resonance_deck: KarmanyResonanceDeck = null
var equipment_market: KarmanyEquipmentMarket = null
var beast_decks: Dictionary = {}
var legacy_points: KarmanyLegacyPointsController = null
var objectives_missions: KarmanyObjectiveMissionManager = null
var coordinator: KarmanyMatchCoordinator = null


func configure(
	p_board_state: KarmanyBoardState,
	p_turn_manager: KarmanyTurnManager,
	p_players: Array[KarmanyPlayerState],
	p_resonance_deck: KarmanyResonanceDeck,
	p_equipment_market: KarmanyEquipmentMarket,
	p_legacy_points: KarmanyLegacyPointsController,
	p_objectives_missions: KarmanyObjectiveMissionManager,
	p_coordinator: KarmanyMatchCoordinator,
	p_beast_decks: Dictionary = {}
) -> bool:
	board_state = p_board_state
	turn_manager = p_turn_manager
	players = p_players.duplicate()
	resonance_deck = p_resonance_deck
	equipment_market = p_equipment_market
	legacy_points = p_legacy_points
	objectives_missions = p_objectives_missions
	coordinator = p_coordinator
	beast_decks = p_beast_decks.duplicate()
	return is_valid()


func is_valid() -> bool:
	if board_state == null or turn_manager == null:
		return false
	if players.size() < KarmanyTurnManager.MIN_PLAYERS or players.size() > KarmanyTurnManager.MAX_PLAYERS:
		return false
	if resonance_deck == null or equipment_market == null:
		return false
	if legacy_points == null or objectives_missions == null or coordinator == null:
		return false
	for player in players:
		if player == null or player.player_id == &"":
			return false
	for deck_value in beast_decks.values():
		if not (deck_value is KarmanyBeastDeck):
			return false
	return true
