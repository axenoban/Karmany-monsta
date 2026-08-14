class_name KarmanyFullMatchActionCoreSession
extends KarmanyFullMatchSetupSession


func build_full_legal_actions(
	player: KarmanyPlayerState
) -> Array[KarmanyAiActionCandidate]:
	var candidates := KarmanyAiLegalActionGenerator.build_legal_actions(
		runtime.coordinator,
		player
	)
	# Los candidatos especiales de F38 se construyen solo cuando su contexto
	# real es legal. Se anexan despues del generador base porque el mecanismo
	# legacy de special_candidates exige un Callable legal_check en payload;
	# duplicarlo aqui crearia una segunda capa de legalidad.
	for special in _build_special_candidates(player):
		if special != null and special.is_valid():
			candidates.append(special)
	var filtered: Array[KarmanyAiActionCandidate] = []
	for candidate in candidates:
		if candidate == null:
			continue
		if (
			has_explored_this_turn(player.player_id)
			and candidate.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE
		):
			continue
		if candidate.action_type == KarmanyAiActionCandidate.ActionType.MOVE:
			var own_unit_id: StringName = runtime.local_session.get_unit_id_for_player(
				player.player_id
			)

			var target_occupant: StringName = runtime.board_state.get_occupying_unit_id(
				candidate.target_coord
			)

			# F38: una posicion ocupada por otro entrenador no es un destino
			# ejecutable para Mover. Evitamos ofrecer a la IA una accion que
			# _relocate_player() rechazaria posteriormente.
			if target_occupant != &"" and target_occupant != own_unit_id:
				continue

			var entry_status: StringName = get_entry_bonus_status(
				player,
				candidate.target_coord
			)

			if entry_status != &"eligible":
				candidate.economy_value = 0.0
				candidate.opportunity_value = minf(
					candidate.opportunity_value,
					0.5
				)
			if entry_status != &"eligible":
				# El generador F34 valora entry_effects publicos. Si F38 ya
				# consumio esa bonificacion segun v0.74, no permitimos que la IA
				# siga persiguiendo una utilidad que ya no recibira.
				candidate.economy_value = 0.0
				candidate.opportunity_value = minf(
					candidate.opportunity_value,
					0.5
				)
		filtered.append(candidate)
	return filtered


func run_automated_current_turn() -> bool:
	if not configured or match_state != MatchState.PLAYING:
		return false
	var manager := runtime.local_session.turn_manager
	if manager == null or not manager.is_running:
		return runtime.coordinator.is_finished
	var player := manager.get_active_player()
	if player == null:
		return _fail("Turno sin jugador activo.")
	if manager.actions_remaining < 0 or manager.actions_remaining > KarmanyTurnManager.ACTIONS_PER_TURN:
		return _fail("Presupuesto de acciones invalido.")

	var controller: KarmanyAiTurnController = null
	var brain: KarmanyAiBrain = _auto_human_brain
	if runtime.ai_match_controller.is_ai_player(player.player_id):
		controller = runtime.ai_match_controller.get_ai_controller(player.player_id)
		if controller == null:
			return _fail("IA sin controlador: %s." % String(player.player_id))
		brain = controller.brain

	var failed_attempts: int = 0
	while (
		match_state == MatchState.PLAYING
		and manager.is_running
		and manager.get_active_player() == player
		and manager.actions_remaining > 0
	):
		var legal_actions := build_full_legal_actions(player)
		if legal_actions.is_empty():
			_log("WATCHDOG | %s sin acciones legales; cede presupuesto inutilizable." % String(player.player_id))
			if not _relinquish_no_legal_budget(player):
				return _fail("No se pudo ceder presupuesto sin acciones legales.")
			break

		var choice := brain.choose_action(legal_actions)
		if choice == null:
			return _fail("%s no pudo seleccionar una accion legal." % String(player.player_id))
		var actions_before: int = manager.actions_remaining
		var success: bool = _execute_candidate(player, choice)
		full_action_resolved.emit(player.player_id, choice.debug_label, success)
		if not success:
			failed_attempts += 1
			_log("ACTION REJECTED | %s | %s" % [String(player.player_id), choice.debug_label])
			if failed_attempts > MAX_FAILED_ACTIONS_PER_TURN:
				return _fail("Mas de %d acciones rechazadas en un turno." % MAX_FAILED_ACTIONS_PER_TURN)
			continue

		failed_attempts = 0
		brain.record_executed_action(choice)
		statistics["actions"] = int(statistics.get("actions", 0)) + 1
		if choice.action_type == KarmanyAiActionCandidate.ActionType.EXPLORE:
			statistics["explorations"] = int(statistics.get("explorations", 0)) + 1
		if manager.actions_remaining >= actions_before:
			return _fail("Una accion exitosa no consumio presupuesto reglamentario.")

	if (
		match_state == MatchState.PLAYING
		and manager.is_running
		and manager.get_active_player() == player
		and manager.actions_remaining == 0
	):
		if not _end_turn_with_hand_limit(player):
			return _fail("No se pudo cerrar el turno de %s." % String(player.player_id))
	return true


func finish_human_turn_if_ready() -> bool:
	if not configured or match_state != MatchState.PLAYING:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return false
	if manager.actions_remaining != 0:
		return false
	return _end_turn_with_hand_limit(player)


func execute_human_special(preferred_types: Array[int]) -> bool:
	if not configured or match_state != MatchState.PLAYING:
		return false
	var manager := runtime.local_session.turn_manager
	var player := manager.get_active_player()
	if player == null or not runtime.ai_match_controller.is_human_player(player.player_id):
		return false
	var candidates := build_full_legal_actions(player)
	for preferred_type in preferred_types:
		for candidate in candidates:
			if candidate != null and candidate.action_type == preferred_type:
				var success: bool = _execute_candidate(player, candidate)
				full_action_resolved.emit(player.player_id, candidate.debug_label, success)
				if success:
					statistics["actions"] = int(statistics.get("actions", 0)) + 1
					if manager.actions_remaining == 0 and manager.get_active_player() == player:
						_end_turn_with_hand_limit(player)
				return success
	return false





func _full_explore_executor(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	if player == null or has_explored_this_turn(player.player_id):
		return false
	if not runtime._explore_executor(player, target_coord):
		return false
	_explored_this_turn_by_player[player.player_id] = true
	return true


func _full_move_executor(
	player: KarmanyPlayerState,
	target_coord: Vector2i
) -> bool:
	if runtime == null or player == null:
		return false
	var manager := runtime.local_session.turn_manager
	if (
		KarmanyMovementRules.validate_move(
			runtime.board_state,
			manager,
			player,
			target_coord
		)
		!= KarmanyMovementRules.MoveValidation.OK
	):
		return false

	var previous_coord: Vector2i = player.current_coord
	if not runtime._relocate_player(player, target_coord):
		return false
	if not manager.spend_action_for(KarmanyMovementRules.ACTION_ID_MOVE, 1):
		runtime._relocate_player(player, previous_coord)
		return false

	var entry_status: StringName = get_entry_bonus_status(player, target_coord)
	if entry_status == &"eligible":
		var tile := runtime.get_public_tile_data(target_coord)
		if tile != null:
			var used_value: Variant = _entry_bonus_coords_by_player.get(
				player.player_id,
				{}
			)
			var used: Dictionary = used_value if used_value is Dictionary else {}
			used[target_coord] = true
			_entry_bonus_coords_by_player[player.player_id] = used
			_entry_bonus_count_by_player[player.player_id] = (
				int(_entry_bonus_count_by_player.get(player.player_id, 0)) + 1
			)
			for effect in tile.entry_effects:
				KarmanyEffectResolver.apply_effect(
					effect,
					player,
					runtime.coordinator.effect_context
				)
	elif entry_status == &"text_only":
		_log(
			"ENTRY AUTOMATION PENDING | %s | %s"
			% [String(player.player_id), String(runtime.get_public_tile_data(target_coord).tile_id)]
		)
	return true


func _end_turn_with_hand_limit(player: KarmanyPlayerState) -> bool:
	if player == null or runtime == null or runtime.coordinator == null:
		return false
	var pending: int = player.resonance_hand.get_pending_discard_count()
	if pending <= 0:
		pending = player.request_end_turn_resonance_discard()
	if pending > 0:
		var hand := player.get_resonance_hand()
		if hand.size() < pending:
			return false
		var ordered: Array[KarmanyResonanceData] = []
		for card in hand:
			if card != null:
				ordered.append(card)
		_sort_resonances_low_power_first(ordered)
		var discard_ids: Array[StringName] = []
		for index in range(pending):
			discard_ids.append(ordered[index].resonance_id)
		if not runtime.coordinator.resolve_pending_resonance_discard(player, discard_ids):
			return false
		_log("HAND LIMIT | %s descarta %s" % [String(player.player_id), str(discard_ids)])
	return runtime.coordinator.end_turn()


func _relinquish_no_legal_budget(player: KarmanyPlayerState) -> bool:
	var manager := runtime.local_session.turn_manager
	while manager.is_running and manager.get_active_player() == player and manager.actions_remaining > 0:
		if not manager.spend_action_for(NO_LEGAL_ACTION_BUDGET_ID, 1):
			return false
	return true


func _build_special_candidates(_player: KarmanyPlayerState) -> Array[KarmanyAiActionCandidate]:
	return []


func _execute_candidate(
	_player: KarmanyPlayerState,
	_candidate: KarmanyAiActionCandidate
) -> bool:
	return false


func _choose_automated_combat_resonance(
	_player: KarmanyPlayerState
) -> StringName:
	return &""
