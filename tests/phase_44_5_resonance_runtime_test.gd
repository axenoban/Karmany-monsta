extends Node


const PENDING_DIR := "res://data/resonances/canonical_pending"


func _ready() -> void:
	print("")
	print("========================================")
	print("KARMANY MONSTA - FASE 44.5 RESONANCIAS")
	print("========================================")
	var ok := _test_contract_coverage()
	ok = _test_pending_runtime_exclusion() and ok
	ok = _test_canonical_runtime_hooks() and ok
	print("")
	print("========================================")
	if ok:
		print("FASE 44.5 OK - 40/40 Resonancias con contrato runtime explicito; 6 FULLY_EXECUTABLE y 34 PARTIAL sin promociones falsas.")
	else:
		push_error("FASE 44.5 ERROR - revisar el primer fallo real.")
	print("========================================")


func _test_contract_coverage() -> bool:
	var all_resonances := _load_dir("res://data/resonances")
	all_resonances.append_array(_load_dir(PENDING_DIR))
	if all_resonances.size() != 40:
		return _fail("Se esperaban 40 Resonancias y se cargaron %d." % all_resonances.size())
	for data in all_resonances:
		if data == null or not KarmanyResonanceAbilityRuntimeService.has_contract(data.resonance_id):
			return _fail("Resonancia sin contrato F44.5: %s." % String(data.resonance_id if data != null else &"NULL"))
		var contract := KarmanyResonanceAbilityRuntimeService.get_contract(data.resonance_id)
		var status := StringName(contract.get("status", &"PENDING"))
		if status == KarmanyResonanceAbilityRuntimeService.STATUS_PENDING or status == KarmanyResonanceAbilityRuntimeService.STATUS_DATA_ONLY:
			return _fail("%s conserva estado no resuelto %s." % [String(data.resonance_id), String(status)])
		if status == KarmanyResonanceAbilityRuntimeService.STATUS_PARTIAL and String(contract.get("reason", "")).is_empty():
			return _fail("%s es PARTIAL sin motivo explicito." % String(data.resonance_id))
	var counts := KarmanyResonanceAbilityRuntimeService.get_contract_counts()
	if int(counts.get(KarmanyResonanceAbilityRuntimeService.STATUS_FULLY, 0)) != 6:
		return _fail("Se esperaban 6 contratos FULLY_EXECUTABLE: %s." % str(counts))
	if int(counts.get(KarmanyResonanceAbilityRuntimeService.STATUS_PARTIAL, 0)) != 34:
		return _fail("Se esperaban 34 contratos PARTIAL: %s." % str(counts))
	print("F44.5 CONTRACTS | 40/40 | FULLY=6 PARTIAL=34 DATA_ONLY=0 PENDING=0")
	return true


func _test_pending_runtime_exclusion() -> bool:
	var direct := _load_dir("res://data/resonances")
	if direct.size() != 13:
		return _fail("El runtime directo debe conservar exactamente 13 Resonancias durante F44.5.")
	var pending := _load_dir(PENDING_DIR)
	if pending.size() != 27:
		return _fail("Se esperaban 27 Resonancias materializadas aisladas.")
	for data in pending:
		if not data.tags.has("pending_f44"):
			return _fail("%s no conserva el marcador canonical_pending." % String(data.resonance_id))
		if not KarmanyResonanceAbilityRuntimeService.is_runtime_excluded(data.resonance_id):
			return _fail("%s fue promovida al runtime sin estructurar su regla." % String(data.resonance_id))

	var r10 := load("res://data/resonances/canonical_pending/r_10_pulso_de_batalla.tres") as KarmanyResonanceData
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"f44_5_pending", Vector2i.ZERO)
	if not player.resonance_hand.add_card(r10):
		return _fail("No se pudo preparar R-10 para probar exclusion del resolver.")
	var deck := _new_deck(4451)
	if deck == null:
		return _fail("No se pudo preparar mazo para exclusion F44.5.")
	var context := _combat_context(&"f44_5_pending_combat", PackedStringArray(["combat", "pvp"]))
	var play := KarmanyResonanceResolver.play_from_hand(player, &"R-10", deck, context)
	if play.status != KarmanyResonancePlayResult.Status.WINDOW_NOT_ALLOWED:
		return _fail("R-10 canonical_pending no fue bloqueada por ResonanceResolver.")
	if not player.resonance_hand.has_card_id(&"R-10"):
		return _fail("R-10 excluida fue retirada incorrectamente de la mano.")
	print("F44.5 EXCLUSION | 27 canonical_pending bloqueadas por ResonanceResolver; 13 Resonancias directas auditadas.")
	return true


func _test_canonical_runtime_hooks() -> bool:
	var r01 := load("res://data/resonances/r_01_impulso_luminico.tres") as KarmanyResonanceData
	var r04 := load("res://data/resonances/r_04_embate_de_raiz.tres") as KarmanyResonanceData
	var r08 := load("res://data/resonances/r_08_resonancia_creciente.tres") as KarmanyResonanceData
	var r09 := load("res://data/resonances/r_09_ruptura_runica.tres") as KarmanyResonanceData
	var r20 := load("res://data/resonances/r_20_ultima_defensa.tres") as KarmanyResonanceData
	var r37 := load("res://data/resonances/r_37_instinto_de_caza.tres") as KarmanyResonanceData
	if r01 == null or r04 == null or r08 == null or r09 == null or r20 == null or r37 == null:
		return _fail("No se pudieron cargar Resonancias directas de prueba.")

	var stable := KarmanyData.new()
	stable.primary_type = KarmanyData.StrategicType.STABLE
	var stable_tags := KarmanyResonanceAbilityRuntimeService.enrich_combat_context_tags(
		PackedStringArray(["combat"]), stable
	)
	if r08.get_power_bonus(stable_tags) != 5:
		return _fail("R-08 no aplica +3 base +2 adicional con Karmany Estable.")
	var wild := KarmanyData.new()
	wild.primary_type = KarmanyData.StrategicType.WILD
	var wild_tags := KarmanyResonanceAbilityRuntimeService.enrich_combat_context_tags(
		PackedStringArray(["combat"]), wild
	)
	if r08.get_power_bonus(wild_tags) != 3:
		return _fail("R-08 aplica el bono Estable a un Karmany no Estable.")

	if not KarmanyResonanceAbilityRuntimeService.validate_play_context(
		r37, PackedStringArray(["combat", "pvp"])
	).contains("solo puede"):
		return _fail("R-37 no rechaza un combate que no sea contra Bestia.")
	if not KarmanyResonanceAbilityRuntimeService.validate_play_context(
		r37, PackedStringArray(["combat", "target_beast"])
	).is_empty():
		return _fail("R-37 rechaza incorrectamente un combate contra Bestia.")
	if r37.get_power_bonus(PackedStringArray(["combat", "target_beast"])) != 2:
		return _fail("R-37 no aplica +2 Poder contra Bestia.")

	if r04.get_power_bonus(PackedStringArray(["combat", "target_beast"])) != 5:
		return _fail("R-04 no aplica +3 base +2 contra Bestia.")
	if r04.get_power_bonus(PackedStringArray(["combat", "pvp"])) != 3:
		return _fail("R-04 no conserva +3 fuera de combate contra Bestia.")
	if r01.get_matching_effect_blocks(&"after_combat", PackedStringArray(["combat_won"])).size() != 1:
		return _fail("R-01 no conserva recompensa post-victoria estructurada.")
	if r09.get_matching_effect_blocks(&"after_combat", PackedStringArray(["combat_won", "target_beast"])).size() != 1:
		return _fail("R-09 no conserva +2 MR post-victoria contra Bestia.")
	if r20.get_matching_effect_blocks(&"after_combat", PackedStringArray(["combat_lost"])).size() != 1:
		return _fail("R-20 no conserva robo/descarte tras derrota.")

	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"f44_5_r37", Vector2i.ZERO)
	if not player.resonance_hand.add_card(r37):
		return _fail("No se pudo preparar R-37 para prueba del resolver.")
	var deck := _new_deck(4452)
	if deck == null:
		return _fail("No se pudo preparar mazo para R-37.")
	var invalid_context := _combat_context(&"f44_5_r37_invalid", PackedStringArray(["combat", "pvp"]))
	var invalid_play := KarmanyResonanceResolver.play_from_hand(player, &"R-37", deck, invalid_context)
	if invalid_play.status != KarmanyResonancePlayResult.Status.WINDOW_NOT_ALLOWED:
		return _fail("ResonanceResolver permite R-37 fuera de combate contra Bestia.")
	var valid_context := _combat_context(&"f44_5_r37_valid", PackedStringArray(["combat", "target_beast"]))
	var valid_play := KarmanyResonanceResolver.play_from_hand(player, &"R-37", deck, valid_context)
	if not valid_play.is_success() or valid_play.power_applied != 2:
		return _fail("ResonanceResolver no ejecuta R-37 con +2 contra Bestia.")
	KarmanyResonanceResolver.finish_combat(valid_context.combat_id, valid_context.usage_tracker, deck)
	print("F44.5 HOOKS | R-08 aplica +2 Estable; R-37 solo Bestia; R-01/R-04/R-09/R-20 conservan efectos data-driven.")
	return true


func _combat_context(combat_id: StringName, tags: PackedStringArray) -> KarmanyResonanceUseContext:
	var context := KarmanyResonanceUseContext.new()
	context.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	context.context_tags = tags
	context.combat_id = combat_id
	context.combat_modifiers = KarmanyCombatPowerModifiers.new()
	context.usage_tracker = KarmanyResonanceUsageTracker.new()
	return context


func _new_deck(seed_value: int) -> KarmanyResonanceDeck:
	var r01 := load("res://data/resonances/r_01_impulso_luminico.tres") as KarmanyResonanceData
	var cards: Array[KarmanyResonanceData] = []
	cards.append(r01)
	var deck := KarmanyResonanceDeck.new()
	if not deck.setup(cards, false, seed_value):
		return null
	return deck


func _load_dir(path: String) -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	var names := directory.get_files()
	names.sort()
	for file_name in names:
		if not file_name.ends_with(".tres"):
			continue
		var data := ResourceLoader.load("%s/%s" % [path, file_name]) as KarmanyResonanceData
		if data != null:
			result.append(data)
	return result


func _fail(message: String) -> bool:
	push_error("F44.5: %s" % message)
	return false
