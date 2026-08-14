class_name KarmanyAiLegalActionGenerator
extends RefCounted


static func build_legal_actions(
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState,
	special_candidates: Array[KarmanyAiActionCandidate] = []
) -> Array[KarmanyAiActionCandidate]:
	var result: Array[KarmanyAiActionCandidate] = []
	if coordinator == null or player == null:
		return result
	if not coordinator.is_configured() or coordinator.is_finished:
		return result
	if coordinator.turn_manager == null or coordinator.board_state == null:
		return result
	if not coordinator.turn_manager.is_running:
		return result
	if coordinator.turn_manager.get_active_player() != player:
		return result
	if not coordinator.turn_manager.can_spend_action(1):
		return result

	_append_move_and_explore(result, coordinator, player)
	_append_interactions(result, coordinator, player)
	_append_book_upgrade(result, coordinator, player)
	_append_valid_special_candidates(result, special_candidates)
	return result


static func _append_move_and_explore(
	result: Array[KarmanyAiActionCandidate],
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState
) -> void:
	for coord in coordinator.board_state.get_existing_neighbors(player.current_coord):
		if KarmanyMovementRules.is_move_valid(
			coordinator.board_state,
			coordinator.turn_manager,
			player,
			coord
		):
			var move := KarmanyAiActionCandidate.new()
			move.action_type = KarmanyAiActionCandidate.ActionType.MOVE
			move.target_coord = coord
			move.debug_label = "Mover a %s" % str(coord)
			move.base_utility = 1.0
			move.exploration_value = 0.25
			var tile: KarmanyTileData = coordinator.board_state.get_tile_data(coord)
			if tile != null:
				var entry_estimate := KarmanyAiResourceUtility.estimate_effects(
					tile.entry_effects,
					player,
					coordinator
				)
				var entry_value: float = float(entry_estimate.get("value", 0.0))
				move.economy_value = entry_value
				move.opportunity_value = 0.5 + entry_value
				move.progress_value = float(tile.level) * 0.25
				move.payload["resource_utility"] = entry_estimate
			result.append(move)

		if KarmanyExplorationRules.is_exploration_valid(
			coordinator.board_state,
			coordinator.turn_manager,
			player,
			coord
		):
			var explore := KarmanyAiActionCandidate.new()
			explore.action_type = KarmanyAiActionCandidate.ActionType.EXPLORE
			explore.target_coord = coord
			explore.debug_label = "Explorar %s" % str(coord)
			explore.base_utility = 1.0
			explore.exploration_value = 3.0
			explore.opportunity_value = 0.75

			# La IA recibe solo el nivel estructural publico. No se consulta
			# KarmanyTileData mientras la posicion permanezca oculta.
			var public_level: int = coordinator.board_state.get_structural_level(coord)
			if public_level >= 0:
				explore.payload["public_level"] = public_level
				explore.progress_value = 1.0 + maxf(float(public_level), 0.0) * 0.20
			else:
				explore.progress_value = 1.0
			result.append(explore)


static func _append_interactions(
	result: Array[KarmanyAiActionCandidate],
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState
) -> void:
	var validation := KarmanyTileInteractionResolver.validate_interaction(
		player,
		coordinator.board_state,
		coordinator.turn_manager
	)
	if validation == null or not validation.is_success():
		return

	var tile: KarmanyTileData = coordinator.board_state.get_tile_data(player.current_coord)
	if tile == null or tile.later_use_effects.is_empty():
		return

	for option_index in range(tile.later_use_effects.size()):
		var effect: KarmanyEffectData = tile.later_use_effects[option_index]
		if effect == null:
			continue
		var candidate := KarmanyAiActionCandidate.new()
		candidate.action_type = KarmanyAiActionCandidate.ActionType.INTERACT
		candidate.option_index = option_index
		candidate.target_coord = player.current_coord
		candidate.debug_label = "Interactuar %s opcion %d" % [tile.tile_id, option_index]
		candidate.base_utility = 1.0

		var estimate := KarmanyAiResourceUtility.estimate_effects(
			[effect],
			player,
			coordinator
		)
		candidate.economy_value = float(estimate.get("value", 0.0))
		candidate.opportunity_value = candidate.economy_value + 0.5
		candidate.payload["resource_utility"] = estimate
		candidate.payload["public_tile_id"] = String(tile.tile_id)

		if effect.effect_type == KarmanyEffectData.EffectType.MODIFY_STATE:
			candidate.progress_value = maxf(float(effect.amount), 1.0)
		result.append(candidate)


static func _append_book_upgrade(
	result: Array[KarmanyAiActionCandidate],
	coordinator: KarmanyMatchCoordinator,
	player: KarmanyPlayerState
) -> void:
	var state: KarmanyBookProgressState = coordinator.get_book_state(player.player_id)
	if state == null or not state.can_improve():
		return
	if not coordinator.turn_manager.can_spend_action(1):
		return
	var next_level: int = state.get_next_level()
	var cost: Dictionary = KarmanyBookProgressController.get_upgrade_cost(next_level)
	if cost.is_empty() or not player.can_afford_resources(cost):
		return

	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK
	candidate.debug_label = "Mejorar Libro a nivel %d" % next_level
	candidate.base_utility = 1.0
	candidate.progress_value = 5.0 if next_level == 3 else 3.0
	candidate.opportunity_value = 2.0 if next_level == 3 else 1.0
	candidate.economy_value = 0.5
	candidate.payload["resource_cost"] = cost.duplicate()
	result.append(candidate)


static func _append_valid_special_candidates(
	result: Array[KarmanyAiActionCandidate],
	special_candidates: Array[KarmanyAiActionCandidate]
) -> void:
	for candidate in special_candidates:
		if candidate == null or not candidate.is_valid():
			continue
		var legal_check_value: Variant = candidate.payload.get("legal_check", Callable())
		if not (legal_check_value is Callable):
			continue
		var legal_check: Callable = legal_check_value
		if not legal_check.is_valid():
			continue
		var check_result: Variant = legal_check.call()
		if check_result is bool and bool(check_result):
			result.append(candidate)
