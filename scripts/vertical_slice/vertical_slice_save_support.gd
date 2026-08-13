class_name KarmanyVerticalSliceSaveSupport
extends RefCounted


var save_context: KarmanySaveGameContext = null


func configure(slice_match: KarmanyPhase24FullMatchBridge) -> bool:
	if slice_match == null:
		return false
	var context := KarmanySaveGameContext.new()
	var players: Array[KarmanyPlayerState] = [
		slice_match.player_1,
		slice_match.player_2
	]
	var beast_decks: Dictionary = {
		"basic": slice_match.beast_deck,
		"complex": slice_match.complex_beast_deck
	}
	if not context.configure(
		slice_match.board_prototype.board_state,
		slice_match.turn_manager,
		players,
		slice_match.resonance_deck,
		slice_match.equipment_market,
		slice_match.legacy_points,
		slice_match.objectives_missions,
		slice_match.coordinator,
		beast_decks,
		slice_match.dorian_pvp
	):
		return false
	save_context = context
	return save_context.is_valid()


func save_to(path: String) -> bool:
	return (
		not path.is_empty()
		and save_context != null
		and save_context.is_valid()
		and KarmanySaveGameFacade.save_to_path(save_context, path)
	)


func load_from(path: String) -> bool:
	if path.is_empty() or save_context == null or not save_context.is_valid():
		return false
	var snapshot: Dictionary = KarmanySaveGameFacade.load_snapshot_from_path(path)
	return (
		not snapshot.is_empty()
		and KarmanySaveGameFacade.restore(save_context, snapshot)
	)
