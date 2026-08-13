class_name KarmanyLegacyMilestoneCatalog
extends RefCounted


const FIRST_N2_LINKED: StringName = &"first_karmany_n2_linked"
const FIRST_N3_LINKED: StringName = &"first_karmany_n3_linked"
const FIRST_ADVANCED_EQUIPMENT: StringName = &"first_advanced_equipment_created"
const FIRST_ANCESTRAL_EQUIPMENT: StringName = &"first_ancestral_equipment_created"
const BOOK_III_REACHED: StringName = &"book_iii_reached"


static func get_points(milestone_id: StringName) -> int:
	match milestone_id:
		FIRST_N2_LINKED:
			return 1
		FIRST_N3_LINKED:
			return 2
		FIRST_ADVANCED_EQUIPMENT:
			return 1
		FIRST_ANCESTRAL_EQUIPMENT:
			return 2
		BOOK_III_REACHED:
			return 3
	return 0


static func is_valid_milestone(milestone_id: StringName) -> bool:
	return get_points(milestone_id) > 0
