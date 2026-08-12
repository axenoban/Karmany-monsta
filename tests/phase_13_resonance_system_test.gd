extends Node


const R01: KarmanyResonanceData = preload("res://data/resonances/r_01_impulso_luminico.tres")
const R03: KarmanyResonanceData = preload("res://data/resonances/r_03_corte_de_bruma.tres")
const R04: KarmanyResonanceData = preload("res://data/resonances/r_04_embate_de_raiz.tres")
const R13: KarmanyResonanceData = preload("res://data/resonances/r_13_defensa_instintiva.tres")
const R22: KarmanyResonanceData = preload("res://data/resonances/r_22_mirada_del_sendero.tres")
const R37: KarmanyResonanceData = preload("res://data/resonances/r_37_instinto_de_caza.tres")
const EQ08: KarmanyEquipmentData = preload("res://data/equipment/eq_08_prisma_ancestral.tres")


var _activated_conditions: Array[StringName] = []


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 13 RESONANCE TEST")
	print("================================")

	var test_passed: bool = true
	test_passed = _test_definitions_and_enum_compatibility() and test_passed
	test_passed = _test_deck_hand_limit_and_recycle() and test_passed
	test_passed = _test_combat_limit_power_and_equipment_trigger() and test_passed
	test_passed = _test_effect_bridge_draw_and_chosen_discard() and test_passed
	test_passed = _test_post_combat_effects() and test_passed
	test_passed = _test_exploration_resonance() and test_passed

	print("")
	print("================================")
	if test_passed:
		print("FASE 13 OK - Resonancias, mano, mazo, uso, descarte y efectos validados.")
	else:
		push_error("FASE 13 ERROR - Revisar sistema de Resonancias.")
	print("================================")


func _test_definitions_and_enum_compatibility() -> bool:
	var ok: bool = true

	for resonance in [R01, R03, R04, R13, R22, R37]:
		ok = _expect(
			resonance.is_valid_definition(),
			"Definicion invalida: %s" % resonance.display_name
		) and ok

	ok = _expect(
		KarmanyEffectData.EffectType.ADD_RESOURCE == 1,
		"ADD_RESOURCE debe conservar valor serializado 1."
	) and ok
	ok = _expect(
		KarmanyEffectData.EffectType.TRIGGER_ENCOUNTER == 6,
		"TRIGGER_ENCOUNTER debe conservar valor serializado 6."
	) and ok
	ok = _expect(
		KarmanyEffectData.EffectType.DISCARD_CARDS == 7,
		"DISCARD_CARDS debe agregarse al final del enum."
	) and ok

	ok = _expect(
		R04.get_power_bonus(PackedStringArray(["target_beast"])) == 5,
		"R-04 debe dar +3 base y +2 contra Bestia."
	) and ok
	ok = _expect(
		R04.get_power_bonus(PackedStringArray()) == 3,
		"R-04 fuera de Bestia debe conservar +3."
	) and ok
	ok = _expect(
		R37.get_power_bonus(PackedStringArray(["target_beast"])) == 2,
		"R-37 debe dar +2 contra Bestia aunque su valor impreso sea +0."
	) and ok

	print("ResonanceData + compatibilidad EffectType: ", "OK" if ok else "ERROR")
	return ok


func _test_deck_hand_limit_and_recycle() -> bool:
	var player := _new_player()
	var deck := KarmanyResonanceDeck.new()
	var ok: bool = _expect(
		deck.setup(_standard_deck(), false, 1301),
		"No se pudo preparar el mazo de Resonancias."
	)

	ok = _expect(
		deck.deal_initial_hand(player),
		"La mano inicial debe robar exactamente 5 Resonancias."
	) and ok
	ok = _expect(player.get_resonance_count() == 5, "La mano inicial debe tener 5 cartas.") and ok
	ok = _expect(deck.get_draw_count() == 1, "Tras la mano inicial debe quedar 1 carta en este fixture.") and ok
	ok = _expect(player.resonance_hand.get_hand_limit() == 5, "El limite base de mano debe ser 5.") and ok

	ok = _expect(
		deck.draw_to_hand(player.resonance_hand, 1) == 1,
		"El robo puede superar temporalmente el limite de mano."
	) and ok
	ok = _expect(player.get_resonance_count() == 6, "La mano debe poder quedar temporalmente en 6.") and ok
	ok = _expect(
		player.request_end_turn_resonance_discard() == 1,
		"Al final del turno debe solicitarse 1 descarte por exceso."
	) and ok
	ok = _expect(
		player.resonance_hand.get_pending_discard_count() == 1,
		"Debe existir una obligacion de descarte elegible."
	) and ok

	var discard_ids: Array[StringName] = []
	discard_ids.append(&"R-37")
	ok = _expect(
		player.resonance_hand.resolve_pending_discard(discard_ids, deck),
		"El jugador debe poder elegir R-37 para el descarte pendiente."
	) and ok
	ok = _expect(player.get_resonance_count() == 5, "Tras descartar debe volver a 5.") and ok
	ok = _expect(deck.get_discard_count() == 1, "R-37 debe estar en el descarte comun.") and ok

	ok = _expect(
		deck.draw_to_hand(player.resonance_hand, 1) == 1,
		"Con mazo agotado debe reciclarse el descarte."
	) and ok
	ok = _expect(player.resonance_hand.has_card_id(&"R-37"), "R-37 debe poder volver desde el descarte reciclado.") and ok
	ok = _expect(deck.get_discard_count() == 0, "El descarte reciclado debe vaciarse.") and ok

	print("Mano 5 + exceso elegido + reciclaje de descarte: ", "OK" if ok else "ERROR")
	return ok


func _test_combat_limit_power_and_equipment_trigger() -> bool:
	var player := _new_player()
	var deck := KarmanyResonanceDeck.new()
	var ok: bool = _expect(deck.setup(_standard_deck(), false, 1302), "Mazo de combate invalido.")
	ok = _expect(player.resonance_hand.add_card(R04), "Falta R-04 en mano.") and ok
	ok = _expect(player.resonance_hand.add_card(R01), "Falta R-01 en mano.") and ok
	ok = _expect(player.add_equipment(EQ08), "No se pudo equipar EQ-08 para el trigger.") and ok

	var tracker := KarmanyResonanceUsageTracker.new()
	var modifiers := KarmanyCombatPowerModifiers.new()
	var context := KarmanyResonanceUseContext.new()
	context.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	context.combat_id = &"phase13_combat_1"
	context.context_tags = PackedStringArray(["target_beast"])
	context.combat_modifiers = modifiers
	context.usage_tracker = tracker

	var play := KarmanyResonanceResolver.play_from_hand(
		player,
		&"R-04",
		deck,
		context
	)
	ok = _expect(play.is_success(), "R-04 debe jugarse en combate.") and ok
	ok = _expect(play.power_applied == 5, "R-04 debe aplicar +5 contra Bestia.") and ok
	ok = _expect(modifiers.resonance_power == 5, "CombatPowerModifiers debe registrar +5 de Resonancia.") and ok
	ok = _expect(play.held_until_combat_end, "R-04 debe esperar al fin del combate antes de descartarse.") and ok
	ok = _expect(deck.get_discard_count() == 0, "La Resonancia de combate no debe descartarse antes del cierre.") and ok
	ok = _expect(play.trigger_ids.has("resonance_played"), "Debe emitirse trigger resonance_played.") and ok

	var equipment_bonus := KarmanyEquipmentCombatRules.get_power_bonus(
		player.equipment_inventory,
		KarmanyCombatRequest.TargetType.BEAST,
		play.trigger_ids
	)
	ok = _expect(equipment_bonus == 2, "EQ-08 debe reconocer resonance_played y aportar +2.") and ok

	var second := KarmanyResonanceResolver.play_from_hand(
		player,
		&"R-01",
		deck,
		context
	)
	ok = _expect(
		second.status == KarmanyResonancePlayResult.Status.COMBAT_LIMIT_REACHED,
		"No debe permitirse una segunda Resonancia del mismo jugador en el combate."
	) and ok
	ok = _expect(player.resonance_hand.has_card_id(&"R-01"), "La Resonancia rechazada debe permanecer en mano.") and ok

	ok = _expect(
		KarmanyResonanceResolver.finish_combat(
			&"phase13_combat_1",
			tracker,
			deck
		) == 1,
		"Al cerrar el combate debe descartarse exactamente R-04."
	) and ok
	ok = _expect(deck.get_discard_count() == 1, "El descarte debe contener la Resonancia usada.") and ok

	print("1 Resonancia/combate + Poder + trigger de Equipo: ", "OK" if ok else "ERROR")
	return ok


func _test_effect_bridge_draw_and_chosen_discard() -> bool:
	var player := _new_player()
	var deck := KarmanyResonanceDeck.new()
	var draw_cards: Array[KarmanyResonanceData] = []
	draw_cards.append(R37)
	draw_cards.append(R01)
	var ok: bool = _expect(deck.setup(draw_cards, false, 1303), "Mazo para R-03 invalido.")
	ok = _expect(player.resonance_hand.add_card(R03), "Falta R-03 en mano.") and ok

	var effect_context := KarmanyEffectContext.new()
	var adapter := KarmanyResonanceEffectAdapter.new()
	ok = _expect(adapter.setup(deck), "No se pudo preparar adaptador de Resonancias.") and ok
	ok = _expect(adapter.configure_context(effect_context), "No se pudo conectar EffectContext.") and ok

	var tracker := KarmanyResonanceUsageTracker.new()
	var use_context := KarmanyResonanceUseContext.new()
	use_context.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	use_context.combat_id = &"phase13_combat_draw"
	use_context.context_tags = PackedStringArray([
		"tile_revealed_or_explored_this_turn"
	])
	use_context.combat_modifiers = KarmanyCombatPowerModifiers.new()
	use_context.effect_context = effect_context
	use_context.usage_tracker = tracker

	var play := KarmanyResonanceResolver.play_from_hand(
		player,
		&"R-03",
		deck,
		use_context
	)
	ok = _expect(play.is_success(), "R-03 debe resolverse con el adaptador.") and ok
	ok = _expect(play.effect_results.size() == 2, "R-03 debe resolver robo y solicitud de descarte.") and ok
	ok = _expect(player.get_resonance_count() == 2, "R-03 debe robar 2 Resonancias tras salir de la mano.") and ok
	ok = _expect(player.resonance_hand.get_pending_discard_count() == 1, "R-03 debe exigir elegir 1 descarte.") and ok

	var chosen: Array[StringName] = []
	chosen.append(&"R-37")
	ok = _expect(
		player.resonance_hand.resolve_pending_discard(chosen, deck),
		"El descarte de R-03 debe resolverse mediante eleccion explicita."
	) and ok
	ok = _expect(player.get_resonance_count() == 1, "Tras elegir descarte debe quedar 1 carta robada.") and ok
	ok = _expect(deck.get_discard_count() == 1, "R-37 debe estar en descarte antes del cierre del combate.") and ok

	ok = _expect(
		KarmanyResonanceResolver.finish_combat(
			&"phase13_combat_draw",
			tracker,
			deck
		) == 1,
		"R-03 debe descartarse al terminar el combate."
	) and ok
	ok = _expect(deck.get_discard_count() == 2, "El descarte debe contener R-37 y R-03.") and ok

	print("EffectResolver DRAW/DISCARD + eleccion de descarte: ", "OK" if ok else "ERROR")
	return ok


func _test_post_combat_effects() -> bool:
	var player := _new_player()
	var ok: bool = player.resonance_hand.add_card(R01)
	var deck := KarmanyResonanceDeck.new()
	ok = _expect(deck.setup(_standard_deck(), false, 1304), "Mazo post-combate invalido.") and ok

	var tracker := KarmanyResonanceUsageTracker.new()
	var use_context := KarmanyResonanceUseContext.new()
	use_context.window_id = KarmanyResonanceUseContext.WINDOW_COMBAT
	use_context.combat_id = &"phase13_combat_win"
	use_context.combat_modifiers = KarmanyCombatPowerModifiers.new()
	use_context.usage_tracker = tracker

	var play := KarmanyResonanceResolver.play_from_hand(
		player,
		&"R-01",
		deck,
		use_context
	)
	ok = _expect(play.is_success(), "R-01 debe jugarse.") and ok
	ok = _expect(play.power_applied == 4, "R-01 debe aportar +4 Poder.") and ok

	var ek_before: int = player.ek
	var post_results := KarmanyResonanceResolver.resolve_effects(
		R01,
		player,
		&"after_combat",
		PackedStringArray(["combat_won"])
	)
	ok = _expect(post_results.size() == 1, "R-01 debe tener un efecto tras victoria.") and ok
	ok = _expect(player.ek == ek_before + 2, "R-01 debe recuperar 2 EK al ganar.") and ok

	_activated_conditions.clear()
	var condition_context := KarmanyEffectContext.new()
	condition_context.activate_condition_handler = Callable(
		self,
		"_condition_handler"
	)
	var r13_results := KarmanyResonanceResolver.resolve_effects(
		R13,
		player,
		&"after_combat",
		PackedStringArray(["combat_lost"]),
		condition_context
	)
	ok = _expect(r13_results.size() == 1, "R-13 debe resolver su efecto tras derrota.") and ok
	ok = _expect(
		_activated_conditions.has(&"prevent_retreat_on_combat_loss"),
		"R-13 debe delegar la prevencion de retroceso al EffectContext."
	) and ok

	print("Efectos post-combate data-driven: ", "OK" if ok else "ERROR")
	return ok


func _test_exploration_resonance() -> bool:
	var player := _new_player()
	var deck := KarmanyResonanceDeck.new()
	var draw_cards: Array[KarmanyResonanceData] = []
	draw_cards.append(R37)
	var ok: bool = _expect(deck.setup(draw_cards, false, 1305), "Mazo de exploracion invalido.")
	ok = _expect(player.resonance_hand.add_card(R22), "Falta R-22 en mano.") and ok

	_activated_conditions.clear()
	var effect_context := KarmanyEffectContext.new()
	var adapter := KarmanyResonanceEffectAdapter.new()
	ok = _expect(adapter.setup(deck), "Adaptador R-22 invalido.") and ok
	ok = _expect(adapter.configure_context(effect_context), "No se conecto el adaptador R-22.") and ok
	effect_context.activate_condition_handler = Callable(
		self,
		"_condition_handler"
	)

	var use_context := KarmanyResonanceUseContext.new()
	use_context.window_id = KarmanyResonanceUseContext.WINDOW_EXPLORATION
	use_context.effect_context = effect_context

	var play := KarmanyResonanceResolver.play_from_hand(
		player,
		&"R-22",
		deck,
		use_context
	)
	ok = _expect(play.is_success(), "R-22 debe poder jugarse en Exploracion.") and ok
	ok = _expect(play.discarded_immediately, "R-22 fuera de combate debe descartarse tras resolver.") and ok
	ok = _expect(
		_activated_conditions.has(&"peek_hidden_adjacent_tile"),
		"R-22 debe delegar la accion de mirar una loseta."
	) and ok
	ok = _expect(player.get_resonance_count() == 1, "R-22 debe robar 1 Resonancia.") and ok
	ok = _expect(player.resonance_hand.get_pending_discard_count() == 1, "R-22 debe exigir descartar 1 de eleccion.") and ok

	var invalid_context := KarmanyResonanceUseContext.new()
	invalid_context.window_id = KarmanyResonanceUseContext.WINDOW_MOVEMENT
	var invalid := KarmanyResonanceResolver.play_from_hand(
		player,
		&"R-37",
		deck,
		invalid_context
	)
	ok = _expect(
		invalid.status == KarmanyResonancePlayResult.Status.WINDOW_NOT_ALLOWED,
		"Una Resonancia de combate no debe jugarse como Movimiento."
	) and ok

	var chosen: Array[StringName] = []
	chosen.append(&"R-37")
	ok = _expect(
		player.resonance_hand.resolve_pending_discard(chosen, deck),
		"Debe poder resolverse el descarte elegido de R-22."
	) and ok

	print("Uso fuera de combate + ventana legal + descarte: ", "OK" if ok else "ERROR")
	return ok


func _standard_deck() -> Array[KarmanyResonanceData]:
	var result: Array[KarmanyResonanceData] = []
	result.append(R01)
	result.append(R03)
	result.append(R04)
	result.append(R13)
	result.append(R22)
	result.append(R37)
	return result


func _new_player() -> KarmanyPlayerState:
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_1", Vector2i.ZERO)
	return player


func _condition_handler(
	condition_id: StringName,
	_player: KarmanyPlayerState
) -> bool:
	_activated_conditions.append(condition_id)
	return true


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 13 ERROR: %s" % message)
	return false
