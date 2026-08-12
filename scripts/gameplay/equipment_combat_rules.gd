class_name KarmanyEquipmentCombatRules
extends RefCounted


static func get_power_bonus(
	inventory: KarmanyEquipmentInventory,
	target_type: int,
	active_trigger_ids: PackedStringArray = PackedStringArray()
) -> int:
	if inventory == null:
		return 0

	var target_tags := get_target_tags(target_type)
	if target_tags.is_empty():
		return 0

	var total: int = 0

	for equipment in inventory.get_all():
		if equipment == null:
			continue

		for modifier in equipment.modifiers:
			if modifier == null:
				continue
			if (
				modifier.modifier_type
				!= KarmanyEquipmentModifierData.ModifierType.COMBAT_POWER
			):
				continue
			if not modifier.matches_target_tags(target_tags):
				continue

			if modifier.automatic_in_combat:
				total += modifier.amount
				continue

			if (
				modifier.trigger_id != &""
				and active_trigger_ids.has(String(modifier.trigger_id))
			):
				total += modifier.amount

	return total


static func apply_to_combat_modifiers(
	inventory: KarmanyEquipmentInventory,
	target_type: int,
	combat_modifiers: KarmanyCombatPowerModifiers,
	active_trigger_ids: PackedStringArray = PackedStringArray()
) -> bool:
	if combat_modifiers == null:
		return false

	combat_modifiers.equipment_power = get_power_bonus(
		inventory,
		target_type,
		active_trigger_ids
	)
	return true


static func get_target_tags(target_type: int) -> PackedStringArray:
	match target_type:
		KarmanyCombatRequest.TargetType.UNBOUND_KARMANY:
			return PackedStringArray(["unbound_karmany"])
		KarmanyCombatRequest.TargetType.BEAST:
			return PackedStringArray(["beast"])
		KarmanyCombatRequest.TargetType.BOSS:
			return PackedStringArray(["beast", "boss"])
		KarmanyCombatRequest.TargetType.LEGENDARY:
			return PackedStringArray(["legendary"])
	return PackedStringArray()
