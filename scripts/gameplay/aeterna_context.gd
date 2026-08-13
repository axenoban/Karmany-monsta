class_name KarmanyAeternaContext
extends RefCounted


const SANCTUARY_TILE_ID: String = "L-01"


var board_state: KarmanyBoardState = null
var turn_manager: KarmanyTurnManager = null
var legacy_points_controller: KarmanyLegacyPointsController = null
var resonance_deck: KarmanyResonanceDeck = null
var aeterna_state: KarmanyAeternaState = null

var map_format: int = KarmanyLegacyModeConfig.MapFormat.MAP_22
var book_level: int = 1
var instinct_roll: int = 0
var modifiers: KarmanyCombatPowerModifiers = KarmanyCombatPowerModifiers.new()
var risk_authorized: bool = false
var risk_roll: int = 0
var action_cost: int = 1


func is_valid() -> bool:
	if board_state == null or turn_manager == null:
		return false
	if legacy_points_controller == null or resonance_deck == null:
		return false
	if aeterna_state == null or modifiers == null:
		return false
	if map_format < KarmanyLegacyModeConfig.MapFormat.MAP_22:
		return false
	if map_format > KarmanyLegacyModeConfig.MapFormat.MAP_41:
		return false
	if book_level <= 0 or action_cost <= 0:
		return false
	return true


func is_player_at_sanctuary(player: KarmanyPlayerState) -> bool:
	if player == null or board_state == null:
		return false
	var tile := board_state.get_tile_data(player.current_coord)
	if tile == null:
		return false
	return tile.level == KarmanyTileData.TileLevel.SANCTUARY and tile.tile_id == SANCTUARY_TILE_ID
