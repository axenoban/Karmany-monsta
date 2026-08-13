class_name KarmanyLegacyPointsController
extends RefCounted


signal points_awarded(
	player_id: StringName,
	points: int,
	total_after: int,
	source_type: int,
	source_id: StringName
)
signal pending_reward_consumed(
	player_id: StringName,
	source_id: StringName
)


const REASON_STANDARD_ROUND_LIMIT: StringName = &"standard_round_limit"
const REASON_LEGACY_RACE_TARGET: StringName = &"legacy_race_target"


var mode_config: KarmanyLegacyModeConfig = KarmanyLegacyModeConfig.new()

var _totals: Dictionary = {}
var _entries: Array[KarmanyLegacyPointsEntry] = []
var _unique_awards: Dictionary = {}


func configure(
	players: Array[KarmanyPlayerState],
	p_mode_config: KarmanyLegacyModeConfig
) -> bool:
	if players.is_empty() or p_mode_config == null:
		return false

	var totals: Dictionary = {}
	for player in players:
		if player == null or player.player_id == &"":
			return false
		if totals.has(player.player_id):
			return false
		totals[player.player_id] = 0

	mode_config = p_mode_config
	_totals = totals
	_entries.clear()
	_unique_awards.clear()
	return true


func get_total(player_id: StringName) -> int:
	return int(_totals.get(player_id, 0))


func get_points(player_id: StringName) -> int:
	# Alias de lectura para capas UI/integracion. La fuente de verdad sigue
	# siendo exactamente el mismo total centralizado de Fase 17.
	return get_total(player_id)


func has_player(player_id: StringName) -> bool:
	return _totals.has(player_id)


func get_registered_player_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for player_id in _totals.keys():
		result.append(player_id)
	return result


func get_entries() -> Array[KarmanyLegacyPointsEntry]:
	var result: Array[KarmanyLegacyPointsEntry] = []
	for entry in _entries:
		result.append(entry)
	return result


func get_entries_for_player(
	player_id: StringName
) -> Array[KarmanyLegacyPointsEntry]:
	var result: Array[KarmanyLegacyPointsEntry] = []
	for entry in _entries:
		if entry.player_id == player_id:
			result.append(entry)
	return result


func get_points_by_source_type(
	player_id: StringName,
	source_type: int
) -> int:
	var total: int = 0
	for entry in _entries:
		if entry.player_id == player_id and entry.source_type == source_type:
			total += entry.points
	return total


func award_points(
	player_id: StringName,
	source_type: int,
	source_id: StringName,
	points: int,
	round_number: int,
	unique_key: StringName = &"",
	note: String = ""
) -> KarmanyLegacyPointsAwardResult:
	if not has_player(player_id):
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"Jugador no registrado en el controlador de PL."
		)
	if points <= 0:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.NO_POINTS,
			"La recompensa no contiene PL positivos."
		)
	if source_id == &"" or round_number <= 0:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"Fuente y ronda son obligatorias para registrar PL."
		)
	if unique_key != &"" and _unique_awards.has(unique_key):
		return _result(
			KarmanyLegacyPointsAwardResult.Status.DUPLICATE,
			"Esta recompensa de PL ya fue registrada."
		)

	var entry := KarmanyLegacyPointsEntry.new()
	if not entry.configure(
		player_id,
		source_type,
		source_id,
		points,
		round_number,
		unique_key,
		note
	):
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"No se pudo construir la entrada del libro mayor de PL."
		)

	var total_after: int = get_total(player_id) + points
	_totals[player_id] = total_after
	_entries.append(entry)
	if unique_key != &"":
		_unique_awards[unique_key] = true

	points_awarded.emit(
		player_id,
		points,
		total_after,
		source_type,
		source_id
	)

	var result := KarmanyLegacyPointsAwardResult.new()
	result.status = KarmanyLegacyPointsAwardResult.Status.APPLIED
	result.entry = entry
	result.total_after = total_after
	result.message = "PL registrados correctamente."
	return result


func consume_pending_reward(
	reward: KarmanyLegacyRewardPending
) -> KarmanyLegacyPointsAwardResult:
	if reward == null:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"La recompensa pendiente es obligatoria."
		)
	if reward.consumed:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.ALREADY_CONSUMED,
			"La recompensa pendiente ya fue consumida."
		)

	var source_type := _map_pending_source_type(reward.source_type)
	if source_type < 0:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"Tipo de recompensa pendiente no soportado."
		)

	var unique_key := StringName(
		"pending:%d:%s:%s" % [
			reward.source_type,
			String(reward.player_id),
			String(reward.source_id)
		]
	)
	var result := award_points(
		reward.player_id,
		source_type,
		reward.source_id,
		reward.legacy_points,
		reward.round_number,
		unique_key,
		"Recompensa pendiente consumida."
	)
	if result.was_applied():
		reward.mark_consumed()
		pending_reward_consumed.emit(
			reward.player_id,
			reward.source_id
		)
	return result


func award_beast_result(
	player_id: StringName,
	beast_result: KarmanyBeastCombatResult,
	round_number: int
) -> KarmanyLegacyPointsAwardResult:
	if beast_result == null or not beast_result.is_victory():
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"Solo una victoria contra Bestia puede otorgar PL."
		)
	if beast_result.beast_state == null or beast_result.beast_state.beast_data == null:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"El resultado de Bestia no contiene una fuente valida."
		)

	var beast_id: StringName = beast_result.beast_state.beast_data.beast_id
	var unique_key := StringName(
		"beast:%s" % String(beast_result.beast_state.instance_id)
	)
	return award_points(
		player_id,
		KarmanyLegacyPointsEntry.SourceType.BEAST,
		beast_id,
		beast_result.reward_legacy_points_pending,
		round_number,
		unique_key,
		"Bestia derrotada."
	)


func award_pvp_result(
	pvp_result: KarmanyPvpCombatResult,
	round_number: int
) -> KarmanyLegacyPointsAwardResult:
	if pvp_result == null or not pvp_result.is_resolved():
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"El PvP debe estar resuelto antes de registrar PL."
		)
	if pvp_result.winner_player_id == &"" or pvp_result.combat_id == &"":
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"El resultado PvP requiere ganador y combat_id."
		)

	var unique_key := StringName(
		"pvp:%s" % String(pvp_result.combat_id)
	)
	return award_points(
		pvp_result.winner_player_id,
		KarmanyLegacyPointsEntry.SourceType.PVP,
		pvp_result.combat_id,
		pvp_result.reward_legacy_points_pending,
		round_number,
		unique_key,
		"Victoria PvP."
	)


func award_milestone(
	player_id: StringName,
	milestone_id: StringName,
	round_number: int
) -> KarmanyLegacyPointsAwardResult:
	var points: int = KarmanyLegacyMilestoneCatalog.get_points(milestone_id)
	if points <= 0:
		return _result(
			KarmanyLegacyPointsAwardResult.Status.INVALID_REQUEST,
			"Hito de Progresion desconocido."
		)

	var unique_key := StringName(
		"milestone:%s:%s" % [
			String(player_id),
			String(milestone_id)
		]
	)
	return award_points(
		player_id,
		KarmanyLegacyPointsEntry.SourceType.MILESTONE,
		milestone_id,
		points,
		round_number,
		unique_key,
		"Hito de Progresion."
	)


func evaluate_end_of_round(
	round_number: int
) -> KarmanyLegacyMatchEvaluation:
	var evaluation := KarmanyLegacyMatchEvaluation.new()
	evaluation.round_number = round_number
	if round_number <= 0 or _totals.is_empty():
		return evaluation

	var leading_score: int = -1
	for player_id in _totals.keys():
		var score: int = get_total(player_id)
		if score > leading_score:
			leading_score = score
			evaluation.leader_player_ids.clear()
			evaluation.leader_player_ids.append(player_id)
		elif score == leading_score:
			evaluation.leader_player_ids.append(player_id)
	evaluation.leading_score = maxi(leading_score, 0)

	if mode_config.is_standard():
		if round_number >= mode_config.standard_round_limit:
			evaluation.should_end_match = true
			evaluation.reason_id = REASON_STANDARD_ROUND_LIMIT
		return evaluation

	evaluation.target_points = mode_config.race_target_points
	for player_id in _totals.keys():
		if get_total(player_id) >= mode_config.race_target_points:
			evaluation.target_reached_player_ids.append(player_id)
	if not evaluation.target_reached_player_ids.is_empty():
		evaluation.should_end_match = true
		evaluation.reason_id = REASON_LEGACY_RACE_TARGET
	return evaluation


func _map_pending_source_type(source_type: int) -> int:
	match source_type:
		KarmanyLegacyRewardPending.SourceType.PUBLIC_OBJECTIVE:
			return KarmanyLegacyPointsEntry.SourceType.PUBLIC_OBJECTIVE
		KarmanyLegacyRewardPending.SourceType.TRAINER_MISSION:
			return KarmanyLegacyPointsEntry.SourceType.TRAINER_MISSION
	return -1


func _result(
	status_value: int,
	message: String
) -> KarmanyLegacyPointsAwardResult:
	var result := KarmanyLegacyPointsAwardResult.new()
	result.status = status_value
	result.message = message
	return result
