class_name KarmanyVerticalSliceActionRouter
extends RefCounted

var slice_match: KarmanyPhase24FullMatchBridge = null
var coordinator: KarmanyMatchCoordinator = null
var human_player: KarmanyPlayerState = null

func configure(p_slice_match: KarmanyPhase24FullMatchBridge, p_coordinator: KarmanyMatchCoordinator, p_human_player: KarmanyPlayerState) -> bool:
	if p_slice_match == null or p_coordinator == null or p_human_player == null:
		return false
	slice_match = p_slice_match
	coordinator = p_coordinator
	human_player = p_human_player
	return true

func move_to(coord: Vector2i) -> bool:
	return _can_human_act() and coordinator.move_player(human_player, coord)

func explore_to(coord: Vector2i) -> bool:
	if not _can_human_act() or not coordinator.explore_player(human_player, coord):
		return false
	if coord == KarmanyPhase24FullMatchBridge.TILE_EK and not slice_match.board_prototype.board_state.has_beast(coord):
		var spawn_result: KarmanyBeastSpawnResult = coordinator.spawn_beast(coord, slice_match.beast_deck, false)
		if not spawn_result.is_spawned():
			return false
	return true

func interact_current_tile(option_index: int = 0) -> bool:
	return _can_human_act() and coordinator.interact_effect_option(human_player, option_index).is_success()

func call_or_bond() -> bool:
	if not _can_human_act():
		return false
	var visible: Array[KarmanyEncounterState] = coordinator.encounter_resolver.get_visible_encounters_at(human_player.current_coord)
	if not visible.is_empty():
		var bond: KarmanyEncounterResult = coordinator.bond_visible_by_payment(human_player)
		if not bond.is_success() or bond.linked_karmany == null:
			return false
		human_player.set_active_karmany(bond.linked_karmany.instance_id)
		return true
	if human_player.current_coord != KarmanyPhase24FullMatchBridge.TILE_N2:
		return false
	var candidates: Array[KarmanyData] = [KarmanyPhase24FullMatchBridge.BRUMAK, KarmanyPhase24FullMatchBridge.RAUK]
	var call_result: KarmanyEncounterResult = coordinator.call_karmany(human_player, candidates, 0, KarmanyData.Rank.N2)
	return call_result.is_success()

func craft_slice_equipment() -> bool:
	if not _can_human_act() or human_player.current_coord != KarmanyPhase24FullMatchBridge.TILE_N2:
		return false
	var visible_index: int = _find_visible_equipment(&"EQ-01")
	if visible_index < 0:
		return false
	var craft_context := KarmanyEquipmentCraftContext.new()
	craft_context.source_id = &"N2-05"
	craft_context.allow_basic = true
	craft_context.allow_advanced = true
	var craft_result: KarmanyEquipmentCraftResult = coordinator.craft_from_market(human_player, visible_index, craft_context)
	return craft_result.is_success() and craft_result.equipment != null and craft_result.equipment.equipment_id == &"EQ-01"

func fight_current_beast() -> bool:
	if not _can_human_act():
		return false
	var coord: Vector2i = human_player.current_coord
	if not slice_match.board_prototype.board_state.has_beast(coord) or human_player.resonance_hand.get_card_by_id(&"R-04") == null:
		return false
	var combat_context := KarmanyBeastCombatContext.new()
	combat_context.turn_manager = slice_match.turn_manager
	combat_context.effect_context = coordinator.effect_context
	combat_context.instinct_roll = 3
	combat_context.action_cost = 1
	var combat_result: KarmanyBeastCombatResult = KarmanyBeastCombatIntegrationController.fight_with_existing_systems(coordinator, human_player, coord, slice_match.beast_deck, combat_context, &"R-04", coordinator.get_book_state(human_player.player_id))
	return combat_result.is_victory()

func improve_book() -> bool:
	return _can_human_act() and coordinator.improve_book(human_player).is_success()

func _find_visible_equipment(equipment_id: StringName) -> int:
	for index in range(slice_match.equipment_market.get_visible_count()):
		var equipment: KarmanyEquipmentData = slice_match.equipment_market.get_visible_at(index)
		if equipment != null and equipment.equipment_id == equipment_id:
			return index
	return -1

func _can_human_act() -> bool:
	return slice_match != null and coordinator != null and human_player != null and slice_match.turn_manager != null and slice_match.turn_manager.is_running and slice_match.turn_manager.get_active_player() == human_player and slice_match.turn_manager.actions_remaining > 0
