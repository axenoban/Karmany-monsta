class_name KarmanyStartingKarmanySetupPlan
extends RefCounted


var trainer_by_player: Dictionary = {}
var offered_by_player: Dictionary = {}
var chosen_by_player: Dictionary = {}
var pending_player_id: StringName = &""
var last_error: String = ""


func build(
	players: Array[KarmanyPlayerState],
	trainers: Array[KarmanyTrainerData],
	starting_karmanys: Array[KarmanyData],
	rng: RandomNumberGenerator,
	forced_choice_by_player: Dictionary = {},
	stop_before_player_id: StringName = &""
) -> bool:
	trainer_by_player.clear()
	offered_by_player.clear()
	chosen_by_player.clear()
	pending_player_id = &""
	last_error = ""

	if players.is_empty() or rng == null:
		return _fail("Plan de setup sin jugadores o RNG.")
	if trainers.size() < players.size():
		return _fail("No hay suficientes Entrenadores para el setup.")
	if starting_karmanys.size() < 3:
		return _fail("No hay suficientes Karmany iniciales para revelar 3.")

	var trainer_deck: Array[KarmanyTrainerData] = []
	for trainer in trainers:
		if trainer == null or not trainer.is_valid_definition():
			return _fail("Entrenador invalido en el catalogo de setup.")
		trainer_deck.append(trainer)
	_shuffle_trainers(trainer_deck, rng)

	var starting_deck: Array[KarmanyData] = []
	for karmany in starting_karmanys:
		if (
			karmany == null
			or not karmany.is_starting_karmany
			or not karmany.is_valid_definition()
		):
			return _fail("Karmany inicial invalido en el catalogo de setup.")
		starting_deck.append(karmany)
	_shuffle_karmanys(starting_deck, rng)

	for player_index in range(players.size()):
		var player: KarmanyPlayerState = players[player_index]
		if player == null or player.player_id == &"":
			return _fail("PlayerState invalido durante planificacion del setup.")
		trainer_by_player[player.player_id] = trainer_deck[player_index]

	for player in players:
		if starting_deck.size() < 3:
			return _fail("Mazo de iniciales insuficiente para revelar 3.")
		var offered: Array[KarmanyData] = [
			starting_deck[0],
			starting_deck[1],
			starting_deck[2]
		]
		offered_by_player[player.player_id] = _copy_karmany_array(offered)

		if (
			player.player_id == stop_before_player_id
			and not forced_choice_by_player.has(player.player_id)
		):
			pending_player_id = player.player_id
			return true

		var chosen_index: int = -1
		if forced_choice_by_player.has(player.player_id):
			var forced_id := StringName(forced_choice_by_player[player.player_id])
			chosen_index = _find_karmany_index(offered, forced_id)
			if chosen_index < 0:
				return _fail(
					"La eleccion forzada %s no pertenece a las 3 opciones de %s."
					% [String(forced_id), String(player.player_id)]
				)
		else:
			chosen_index = rng.randi_range(0, 2)

		var chosen: KarmanyData = offered[chosen_index]
		chosen_by_player[player.player_id] = chosen
		_return_unchosen_cards_to_deck(starting_deck, offered, chosen_index)

	return true


func get_trainer(player_id: StringName) -> KarmanyTrainerData:
	return trainer_by_player.get(player_id, null) as KarmanyTrainerData


func get_offered(player_id: StringName) -> Array[KarmanyData]:
	var value: Variant = offered_by_player.get(player_id, [])
	if not (value is Array):
		return []
	var result: Array[KarmanyData] = []
	for item in value:
		if item is KarmanyData:
			result.append(item as KarmanyData)
	return result


func get_chosen(player_id: StringName) -> KarmanyData:
	return chosen_by_player.get(player_id, null) as KarmanyData


func _return_unchosen_cards_to_deck(
	starting_deck: Array[KarmanyData],
	offered: Array[KarmanyData],
	chosen_index: int
) -> void:
	var returned: Array[KarmanyData] = []
	for index in range(offered.size()):
		if index != chosen_index:
			returned.append(offered[index])

	# Conserva exactamente la semantica F38: retirar el elegido y devolver
	# las otras dos cartas al final del mazo de iniciales.
	starting_deck.remove_at(chosen_index)
	for _remove_index in range(2):
		starting_deck.pop_front()
	for card in returned:
		starting_deck.append(card)


func _find_karmany_index(
	offered: Array[KarmanyData],
	karmany_id: StringName
) -> int:
	for index in range(offered.size()):
		if offered[index] != null and offered[index].karmany_id == karmany_id:
			return index
	return -1


func _copy_karmany_array(values: Array[KarmanyData]) -> Array[KarmanyData]:
	var result: Array[KarmanyData] = []
	for value in values:
		if value != null:
			result.append(value)
	return result


func _shuffle_trainers(
	values: Array[KarmanyTrainerData],
	rng: RandomNumberGenerator
) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var temporary: KarmanyTrainerData = values[index]
		values[index] = values[other]
		values[other] = temporary


func _shuffle_karmanys(
	values: Array[KarmanyData],
	rng: RandomNumberGenerator
) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var temporary: KarmanyData = values[index]
		values[index] = values[other]
		values[other] = temporary


func _fail(message: String) -> bool:
	last_error = message
	return false
