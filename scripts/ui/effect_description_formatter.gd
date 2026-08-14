class_name KarmanyEffectDescriptionFormatter
extends RefCounted


const PENDING_AUTOMATION_PREFIX: String = "Regla publica · automatizacion pendiente: "


static func describe_effect(effect: KarmanyEffectData) -> String:
	if effect == null:
		return "Efecto no disponible."

	match effect.effect_type:
		KarmanyEffectData.EffectType.NONE:
			return _description_or(effect, "Sin efecto adicional.")
		KarmanyEffectData.EffectType.ADD_RESOURCE:
			return "Obten +%d %s" % [
				maxi(effect.amount, 0),
				resource_short_name(effect.resource_type)
			]
		KarmanyEffectData.EffectType.REMOVE_RESOURCE:
			return "Pierde hasta %d %s" % [
				maxi(effect.amount, 0),
				resource_short_name(effect.resource_type)
			]
		KarmanyEffectData.EffectType.DRAW_CARDS:
			return "Roba %d %s" % [
				maxi(effect.amount, 0),
				card_source_label(effect.card_source_id, effect.amount)
			]
		KarmanyEffectData.EffectType.DISCARD_CARDS:
			return "Descarta %d %s" % [
				maxi(effect.amount, 0),
				card_source_label(effect.card_source_id, effect.amount)
			]
		KarmanyEffectData.EffectType.MODIFY_STATE:
			return _description_or(
				effect,
				"Modifica el estado publico %s." % String(effect.state_id)
			)
		KarmanyEffectData.EffectType.ACTIVATE_CONDITION:
			return _description_or(
				effect,
				"Activa la condicion %s." % String(effect.condition_id)
			)
		KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER:
			# La descripcion comunica la regla conocida, no el resultado que
			# posteriormente determine un mazo o RNG.
			return _description_or(
				effect,
				"Activa un encuentro."
			)
	return _description_or(effect, "Efecto publico.")


static func describe_effects(effects: Array[KarmanyEffectData]) -> String:
	if effects.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for effect in effects:
		if effect != null:
			parts.append(describe_effect(effect))
	return " / ".join(parts)


static func describe_entry(tile: KarmanyTileData) -> String:
	if tile == null:
		return "Sin informacion publica."
	var executable_text: String = describe_effects(tile.entry_effects)
	if not executable_text.is_empty():
		return executable_text
	var public_text: String = tile.entry_bonus_text.strip_edges()
	if not public_text.is_empty():
		return PENDING_AUTOMATION_PREFIX + public_text
	return "Sin efecto de Entrada."


static func describe_interaction(tile: KarmanyTileData) -> String:
	if tile == null:
		return "Sin informacion publica."
	var executable_text: String = describe_effects(tile.later_use_effects)
	if not executable_text.is_empty():
		return executable_text
	var public_text: String = tile.later_use_text.strip_edges()
	if not public_text.is_empty():
		return PENDING_AUTOMATION_PREFIX + public_text
	return "Sin Uso posterior."


static func describe_limit(tile: KarmanyTileData) -> String:
	if tile == null:
		return ""
	var value: String = tile.limit_text.strip_edges()
	if value.is_empty() or value == "-":
		return "Sin limitacion publica adicional."
	return value


static func build_revealed_tile_preview(tile: KarmanyTileData) -> String:
	if tile == null:
		return "OCULTA"
	return "%s\nNivel %s\n\nENTRADA\n%s\n\nINTERACTUAR\n%s\n\nLIMITACION\n%s" % [
		tile.display_name,
		tile_level_label(tile.level),
		describe_entry(tile),
		describe_interaction(tile),
		describe_limit(tile)
	]


static func resource_short_name(resource_type: int) -> String:
	match resource_type:
		KarmanyEffectData.ResourceType.MN:
			return "MN"
		KarmanyEffectData.ResourceType.MR:
			return "MR"
		KarmanyEffectData.ResourceType.EK:
			return "EK"
		KarmanyEffectData.ResourceType.FA:
			return "FA"
	return "recurso"


static func tile_level_label(level: int) -> String:
	match level:
		KarmanyTileData.TileLevel.START:
			return "Inicial"
		KarmanyTileData.TileLevel.N1:
			return "N1"
		KarmanyTileData.TileLevel.N2:
			return "N2"
		KarmanyTileData.TileLevel.N3:
			return "N3"
		KarmanyTileData.TileLevel.SANCTUARY:
			return "Legendaria"
	return "?"


static func card_source_label(card_source_id: StringName, amount: int) -> String:
	if card_source_id == KarmanyResonanceEffectAdapter.CARD_SOURCE_ID:
		return "Resonancia" if amount == 1 else "Resonancias"
	if card_source_id == &"":
		return "carta" if amount == 1 else "cartas"
	return String(card_source_id)


static func _description_or(effect: KarmanyEffectData, fallback: String) -> String:
	var description: String = effect.description.strip_edges()
	return description if not description.is_empty() else fallback
