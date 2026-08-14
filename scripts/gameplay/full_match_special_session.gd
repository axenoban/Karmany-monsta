class_name KarmanyFullMatchSpecialSession
extends KarmanyFullMatchActionCoreSession


func _build_special_candidates(
	player: KarmanyPlayerState
) -> Array[KarmanyAiActionCandidate]:
	var result: Array[KarmanyAiActionCandidate] = []
	if player == null or match_state != MatchState.PLAYING:
		return result
	var manager := runtime.local_session.turn_manager
	if manager.get_active_player() != player or manager.actions_remaining <= 0:
		return result
	_append_bond_candidate(result, player)
	_append_bond_combat_candidate(result, player)
	_append_call_candidate(result, player)
	_append_beast_candidate(result, player)
	_append_craft_candidate(result, player)
	_append_forge_candidate(result, player)
	_append_pvp_candidates(result, player)
	_append_aeterna_candidate(result, player)
	return result


func _append_bond_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	var visible := runtime.coordinator.encounter_resolver.get_visible_encounters_at(player.current_coord)
	if visible.size() != 1:
		return
	var encounter: KarmanyEncounterState = visible[0]
	var data := encounter.get_karmany_data()
	if data == null or not data.has_payment_method() or not player.can_afford_resources(data.get_bond_cost()):
		return
	var book := runtime.coordinator.get_book_state(player.player_id)
	if book == null or not book.can_hold_karmany_count(player.get_linked_karmanys().size() + 1):
		return
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.BOND_PAYMENT
	candidate.target_coord = player.current_coord
	candidate.debug_label = "Vincular %s" % data.display_name
	candidate.base_utility = 2.0
	candidate.progress_value = 2.5
	candidate.opportunity_value = 2.0
	result.append(candidate)


func _append_bond_combat_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	if player == null or not player.has_active_karmany():
		return
	var visible := runtime.coordinator.encounter_resolver.get_visible_encounters_at(player.current_coord)
	if visible.size() != 1:
		return
	var encounter: KarmanyEncounterState = visible[0]
	var data := encounter.get_karmany_data()
	if data == null or not data.has_defeat_method() or data.encounter_defense <= 0:
		return
	var book := runtime.coordinator.get_book_state(player.player_id)
	if book == null or not book.can_hold_karmany_count(player.get_linked_karmanys().size() + 1):
		return
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.BOND_COMBAT
	candidate.target_coord = player.current_coord
	candidate.debug_label = "Vincular por combate: %s" % data.display_name
	candidate.base_utility = 1.6
	candidate.aggression_value = 1.5
	candidate.progress_value = 2.75
	candidate.opportunity_value = 1.5
	candidate.risk_value = 1.0
	candidate.payload["encounter"] = encounter
	candidate.payload["instinct_roll"] = _action_rng.randi_range(1, 6)
	var resonance_id := _choose_automated_combat_resonance(player)
	if resonance_id != &"":
		candidate.payload["resonance_id"] = resonance_id
	result.append(candidate)


func _append_call_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	if runtime.coordinator.encounter_resolver.has_called_this_round(player.player_id):
		return
	if runtime.board_state.is_blocked_by_beast(player.current_coord):
		return
	if not runtime.coordinator.encounter_resolver.get_visible_encounters_at(player.current_coord).is_empty():
		return
	var level: int = runtime.get_public_level(player.current_coord)
	var rank_value: int = _rank_from_tile_level(level)
	if rank_value < KarmanyData.Rank.N1 or rank_value > KarmanyData.Rank.N3:
		return
	if runtime.get_karmany_pool_for_rank(rank_value).size() < 2:
		return
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.CALL_KARMANY
	candidate.target_coord = player.current_coord
	candidate.debug_label = "Llamar Karmany N%d" % level
	candidate.base_utility = 1.25
	candidate.progress_value = 1.5
	candidate.opportunity_value = 2.0
	result.append(candidate)


func _append_beast_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	if not player.has_active_karmany():
		return
	var origin: Vector2i = player.current_coord
	var target_coords: Array[Vector2i] = [origin]
	for neighbor in runtime.board_state.get_existing_neighbors(origin):
		target_coords.append(neighbor)
	for target_coord in target_coords:
		var existing_beast := runtime.board_state.get_beast(target_coord)
		if existing_beast == null or existing_beast.beast_data == null:
			continue
		_append_existing_beast_combat_candidate(result, player, target_coord, int(existing_beast.beast_data.tier), target_coord != origin)
	if runtime.board_state.has_beast(origin):
		return
	var tile := runtime.get_public_tile_data(origin)
	if tile == null:
		return
	var tier_value: int = _beast_tier_from_tile(tile)
	if tier_value < 0:
		return
	var lower_later: String = tile.later_use_text.to_lower()
	if not (lower_later.contains("bestia") and (lower_later.contains("enfrent") or lower_later.contains("comb"))):
		return
	var deck := runtime.get_beast_deck_for_tier(tier_value)
	if deck == null:
		return
	var context := KarmanyBeastCombatContext.new()
	context.turn_manager = runtime.local_session.turn_manager
	context.action_cost = 1
	context.action_id = &"combat_beast"
	context.instinct_roll = _action_rng.randi_range(1, 6)
	context.effect_context = runtime.coordinator.effect_context
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.FIGHT_BEAST
	candidate.target_coord = origin
	candidate.debug_label = "Enfrentar Bestia de %s" % tile.display_name
	candidate.base_utility = 1.0
	candidate.aggression_value = 2.5
	candidate.progress_value = 2.0
	candidate.risk_value = 1.25
	candidate.payload["deck"] = deck
	candidate.payload["combat_context"] = context
	candidate.payload["spawn_if_missing"] = true
	candidate.payload["enter_after_victory"] = false
	candidate.payload["book_state"] = runtime.coordinator.get_book_state(player.player_id)
	var resonance_id := _choose_automated_combat_resonance(player)
	if resonance_id != &"":
		candidate.payload["resonance_id"] = resonance_id
	result.append(candidate)


func _append_existing_beast_combat_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState, target_coord: Vector2i, tier_value: int, enter_after_victory: bool) -> void:
	var deck := runtime.get_beast_deck_for_tier(tier_value)
	if deck == null:
		return
	if enter_after_victory and runtime.board_state.is_occupied(target_coord):
		return
	var context := KarmanyBeastCombatContext.new()
	context.turn_manager = runtime.local_session.turn_manager
	context.action_cost = 1
	context.action_id = &"combat_beast"
	context.instinct_roll = _action_rng.randi_range(1, 6)
	context.effect_context = runtime.coordinator.effect_context
	context.enter_after_victory = false
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.FIGHT_BEAST
	candidate.target_coord = target_coord
	candidate.debug_label = "Combatir Bestia y entrar" if enter_after_victory else "Combatir Bestia"
	candidate.base_utility = 1.1
	candidate.aggression_value = 2.75
	candidate.progress_value = 2.0
	candidate.risk_value = 1.25
	candidate.payload["deck"] = deck
	candidate.payload["combat_context"] = context
	candidate.payload["spawn_if_missing"] = false
	candidate.payload["enter_after_victory"] = enter_after_victory
	candidate.payload["book_state"] = runtime.coordinator.get_book_state(player.player_id)
	var resonance_id := _choose_automated_combat_resonance(player)
	if resonance_id != &"":
		candidate.payload["resonance_id"] = resonance_id
	result.append(candidate)


func _append_craft_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	if player.get_equipment_count() >= 3:
		return
	var tile := runtime.get_public_tile_data(player.current_coord)
	if tile == null or runtime.board_state.is_blocked_by_beast(player.current_coord):
		return
	var text: String = ("%s %s" % [" ".join(tile.function_tags), tile.later_use_text]).to_lower()
	if not (text.contains("equipo") and (text.contains("crear") or text.contains("craf") or text.contains("taller"))):
		return
	var context := KarmanyEquipmentCraftContext.new()
	context.source_id = StringName("tile:%s" % tile.tile_id)
	context.allow_basic = text.contains("basico") or text.contains("básico")
	context.allow_advanced = text.contains("avanzado")
	context.allow_ancestral = text.contains("ancestral")
	if not context.allow_basic and not context.allow_advanced and not context.allow_ancestral:
		return
	var visible := runtime.equipment_market.get_visible()
	for index in range(visible.size()):
		var equipment: KarmanyEquipmentData = visible[index]
		if equipment == null or not context.allows_rarity(equipment.rarity):
			continue
		var cost := context.get_discounted_cost(equipment.get_cost())
		if not player.can_afford_resources(cost):
			continue
		var candidate := KarmanyAiActionCandidate.new()
		candidate.action_type = KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT
		candidate.target_coord = player.current_coord
		candidate.debug_label = "Craftear %s" % equipment.display_name
		candidate.base_utility = 1.25
		candidate.economy_value = 2.0
		candidate.progress_value = 2.0
		candidate.payload["craft_context"] = context
		candidate.payload["visible_index"] = index
		result.append(candidate)


func _append_forge_candidate(
	result: Array[KarmanyAiActionCandidate],
	player: KarmanyPlayerState
) -> void:
	if player == null:
		return

	if runtime.board_state.is_blocked_by_beast(player.current_coord):
		return

	var tile := runtime.get_public_tile_data(player.current_coord)

	if tile == null:
		return

	# La conversion reglamentaria solo pertenece a N3-02 Forja Antigua.
	if StringName(tile.tile_id) != KarmanyForgeInteractionController.FORGE_TILE_ID:
		return

	# La conversion de Forja solo puede utilizarse una vez por jugador.
	if runtime.coordinator.forge_controller.has_used_conversion(
		player.player_id
	):
		return

	var pair := _find_two_common_resources(player)

	if pair.size() != 2:
		return

	var candidate := KarmanyAiActionCandidate.new()

	candidate.action_type = (
		KarmanyAiActionCandidate.ActionType.FORGE
	)

	candidate.target_coord = player.current_coord
	candidate.debug_label = "Forja 2 comunes -> 1 FA"
	candidate.base_utility = 1.0
	candidate.economy_value = 2.0
	candidate.progress_value = 2.5

	candidate.payload["first_resource"] = pair[0]
	candidate.payload["second_resource"] = pair[1]

	result.append(candidate)


func _append_pvp_candidates(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	var manager := runtime.local_session.turn_manager
	if manager.current_round <= 1 or not player.has_active_karmany():
		return
	var tile := runtime.get_public_tile_data(player.current_coord)
	if tile == null:
		return
	var text: String = ("%s %s %s" % [" ".join(tile.function_tags), tile.on_explore_text, tile.later_use_text]).to_lower()
	var range_mode: int = -1
	if text.contains("pvp adyacente") or text.contains("rival adyacente"):
		range_mode = KarmanyPvpAuthorizationContext.RangeMode.ADJACENT
	elif text.contains("pvp misma loseta") or text.contains("rival en tu loseta"):
		range_mode = KarmanyPvpAuthorizationContext.RangeMode.SAME_TILE
	if range_mode < 0:
		return
	for defender in runtime.local_session.players:
		if defender == player or not defender.has_active_karmany():
			continue
		var authorization := KarmanyPvpAuthorizationContext.new()
		authorization.source_id = StringName("tile:%s" % tile.tile_id)
		authorization.range_mode = range_mode
		if not authorization.is_target_in_range(runtime.board_state, player.current_coord, defender.current_coord):
			continue
		var candidate := KarmanyAiActionCandidate.new()
		candidate.action_type = KarmanyAiActionCandidate.ActionType.PVP
		candidate.target_coord = defender.current_coord
		candidate.debug_label = "PvP contra %s" % String(defender.player_id)
		candidate.base_utility = 0.75
		candidate.aggression_value = 3.0
		candidate.risk_value = 1.5
		candidate.payload["defender"] = defender
		candidate.payload["authorization"] = authorization
		var attacker_resonance := _choose_automated_combat_resonance(player)
		var defender_resonance := _choose_automated_combat_resonance(defender)
		if attacker_resonance != &"":
			candidate.payload["attacker_resonance_id"] = attacker_resonance
		if defender_resonance != &"":
			candidate.payload["defender_resonance_id"] = defender_resonance
		result.append(candidate)


func _append_aeterna_candidate(result: Array[KarmanyAiActionCandidate], player: KarmanyPlayerState) -> void:
	var manager := runtime.local_session.turn_manager
	if manager.current_round < 8:
		return
	var tile := runtime.get_public_tile_data(player.current_coord)
	if tile == null or tile.level != KarmanyTileData.TileLevel.SANCTUARY:
		return
	if runtime.coordinator.aeterna_state.defeated:
		return
	var book := runtime.coordinator.get_book_state(player.player_id)
	if book == null or book.level < 3:
		return
	if player.fa < 1 or not player.has_active_karmany():
		return
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.AETERNA
	candidate.target_coord = player.current_coord
	candidate.debug_label = "Combatir Aeterna Draconis"
	candidate.base_utility = 2.0
	candidate.aggression_value = 3.0
	candidate.progress_value = 4.0
	candidate.risk_value = 2.0
	candidate.payload["instinct_roll"] = _action_rng.randi_range(1, 6)
	var resonance_id := _choose_automated_combat_resonance(player)
	if resonance_id != &"":
		candidate.payload["resonance_id"] = resonance_id
	result.append(candidate)


func _choose_automated_combat_resonance(player: KarmanyPlayerState) -> StringName:
	if player == null:
		return &""
	var best_id: StringName = &""
	var best_power: int = -1
	for card in player.get_resonance_hand():
		if card == null:
			continue
		if not KarmanyV074CanonicalRuntimeCatalog.is_resonance_automated(card.resonance_id):
			continue
		if not card.can_use_in(KarmanyResonanceUseContext.WINDOW_COMBAT):
			continue
		if card.printed_power > best_power:
			best_power = card.printed_power
			best_id = card.resonance_id
	return best_id




func _rank_from_tile_level(level: int) -> int:
	match level:
		KarmanyTileData.TileLevel.N1:
			return KarmanyData.Rank.N1
		KarmanyTileData.TileLevel.N2:
			return KarmanyData.Rank.N2
		KarmanyTileData.TileLevel.N3:
			return KarmanyData.Rank.N3
	return -1


func _beast_tier_from_tile(tile: KarmanyTileData) -> int:
	if tile == null:
		return -1
	for tag in tile.function_tags:
		var normalized: String = tag.to_lower()
		if normalized.contains("bestia basica") or normalized.contains("bestia básica"):
			return KarmanyBeastData.Tier.BASIC
		if normalized.contains("bestia media"):
			return KarmanyBeastData.Tier.MEDIUM
		if normalized.contains("bestia compleja"):
			return KarmanyBeastData.Tier.COMPLEX
		if normalized.contains("jefe"):
			return KarmanyBeastData.Tier.BOSS
	return -1


func _find_two_common_resources(player: KarmanyPlayerState) -> Array[int]:
	var result: Array[int] = []
	for resource_type in [KarmanyEffectData.ResourceType.MN, KarmanyEffectData.ResourceType.MR, KarmanyEffectData.ResourceType.EK]:
		var count: int = player.get_resource(resource_type)
		for _index in range(count):
			result.append(resource_type)
			if result.size() == 2:
				return result
	return []
