class_name KarmanyLegacyModeConfig
extends RefCounted


enum Mode {
	STANDARD,
	LEGACY_RACE
}

enum MapFormat {
	MAP_22,
	MAP_41
}


var mode: Mode = Mode.STANDARD
var map_format: MapFormat = MapFormat.MAP_22
var standard_round_limit: int = 7
var race_target_points: int = 22


func configure_standard(
	p_map_format: int,
	round_limit_override: int = 0
) -> bool:
	if p_map_format < MapFormat.MAP_22 or p_map_format > MapFormat.MAP_41:
		return false
	if round_limit_override < 0:
		return false

	mode = Mode.STANDARD
	map_format = p_map_format
	standard_round_limit = round_limit_override
	if standard_round_limit == 0:
		standard_round_limit = 7 if map_format == MapFormat.MAP_22 else 8
	race_target_points = 22 if map_format == MapFormat.MAP_22 else 25
	return true


func configure_legacy_race(
	p_map_format: int,
	target_override: int = 0
) -> bool:
	if p_map_format < MapFormat.MAP_22 or p_map_format > MapFormat.MAP_41:
		return false
	if target_override < 0:
		return false

	mode = Mode.LEGACY_RACE
	map_format = p_map_format
	standard_round_limit = 0
	race_target_points = target_override
	if race_target_points == 0:
		race_target_points = 22 if map_format == MapFormat.MAP_22 else 25
	return true


func is_standard() -> bool:
	return mode == Mode.STANDARD


func is_legacy_race() -> bool:
	return mode == Mode.LEGACY_RACE
