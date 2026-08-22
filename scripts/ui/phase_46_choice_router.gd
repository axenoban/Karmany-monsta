class_name KarmanyPhase46ChoiceRouter
extends RefCounted


enum ChoiceKind {
	NONE,
	ACTION,
	INSTINCT,
	COMBAT_RESONANCE,
	HAND_DISCARD,
	AETERNA_REWARD,
	AETERNA_RESOURCE_DISCARD,
	AETERNA_RESONANCE_DISCARD,
}


var full_session: KarmanyFullMatchSession = null


func configure(session: KarmanyFullMatchSession) -> bool:
	if session == null or not session.configured or session.runtime == null:
		return false
	full_session = session
	return true


func get_pending_choice() -> Dictionary:
	if full_session == null or not full_session.configured:
		return {}

	var aeterna_reward := full_session.get_pending_human_aeterna_reward_request()
	if aeterna_reward != null:
		return _present_aeterna_reward(aeterna_reward)

	var aeterna_resources := full_session.get_pending_human_aeterna_resource_discard_request()
	if aeterna_resources != null:
		return _present_aeterna_resources(aeterna_resources)

	var aeterna_resonance := full_session.get_pending_human_aeterna_resonance_discard_request()
	if aeterna_resonance != null:
		return _present_resonance_discard(
			aeterna_resonance,
			ChoiceKind.AETERNA_RESONANCE_DISCARD,
			"Aeterna: elige Resonancia a descartar"
		)

	var instinct := full_session.get_pending_human_instinct_roll_request()
	if instinct != null:
		return {
			"kind": ChoiceKind.INSTINCT,
			"prompt": "%s\nLanza el Dado de Instinto antes de elegir Resonancia." % instinct.action_label,
			"required_count": 1,
			"options": [{
				"option_id": &"roll_instinct",
				"label": "Lanzar D6 de Instinto",
				"detail": "El resultado se obtiene del RNG determinista de la partida.",
			}],
		}

	var combat_resonance := full_session.get_pending_human_combat_resonance_request()
	if combat_resonance != null:
		var options: Array[Dictionary] = []
		for row in combat_resonance.get_options():
			options.append({
				"option_id": StringName(row.get("option_id", "")),
				"label": String(row.get("display_name", "Resonancia")),
				"detail": String(row.get("rules_text", "")),
			})
		return {
			"kind": ChoiceKind.COMBAT_RESONANCE,
			"prompt": "%s\nElige Resonancia o resuelve sin jugar una." % combat_resonance.action_label,
			"required_count": 1,
			"options": options,
		}

	var hand_discard := full_session.get_pending_human_resonance_discard_request()
	if hand_discard == null:
		hand_discard = full_session.build_human_resonance_discard_request()
	if hand_discard != null:
		return _present_resonance_discard(
			hand_discard,
			ChoiceKind.HAND_DISCARD,
			"Limite de mano: elige Resonancias a descartar"
		)

	var action_request := full_session.get_pending_human_choice_request()
	if action_request == null:
		action_request = full_session.build_human_action_choice_request()
	if action_request != null:
		var action_options: Array[Dictionary] = []
		for row in action_request.get_options():
			action_options.append({
				"option_id": StringName(row.get("option_id", "")),
				"label": String(row.get("label", row.get("action_name", "Accion"))),
				"detail": "Destino %s" % str(row.get("target_coord", Vector2i.ZERO)),
			})
		return {
			"kind": ChoiceKind.ACTION,
			"prompt": "Elige una accion legal",
			"required_count": 1,
			"options": action_options,
		}

	return {}


func resolve_choice(
	kind: int,
	selected_option_ids: Array[StringName],
	replacement_equipment_id: StringName = &""
) -> bool:
	if full_session == null:
		return false
	match kind:
		ChoiceKind.ACTION:
			return selected_option_ids.size() == 1 and full_session.resolve_human_action_choice(selected_option_ids[0])
		ChoiceKind.INSTINCT:
			return selected_option_ids.size() == 1 and full_session.resolve_human_instinct_roll()
		ChoiceKind.COMBAT_RESONANCE:
			return selected_option_ids.size() == 1 and full_session.resolve_human_combat_resonance_choice(selected_option_ids[0])
		ChoiceKind.HAND_DISCARD:
			return full_session.resolve_human_resonance_discard_choice(selected_option_ids)
		ChoiceKind.AETERNA_REWARD:
			return selected_option_ids.size() == 1 and full_session.resolve_human_aeterna_reward_choice(
				selected_option_ids[0],
				replacement_equipment_id
			)
		ChoiceKind.AETERNA_RESOURCE_DISCARD:
			var resources: Array[int] = []
			for option_id in selected_option_ids:
				var text := String(option_id)
				if not text.begins_with("aeterna_resource:"):
					return false
				resources.append(int(text.get_slice(":", 1)))
			return full_session.resolve_human_aeterna_resource_discard_choice(resources)
		ChoiceKind.AETERNA_RESONANCE_DISCARD:
			return full_session.resolve_human_aeterna_resonance_discard_choice(selected_option_ids)
	return false


func _present_aeterna_reward(request: KarmanyAeternaRewardChoiceRequest) -> Dictionary:
	var options: Array[Dictionary] = []
	if request.has_resonance_option():
		options.append({
			"option_id": KarmanyAeternaRewardChoiceRequest.OPTION_RESONANCES,
			"label": "Robar 3 Resonancias y conservar 2",
			"detail": "Despues eliges 1 de las 3 cartas recien robadas para descartarla.",
		})
	for row in request.get_equipment_options():
		options.append({
			"option_id": StringName(row.get("option_id", "")),
			"label": "Equipo ancestral: %s" % String(row.get("display_name", "")),
			"detail": "Recompensa gratuita desde el mercado visible.",
		})
	return {
		"kind": ChoiceKind.AETERNA_REWARD,
		"prompt": "Victoria contra Aeterna: elige una recompensa",
		"required_count": 1,
		"options": options,
		"requires_equipment_replacement": request.requires_equipment_replacement,
		"replacement_equipment_ids": request.get_current_equipment_ids(),
	}


func _present_aeterna_resources(request: KarmanyAeternaResourceDiscardRequest) -> Dictionary:
	var options: Array[Dictionary] = []
	var available := request.get_available_counts()
	for resource_type in [
		KarmanyEffectData.ResourceType.MN,
		KarmanyEffectData.ResourceType.MR,
		KarmanyEffectData.ResourceType.EK,
	]:
		var amount: int = int(available.get(resource_type, 0))
		if amount <= 0:
			continue
		options.append({
			"option_id": StringName("aeterna_resource:%d" % resource_type),
			"label": "%s disponible: %d" % [_resource_label(resource_type), amount],
			"detail": "Puedes elegir este recurso mas de una vez si tienes suficientes unidades.",
			"available_count": amount,
		})
	return {
		"kind": ChoiceKind.AETERNA_RESOURCE_DISCARD,
		"prompt": "Derrota contra Aeterna: elige %d recursos basicos para descartar" % request.required_count,
		"required_count": request.required_count,
		"allow_repeated_options": true,
		"options": options,
	}


func _present_resonance_discard(
	request: KarmanyResonanceDiscardChoiceRequest,
	kind: int,
	prompt: String
) -> Dictionary:
	var options: Array[Dictionary] = []
	for row in request.get_options():
		options.append({
			"option_id": StringName(row.get("option_id", "")),
			"label": String(row.get("display_name", "Resonancia")),
			"detail": String(row.get("rules_text", "")),
		})
	return {
		"kind": kind,
		"prompt": "%s (%d)" % [prompt, request.required_count],
		"required_count": request.required_count,
		"options": options,
	}


func _resource_label(resource_type: int) -> String:
	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			return "MN"
		KarmanyEffectData.ResourceType.MR:
			return "MR"
		KarmanyEffectData.ResourceType.EK:
			return "EK"
	return "?"
