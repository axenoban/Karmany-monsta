class_name KarmanyUniversalTileInteractionService
extends RefCounted


const META_KEY: StringName = &"phase39_universal_tile_interactions"

const PROFILE_EFFECT: StringName = &"effect"
const PROFILE_CAMP_BASIC: StringName = &"camp_basic"
const PROFILE_BEAST_MEDIUM: StringName = &"beast_medium"
const PROFILE_CRYSTAL_PASS: StringName = &"crystal_pass"
const PROFILE_FORGE: StringName = &"forge"
const PROFILE_CRYSTAL_CAVE: StringName = &"crystal_cave"
const PROFILE_AETERNA: StringName = &"aeterna"

const PAYLOAD_KIND: StringName = &"phase39_interaction_kind"
const PAYLOAD_KEY: StringName = &"phase39_interaction_key"
const PAYLOAD_EFFECT_INDEX: StringName = &"phase39_effect_index"

const KIND_EFFECT: StringName = &"effect"
const KIND_UNDERLYING: StringName = &"underlying"
const KIND_AETERNA_SYNC: StringName = &"aeterna_sync"
const KIND_AETERNA_POST_EK: StringName = &"aeterna_post_ek"

const CRAFT_ACTION_ID: StringName = &"interact_craft_equipment"


var runtime: KarmanyMultiAiAlphaRuntime = null
var _special_builder: Callable = Callable()
var _special_executor: Callable = Callable()
var _fa_round_usage: Dictionary = {}


func configure(
	p_runtime: KarmanyMultiAiAlphaRuntime,
	special_builder: Callable,
	special_executor: Callable
) -> bool:
	if p_runtime == null or not p_runtime.configured:
		return false
	if p_runtime.coordinator == null or not p_runtime.coordinator.is_configured():
		return false
	if not special_builder.is_valid() or not special_executor.is_valid():
		return false
	runtime = p_runtime
	_special_builder = special_builder
	_special_executor = special_executor
	_fa_round_usage.clear()
	return true


func is_configured() -> bool:
	return (
		runtime != null
		and runtime.configured
		and _special_builder.is_valid()
		and _special_executor.is_valid()
	)


func is_tile_definition_valid(tile: KarmanyTileData) -> bool:
	if tile == null or not tile.has_universal_interaction_definition():
		return false
	return _is_known_profile(tile.interaction_profile_id)


func build_legal_candidates(
	player: KarmanyPlayerState
) -> Array[KarmanyAiActionCandidate]:
	var result: Array[KarmanyAiActionCandidate] = []
	if not is_configured() or player == null:
		return result
	for option in _build_current_options(player):
		if not bool(option.get("legal", false)):
			continue
		var candidate := _wrap_option_as_candidate(player, option)
		if candidate != null and candidate.is_valid():
			result.append(candidate)
	return result


func execute_candidate(
	player: KarmanyPlayerState,
	candidate: KarmanyAiActionCandidate
) -> KarmanyTileInteractionResult:
	if not is_configured() or player == null or candidate == null:
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_REQUEST,
			"Servicio universal de Interactuar no disponible."
		)
	if candidate.action_type != KarmanyAiActionCandidate.ActionType.INTERACT:
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_REQUEST,
			"El candidato no corresponde a Interactuar."
		)
	var requested_key: StringName = StringName(candidate.payload.get(PAYLOAD_KEY, ""))
	if requested_key == &"":
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_OPTION,
			"El candidato no identifica una opcion universal."
		)

	var resolved_option: Dictionary = {}
	for option in _build_current_options(player):
		if StringName(option.get("key", "")) == requested_key:
			resolved_option = option
			break
	if resolved_option.is_empty():
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_OPTION,
			"La opcion ya no pertenece al Uso posterior actual."
		)
	if not bool(resolved_option.get("legal", false)):
		return _result(
			KarmanyTileInteractionResult.Status.INVALID_REQUEST,
			String(resolved_option.get("reason", "La opcion ya no es legal."))
		)

	var manager := runtime.local_session.turn_manager
	var actions_before: int = manager.actions_remaining
	var kind: StringName = StringName(resolved_option.get("kind", ""))
	var success: bool = false
	var raw_result: Variant = null
	var option_index: int = int(resolved_option.get("effect_index", -1))

	if kind == KIND_EFFECT:
		raw_result = KarmanyTileInteractionResolver.interact_effect_option(
			player,
			runtime.board_state,
			manager,
			option_index,
			runtime.coordinator.effect_context
		)
		success = (
			raw_result is KarmanyTileInteractionResult
			and (raw_result as KarmanyTileInteractionResult).is_success()
		)
	elif kind == KIND_UNDERLYING:
		var underlying_value: Variant = resolved_option.get("underlying", null)
		if underlying_value is KarmanyAiActionCandidate:
			raw_result = _special_executor.call(
				player,
				underlying_value as KarmanyAiActionCandidate
			)
			success = raw_result is bool and bool(raw_result)
	elif kind == KIND_AETERNA_SYNC:
		var sync_context := _build_aeterna_context(player)
		raw_result = KarmanyAeternaResolver.resolve_aeterna_sync(player, sync_context)
		success = (
			raw_result is KarmanyAeternaResult
			and (raw_result as KarmanyAeternaResult).is_resolved()
		)
	elif kind == KIND_AETERNA_POST_EK:
		var post_context := _build_aeterna_context(player)
		raw_result = KarmanyAeternaResolver.collect_post_defeat_ek(player, post_context)
		success = (
			raw_result is KarmanyAeternaResult
			and (raw_result as KarmanyAeternaResult).is_resolved()
		)

	if not success:
		return _result(
			KarmanyTileInteractionResult.Status.EFFECT_FAILED,
			"La opcion de Interactuar fue rechazada durante su resolucion."
		)

	var tile := runtime.get_public_tile_data(player.current_coord)
	if (
		tile != null
		and tile.interaction_profile_id == PROFILE_CRYSTAL_CAVE
		and kind == KIND_EFFECT
		and option_index >= 0
		and option_index < tile.later_use_effects.size()
	):
		var effect: KarmanyEffectData = tile.later_use_effects[option_index]
		if (
			effect != null
			and effect.effect_type == KarmanyEffectData.EffectType.ADD_RESOURCE
			and effect.resource_type == KarmanyEffectData.ResourceType.FA
		):
			_mark_crystal_fa_used(player.player_id, manager.current_round)

	var result := KarmanyTileInteractionResult.new()
	result.status = KarmanyTileInteractionResult.Status.SUCCESS
	result.message = "Uso posterior resuelto mediante la fuente universal F39."
	result.tile_id = StringName(tile.tile_id) if tile != null else &""
	result.option_index = option_index
	result.action_consumed = manager.actions_remaining < actions_before
	if raw_result is KarmanyTileInteractionResult:
		result.effect_result = (
			raw_result as KarmanyTileInteractionResult
		).effect_result
	return result


func get_public_preview(
	player: KarmanyPlayerState,
	coord: Vector2i
) -> Dictionary:
	var result: Dictionary = {
		"visible": false,
		"defined": false,
		"interaction_text": "OCULTA",
		"requirements_text": "La identidad permanece oculta.",
		"legal_now": false,
		"legal_options": PackedStringArray()
	}
	if not is_configured() or not runtime.board_state.has_coord(coord):
		return result
	if not runtime.board_state.is_revealed(coord):
		return result
	var tile := runtime.get_public_tile_data(coord)
	if tile == null:
		return result
	result["visible"] = true
	result["defined"] = is_tile_definition_valid(tile)
	result["tile_id"] = String(tile.tile_id)
	result["interaction_text"] = tile.later_use_text
	var requirements: PackedStringArray = PackedStringArray()
	if (
		not tile.limit_text.strip_edges().is_empty()
		and tile.limit_text.strip_edges() != "-"
	):
		requirements.append(tile.limit_text.strip_edges())

	if not is_tile_definition_valid(tile):
		requirements.append(
			"Definicion F39 invalida: falta un perfil canonico de Uso posterior."
		)
		result["requirements_text"] = " ".join(requirements)
		return result
	if player == null:
		requirements.append("Selecciona un jugador activo para evaluar legalidad.")
		result["requirements_text"] = " ".join(requirements)
		return result
	if player.current_coord != coord:
		requirements.append("Debes estar sobre esta loseta para Interactuar.")
		result["requirements_text"] = " ".join(requirements)
		return result

	var options := _build_current_options(player)
	var legal_labels: PackedStringArray = PackedStringArray()
	var blocked_reasons: PackedStringArray = PackedStringArray()
	for option in options:
		if bool(option.get("legal", false)):
			legal_labels.append(String(option.get("label", "Interactuar")))
		else:
			var reason: String = String(option.get("reason", "")).strip_edges()
			if not reason.is_empty() and not blocked_reasons.has(reason):
				blocked_reasons.append(reason)
	result["legal_now"] = not legal_labels.is_empty()
	result["legal_options"] = legal_labels
	if not legal_labels.is_empty():
		requirements.append("Disponible ahora: %s." % " / ".join(legal_labels))
	elif not blocked_reasons.is_empty():
		requirements.append("Bloqueado ahora: %s" % " / ".join(blocked_reasons))
	else:
		requirements.append(_profile_block_reason(tile))
	result["requirements_text"] = " ".join(requirements)
	return result


func _build_current_options(player: KarmanyPlayerState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not is_configured() or player == null:
		return result
	var manager := runtime.local_session.turn_manager
	if manager == null or manager.get_active_player() != player:
		return result
	var tile := runtime.get_public_tile_data(player.current_coord)
	if tile == null or not is_tile_definition_valid(tile):
		return result

	var common := KarmanyTileInteractionResolver.validate_common(
		player,
		runtime.board_state,
		manager
	)
	var common_legal: bool = common.is_success()
	var common_reason: String = "" if common_legal else common.message

	for effect_index in range(tile.later_use_effects.size()):
		var effect: KarmanyEffectData = tile.later_use_effects[effect_index]
		if effect == null:
			continue
		var validation := KarmanyTileInteractionResolver.validate_effect_option(
			player,
			runtime.board_state,
			manager,
			effect_index,
			runtime.coordinator.effect_context
		)
		var legal: bool = common_legal and validation.is_success()
		var reason: String = common_reason if not common_legal else validation.message
		if (
			tile.interaction_profile_id == PROFILE_CRYSTAL_CAVE
			and effect.effect_type == KarmanyEffectData.EffectType.ADD_RESOURCE
			and effect.resource_type == KarmanyEffectData.ResourceType.FA
			and _has_crystal_fa_used(player.player_id, manager.current_round)
		):
			legal = false
			reason = "Ya recolectaste el FA de esta loseta durante la ronda actual."
		result.append({
			"key": StringName("effect:%d" % effect_index),
			"kind": KIND_EFFECT,
			"effect_index": effect_index,
			"label": KarmanyEffectDescriptionFormatter.describe_effect(effect),
			"legal": legal,
			"reason": reason
		})

	if common_legal:
		var special_value: Variant = _special_builder.call(player)
		if special_value is Array:
			for value in special_value:
				if not (value is KarmanyAiActionCandidate):
					continue
				var underlying := value as KarmanyAiActionCandidate
				if not _candidate_matches_profile(
					underlying,
					tile.interaction_profile_id
				):
					continue
				if (
					tile.interaction_profile_id == PROFILE_CRYSTAL_PASS
					and underlying.action_type == KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT
					and manager.has_used_action(CRAFT_ACTION_ID)
				):
					continue
				result.append({
					"key": _underlying_key(underlying),
					"kind": KIND_UNDERLYING,
					"label": underlying.debug_label,
					"legal": true,
					"reason": "",
					"underlying": underlying
				})

	if tile.interaction_profile_id == PROFILE_AETERNA:
		_append_aeterna_direct_options(
			result,
			player,
			common_legal,
			common_reason
		)
	return result


func _append_aeterna_direct_options(
	result: Array[Dictionary],
	player: KarmanyPlayerState,
	common_legal: bool,
	common_reason: String
) -> void:
	var sync_status := _aeterna_sync_preflight(player)
	result.append({
		"key": &"aeterna:sync",
		"kind": KIND_AETERNA_SYNC,
		"label": "Sintonizar con Aeterna",
		"legal": common_legal and bool(sync_status.get("legal", false)),
		"reason": common_reason if not common_legal else String(sync_status.get("reason", ""))
	})
	var post_status := _aeterna_post_ek_preflight(player)
	result.append({
		"key": &"aeterna:post_ek",
		"kind": KIND_AETERNA_POST_EK,
		"label": "Recolectar 2 EK del Santuario",
		"legal": common_legal and bool(post_status.get("legal", false)),
		"reason": common_reason if not common_legal else String(post_status.get("reason", ""))
	})


func _aeterna_sync_preflight(player: KarmanyPlayerState) -> Dictionary:
	var context := _build_aeterna_context(player)
	if context == null or not context.is_valid():
		return {"legal": false, "reason": "Contexto de Aeterna invalido."}
	if context.aeterna_state.defeated:
		return {"legal": false, "reason": "Aeterna ya fue derrotada."}
	if context.aeterna_state.has_used_aeterna_sync(player.player_id):
		return {"legal": false, "reason": "Sintonizar con Aeterna ya fue usado por este jugador."}
	if _available_resonances() < 3:
		return {"legal": false, "reason": "No hay 3 Resonancias disponibles para Sintonizar."}
	if not context.turn_manager.can_spend_action(1):
		return {"legal": false, "reason": "No quedan acciones para Sintonizar."}
	return {"legal": true, "reason": ""}


func _aeterna_post_ek_preflight(player: KarmanyPlayerState) -> Dictionary:
	var context := _build_aeterna_context(player)
	if context == null or not context.is_valid():
		return {"legal": false, "reason": "Contexto de Aeterna invalido."}
	if not context.aeterna_state.defeated:
		return {"legal": false, "reason": "Aeterna aun no ha sido derrotada."}
	var round_number: int = context.turn_manager.current_round
	if not context.aeterna_state.can_collect_post_defeat_ek(
		player.player_id,
		round_number
	):
		return {"legal": false, "reason": "Ya recolectaste los 2 EK del Santuario esta ronda."}
	if not context.turn_manager.can_spend_action(1):
		return {"legal": false, "reason": "No quedan acciones para Interactuar con el Santuario."}
	return {"legal": true, "reason": ""}


func _build_aeterna_context(
	player: KarmanyPlayerState
) -> KarmanyAeternaContext:
	if runtime == null or runtime.coordinator == null or player == null:
		return null
	var context := runtime.coordinator._build_aeterna_context(
		player,
		1,
		KarmanyCombatPowerModifiers.new(),
		false,
		0
	)
	if context != null:
		context.map_format = KarmanyLegacyModeConfig.MapFormat.MAP_41
	return context


func _available_resonances() -> int:
	if runtime == null or runtime.resonance_deck == null:
		return 0
	return (
		runtime.resonance_deck.get_draw_count()
		+ runtime.resonance_deck.get_discard_count()
	)


func _wrap_option_as_candidate(
	player: KarmanyPlayerState,
	option: Dictionary
) -> KarmanyAiActionCandidate:
	var candidate := KarmanyAiActionCandidate.new()
	candidate.action_type = KarmanyAiActionCandidate.ActionType.INTERACT
	candidate.target_coord = player.current_coord
	candidate.debug_label = "Interactuar · %s" % String(
		option.get("label", "Uso posterior")
	)
	candidate.base_utility = 1.0
	candidate.opportunity_value = 1.0
	candidate.payload[PAYLOAD_KIND] = option.get("kind", &"")
	candidate.payload[PAYLOAD_KEY] = option.get("key", &"")
	if option.has("effect_index"):
		candidate.option_index = int(option.get("effect_index", -1))
		candidate.payload[PAYLOAD_EFFECT_INDEX] = candidate.option_index
		var tile := runtime.get_public_tile_data(player.current_coord)
		if (
			tile != null
			and candidate.option_index >= 0
			and candidate.option_index < tile.later_use_effects.size()
		):
			var effect := tile.later_use_effects[candidate.option_index]
			var estimate := KarmanyAiResourceUtility.estimate_effects(
				[effect],
				player,
				runtime.coordinator
			)
			candidate.economy_value = float(estimate.get("value", 0.0))
			candidate.opportunity_value += candidate.economy_value
			candidate.payload["resource_utility"] = estimate
	if option.has("underlying"):
		var underlying := option.get("underlying", null) as KarmanyAiActionCandidate
		if underlying != null:
			candidate.base_utility = underlying.base_utility
			candidate.exploration_value = underlying.exploration_value
			candidate.economy_value = underlying.economy_value
			candidate.aggression_value = underlying.aggression_value
			candidate.opportunity_value = underlying.opportunity_value
			candidate.progress_value = underlying.progress_value
			candidate.risk_value = underlying.risk_value
	if StringName(option.get("kind", "")) == KIND_AETERNA_SYNC:
		candidate.progress_value = 2.0
		candidate.opportunity_value = 2.0
	elif StringName(option.get("kind", "")) == KIND_AETERNA_POST_EK:
		candidate.economy_value = 2.0
	return candidate


func _candidate_matches_profile(
	candidate: KarmanyAiActionCandidate,
	profile_id: StringName
) -> bool:
	match profile_id:
		PROFILE_CAMP_BASIC, PROFILE_CRYSTAL_PASS:
			return candidate.action_type == KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT
		PROFILE_BEAST_MEDIUM, PROFILE_CRYSTAL_CAVE:
			return candidate.action_type == KarmanyAiActionCandidate.ActionType.FIGHT_BEAST
		PROFILE_FORGE:
			return candidate.action_type in [
				KarmanyAiActionCandidate.ActionType.CRAFT_EQUIPMENT,
				KarmanyAiActionCandidate.ActionType.FORGE,
				KarmanyAiActionCandidate.ActionType.IMPROVE_BOOK
			]
		PROFILE_AETERNA:
			return candidate.action_type == KarmanyAiActionCandidate.ActionType.AETERNA
	return false


func _profile_block_reason(tile: KarmanyTileData) -> String:
	match tile.interaction_profile_id:
		PROFILE_CAMP_BASIC:
			return "No hay un Equipo Basico legal y pagable; recolectar 2 MN es la alternativa de la loseta."
		PROFILE_CRYSTAL_PASS:
			return "No hay un Equipo Basico/Avanzado legal y pagable o el crafteo de este turno ya fue usado."
		PROFILE_BEAST_MEDIUM:
			return "No hay un combate de Bestia Media legal; recolectar 2 EK es la alternativa de la loseta."
		PROFILE_FORGE:
			return "Necesitas una opcion legal de crafteo, mejora de Libro o 2 recursos comunes; la conversion a FA solo puede usarse una vez por jugador."
		PROFILE_CRYSTAL_CAVE:
			return "No hay una opcion de Bestia/recoleccion legal en el estado actual. El FA se limita a una vez por jugador por ronda."
		PROFILE_AETERNA:
			return "El Santuario evalua Aeterna, Sintonizar y la recoleccion post-Aeterna segun el estado actual."
		PROFILE_EFFECT:
			return "El efecto esta definido, pero sus requisitos actuales no permiten ejecutarlo."
	return "Perfil de Interactuar no reconocido."


func _underlying_key(candidate: KarmanyAiActionCandidate) -> StringName:
	return StringName(
		"underlying:%d:%s:%d" % [
			candidate.action_type,
			candidate.debug_label,
			candidate.option_index
		]
	)


func _has_crystal_fa_used(player_id: StringName, round_number: int) -> bool:
	return _fa_round_usage.has(_round_usage_key(player_id, round_number))


func _mark_crystal_fa_used(player_id: StringName, round_number: int) -> void:
	_fa_round_usage[_round_usage_key(player_id, round_number)] = true


func _round_usage_key(player_id: StringName, round_number: int) -> String:
	return "%s:%d" % [String(player_id), round_number]


func _is_known_profile(profile_id: StringName) -> bool:
	return profile_id in [
		PROFILE_EFFECT,
		PROFILE_CAMP_BASIC,
		PROFILE_BEAST_MEDIUM,
		PROFILE_CRYSTAL_PASS,
		PROFILE_FORGE,
		PROFILE_CRYSTAL_CAVE,
		PROFILE_AETERNA
	]


func _result(status_value: int, message: String) -> KarmanyTileInteractionResult:
	var result := KarmanyTileInteractionResult.new()
	result.status = status_value
	result.message = message
	return result
