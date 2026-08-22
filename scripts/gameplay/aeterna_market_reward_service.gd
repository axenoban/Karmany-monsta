class_name KarmanyAeternaMarketRewardService
extends RefCounted


static func can_offer_visible_ancestral(
	player: KarmanyPlayerState,
	market: KarmanyEquipmentMarket
) -> bool:
	if player == null or market == null:
		return false
	for equipment in market.get_visible():
		if equipment == null:
			continue
		if equipment.rarity != KarmanyEquipmentData.Rarity.ANCESTRAL:
			continue
		if player.equipment_inventory.has_equipment_id(equipment.equipment_id):
			continue
		return true
	return false


static func resolve_visible_reward(
	player: KarmanyPlayerState,
	victory_result: KarmanyAeternaResult,
	market: KarmanyEquipmentMarket,
	visible_index: int,
	discard_equipment_id: StringName = &""
) -> bool:
	if player == null or victory_result == null or market == null:
		return false
	if not victory_result.is_victory() or not victory_result.reward_choice_required:
		return false
	if victory_result.reward_resolved:
		return false

	var equipment := market.get_visible_at(visible_index)
	if equipment == null or not equipment.is_valid_definition():
		return false
	if equipment.rarity != KarmanyEquipmentData.Rarity.ANCESTRAL:
		return false
	if player.equipment_inventory.has_equipment_id(equipment.equipment_id):
		return false

	var replaced: KarmanyEquipmentData = null
	if player.equipment_inventory.is_full():
		if discard_equipment_id == &"":
			return false
		var current := player.equipment_inventory.get_equipment_by_id(discard_equipment_id)
		if current == null or not market.can_accept_discard(current):
			return false
		if not player.equipment_inventory.can_replace(discard_equipment_id, equipment):
			return false
	else:
		if discard_equipment_id != &"" or not player.equipment_inventory.can_add(equipment):
			return false

	# take_visible() retira exactamente una de las cuatro cartas publicas y
	# repone esa posicion de inmediato. No se ejecuta crafteo ni se pagan
	# recursos: Aeterna entrega el Equipo como recompensa gratuita.
	var rewarded := market.take_visible(visible_index)
	if rewarded == null or rewarded.equipment_id != equipment.equipment_id:
		return false

	if player.equipment_inventory.is_full():
		replaced = player.replace_equipment(discard_equipment_id, rewarded)
		if replaced == null:
			return false
		if not market.add_to_discard(replaced):
			return false
	else:
		if not player.add_equipment(rewarded):
			return false

	victory_result.reward_choice = KarmanyAeternaResult.RewardChoice.ANCESTRAL_EQUIPMENT
	victory_result.reward_resolved = true
	victory_result.reward_choice_required = false
	victory_result.ancestral_equipment_id = rewarded.equipment_id
	if replaced != null:
		victory_result.replaced_equipment_id = replaced.equipment_id
	return true
