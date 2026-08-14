class_name KarmanyPhase37AlphaContentCatalog
extends RefCounted


const CATEGORY_DIRS: Dictionary = {
	&"trainers": "res://data/trainers",
	&"tiles": "res://data/tiles",
	&"karmanys": "res://data/karmanys",
	&"beasts": "res://data/beasts",
	&"equipment": "res://data/equipment",
	&"resonances": "res://data/resonances",
	&"objectives": "res://data/objectives",
	&"missions": "res://data/missions"
}


static func build_inventory() -> Dictionary:
	var result: Dictionary = {}
	for category_value in CATEGORY_DIRS.keys():
		var category: StringName = StringName(category_value)
		var all_resources: Array[Resource] = load_category(category)
		var executable_count: int = 0
		for resource_value in all_resources:
			if is_runtime_safe(category, resource_value):
				executable_count += 1
		var row: Dictionary = {
			"existing": all_resources.size(),
			"runtime_safe": executable_count,
			"canonical": int(KarmanyPhase29ContentCatalog.CANONICAL_COUNTS.get(String(category), 0)),
			"remaining_canonical": maxi(
				int(KarmanyPhase29ContentCatalog.CANONICAL_COUNTS.get(String(category), 0)) - all_resources.size(),
				0
			)
		}
		if category == &"tiles":
			var tile_report: Dictionary = build_tile_automation_report()
			row["structured_entry"] = int(tile_report.get("structured_entry", 0))
			row["structured_interaction"] = int(tile_report.get("structured_interaction", 0))
			row["fully_structured"] = int(tile_report.get("fully_structured", 0))
			row["text_only_rules"] = int(tile_report.get("text_only_rules", 0))
		result[String(category)] = row
	return result


static func build_tile_automation_report() -> Dictionary:
	var structured_entry: int = 0
	var structured_interaction: int = 0
	var fully_structured: int = 0
	var text_only_rules: int = 0
	for tile in get_tiles():
		var has_entry_data: bool = not tile.entry_effects.is_empty()
		var has_interaction_data: bool = not tile.later_use_effects.is_empty()
		var has_entry_text: bool = not tile.entry_bonus_text.strip_edges().is_empty()
		var has_interaction_text: bool = not tile.later_use_text.strip_edges().is_empty()
		if has_entry_data:
			structured_entry += 1
		if has_interaction_data:
			structured_interaction += 1
		if has_entry_data and has_interaction_data:
			fully_structured += 1
		if (
			(has_entry_text and not has_entry_data)
			or (has_interaction_text and not has_interaction_data)
		):
			text_only_rules += 1
	return {
		"structured_entry": structured_entry,
		"structured_interaction": structured_interaction,
		"fully_structured": fully_structured,
		"text_only_rules": text_only_rules
	}


static func load_category(category: StringName) -> Array[Resource]:
	var result: Array[Resource] = []
	var directory_path: String = String(CATEGORY_DIRS.get(category, ""))
	if directory_path.is_empty():
		return result
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return result

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()
	for file_name in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var resource_path: String = "%s/%s" % [directory_path, file_name]
		if not ResourceLoader.exists(resource_path):
			continue
		var resource_value: Resource = ResourceLoader.load(resource_path)
		if not _matches_category(category, resource_value):
			continue
		result.append(resource_value)
	return result


static func get_tiles() -> Array[KarmanyTileData]:
	var result: Array[KarmanyTileData] = []
	for resource_value in load_category(&"tiles"):
		var tile := resource_value as KarmanyTileData
		if tile != null:
			result.append(tile)
	return result


static func get_starting_karmanys() -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	for resource_value in load_category(&"karmanys"):
		var data := resource_value as KarmanyData
		if data != null and data.is_starting_karmany and data.is_valid_definition():
			result.append(data)
	return result


static func get_runtime_karmanys() -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	for resource_value in load_category(&"karmanys"):
		var data := resource_value as KarmanyData
		if data == null or data.is_starting_karmany:
			continue
		if is_runtime_safe(&"karmanys", data):
			result.append(data)
	return result


static func get_runtime_beasts() -> Array[KarmanyBeastData]:
	var result: Array[KarmanyBeastData] = []
	for resource_value in load_category(&"beasts"):
		var data := resource_value as KarmanyBeastData
		if data != null and is_runtime_safe(&"beasts", data):
			result.append(data)
	return result


static func get_runtime_equipment() -> Array[KarmanyEquipmentData]:
	var result: Array[KarmanyEquipmentData] = []
	for resource_value in load_category(&"equipment"):
		var data := resource_value as KarmanyEquipmentData
		if data != null and is_runtime_safe(&"equipment", data):
			result.append(data)
	return result


static func get_runtime_resonances() -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	for resource_value in load_category(&"resonances"):
		var data := resource_value as KarmanyResonanceData
		if data != null and is_runtime_safe(&"resonances", data):
			result.append(data)
	return result


static func get_runtime_objectives() -> Array[KarmanyObjectiveData]:
	var result: Array[KarmanyObjectiveData] = []
	for resource_value in load_category(&"objectives"):
		var data := resource_value as KarmanyObjectiveData
		if data != null and is_runtime_safe(&"objectives", data):
			result.append(data)
	return result


static func get_runtime_missions() -> Array[KarmanyMissionData]:
	var result: Array[KarmanyMissionData] = []
	for resource_value in load_category(&"missions"):
		var data := resource_value as KarmanyMissionData
		if data != null and is_runtime_safe(&"missions", data):
			result.append(data)
	return result


static func is_runtime_safe(category: StringName, resource_value: Resource) -> bool:
	if resource_value == null:
		return false
	if not KarmanyPhase29ContentCatalog.is_resource_valid(category, resource_value):
		return false

	# Every materialized tile can safely exist as public/map data. Individual
	# tile effects can still be text-only; build_tile_automation_report() keeps
	# that limitation explicit instead of pretending it is automated.
	if category == &"tiles":
		return true

	var content_id: StringName = KarmanyPhase29ContentCatalog.get_content_id(
		category,
		resource_value
	)
	if content_id == &"":
		return false

	var added_ids: Array[StringName] = KarmanyPhase29ContentCatalog.get_added_ids(category)
	if not added_ids.has(content_id):
		# Content that predates Phase 29 is the executable baseline that the
		# Phase 29 coverage table explicitly extends.
		return true
	return (
		KarmanyPhase29ContentCatalog.get_coverage_state(category, content_id)
		== KarmanyPhase29ContentCatalog.CoverageState.EXECUTABLE
	)


static func _matches_category(category: StringName, resource_value: Resource) -> bool:
	if resource_value == null:
		return false
	match category:
		&"trainers":
			return resource_value is KarmanyTrainerData
		&"tiles":
			return resource_value is KarmanyTileData
		&"karmanys":
			return resource_value is KarmanyData
		&"beasts":
			return resource_value is KarmanyBeastData
		&"equipment":
			return resource_value is KarmanyEquipmentData
		&"resonances":
			return resource_value is KarmanyResonanceData
		&"objectives":
			return resource_value is KarmanyObjectiveData
		&"missions":
			return resource_value is KarmanyMissionData
	return false
