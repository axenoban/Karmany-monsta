class_name KarmanyPhase26SaveBridge
extends Node3D


const PHASE_24_SCENE: PackedScene = preload("res://scenes/ui/phase_24_full_match_prototype.tscn")
const SAVE_PATH: String = "user://karmany_phase26_save.json"

@onready var match_container: Node3D = $MatchContainer
@onready var status_label: Label = $SaveOverlay/Panel/Margin/VBox/StatusLabel
@onready var log_label: Label = $SaveOverlay/Panel/Margin/VBox/LogLabel
@onready var new_button: Button = $SaveOverlay/Panel/Margin/VBox/Buttons/NewButton
@onready var checkpoint_button: Button = $SaveOverlay/Panel/Margin/VBox/Buttons/CheckpointButton
@onready var save_button: Button = $SaveOverlay/Panel/Margin/VBox/Buttons/SaveButton
@onready var load_button: Button = $SaveOverlay/Panel/Margin/VBox/Buttons/LoadButton

var current_match: KarmanyPhase24FullMatchBridge = null
var context: KarmanySaveGameContext = null
var last_operation_ok: bool = false
var last_message: String = ""
var _log_lines: Array[String] = []


func _ready() -> void:
	_connect_buttons()
	await new_game()


func new_game() -> bool:
	last_operation_ok = await _spawn_fresh_match()
	last_message = "NUEVA PARTIDA OK" if last_operation_ok else "NUEVA PARTIDA ERROR"
	_log(last_message)
	_update_status()
	return last_operation_ok


func save_game() -> bool:
	if context == null or not context.is_valid():
		return _operation_error("No existe contexto valido para guardar.")
	last_operation_ok = KarmanySaveGameFacade.save_to_path(context, SAVE_PATH)
	last_message = "GUARDADO OK → %s" % SAVE_PATH if last_operation_ok else "GUARDADO ERROR"
	_log(last_message)
	_update_status()
	return last_operation_ok


func load_game() -> bool:
	var snapshot := KarmanySaveGameFacade.load_snapshot_from_path(SAVE_PATH)
	if snapshot.is_empty():
		return _operation_error("No existe un guardado compatible para cargar.")
	if not await _spawn_fresh_match():
		return _operation_error("No se pudo crear la instancia limpia previa a Cargar.")
	if not KarmanySaveGameFacade.restore(context, snapshot):
		return _operation_error("El snapshot no pudo restaurarse en la partida nueva.")
	_refresh_loaded_presentation()
	last_operation_ok = true
	last_message = "CARGA OK ← %s" % SAVE_PATH
	_log(last_message)
	_update_status()
	return true


func prepare_demo_checkpoint() -> bool:
	if current_match == null or context == null:
		return _operation_error("No existe partida para preparar checkpoint.")
	var player := current_match.player_1
	var coordinator := current_match.coordinator
	if current_match.turn_manager.current_round != 1 or current_match.turn_manager.get_active_player() != player:
		return _operation_error("El checkpoint tecnico requiere una nueva partida en ronda 1.")
	if current_match.turn_manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _operation_error("El checkpoint tecnico requiere 2 acciones disponibles.")

	var interaction := coordinator.interact_effect_option(player, 0)
	if interaction == null or not interaction.is_success():
		return _operation_error("No se pudo ejecutar la accion real Interactuar del checkpoint.")

	var taken := current_match.equipment_market.take_visible(0)
	if taken == null or not player.add_equipment(taken):
		return _operation_error("No se pudo preparar inventario de Equipo para el checkpoint.")
	var extra_card := current_match.resonance_deck.draw_one()
	if extra_card == null or not player.resonance_hand.add_card(extra_card):
		return _operation_error("No se pudo preparar mano de Resonancia para el checkpoint.")
	if not player.resonance_hand.request_discard(1):
		return _operation_error("No se pudo preparar descarte pendiente del checkpoint.")

	var encounter := coordinator.encounter_resolver.create_visible_encounter(
		KarmanyPhase24FullMatchBridge.BRUMAK,
		player.current_coord,
		KarmanyData.Rank.N2,
		player.player_id
	)
	if encounter == null:
		return _operation_error("No se pudo preparar encuentro visible del checkpoint.")
	var book := coordinator.get_book_state(player.player_id)
	if book == null or not book.set_level(2):
		return _operation_error("No se pudo preparar Libro II del checkpoint.")

	var award := current_match.legacy_points.award_points(
		player.player_id,
		KarmanyLegacyPointsEntry.SourceType.OTHER,
		&"phase26_checkpoint",
		2,
		current_match.turn_manager.current_round,
		&"phase26_checkpoint_unique",
		"Checkpoint tecnico de guardado."
	)
	if not award.was_applied():
		return _operation_error("No se pudo preparar PL del checkpoint.")

	var beast_spawn := coordinator.spawn_beast(
		KarmanyPhase24FullMatchBridge.P2_START,
		current_match.beast_deck,
		false
	)
	if not beast_spawn.is_spawned():
		return _operation_error("No se pudo preparar Bestia del checkpoint.")

	# Estado por ronda de Entrenador: debe sobrevivir a Cargar igual que una
	# tregua o limite de Llamar; de lo contrario Dorian podria reutilizar E-03.
	current_match.dorian_pvp.mark_special_pvp_used(
		current_match.player_2.player_id,
		2
	)

	current_match.objectives_missions.record_event(
		player,
		KarmanyMatchCoordinator.EVENT_TILE_VISITED,
		{"coord_key": "phase26_checkpoint"}
	)
	current_match.board_ux.refresh_board_ux()
	current_match.phase_23.refresh_visual_direction()
	if current_match.hud != null:
		current_match.hud.call("_refresh")
	last_operation_ok = true
	last_message = "CHECKPOINT OK — turno parcial + inventarios + encuentro + Bestia + PL preparados."
	_log(last_message)
	_update_status()
	return true


func capture_current_snapshot() -> Dictionary:
	if context == null:
		return {}
	return KarmanySaveGameFacade.capture(context)


func _spawn_fresh_match() -> bool:
	if current_match != null and is_instance_valid(current_match):
		current_match.queue_free()
		current_match = null
		context = null
		await get_tree().process_frame

	var instance := PHASE_24_SCENE.instantiate() as KarmanyPhase24FullMatchBridge
	if instance == null:
		return false
	match_container.add_child(instance)
	current_match = instance
	await get_tree().process_frame
	await get_tree().process_frame
	if not current_match.setup_ok:
		return false
	var phase_24_overlay := current_match.get_node_or_null("Phase24Overlay") as CanvasLayer
	if phase_24_overlay != null:
		phase_24_overlay.visible = false
	context = _build_context(current_match)
	return context != null and context.is_valid()


func _build_context(match: KarmanyPhase24FullMatchBridge) -> KarmanySaveGameContext:
	if match == null:
		return null
	var result := KarmanySaveGameContext.new()
	var players: Array[KarmanyPlayerState] = [match.player_1, match.player_2]
	var beast_decks: Dictionary = {
		"basic": match.beast_deck,
		"complex": match.complex_beast_deck
	}
	if not result.configure(
		match.board_prototype.board_state,
		match.turn_manager,
		players,
		match.resonance_deck,
		match.equipment_market,
		match.legacy_points,
		match.objectives_missions,
		match.coordinator,
		beast_decks,
		match.dorian_pvp
	):
		return null
	return result


func _refresh_loaded_presentation() -> void:
	if current_match == null:
		return
	for coord in current_match.board_prototype.board_state.get_coords():
		current_match.board_prototype.call("_refresh_tile_view_from_state", coord)
	current_match.board_prototype.call("place_trainer_at", current_match.player_1.current_coord)
	current_match.board_ux.refresh_board_ux()
	current_match.phase_23.refresh_visual_direction()
	if current_match.hud != null:
		current_match.hud.call("_refresh")
	current_match.call("_update_status")


func _connect_buttons() -> void:
	new_button.pressed.connect(_on_new_pressed)
	checkpoint_button.pressed.connect(_on_checkpoint_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)


func _on_new_pressed() -> void:
	await new_game()


func _on_checkpoint_pressed() -> void:
	prepare_demo_checkpoint()


func _on_save_pressed() -> void:
	save_game()


func _on_load_pressed() -> void:
	await load_game()


func _update_status() -> void:
	if status_label == null:
		return
	if current_match == null or context == null:
		status_label.text = "FASE 26 · GUARDADO\nSin partida activa."
		return
	var active: String = "FINALIZADA"
	if current_match.turn_manager.is_running and current_match.turn_manager.get_active_player() != null:
		active = String(current_match.turn_manager.get_active_player().player_id)
	status_label.text = (
		"FASE 26 · GUARDADO VERSIONADO\n"
		+ "Ronda %d | Activo %s | Acciones %d\n" % [current_match.turn_manager.current_round, active, current_match.turn_manager.actions_remaining]
		+ "P1: MN %d · MR %d · EK %d · FA %d · PL %d\n" % [current_match.player_1.mn, current_match.player_1.mr, current_match.player_1.ek, current_match.player_1.fa, current_match.legacy_points.get_total(current_match.player_1.player_id)]
		+ "Equipo %d | Resonancias %d | Encuentros %d | Bestias tablero %d\n" % [current_match.player_1.get_equipment_count(), current_match.player_1.get_resonance_count(), current_match.coordinator.encounter_resolver.active_encounters.size(), _count_board_beasts()]
		+ "Archivo: %s" % SAVE_PATH
	)


func _count_board_beasts() -> int:
	if current_match == null:
		return 0
	var total: int = 0
	for coord in current_match.board_prototype.board_state.get_coords():
		if current_match.board_prototype.board_state.has_beast(coord):
			total += 1
	return total


func _log(message: String) -> void:
	if message.is_empty():
		return
	_log_lines.append(message)
	while _log_lines.size() > 10:
		_log_lines.pop_front()
	if log_label != null:
		log_label.text = "\n".join(_log_lines)
	print("FASE 26 UI: ", message)


func _operation_error(message: String) -> bool:
	last_operation_ok = false
	last_message = message
	push_error("FASE 26 ERROR: %s" % message)
	_log("ERROR: " + message)
	_update_status()
	return false
