extends Node


var _draw_log: Array[Dictionary] = []
var _runtime_states: Dictionary = {}
var _activated_conditions: Array[StringName] = []
var _encounter_log: Array[StringName] = []


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 7 EFFECT ENGINE TEST")
	print("================================")

	var test_passed: bool = true
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_effect_test")

	var context := KarmanyEffectContext.new()
	context.draw_cards_handler = Callable(self, "_handle_draw_cards")
	context.modify_state_handler = Callable(self, "_handle_modify_state")
	context.activate_condition_handler = Callable(self, "_handle_activate_condition")
	context.trigger_encounter_handler = Callable(self, "_handle_trigger_encounter")

	# Compatibilidad con Fases 1-6: la firma antigua sin contexto sigue funcionando.
	var add_mn := _make_effect(
		KarmanyEffectData.EffectType.ADD_RESOURCE,
		3
	)
	add_mn.resource_type = KarmanyEffectData.ResourceType.MN

	var add_result := KarmanyEffectResolver.apply_effect(
		add_mn,
		player
	)

	if not _expect(add_result.was_applied(), "ADD_RESOURCE no fue aplicado."):
		test_passed = false
	if not _expect(player.mn == 5, "ADD_RESOURCE debia llevar MN 2 -> 5."):
		test_passed = false
	if not _expect(add_result.amount_applied == 3, "ADD_RESOURCE reporto cantidad incorrecta."):
		test_passed = false

	# Perder recursos nunca deja el contador por debajo de cero.
	var remove_mr := _make_effect(
		KarmanyEffectData.EffectType.REMOVE_RESOURCE,
		5
	)
	remove_mr.resource_type = KarmanyEffectData.ResourceType.MR

	var remove_result := KarmanyEffectResolver.apply_effect(
		remove_mr,
		player
	)

	if not _expect(remove_result.was_applied(), "REMOVE_RESOURCE no fue aplicado."):
		test_passed = false
	if not _expect(player.mr == 0, "REMOVE_RESOURCE debia limitar MR a cero."):
		test_passed = false
	if not _expect(remove_result.amount_applied == 1, "REMOVE_RESOURCE debia reportar solo 1 MR perdido."):
		test_passed = false

	# Robo delegado: Phase 7 despacha; la implementacion del mazo vendra en su fase.
	var draw_resonance := _make_effect(
		KarmanyEffectData.EffectType.DRAW_CARDS,
		2
	)
	draw_resonance.card_source_id = &"resonance"

	var draw_result := KarmanyEffectResolver.apply_effect(
		draw_resonance,
		player,
		context
	)

	if not _expect(draw_result.was_applied(), "DRAW_CARDS no fue despachado."):
		test_passed = false
	if not _expect(_draw_log.size() == 1, "DRAW_CARDS no llego al adaptador."):
		test_passed = false
	elif not _expect(int(_draw_log[0]["amount"]) == 2, "DRAW_CARDS envio cantidad incorrecta."):
		test_passed = false
	elif not _expect(StringName(_draw_log[0]["source_id"]) == &"resonance", "DRAW_CARDS envio fuente incorrecta."):
		test_passed = false

	# Estados genericos mediante adaptador, sin acoplar PlayerState a sistemas futuros.
	var add_state := _make_effect(
		KarmanyEffectData.EffectType.MODIFY_STATE,
		2
	)
	add_state.state_id = &"power_bonus"
	add_state.state_operation = KarmanyEffectData.StateOperation.ADD

	var set_state := _make_effect(
		KarmanyEffectData.EffectType.MODIFY_STATE,
		7
	)
	set_state.state_id = &"power_bonus"
	set_state.state_operation = KarmanyEffectData.StateOperation.SET

	var remove_state := _make_effect(
		KarmanyEffectData.EffectType.MODIFY_STATE,
		3
	)
	remove_state.state_id = &"power_bonus"
	remove_state.state_operation = KarmanyEffectData.StateOperation.REMOVE

	if not KarmanyEffectResolver.apply_effect(add_state, player, context).was_applied():
		test_passed = _fail("MODIFY_STATE ADD fue rechazado.")
	if not _expect(int(_runtime_states.get(&"power_bonus", 0)) == 2, "MODIFY_STATE ADD no produjo 2."):
		test_passed = false

	if not KarmanyEffectResolver.apply_effect(set_state, player, context).was_applied():
		test_passed = _fail("MODIFY_STATE SET fue rechazado.")
	if not _expect(int(_runtime_states.get(&"power_bonus", 0)) == 7, "MODIFY_STATE SET no produjo 7."):
		test_passed = false

	if not KarmanyEffectResolver.apply_effect(remove_state, player, context).was_applied():
		test_passed = _fail("MODIFY_STATE REMOVE fue rechazado.")
	if not _expect(int(_runtime_states.get(&"power_bonus", 0)) == 4, "MODIFY_STATE REMOVE no produjo 4."):
		test_passed = false

	# Condiciones y encuentros se despachan sin implementar aun sus subsistemas finales.
	var condition_effect := _make_effect(
		KarmanyEffectData.EffectType.ACTIVATE_CONDITION,
		0
	)
	condition_effect.condition_id = &"legacy_trigger_ready"

	var condition_result := KarmanyEffectResolver.apply_effect(
		condition_effect,
		player,
		context
	)

	if not _expect(condition_result.was_applied(), "ACTIVATE_CONDITION fue rechazado."):
		test_passed = false
	if not _expect(_activated_conditions.has(&"legacy_trigger_ready"), "La condicion no llego al adaptador."):
		test_passed = false

	var encounter_effect := _make_effect(
		KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER,
		0
	)
	encounter_effect.encounter_id = &"beast_basic"

	var encounter_result := KarmanyEffectResolver.apply_effect(
		encounter_effect,
		player,
		context
	)

	if not _expect(encounter_result.was_applied(), "TRIGGER_ENCOUNTER fue rechazado."):
		test_passed = false
	if not _expect(_encounter_log.has(&"beast_basic"), "El encuentro no llego al adaptador."):
		test_passed = false

	# Batch data-driven: una loseta puede entregar un array y el resolver ejecuta en orden.
	var entry_mn := _make_effect(
		KarmanyEffectData.EffectType.ADD_RESOURCE,
		1
	)
	entry_mn.resource_type = KarmanyEffectData.ResourceType.MN

	var entry_ek := _make_effect(
		KarmanyEffectData.EffectType.ADD_RESOURCE,
		2
	)
	entry_ek.resource_type = KarmanyEffectData.ResourceType.EK

	var tile := KarmanyTileData.new()
	var entry_effects: Array[KarmanyEffectData] = [
		entry_mn,
		entry_ek
	]
	tile.entry_effects = entry_effects

	var batch_results := KarmanyEffectResolver.apply_effects(
		tile.entry_effects,
		player,
		context
	)

	if not _expect(batch_results.size() == 2, "apply_effects no devolvio dos resultados."):
		test_passed = false
	if not _expect(KarmanyEffectResolver.count_applied(batch_results) == 2, "count_applied debia devolver 2."):
		test_passed = false
	if not _expect(player.mn == 6, "Batch de Entrada debia dejar MN=6."):
		test_passed = false
	if not _expect(player.ek == 3, "Batch de Entrada debia dejar EK=3."):
		test_passed = false

	# Fallos controlados: un dominio futuro sin contexto/handler no debe crashear.
	var missing_context_result := KarmanyEffectResolver.apply_effect(
		draw_resonance,
		player
	)
	if not _expect(
		missing_context_result.status == KarmanyEffectResult.Status.MISSING_CONTEXT,
		"DRAW_CARDS sin contexto debia devolver MISSING_CONTEXT."
	):
		test_passed = false

	var empty_context := KarmanyEffectContext.new()
	var missing_handler_result := KarmanyEffectResolver.apply_effect(
		draw_resonance,
		player,
		empty_context
	)
	if not _expect(
		missing_handler_result.status == KarmanyEffectResult.Status.MISSING_HANDLER,
		"DRAW_CARDS sin adaptador debia devolver MISSING_HANDLER."
	):
		test_passed = false

	var rejecting_context := KarmanyEffectContext.new()
	rejecting_context.draw_cards_handler = Callable(self, "_reject_draw_cards")
	var rejected_result := KarmanyEffectResolver.apply_effect(
		draw_resonance,
		player,
		rejecting_context
	)
	if not _expect(
		rejected_result.status == KarmanyEffectResult.Status.FAILED,
		"Un adaptador que devuelve false debia producir FAILED."
	):
		test_passed = false

	var invalid_add := _make_effect(
		KarmanyEffectData.EffectType.ADD_RESOURCE,
		0
	)
	var invalid_result := KarmanyEffectResolver.apply_effect(
		invalid_add,
		player
	)
	if not _expect(
		invalid_result.status == KarmanyEffectResult.Status.INVALID_EFFECT,
		"Cantidad cero debia ser INVALID_EFFECT."
	):
		test_passed = false

	var none_effect := _make_effect(
		KarmanyEffectData.EffectType.NONE,
		0
	)
	var none_result := KarmanyEffectResolver.apply_effect(
		none_effect,
		player
	)
	if not _expect(
		none_result.status == KarmanyEffectResult.Status.NO_OP,
		"NONE debia devolver NO_OP."
	):
		test_passed = false

	print("")
	print("Recursos directos: OK")
	print("Robo delegado: ", _draw_log)
	print("Estado power_bonus: ", _runtime_states.get(&"power_bonus", 0))
	print("Condiciones activadas: ", _activated_conditions)
	print("Encuentros solicitados: ", _encounter_log)
	print("Batch de Resource: ", KarmanyEffectResolver.count_applied(batch_results), "/", batch_results.size())
	print("")
	print("================================")

	if test_passed:
		print("FASE 7 OK - Motor de efectos data-driven validado.")
	else:
		push_error("FASE 7 ERROR - Revisar motor de efectos.")

	print("================================")


func _make_effect(
	effect_type: int,
	amount: int
) -> KarmanyEffectData:
	var effect := KarmanyEffectData.new()
	effect.effect_type = effect_type
	effect.amount = amount
	return effect


func _handle_draw_cards(
	source_id: StringName,
	amount: int,
	player: KarmanyPlayerState
) -> bool:
	_draw_log.append({
		"source_id": source_id,
		"amount": amount,
		"player_id": player.player_id
	})
	return true


func _handle_modify_state(
	state_id: StringName,
	operation: int,
	amount: int,
	_player: KarmanyPlayerState
) -> bool:
	var current_value: int = int(
		_runtime_states.get(
			state_id,
			0
		)
	)

	match operation:
		KarmanyEffectData.StateOperation.ADD:
			current_value += amount
		KarmanyEffectData.StateOperation.SET:
			current_value = amount
		KarmanyEffectData.StateOperation.REMOVE:
			current_value = maxi(
				0,
				current_value - amount
			)
		_:
			return false

	_runtime_states[state_id] = current_value
	return true


func _handle_activate_condition(
	condition_id: StringName,
	_player: KarmanyPlayerState
) -> bool:
	_activated_conditions.append(condition_id)
	return true


func _handle_trigger_encounter(
	encounter_id: StringName,
	_player: KarmanyPlayerState
) -> bool:
	_encounter_log.append(encounter_id)
	return true


func _reject_draw_cards(
	_source_id: StringName,
	_amount: int,
	_player: KarmanyPlayerState
) -> bool:
	return false


func _expect(
	condition: bool,
	message: String
) -> bool:
	if condition:
		return true

	push_error("FASE 7 ERROR: %s" % message)
	return false


func _fail(message: String) -> bool:
	push_error("FASE 7 ERROR: %s" % message)
	return false
