extends Node


const TRAINER_DIR := "res://data/trainers"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.7 ENTRENADORES")
	print("========================================")
	var ok: bool = true
	ok = _test_contract_coverage() and ok
	ok = _test_existing_setup_runtime() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.7 OK - 8/8 Entrenadores auditados: 3 PARTIAL, 5 DATA_ONLY, 0 PENDING; toda clausula implementada, parcial o explicitamente excluida.")
	else:
		push_error("FASE 44.7 ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_contract_coverage() -> bool:
	var trainers := _load_trainers()
	if trainers.size() != 8:
		return _fail("Se esperaban 8 Entrenadores directos y hay %d." % trainers.size())
	for trainer in trainers:
		if trainer == null or not trainer.is_valid_definition():
			return _fail("Existe un Entrenador invalido.")
		if not KarmanyTrainerAbilityRuntimeService.has_contract(trainer.trainer_id):
			return _fail("Falta contrato F44.7 para %s." % String(trainer.trainer_id))
		var expected_status := _status_from_resource(trainer.automation_status)
		var actual_status := KarmanyTrainerAbilityRuntimeService.get_status(trainer.trainer_id)
		if actual_status != expected_status:
			return _fail("%s: Resource=%s contrato=%s." % [String(trainer.trainer_id), String(expected_status), String(actual_status)])
		var contract := KarmanyTrainerAbilityRuntimeService.get_contract(trainer.trainer_id)
		if String(contract.get("reason", "")).strip_edges().is_empty():
			return _fail("%s no documenta razon de cobertura." % String(trainer.trainer_id))
		for clause_id in [trainer.passive_id, trainer.active_id, trainer.setup_bonus_id]:
			var coverage := KarmanyTrainerAbilityRuntimeService.get_clause_coverage(
				trainer.trainer_id,
				clause_id
			)
			if coverage == &"missing":
				return _fail("%s deja sin clasificar la clausula %s." % [String(trainer.trainer_id), String(clause_id)])

	var counts := KarmanyTrainerAbilityRuntimeService.get_contract_counts()
	if int(counts.get(KarmanyTrainerAbilityRuntimeService.STATUS_PARTIAL, 0)) != 3:
		return _fail("Se esperaban 3 PARTIAL: %s." % str(counts))
	if int(counts.get(KarmanyTrainerAbilityRuntimeService.STATUS_DATA_ONLY, 0)) != 5:
		return _fail("Se esperaban 5 DATA_ONLY: %s." % str(counts))
	if int(counts.get(KarmanyTrainerAbilityRuntimeService.STATUS_FULLY, 0)) != 0:
		return _fail("No existe Entrenador FULLY_EXECUTABLE certificado en F44.7.")
	if int(counts.get(KarmanyTrainerAbilityRuntimeService.STATUS_PENDING, 0)) != 0:
		return _fail("No debe quedar ningun Entrenador PENDING.")
	print("F44.7 CONTRACTS | 8/8 | FULLY=0 PARTIAL=3 DATA_ONLY=5 PENDING=0")
	return true


func _test_existing_setup_runtime() -> bool:
	var runtime := KarmanyMultiAiAlphaRuntime.new()
	if not runtime.configure_new(4, 447700):
		return _fail("No se pudo crear runtime para validar setup de Entrenadores.")
	var session := KarmanyFullMatchSession.new()
	if not session.configure(runtime):
		return _fail("No se pudo configurar FullMatchSession: %s" % session.last_error)
	var player := runtime.local_session.players[0]
	if player == null:
		return _fail("Fixture sin player_1.")

	var dorian := load("res://data/trainers/e_03_dorian.tres") as KarmanyTrainerData
	var maelis := load("res://data/trainers/e_05_maelis.tres") as KarmanyTrainerData
	var oryn := load("res://data/trainers/e_08_oryn.tres") as KarmanyTrainerData
	if dorian == null or maelis == null or oryn == null:
		return _fail("No se pudieron cargar Dorian/Maelis/Oryn.")

	session.trainer_by_player[player.player_id] = dorian
	var hand_before: int = player.get_resonance_count()
	if not session._apply_trainer_resonance_setup_bonus(player):
		return _fail("Setup de Dorian fue rechazado.")
	if player.get_resonance_count() != hand_before + 1:
		return _fail("Dorian debe robar exactamente 1 Resonancia de setup.")

	session.trainer_by_player[player.player_id] = oryn
	hand_before = player.get_resonance_count()
	if not session._apply_trainer_resonance_setup_bonus(player):
		return _fail("Setup de Oryn fue rechazado.")
	if player.get_resonance_count() != hand_before + 1:
		return _fail("Oryn debe robar exactamente 1 Resonancia de setup.")

	session.trainer_by_player[player.player_id] = maelis
	hand_before = player.get_resonance_count()
	var draw_before: int = runtime.resonance_deck.get_draw_count()
	var discard_before: int = runtime.resonance_deck.get_discard_count()
	if not session._apply_trainer_resonance_setup_bonus(player):
		return _fail("Setup Alpha parcial de Maelis fue rechazado.")
	if player.get_resonance_count() != hand_before:
		return _fail("Maelis debe robar 1 y descartar 1: la mano neta no cambia.")
	if runtime.resonance_deck.get_draw_count() != draw_before - 1:
		return _fail("Maelis no robo exactamente 1 Resonancia antes del descarte.")
	if runtime.resonance_deck.get_discard_count() != discard_before + 1:
		return _fail("Maelis no envio exactamente 1 Resonancia al descarte.")

	print("F44.7 SETUP | Dorian +1, Oryn +1 y Maelis roba1/descarta1 Alpha: OK")
	return true


func _status_from_resource(status_value: int) -> StringName:
	match status_value:
		KarmanyTrainerData.AutomationStatus.DATA_ONLY:
			return KarmanyTrainerAbilityRuntimeService.STATUS_DATA_ONLY
		KarmanyTrainerData.AutomationStatus.PARTIAL:
			return KarmanyTrainerAbilityRuntimeService.STATUS_PARTIAL
		KarmanyTrainerData.AutomationStatus.EXECUTABLE:
			return KarmanyTrainerAbilityRuntimeService.STATUS_FULLY
	return KarmanyTrainerAbilityRuntimeService.STATUS_PENDING


func _load_trainers() -> Array[KarmanyTrainerData]:
	var result: Array[KarmanyTrainerData] = []
	var dir := DirAccess.open(TRAINER_DIR)
	if dir == null:
		return result
	var names := dir.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var trainer := load("%s/%s" % [TRAINER_DIR, file_name]) as KarmanyTrainerData
		if trainer != null:
			result.append(trainer)
	return result


func _fail(message: String) -> bool:
	push_error("FASE 44.7 TEST ERROR: %s" % message)
	return false
