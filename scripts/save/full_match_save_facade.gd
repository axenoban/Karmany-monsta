class_name KarmanyFullMatchSaveFacade
extends RefCounted


const DEFAULT_SAVE_PATH: String = "user://karmany_full_match_continue.json"


static func save_session(
	session: KarmanyFullMatchSession,
	path: String = DEFAULT_SAVE_PATH
) -> bool:
	if path.is_empty():
		return false
	var package := KarmanyFullMatchSaveAdapter.capture(session)
	if package.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(package, "  "))
	file.close()
	return true


static func load_package(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return {}
	var package: Dictionary = parsed
	return package if KarmanyFullMatchSaveAdapter.is_supported_package(package) else {}


static func restore_session(
	session: KarmanyFullMatchSession,
	path: String = DEFAULT_SAVE_PATH
) -> bool:
	var package := load_package(path)
	return not package.is_empty() and KarmanyFullMatchSaveAdapter.restore(session, package)


static func continue_session(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	var package := load_package(path)
	if package.is_empty():
		return {"ok": false, "message": "No existe un guardado F47 compatible."}
	return KarmanyFullMatchSaveAdapter.build_fresh_session_from_package(package)


static func has_compatible_save(path: String = DEFAULT_SAVE_PATH) -> bool:
	return not load_package(path).is_empty()


static func delete_save(path: String = DEFAULT_SAVE_PATH) -> bool:
	if path.is_empty():
		return false
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
