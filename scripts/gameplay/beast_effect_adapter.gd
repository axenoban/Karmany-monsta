class_name KarmanyBeastEffectAdapter
extends RefCounted


var board_state: KarmanyBoardState = null
var last_spawn_result: KarmanyBeastSpawnResult = null
var _decks_by_encounter_id: Dictionary = {}


func setup(p_board_state: KarmanyBoardState) -> bool:
	if p_board_state == null:
		return false
	board_state = p_board_state
	return true


func register_deck(
	encounter_id: StringName,
	deck: KarmanyBeastDeck
) -> bool:
	if encounter_id == &"" or deck == null or deck.tier < 0:
		return false
	_decks_by_encounter_id[encounter_id] = deck
	return true


func configure_context(context: KarmanyEffectContext) -> bool:
	if context == null or board_state == null:
		return false
	context.trigger_encounter_handler = Callable(
		self,
		"_trigger_encounter"
	)
	return true


func get_deck(encounter_id: StringName) -> KarmanyBeastDeck:
	return _decks_by_encounter_id.get(encounter_id, null) as KarmanyBeastDeck


func _trigger_encounter(
	encounter_id: StringName,
	player: KarmanyPlayerState
) -> bool:
	if player == null or board_state == null:
		return false
	var deck := get_deck(encounter_id)
	if deck == null:
		return false

	last_spawn_result = KarmanyBeastEncounterResolver.spawn_from_deck(
		board_state,
		player.current_coord,
		deck,
		true
	)

	if last_spawn_result.is_spawned():
		return true

	# Si ya existe una Bestia, la regla resuelve el efecto sin revelar otra.
	return (
		last_spawn_result.status
		== KarmanyBeastSpawnResult.Status.TILE_ALREADY_HAS_BEAST
	)
