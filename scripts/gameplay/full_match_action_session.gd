class_name KarmanyFullMatchActionSession
extends KarmanyFullMatchSpecialSession


func _execute_candidate(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> bool:
	if candidate == null or player == null:
		return false
	var manager := runtime.local_session.turn_manager
	if manager.get_active_player() != player:
		return false
	_log("ACTION | R%d | %s | %s" % [manager.current_round, String(player.player_id), candidate.debug_label])
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.CALL_KARMANY:
		var call_result := runtime.call_random_karmany(player, 0)
		var call_success: bool = call_result != null and call_result.is_success()
		if call_success:
			statistics["karmany_calls"] = int(statistics.get("karmany_calls", 0)) + 1
		return call_success
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_COMBAT:
		return _execute_bond_combat(player, candidate)
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST and bool(candidate.payload.get("spawn_if_missing", false)) and not runtime.board_state.has_beast(player.current_coord):
		var spawn_result := runtime.spawn_beast_from_current_tile(player, false)
		if spawn_result == null or not spawn_result.is_spawned():
			return false
	var execution := KarmanyAiActionExecutor.execute(runtime.coordinator, player, candidate)
	var success: bool = execution != null and execution.was_executed()
	if not success:
		return false
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.BOND_PAYMENT:
		statistics["karmany_links"] = int(statistics.get("karmany_links", 0)) + 1
	elif candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST:
		var beast_result: KarmanyBeastCombatResult = execution.raw_result as KarmanyBeastCombatResult
		if beast_result != null and beast_result.is_victory():
			statistics["beast_victories"] = int(statistics.get("beast_victories", 0)) + 1
			if bool(candidate.payload.get("enter_after_victory", false)):
				var origin_coord: Vector2i = player.current_coord
				if runtime._relocate_player(player, candidate.target_coord):
					runtime.coordinator._previous_coord_by_player[player.player_id] = origin_coord
					runtime.coordinator._record_visit(player, candidate.target_coord)
					_record_level_entry(player, origin_coord)
					_resolve_entry_bonus_after_beast(player, candidate.target_coord)
		elif beast_result != null and beast_result.retreat_required:
			if not runtime.coordinator._apply_retreat(player.player_id):
				_log("WATCHDOG | no se pudo aplicar retroceso tras derrota contra Bestia.")
	elif candidate.action_type == KarmanyAiActionCandidate.ActionType.PVP:
		statistics["pvp_resolved"] = int(statistics.get("pvp_resolved", 0)) + 1
	elif candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA:
		statistics["aeterna_attempts"] = int(statistics.get("aeterna_attempts", 0)) + 1
		var aeterna_result: KarmanyAeternaResult = execution.raw_result as KarmanyAeternaResult
		if aeterna_result != null:
			_resolve_aeterna_post_result(player, aeterna_result)
	var resonance_id: StringName = _candidate_resonance_id(candidate)
	if resonance_id != &"" and _execution_is_victory(execution, player.player_id):
		runtime.objectives_missions.record_event(player, EVENT_COMBAT_WON_WITH_RESONANCE, {"resonance_id": String(resonance_id)}, manager.current_round)
	return true


func _execute_bond_combat(player: KarmanyPlayerState, candidate: KarmanyAiActionCandidate) -> bool:
	var encounter_value: Variant = candidate.payload.get("encounter", null)
	if not (encounter_value is KarmanyEncounterState):
		return false
	var encounter: KarmanyEncounterState = encounter_value as KarmanyEncounterState
	var begin := runtime.coordinator.encounter_resolver.begin_defeat_bond_attempt(encounter, player)
	if begin == null or begin.status != KarmanyEncounterResult.Status.PENDING_COMBAT:
		return false
	var data := encounter.get_karmany_data()
	var active := player.get_active_karmany()
	if data == null or active == null or active.karmany_data == null:
		runtime.coordinator.encounter_resolver.complete_defeat_bond(encounter, player, false)
		return false
	var modifiers := KarmanyCombatPowerModifiers.new()
	KarmanyEquipmentCombatRules.apply_to_combat_modifiers(player.equipment_inventory, KarmanyCombatRequest.TargetType.UNBOUND_KARMANY, modifiers)
	var combat_id := StringName("phase38_bond_%s_r%d_%d" % [String(player.player_id), runtime.local_session.turn_manager.current_round, statistics.get("actions", 0)])
	var resonance_id: StringName = StringName(candidate.payload.get("resonance_id", ""))
	var played_card: KarmanyResonanceData = null
	var tags := PackedStringArray(["combat", "bond", "unbound_karmany"])
	if resonance_id != &"":
		played_card = runtime.coordinator._play_combat_resonance(player, resonance_id, combat_id, modifiers, tags)
		if played_card == null:
			runtime.coordinator.encounter_resolver.complete_defeat_bond(encounter, player, false)
			return false
	var request := KarmanyCombatRequest.new()
	request.attacker_player_id = player.player_id
	request.attacker_karmany = active.karmany_data
	request.target_id = data.karmany_id
	request.target_type = KarmanyCombatRequest.TargetType.UNBOUND_KARMANY
	request.base_defense = data.encounter_defense
	request.uses_instinct = true
	request.instinct_roll = int(candidate.payload.get("instinct_roll", 0))
	request.modifiers = modifiers
	var combat_result := KarmanyCombatResolver.resolve(request)
	if not combat_result.is_resolved():
		runtime.coordinator.encounter_resolver.complete_defeat_bond(encounter, player, false)
		return false
	if played_card != null:
		var after_tags: PackedStringArray = tags.duplicate()
		after_tags.append("combat_won" if combat_result.is_victory() else "combat_lost")
		KarmanyResonanceResolver.resolve_effects(played_card, player, &"after_combat", after_tags, runtime.coordinator.effect_context)
		KarmanyResonanceResolver.finish_combat(combat_id, runtime.coordinator.resonance_usage_tracker, runtime.coordinator.resonance_deck)
	var complete := runtime.coordinator.encounter_resolver.complete_defeat_bond(encounter, player, combat_result.is_victory())
	if complete == null:
		return false
	if complete.is_success() and complete.linked_karmany != null:
		runtime.coordinator._on_karmany_linked(player, complete.linked_karmany)
		statistics["karmany_links"] = int(statistics.get("karmany_links", 0)) + 1
		if resonance_id != &"":
			runtime.objectives_missions.record_event(player, EVENT_COMBAT_WON_WITH_RESONANCE, {"resonance_id": String(resonance_id)}, runtime.local_session.turn_manager.current_round)
		return true
	return complete.status == KarmanyEncounterResult.Status.COMBAT_FAILED


func _resolve_aeterna_post_result(
	player: KarmanyPlayerState,
	aeterna_result: KarmanyAeternaResult
) -> void:
	if player == null or aeterna_result == null or not aeterna_result.is_resolved():
		return
	if aeterna_result.is_victory() and aeterna_result.reward_choice_required:
		# Para controladores IA/Auto-P1 la opcion Alpha determinista es la
		# recompensa reglamentaria de Resonancias. No se inventa una tercera
		# recompensa ni se altera el premio de 8 PL ya otorgado por Aeterna.
		if runtime.coordinator.resolve_aeterna_resonance_reward(player, aeterna_result):
			_log("AETERNA REWARD | %s | roba 3 Resonancias y conserva 2" % String(player.player_id))
		else:
			_log("AETERNA REWARD PENDING | %s | no se pudo resolver la opcion de Resonancias" % String(player.player_id))
		return
	if aeterna_result.is_defeat() and aeterna_result.basic_resources_discard_pending > 0:
		var requested: int = aeterna_result.basic_resources_discard_pending
		var discarded: int = _discard_basic_resources_by_choice(player, requested)
		_log("AETERNA DEFEAT | %s | descarta %d/%d recursos basicos" % [
			String(player.player_id),
			discarded,
			requested
		])


func _discard_basic_resources_by_choice(
	player: KarmanyPlayerState,
	amount: int
) -> int:
	if player == null or amount <= 0:
		return 0
	var discarded: int = 0
	while discarded < amount:
		var selected_type: int = -1
		var selected_amount: int = 0
		for resource_type in [
			KarmanyEffectData.ResourceType.MN,
			KarmanyEffectData.ResourceType.MR,
			KarmanyEffectData.ResourceType.EK
		]:
			var available: int = player.get_resource(resource_type)
			if available > selected_amount:
				selected_amount = available
				selected_type = resource_type
		if selected_type < 0 or selected_amount <= 0:
			break
		if not player.spend_resource(selected_type, 1):
			break
		discarded += 1
	return discarded


func _resolve_entry_bonus_after_beast(player: KarmanyPlayerState, target_coord: Vector2i) -> void:
	var status: StringName = get_entry_bonus_status(player, target_coord)
	if status == &"eligible":
		var tile := runtime.get_public_tile_data(target_coord)
		if tile == null:
			return
		var used_value: Variant = _entry_bonus_coords_by_player.get(player.player_id, {})
		var used: Dictionary = used_value if used_value is Dictionary else {}
		used[target_coord] = true
		_entry_bonus_coords_by_player[player.player_id] = used
		_entry_bonus_count_by_player[player.player_id] = int(_entry_bonus_count_by_player.get(player.player_id, 0)) + 1
		for effect in tile.entry_effects:
			KarmanyEffectResolver.apply_effect(effect, player, runtime.coordinator.effect_context)
	elif status == &"text_only":
		var tile := runtime.get_public_tile_data(target_coord)
		if tile != null:
			_log("ENTRY AUTOMATION PENDING | %s | %s" % [String(player.player_id), String(tile.tile_id)])


func _execution_is_victory(execution: KarmanyAiExecutionResult, acting_player_id: StringName) -> bool:
	if execution == null:
		return false
	var raw: Variant = execution.raw_result
	if raw is KarmanyBeastCombatResult:
		return (raw as KarmanyBeastCombatResult).is_victory()
	if raw is KarmanyPvpCombatResult:
		return (raw as KarmanyPvpCombatResult).is_resolved() and (raw as KarmanyPvpCombatResult).winner_player_id == acting_player_id
	if raw is KarmanyAeternaResult:
		return (raw as KarmanyAeternaResult).is_victory()
	return false


func _candidate_resonance_id(candidate: KarmanyAiActionCandidate) -> StringName:
	if candidate == null:
		return &""
	if candidate.action_type == KarmanyAiActionCandidate.ActionType.PVP:
		return StringName(candidate.payload.get("attacker_resonance_id", ""))
	return StringName(candidate.payload.get("resonance_id", ""))

func _record_level_entry(player: KarmanyPlayerState, coord_before: Vector2i) -> void:
	if player == null or player.current_coord == coord_before:
		return
	_last_coord_by_player[player.player_id] = player.current_coord
	var level: int = runtime.get_public_level(player.current_coord)
	if level == KarmanyTileData.TileLevel.N2:
		runtime.objectives_missions.record_event(player, EVENT_ENTERED_N2, {"coord_key": _coord_key(player.current_coord)})
	elif level == KarmanyTileData.TileLevel.N3:
		runtime.objectives_missions.record_event(player, EVENT_ENTERED_N3, {"coord_key": _coord_key(player.current_coord)})
