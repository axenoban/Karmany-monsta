class_name KarmanyPhase46AlphaHudBridge
extends RefCounted


var full_session: KarmanyFullMatchSession = null


func configure(session: KarmanyFullMatchSession) -> bool:
	if session == null or not session.configured or session.runtime == null:
		return false
	if session.runtime.local_session == null or session.runtime.coordinator == null:
		return false
	full_session = session
	return true


func is_configured() -> bool:
	return full_session != null and full_session.configured and full_session.runtime != null


func get_snapshot() -> Dictionary:
	if not is_configured():
		return {}
	var runtime := full_session.runtime
	var manager := runtime.local_session.turn_manager
	if manager == null:
		return {}
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
	var active := manager.get_active_player()
	if human == null:
		return {}

	var tile: KarmanyTileData = runtime.get_public_tile_data(human.current_coord)
	var book := runtime.coordinator.get_book_state(human.player_id)
	var active_karmany := human.get_active_karmany()
	var active_karmany_data: KarmanyData = (
		active_karmany.karmany_data
		if active_karmany != null
		else null
	)

	return {
		"match_state": full_session.get_state_label(),
		"round": manager.current_round,
		"actions_remaining": manager.actions_remaining,
		"active_player_id": active.player_id if active != null else &"",
		"human_player_id": human.player_id,
		"is_human_turn": active == human,
		"resources": {
			"MN": human.mn,
			"MR": human.mr,
			"EK": human.ek,
			"FA": human.fa,
		},
		"legacy_points": runtime.local_session.legacy_points.get_points(human.player_id),
		"position": human.current_coord,
		"zone": _build_tile_row(tile, human.current_coord),
		"visible_effects": _build_visible_effects(tile),
		"book_level": book.level if book != null else 0,
		"active_karmany": _build_karmany_row(active_karmany_data),
		"public_objectives": _build_public_objective_rows(human.player_id),
		"secret_mission": _build_secret_mission_row(human.player_id),
		"resonances": _build_resonance_rows(human.get_resonance_hand()),
		"equipment": _build_equipment_rows(human.get_equipped_equipment()),
		"market": _build_equipment_rows(runtime.equipment_market.get_visible()),
		"participants": _build_participant_rows(),
		"recent_events": get_recent_events(8),
	}


func get_recent_events(limit: int = 8) -> PackedStringArray:
	var result := PackedStringArray()
	if not is_configured() or limit <= 0:
		return result
	var log_lines := full_session.get_alpha_log()
	var start: int = maxi(0, log_lines.size() - limit)
	for index in range(start, log_lines.size()):
		result.append(log_lines[index])
	return result


func inspect_current_tile() -> Dictionary:
	if not is_configured():
		return {}
	var runtime := full_session.runtime
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if human == null:
		return {}
	var tile: KarmanyTileData = runtime.get_public_tile_data(human.current_coord)
	if tile == null:
		return {}
	var body := PackedStringArray()
	if not tile.on_explore_text.strip_edges().is_empty():
		body.append("AL EXPLORAR: %s" % tile.on_explore_text)
	if not tile.entry_bonus_text.strip_edges().is_empty():
		body.append("BONIFICACION DE ENTRADA: %s" % tile.entry_bonus_text)
	if not tile.later_use_text.strip_edges().is_empty():
		body.append("USO POSTERIOR: %s" % tile.later_use_text)
	if not tile.limit_text.strip_edges().is_empty():
		body.append("LIMITE: %s" % tile.limit_text)
	return {
		"title": tile.display_name,
		"subtitle": "%s · %s" % [String(tile.tile_id), _tile_level_label(tile.level)],
		"body": "\n\n".join(body),
	}


func inspect_resonance(resonance_id: StringName) -> Dictionary:
	if not is_configured() or resonance_id == &"":
		return {}
	var human := full_session.runtime.local_session.get_player_by_id(
		full_session.runtime.human_player_id
	)
	if human == null:
		return {}
	for card in human.get_resonance_hand():
		if card != null and card.resonance_id == resonance_id:
			return {
				"title": card.display_name,
				"subtitle": "%s · Poder %d" % [String(card.resonance_id), card.printed_power],
				"body": card.rules_text,
			}
	return {}


func inspect_equipment(equipment_id: StringName) -> Dictionary:
	if not is_configured() or equipment_id == &"":
		return {}
	var runtime := full_session.runtime
	var human := runtime.local_session.get_player_by_id(runtime.human_player_id)
	if human == null:
		return {}
	var all_cards: Array[KarmanyEquipmentData] = []
	for card in human.get_equipped_equipment():
		all_cards.append(card)
	for card in runtime.equipment_market.get_visible():
		all_cards.append(card)
	for card in all_cards:
		if card != null and card.equipment_id == equipment_id:
			return {
				"title": card.display_name,
				"subtitle": "%s · %s" % [String(card.equipment_id), card.get_rarity_label()],
				"body": "%s\nCoste: %s" % [card.rules_text, _format_cost(card.get_cost())],
			}
	return {}


func inspect_active_karmany() -> Dictionary:
	if not is_configured():
		return {}
	var human := full_session.runtime.local_session.get_player_by_id(
		full_session.runtime.human_player_id
	)
	if human == null:
		return {}
	var state := human.get_active_karmany()
	if state == null or state.karmany_data == null:
		return {}
	var data := state.karmany_data
	var ability_lines := PackedStringArray()
	for ability in data.abilities:
		if ability != null:
			ability_lines.append(ability.rules_text)
	return {
		"title": data.display_name,
		"subtitle": "%s · %s · Poder %d" % [
			String(data.karmany_id),
			data.get_rank_label(),
			data.power,
		],
		"body": "\n\n".join(ability_lines),
	}


func _build_participant_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_configured():
		return result
	var runtime := full_session.runtime
	for player in runtime.local_session.players:
		if player == null:
			continue
		result.append({
			"player_id": player.player_id,
			"pl": runtime.local_session.legacy_points.get_points(player.player_id),
			"position": player.current_coord,
			"is_human": runtime.ai_match_controller.is_human_player(player.player_id),
		})
	return result


func _build_public_objective_rows(viewer_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_configured():
		return result
	var manager := full_session.runtime.objectives_missions
	for objective in manager.get_public_objectives():
		if objective == null:
			continue
		var state := manager.get_objective_state(objective.objective_id)
		result.append({
			"objective_id": objective.objective_id,
			"display_name": objective.display_name,
			"condition_text": objective.condition_text,
			"reward_pl": objective.reward_legacy_points,
			"claimed": state != null and state.is_claimed(),
			"claimed_by": state.claimed_by_player_id if state != null else &"",
			"claimed_by_viewer": state != null and state.claimed_by_player_id == viewer_id,
		})
	return result


func _build_secret_mission_row(viewer_id: StringName) -> Dictionary:
	if not is_configured():
		return {}
	var manager := full_session.runtime.objectives_missions
	var mission := manager.get_mission_for_viewer(viewer_id, viewer_id)
	var assignment := manager.get_mission_assignment(viewer_id)
	if mission == null or assignment == null:
		return {}
	return {
		"mission_id": mission.mission_id,
		"display_name": mission.display_name,
		"trainer": mission.trainer_display_name,
		"condition_text": mission.condition_text,
		"reward_pl": mission.reward_legacy_points,
		"completed": assignment.is_completed(),
		"completed_round": assignment.completed_round,
	}


func _build_resonance_rows(cards: Array[KarmanyResonanceData]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in cards:
		if card == null:
			continue
		result.append({
			"resonance_id": card.resonance_id,
			"display_name": card.display_name,
			"printed_power": card.printed_power,
			"rules_text": card.rules_text,
		})
	return result


func _build_equipment_rows(cards: Array[KarmanyEquipmentData]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in cards:
		if card == null:
			continue
		result.append({
			"equipment_id": card.equipment_id,
			"display_name": card.display_name,
			"rarity": card.get_rarity_label(),
			"cost": _format_cost(card.get_cost()),
			"rules_text": card.rules_text,
		})
	return result


func _build_karmany_row(data: KarmanyData) -> Dictionary:
	if data == null:
		return {}
	return {
		"karmany_id": data.karmany_id,
		"display_name": data.display_name,
		"rank": data.get_rank_label(),
		"power": data.power,
		"type": data.get_primary_type_label(),
	}


func _build_tile_row(tile: KarmanyTileData, coord: Vector2i) -> Dictionary:
	if tile == null:
		return {"coord": coord, "display_name": "Zona oculta", "level": "?"}
	return {
		"tile_id": StringName(tile.tile_id),
		"display_name": tile.display_name,
		"level": _tile_level_label(tile.level),
		"coord": coord,
		"entry_bonus_status": full_session.get_entry_bonus_status(
			full_session.runtime.local_session.get_player_by_id(full_session.runtime.human_player_id),
			coord
		),
	}


func _build_visible_effects(tile: KarmanyTileData) -> PackedStringArray:
	var result := PackedStringArray()
	if tile == null:
		return result
	if not tile.on_explore_text.strip_edges().is_empty():
		result.append("Explorar: %s" % tile.on_explore_text)
	if not tile.entry_bonus_text.strip_edges().is_empty():
		result.append("Entrada: %s" % tile.entry_bonus_text)
	if not tile.later_use_text.strip_edges().is_empty():
		result.append("Interactuar: %s" % tile.later_use_text)
	if not tile.limit_text.strip_edges().is_empty():
		result.append("Limite: %s" % tile.limit_text)
	return result


func _format_cost(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for resource_type in [
		KarmanyEffectData.ResourceType.MN,
		KarmanyEffectData.ResourceType.MR,
		KarmanyEffectData.ResourceType.EK,
		KarmanyEffectData.ResourceType.FA,
	]:
		var amount: int = int(cost.get(resource_type, 0))
		if amount > 0:
			parts.append("%s %d" % [_resource_label(resource_type), amount])
	return "-" if parts.is_empty() else " · ".join(parts)


func _resource_label(resource_type: int) -> String:
	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			return "MN"
		KarmanyEffectData.ResourceType.MR:
			return "MR"
		KarmanyEffectData.ResourceType.EK:
			return "EK"
		KarmanyEffectData.ResourceType.FA:
			return "FA"
	return "?"


func _tile_level_label(level: int) -> String:
	match level:
		KarmanyTileData.TileLevel.START:
			return "Inicio"
		KarmanyTileData.TileLevel.N1:
			return "N1"
		KarmanyTileData.TileLevel.N2:
			return "N2"
		KarmanyTileData.TileLevel.N3:
			return "N3"
		KarmanyTileData.TileLevel.SANCTUARY:
			return "Santuario"
	return "?"
