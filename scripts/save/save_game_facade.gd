class_name KarmanySaveGameFacade
extends RefCounted


static func capture(context: KarmanySaveGameContext) -> Dictionary:
	var snapshot: Dictionary = KarmanySaveGameService.capture(context)
	if snapshot.is_empty():
		return snapshot
	var trainer_runtime: Dictionary = {}
	if context != null and context.dorian_pvp != null:
		var used_rounds: Array = []
		for player_id in context.dorian_pvp._used_round_by_player.keys():
			used_rounds.append({
				"player_id": String(player_id),
				"round": int(context.dorian_pvp._used_round_by_player[player_id])
			})
		trainer_runtime["dorian_pvp_used"] = used_rounds
	snapshot["trainer_runtime"] = trainer_runtime
	return snapshot


static func save_to_path(context: KarmanySaveGameContext, path: String) -> bool:
	if path.is_empty():
		return false
	var snapshot: Dictionary = capture(context)
	if snapshot.is_empty():
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(snapshot, "  "))
	file.close()
	return true


static func load_snapshot_from_path(path: String) -> Dictionary:
	return KarmanySaveGameService.load_snapshot_from_path(path)


static func restore(context: KarmanySaveGameContext, snapshot: Dictionary) -> bool:
	if not KarmanySaveGameService.restore(context, snapshot):
		return false
	if context.dorian_pvp != null:
		context.dorian_pvp.clear()
		var trainer_runtime: Dictionary = snapshot.get("trainer_runtime", {})
		for value in trainer_runtime.get("dorian_pvp_used", []):
			if not (value is Dictionary):
				continue
			var record: Dictionary = value
			context.dorian_pvp.mark_special_pvp_used(
				StringName(String(record.get("player_id", ""))),
				int(record.get("round", 0))
			)
	return true
