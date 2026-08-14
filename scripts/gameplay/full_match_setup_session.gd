class_name KarmanyFullMatchSetupSession
extends KarmanyFullMatchSessionBase


func _apply_complete_setup() -> bool:
	var players: Array[KarmanyPlayerState] = runtime.local_session.players
	if players.size() != 4:
		return _fail("Setup F38 requiere cuatro PlayerState.")

	# Restablecer solo estado de setup sobre los PlayerState ya creados por F33/F34.
	for player in players:
		player.resource_inventory.reset_to_starting_resources()
		player.karmany_roster.clear()
		player.resonance_hand.clear()
		_last_coord_by_player[player.player_id] = player.current_coord

	if not _setup_trainers_and_starting_karmanys(players):
		return false
	if not _setup_public_objectives_and_missions(players):
		return false
	if not _setup_full_resonance_deck(players):
		return false

	statistics = {
		"turns": 0,
		"actions": 0,
		"explorations": 0,
		"karmany_calls": 0,
		"karmany_links": 0,
		"beast_victories": 0,
		"pvp_resolved": 0,
		"aeterna_attempts": 0
	}
	return true


func _setup_trainers_and_starting_karmanys(
	players: Array[KarmanyPlayerState]
) -> bool:
	var trainer_resources := KarmanyPhase37AlphaContentCatalog.load_category(&"trainers")
	var trainers: Array[KarmanyTrainerData] = []
	for value in trainer_resources:
		if value is KarmanyTrainerData and (value as KarmanyTrainerData).is_valid_definition():
			trainers.append(value as KarmanyTrainerData)
	if trainers.size() != KarmanyV074CanonicalRuntimeCatalog.CANONICAL_COUNTS["trainers"]:
		return _fail("Se requieren los 8 Entrenadores canonicos para setup F38.")
	_shuffle_trainers(trainers)

	var starting_deck := KarmanyPhase37AlphaContentCatalog.get_starting_karmanys()
	if starting_deck.size() != 8:
		return _fail("Se requieren los 8 Karmany iniciales canonicos.")
	_shuffle_karmanys(starting_deck)

	trainer_by_player.clear()
	starting_karmany_by_player.clear()
	setup_choices_by_player.clear()

	for player_index in range(players.size()):
		var player: KarmanyPlayerState = players[player_index]
		var trainer: KarmanyTrainerData = trainers[player_index]
		trainer_by_player[player.player_id] = trainer

		if starting_deck.size() < 3:
			return _fail("Mazo de iniciales insuficiente para revelar 3.")
		var offered: Array[KarmanyData] = [
			starting_deck[0],
			starting_deck[1],
			starting_deck[2]
		]
		var chosen_index: int = _setup_rng.randi_range(0, 2)
		var chosen: KarmanyData = offered[chosen_index]
		var returned: Array[KarmanyData] = []
		for index in range(3):
			if index != chosen_index:
				returned.append(offered[index])
		starting_deck.remove_at(chosen_index)
		for _remove in range(2):
			starting_deck.pop_front()
		for card in returned:
			starting_deck.append(card)

		var runtime_state := KarmanyRuntimeState.new()
		var instance_id := StringName(
			"phase38_start_%s_%s" % [String(player.player_id), String(chosen.karmany_id)]
		)
		if not runtime_state.configure(chosen, instance_id):
			return _fail("No se pudo crear Karmany inicial de %s." % String(player.player_id))
		runtime_state.set_owner_player_id(player.player_id)
		if not runtime_state.set_bond_state(KarmanyRuntimeState.BondState.LINKED):
			return _fail("No se pudo marcar vinculo inicial.")
		if not player.add_linked_karmany(runtime_state):
			return _fail("Roster rechazo el Karmany inicial.")
		if not player.set_active_karmany(instance_id):
			return _fail("No se pudo activar Karmany inicial.")

		starting_karmany_by_player[player.player_id] = chosen
		var offered_ids: PackedStringArray = PackedStringArray()
		for option in offered:
			offered_ids.append(String(option.karmany_id))
		setup_choices_by_player[player.player_id] = {
			"offered": offered_ids,
			"chosen": String(chosen.karmany_id)
		}
	return true


func _setup_public_objectives_and_missions(
	players: Array[KarmanyPlayerState]
) -> bool:
	var all_objectives := KarmanyPhase37AlphaContentCatalog.get_runtime_objectives()
	selected_public_objectives = _select_one_objective_per_family(all_objectives)
	if selected_public_objectives.size() != 4:
		return _fail("Mapa 41 requiere un Objetivo de cada una de las cuatro familias.")
	if not runtime.objectives_missions.configure(
		runtime.local_session.turn_manager,
		selected_public_objectives
	):
		return _fail("No se pudieron configurar los 4 Objetivos Publicos.")

	var mission_pool := KarmanyV074CanonicalRuntimeCatalog.build_runtime_missions(
		KarmanyPhase37AlphaContentCatalog.get_runtime_missions()
	)
	runtime.mission_by_player.clear()
	for player in players:
		var trainer: KarmanyTrainerData = trainer_by_player.get(player.player_id, null) as KarmanyTrainerData
		if trainer == null:
			return _fail("Jugador sin Entrenador durante asignacion de Mision.")
		var mission := _choose_first_game_mission(mission_pool, trainer.trainer_id)
		if mission == null:
			return _fail("No existe Mision recomendada ejecutable para %s." % trainer.display_name)
		if not runtime.objectives_missions.assign_secret_mission(
			player,
			trainer.trainer_id,
			mission
		):
			return _fail("No se pudo asignar Mision a %s." % String(player.player_id))
		runtime.mission_by_player[player.player_id] = mission

		var book := runtime.coordinator.get_book_state(player.player_id)
		if book != null:
			runtime.objectives_missions.set_progress_state(
				player,
				KarmanyMatchCoordinator.STATE_BOOK_LEVEL,
				book.level
			)
		runtime.objectives_missions.record_event(
			player,
			KarmanyMatchCoordinator.EVENT_TILE_VISITED,
			{"coord_key": _coord_key(player.current_coord)}
		)
	return true


func _setup_full_resonance_deck(
	players: Array[KarmanyPlayerState]
) -> bool:
	var existing := KarmanyPhase37AlphaContentCatalog.get_runtime_resonances()
	var full_pool := KarmanyV074CanonicalRuntimeCatalog.build_full_resonance_pool(existing)
	if full_pool.size() != KarmanyV074CanonicalRuntimeCatalog.CANONICAL_COUNTS["resonances"]:
		return _fail("El catalogo v0.74 no produjo las 40 Resonancias canonicas.")
	if not runtime.resonance_deck.setup(
		full_pool,
		true,
		_derive_seed(match_seed, 380401)
	):
		return _fail("No se pudo configurar el mazo completo de Resonancias.")
	for player in players:
		player.resonance_hand.clear()
		if not runtime.resonance_deck.deal_initial_hand(player):
			return _fail("No se pudo repartir mano inicial de 5 Resonancias a %s." % String(player.player_id))
		if not _apply_trainer_resonance_setup_bonus(player):
			return false
	return true


func _apply_trainer_resonance_setup_bonus(
	player: KarmanyPlayerState
) -> bool:
	var trainer: KarmanyTrainerData = trainer_by_player.get(
		player.player_id,
		null
	) as KarmanyTrainerData
	if trainer == null:
		return false
	if trainer.trainer_id == &"dorian" or trainer.trainer_id == &"oryn":
		if runtime.resonance_deck.draw_to_hand(player.resonance_hand, 1) != 1:
			return _fail("No se pudo aplicar Resonancia adicional de setup de %s." % trainer.display_name)
		return true
	if trainer.trainer_id == &"maelis":
		if runtime.resonance_deck.draw_to_hand(player.resonance_hand, 1) != 1:
			return _fail("No se pudo aplicar filtro inicial de Maelis.")
		var ordered := player.get_resonance_hand()
		_sort_resonances_low_power_first(ordered)
		if ordered.is_empty():
			return false
		if not player.resonance_hand.request_discard(1):
			return false
		var discard_ids: Array[StringName] = [ordered[0].resonance_id]
		if not runtime.coordinator.resolve_pending_resonance_discard(
			player,
			discard_ids
		):
			return false
		return true
	# Las otras cinco bonificaciones de setup son mirar/ordenar mazos. El
	# runtime actual no expone una vista privada segura de esos mazos; F38 no
	# simula ni filtra esa informacion.
	return true


func _select_one_objective_per_family(
	all_objectives: Array[KarmanyObjectiveData]
) -> Array[KarmanyObjectiveData]:
	var by_family: Dictionary = {}
	for family in range(4):
		by_family[family] = []
	for objective in all_objectives:
		if objective == null or not objective.is_valid_definition():
			continue
		var family_array: Array = by_family.get(int(objective.family), [])
		family_array.append(objective)
		by_family[int(objective.family)] = family_array

	var result: Array[KarmanyObjectiveData] = []
	for family in range(4):
		var options_value: Variant = by_family.get(family, [])
		if not (options_value is Array):
			return []
		var options: Array = options_value
		if options.is_empty():
			return []
		var chosen_index: int = _setup_rng.randi_range(0, options.size() - 1)
		var chosen_value: Variant = options[chosen_index]
		if chosen_value is KarmanyObjectiveData:
			result.append(chosen_value as KarmanyObjectiveData)
	return result


func _choose_first_game_mission(
	missions: Array[KarmanyMissionData],
	trainer_id: StringName
) -> KarmanyMissionData:
	var alternatives: Array[KarmanyMissionData] = []
	for mission in missions:
		if mission != null and mission.trainer_id == trainer_id and mission.is_valid_definition():
			if mission.recommended_first_game:
				return mission
			alternatives.append(mission)
	if alternatives.is_empty():
		return null
	return alternatives[_setup_rng.randi_range(0, alternatives.size() - 1)]


func _sort_resonances_low_power_first(
	cards: Array[KarmanyResonanceData]
) -> void:
	for outer in range(cards.size()):
		for inner in range(0, cards.size() - 1 - outer):
			var left: KarmanyResonanceData = cards[inner]
			var right: KarmanyResonanceData = cards[inner + 1]
			var should_swap: bool = false
			if left.printed_power > right.printed_power:
				should_swap = true
			elif left.printed_power == right.printed_power:
				should_swap = String(left.resonance_id) > String(right.resonance_id)
			if should_swap:
				cards[inner] = right
				cards[inner + 1] = left


func _shuffle_trainers(values: Array[KarmanyTrainerData]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other: int = _setup_rng.randi_range(0, index)
		var temp: KarmanyTrainerData = values[index]
		values[index] = values[other]
		values[other] = temp


func _shuffle_karmanys(values: Array[KarmanyData]) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other: int = _setup_rng.randi_range(0, index)
		var temp: KarmanyData = values[index]
		values[index] = values[other]
		values[other] = temp


func _connect_runtime_observers() -> void:
	var manager := runtime.local_session.turn_manager
	if not manager.round_started.is_connected(Callable(self, "_on_round_started")):
		manager.round_started.connect(Callable(self, "_on_round_started"))
	if not manager.turn_started.is_connected(Callable(self, "_on_turn_started")):
		manager.turn_started.connect(Callable(self, "_on_turn_started"))
	if not manager.turn_ended.is_connected(Callable(self, "_on_turn_ended")):
		manager.turn_ended.connect(Callable(self, "_on_turn_ended"))
	if not manager.action_spent.is_connected(Callable(self, "_on_action_spent")):
		manager.action_spent.connect(Callable(self, "_on_action_spent"))
	if not runtime.coordinator.match_finished.is_connected(Callable(self, "_on_match_finished")):
		runtime.coordinator.match_finished.connect(Callable(self, "_on_match_finished"))
	if not runtime.local_session.legacy_points.points_awarded.is_connected(Callable(self, "_on_points_awarded")):
		runtime.local_session.legacy_points.points_awarded.connect(Callable(self, "_on_points_awarded"))
	if not runtime.objectives_missions.public_objective_claimed.is_connected(Callable(self, "_on_objective_claimed")):
		runtime.objectives_missions.public_objective_claimed.connect(Callable(self, "_on_objective_claimed"))
	if not runtime.objectives_missions.mission_completed.is_connected(Callable(self, "_on_mission_completed")):
		runtime.objectives_missions.mission_completed.connect(Callable(self, "_on_mission_completed"))
	if not runtime.coordinator.integration_event.is_connected(Callable(self, "_on_integration_event")):
		runtime.coordinator.integration_event.connect(Callable(self, "_on_integration_event"))
