class_name KarmanyEncounterResolver
extends RefCounted


signal encounter_created(encounter: KarmanyEncounterState)
signal encounter_linked(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState
)
signal encounter_expired(encounter: KarmanyEncounterState)


const ACTION_ID_CALL: StringName = &"call_karmany"
const ACTION_ID_BOND: StringName = &"bond_karmany"


var turn_manager: KarmanyTurnManager = null
var active_encounters: Array[KarmanyEncounterState] = []

var _last_call_round_by_player: Dictionary = {}
var _encounter_sequence: int = 0


func configure(p_turn_manager: KarmanyTurnManager) -> bool:
	if p_turn_manager == null:
		return false
	if turn_manager != null:
		return false

	turn_manager = p_turn_manager
	turn_manager.turn_ended.connect(_on_turn_ended)
	return true


func has_called_this_round(player_id: StringName) -> bool:
	if turn_manager == null or not turn_manager.is_running:
		return false
	return int(
		_last_call_round_by_player.get(
			player_id,
			-1
		)
	) == turn_manager.current_round


func call_karmany(
	player: KarmanyPlayerState,
	source_coord: Vector2i,
	source_rank: int,
	candidates: Array[KarmanyData],
	chosen_index: int,
	source_is_revealed: bool = true,
	source_blocked_by_beast: bool = false
) -> KarmanyEncounterResult:
	var player_error := _validate_active_player(player)
	if player_error != null:
		return player_error

	if not turn_manager.can_spend_action(1):
		return _result(
			KarmanyEncounterResult.Status.NO_ACTIONS,
			"No quedan acciones disponibles."
		)

	if player.current_coord != source_coord:
		return _result(
			KarmanyEncounterResult.Status.WRONG_POSITION,
			"Llamar Karmany requiere estar en la loseta de origen."
		)

	if (
		not source_is_revealed
		or source_blocked_by_beast
		or not _is_callable_rank(source_rank)
	):
		return _result(
			KarmanyEncounterResult.Status.INVALID_SOURCE,
			"La loseta no permite Llamar Karmany en este estado."
		)

	if has_called_this_round(player.player_id):
		return _result(
			KarmanyEncounterResult.Status.CALL_LIMIT_REACHED,
			"Llamar Karmany ya fue usado por este jugador en la ronda."
		)

	if not _are_valid_call_candidates(
		candidates,
		chosen_index,
		source_rank
	):
		return _result(
			KarmanyEncounterResult.Status.INVALID_CANDIDATES,
			"Llamar requiere exactamente 2 Karmany validos del nivel de la loseta."
		)

	var chosen: KarmanyData = candidates[chosen_index]
	var returned: KarmanyData = candidates[1 - chosen_index]
	var encounter := create_visible_encounter(
		chosen,
		source_coord,
		source_rank,
		player.player_id
	)

	if encounter == null:
		return _result(
			KarmanyEncounterResult.Status.INVALID_REQUEST,
			"No se pudo crear el encuentro Karmany."
		)

	if not turn_manager.spend_action_for(ACTION_ID_CALL, 1):
		encounter.expire()
		return _result(
			KarmanyEncounterResult.Status.NO_ACTIONS,
			"No se pudo consumir la accion de Llamar."
		)

	_last_call_round_by_player[player.player_id] = turn_manager.current_round

	var result := _result(
		KarmanyEncounterResult.Status.SUCCESS,
		"Karmany llamado y dejado visible."
	)
	result.encounter = encounter
	result.returned_candidate = returned
	result.action_consumed = true
	return result


func create_visible_encounter(
	karmany_data: KarmanyData,
	source_coord: Vector2i,
	source_rank: int,
	revealed_by_player_id: StringName
) -> KarmanyEncounterState:
	if karmany_data == null:
		return null
	if not karmany_data.is_valid_definition():
		return null
	if karmany_data.is_starting_karmany:
		return null
	if karmany_data.rank != source_rank:
		return null
	if revealed_by_player_id == &"":
		return null

	_encounter_sequence += 1
	var encounter_id := StringName(
		"karmany_encounter_%d" % _encounter_sequence
	)
	var encounter := KarmanyEncounterState.new()

	if not encounter.configure(
		karmany_data,
		encounter_id,
		source_coord,
		source_rank,
		revealed_by_player_id
	):
		return null

	active_encounters.append(encounter)
	encounter_created.emit(encounter)
	return encounter


func attempt_payment_bond(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState
) -> KarmanyEncounterResult:
	var context_error := _validate_bond_context(
		encounter,
		player
	)
	if context_error != null:
		return context_error

	var data := encounter.get_karmany_data()
	if data == null or not data.has_payment_method():
		return _result(
			KarmanyEncounterResult.Status.METHOD_NOT_ALLOWED,
			"Este Karmany no permite vinculo por pago."
		)

	var costs: Dictionary = data.get_bond_cost()
	if not player.can_afford_resources(costs):
		return _result(
			KarmanyEncounterResult.Status.INSUFFICIENT_RESOURCES,
			"Recursos insuficientes para vincular este Karmany."
		)

	if not player.spend_resources(costs):
		return _result(
			KarmanyEncounterResult.Status.INSUFFICIENT_RESOURCES,
			"No se pudo pagar el costo de vinculo."
		)

	if not turn_manager.spend_action_for(ACTION_ID_BOND, 1):
		_refund_resources(player, costs)
		return _result(
			KarmanyEncounterResult.Status.NO_ACTIONS,
			"No se pudo consumir la accion de Vincular."
		)

	var result := _finalize_link(encounter, player)
	result.action_consumed = true
	return result


func begin_defeat_bond_attempt(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState
) -> KarmanyEncounterResult:
	var context_error := _validate_bond_context(
		encounter,
		player
	)
	if context_error != null:
		return context_error

	var data := encounter.get_karmany_data()
	if data == null or not data.has_defeat_method():
		return _result(
			KarmanyEncounterResult.Status.METHOD_NOT_ALLOWED,
			"Este Karmany no permite vinculo por derrota de Defensa."
		)

	if not turn_manager.spend_action_for(ACTION_ID_BOND, 1):
		return _result(
			KarmanyEncounterResult.Status.NO_ACTIONS,
			"No se pudo consumir la accion de Vincular."
		)

	if not encounter.mark_pending_combat(player.player_id):
		return _result(
			KarmanyEncounterResult.Status.ENCOUNTER_UNAVAILABLE,
			"El encuentro no puede iniciar combate de vinculo."
		)

	var result := _result(
		KarmanyEncounterResult.Status.PENDING_COMBAT,
		"Combate de vinculo pendiente de CombatResolver."
	)
	result.encounter = encounter
	result.action_consumed = true
	result.requires_instinct_roll = true
	result.defense_target = data.encounter_defense
	return result


func complete_defeat_bond(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState,
	combat_won: bool
) -> KarmanyEncounterResult:
	if encounter == null or player == null:
		return _result(
			KarmanyEncounterResult.Status.INVALID_REQUEST,
			"Encuentro o jugador invalido."
		)

	if encounter.status != KarmanyEncounterState.Status.PENDING_COMBAT:
		return _result(
			KarmanyEncounterResult.Status.ENCOUNTER_UNAVAILABLE,
			"No existe un combate de vinculo pendiente."
		)

	if encounter.pending_player_id != player.player_id:
		return _result(
			KarmanyEncounterResult.Status.INVALID_REQUEST,
			"El resultado pertenece a otro jugador."
		)

	if not combat_won:
		encounter.reset_after_failed_combat()
		var failed := _result(
			KarmanyEncounterResult.Status.COMBAT_FAILED,
			"El Karmany no fue derrotado y permanece sin vincular."
		)
		failed.encounter = encounter
		return failed

	return _finalize_link(encounter, player)


func attempt_condition_bond(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState,
	fulfilled_condition_id: StringName
) -> KarmanyEncounterResult:
	var context_error := _validate_bond_context(
		encounter,
		player
	)
	if context_error != null:
		return context_error

	var data := encounter.get_karmany_data()
	if (
		data == null
		or not data.has_condition_method()
		or fulfilled_condition_id != data.acquisition_condition_id
	):
		return _result(
			KarmanyEncounterResult.Status.METHOD_NOT_ALLOWED,
			"La condicion de vinculo no esta cumplida."
		)

	if not turn_manager.spend_action_for(ACTION_ID_BOND, 1):
		return _result(
			KarmanyEncounterResult.Status.NO_ACTIONS,
			"No se pudo consumir la accion de Vincular."
		)

	var result := _finalize_link(encounter, player)
	result.action_consumed = true
	return result


func get_visible_encounters_at(
	coord: Vector2i
) -> Array[KarmanyEncounterState]:
	var result: Array[KarmanyEncounterState] = []
	for encounter in active_encounters:
		if encounter.source_coord == coord and encounter.is_visible():
			result.append(encounter)
	return result


func _validate_active_player(
	player: KarmanyPlayerState
) -> KarmanyEncounterResult:
	if turn_manager == null or not turn_manager.is_running:
		return _result(
			KarmanyEncounterResult.Status.INVALID_REQUEST,
			"La partida no esta activa."
		)
	if player == null:
		return _result(
			KarmanyEncounterResult.Status.INVALID_REQUEST,
			"Jugador invalido."
		)
	if turn_manager.get_active_player() != player:
		return _result(
			KarmanyEncounterResult.Status.NOT_ACTIVE_PLAYER,
			"Solo el jugador activo puede realizar esta accion."
		)
	return null


func _validate_bond_context(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState
) -> KarmanyEncounterResult:
	var player_error := _validate_active_player(player)
	if player_error != null:
		return player_error

	if not turn_manager.can_spend_action(1):
		return _result(
			KarmanyEncounterResult.Status.NO_ACTIONS,
			"No quedan acciones disponibles."
		)

	if encounter == null or not encounter.is_available():
		return _result(
			KarmanyEncounterResult.Status.ENCOUNTER_UNAVAILABLE,
			"No hay un Karmany visible disponible para vincular."
		)

	if player.current_coord != encounter.source_coord:
		return _result(
			KarmanyEncounterResult.Status.WRONG_POSITION,
			"Vincular requiere estar en la loseta del Karmany visible."
		)

	if player.has_karmany_instance(encounter.encounter_id):
		return _result(
			KarmanyEncounterResult.Status.ROSTER_REJECTED,
			"La instancia Karmany ya pertenece al jugador."
		)

	return null


func _finalize_link(
	encounter: KarmanyEncounterState,
	player: KarmanyPlayerState
) -> KarmanyEncounterResult:
	if encounter == null or encounter.karmany_state == null:
		return _result(
			KarmanyEncounterResult.Status.INVALID_REQUEST,
			"No existe estado Karmany para vincular."
		)

	var runtime := encounter.karmany_state
	runtime.set_owner_player_id(player.player_id)

	if not runtime.set_bond_state(KarmanyRuntimeState.BondState.LINKED):
		runtime.set_owner_player_id(&"")
		return _result(
			KarmanyEncounterResult.Status.ROSTER_REJECTED,
			"No se pudo actualizar el estado de vinculo."
		)

	if not player.add_linked_karmany(runtime):
		runtime.set_bond_state(KarmanyRuntimeState.BondState.UNBOUND)
		runtime.set_owner_player_id(&"")
		if encounter.status == KarmanyEncounterState.Status.PENDING_COMBAT:
			encounter.reset_after_failed_combat()
		return _result(
			KarmanyEncounterResult.Status.ROSTER_REJECTED,
			"El Karmany no pudo incorporarse al jugador."
		)

	encounter.mark_linked()
	encounter_linked.emit(encounter, player)

	var result := _result(
		KarmanyEncounterResult.Status.SUCCESS,
		"Karmany vinculado e incorporado al jugador."
	)
	result.encounter = encounter
	result.linked_karmany = runtime
	return result


func _are_valid_call_candidates(
	candidates: Array[KarmanyData],
	chosen_index: int,
	source_rank: int
) -> bool:
	if candidates.size() != 2:
		return false
	if chosen_index < 0 or chosen_index >= candidates.size():
		return false

	for candidate in candidates:
		if candidate == null:
			return false
		if not candidate.is_valid_definition():
			return false
		if candidate.is_starting_karmany:
			return false
		if candidate.rank != source_rank:
			return false

	return true


func _is_callable_rank(rank: int) -> bool:
	return (
		rank == KarmanyData.Rank.N1
		or rank == KarmanyData.Rank.N2
		or rank == KarmanyData.Rank.N3
	)


func _refund_resources(
	player: KarmanyPlayerState,
	costs: Dictionary
) -> void:
	for resource_key in costs.keys():
		var amount: int = int(costs[resource_key])
		if amount <= 0:
			continue
		player.gain_resource(
			int(resource_key),
			amount
		)


func _on_turn_ended(
	player: KarmanyPlayerState,
	_round_number: int
) -> void:
	if player == null:
		return

	for encounter in active_encounters:
		if encounter == null:
			continue
		if encounter.handle_revealer_turn_end(player.player_id):
			encounter_expired.emit(encounter)


func _result(
	status_value: int,
	text: String
) -> KarmanyEncounterResult:
	var result := KarmanyEncounterResult.new()
	result.status = status_value
	result.message = text
	return result
