extends Node


const HUD_SCENE: PackedScene = preload(
	"res://scenes/ui/resource_debug_hud.tscn"
)


var _resource_change_count: int = 0


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 8 RESOURCE TEST")
	print("================================")

	var test_passed: bool = true
	var player := KarmanyPlayerState.new()
	player.setup_new_game(&"player_resource_test")

	var inventory := player.resource_inventory

	inventory.resource_changed.connect(
		_on_resource_changed
	)

	if not _expect(inventory != null, "No existe ResourceInventory."):
		test_passed = false

	if not _expect(
		player.mn == 2
		and player.mr == 1
		and player.ek == 1
		and player.fa == 0,
		"Los recursos iniciales no son 2 MN, 1 MR, 1 EK, 0 FA."
	):
		test_passed = false

	# Compatibilidad: las propiedades antiguas siguen delegando al inventario.
	player.mn = 4
	if not _expect(
		inventory.get_resource(KarmanyEffectData.ResourceType.MN) == 4,
		"player.mn no esta sincronizado con ResourceInventory."
	):
		test_passed = false

	player.setup_new_game(&"player_resource_test")

	# Ganancia sin limite artificial.
	if not _expect(
		player.gain_resource(
			KarmanyEffectData.ResourceType.MN,
			100
		),
		"No se pudo ganar MN."
	):
		test_passed = false

	if not _expect(player.mn == 102, "La ganancia de MN fue incorrecta."):
		test_passed = false

	if not _expect(
		not player.gain_resource(
			KarmanyEffectData.ResourceType.MN,
			0
		),
		"Una ganancia de cantidad cero deberia rechazarse."
	):
		test_passed = false

	# Gasto individual con validacion previa.
	if not _expect(
		player.can_spend_resource(
			KarmanyEffectData.ResourceType.MN,
			5
		),
		"can_spend_resource rechazo un gasto disponible."
	):
		test_passed = false

	if not _expect(
		player.spend_resource(
			KarmanyEffectData.ResourceType.MN,
			5
		),
		"spend_resource rechazo un gasto valido."
	):
		test_passed = false

	if not _expect(player.mn == 97, "El gasto individual dejo MN incorrecto."):
		test_passed = false

	var mn_before_failed_spend: int = player.mn

	if not _expect(
		not player.spend_resource(
			KarmanyEffectData.ResourceType.MN,
			999
		),
		"Se permitio gastar mas MN del disponible."
	):
		test_passed = false

	if not _expect(
		player.mn == mn_before_failed_spend,
		"Un gasto invalido modifico el inventario."
	):
		test_passed = false

	# Coste multiple atomico: o se paga completo o no se modifica nada.
	player.setup_new_game(&"player_resource_test")

	var valid_cost := {
		KarmanyEffectData.ResourceType.MN: 2,
		KarmanyEffectData.ResourceType.MR: 1,
		KarmanyEffectData.ResourceType.EK: 1,
		KarmanyEffectData.ResourceType.FA: 0
	}

	if not _expect(
		player.can_afford_resources(valid_cost),
		"El coste inicial valido no fue reconocido."
	):
		test_passed = false

	if not _expect(
		player.spend_resources(valid_cost),
		"No se pudo pagar un coste multiple valido."
	):
		test_passed = false

	if not _expect(
		player.mn == 0
		and player.mr == 0
		and player.ek == 0
		and player.fa == 0,
		"El coste multiple no desconto los recursos correctos."
	):
		test_passed = false

	player.setup_new_game(&"player_resource_test")
	var snapshot_before_invalid_cost := player.get_resource_snapshot()

	var invalid_cost := {
		KarmanyEffectData.ResourceType.MN: 1,
		KarmanyEffectData.ResourceType.FA: 1
	}

	if not _expect(
		not player.can_afford_resources(invalid_cost),
		"Se considero pagable un coste con FA insuficiente."
	):
		test_passed = false

	if not _expect(
		not player.spend_resources(invalid_cost),
		"Se permitio pagar parcialmente un coste invalido."
	):
		test_passed = false

	if not _expect(
		_snapshots_equal(
			snapshot_before_invalid_cost,
			player.get_resource_snapshot()
		),
		"El coste invalido modifico parcialmente el inventario."
	):
		test_passed = false

	# Integracion con EffectResolver de Fase 7.
	var add_fa := KarmanyEffectData.new()
	add_fa.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	add_fa.resource_type = KarmanyEffectData.ResourceType.FA
	add_fa.amount = 2

	var remove_mn := KarmanyEffectData.new()
	remove_mn.effect_type = KarmanyEffectData.EffectType.REMOVE_RESOURCE
	remove_mn.resource_type = KarmanyEffectData.ResourceType.MN
	remove_mn.amount = 1

	if not _expect(
		KarmanyEffectResolver.apply_effect(add_fa, player).was_applied(),
		"ADD_RESOURCE no llego al inventario."
	):
		test_passed = false

	if not _expect(
		KarmanyEffectResolver.apply_effect(remove_mn, player).was_applied(),
		"REMOVE_RESOURCE no llego al inventario."
	):
		test_passed = false

	if not _expect(
		player.mn == 1 and player.fa == 2,
		"EffectResolver dejo cantidades incorrectas."
	):
		test_passed = false

	# Integracion data-driven con losetas: arrays de efectos modifican inventario.
	var entry_mr := KarmanyEffectData.new()
	entry_mr.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	entry_mr.resource_type = KarmanyEffectData.ResourceType.MR
	entry_mr.amount = 2

	var explore_ek := KarmanyEffectData.new()
	explore_ek.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	explore_ek.resource_type = KarmanyEffectData.ResourceType.EK
	explore_ek.amount = 3

	var tile := KarmanyTileData.new()
	var entry_effects: Array[KarmanyEffectData] = [entry_mr]
	var explore_effects: Array[KarmanyEffectData] = [explore_ek]
	tile.entry_effects = entry_effects
	tile.on_explore_effects = explore_effects

	var entry_results := KarmanyEffectResolver.apply_effects(
		tile.entry_effects,
		player
	)
	var explore_results := KarmanyEffectResolver.apply_effects(
		tile.on_explore_effects,
		player
	)

	if not _expect(
		KarmanyEffectResolver.count_applied(entry_results) == 1,
		"El efecto de Entrada de la loseta no fue aplicado."
	):
		test_passed = false

	if not _expect(
		KarmanyEffectResolver.count_applied(explore_results) == 1,
		"El efecto Al explorar de la loseta no fue aplicado."
	):
		test_passed = false

	if not _expect(
		player.mr == 3 and player.ek == 4,
		"Los efectos de loseta no actualizaron el inventario correctamente."
	):
		test_passed = false

	# Interfaz temporal: debe reflejar cambios del inventario mediante la senal.
	var hud := HUD_SCENE.instantiate() as KarmanyResourceDebugHUD
	add_child(hud)
	await get_tree().process_frame
	hud.bind_player(player)

	var expected_hud_text := "MN: 1 | MR: 3 | EK: 4 | FA: 2"

	if not _expect(
		hud.get_display_text() == expected_hud_text,
		"El HUD temporal no muestra las cantidades actuales."
	):
		test_passed = false

	var add_mn := KarmanyEffectData.new()
	add_mn.effect_type = KarmanyEffectData.EffectType.ADD_RESOURCE
	add_mn.resource_type = KarmanyEffectData.ResourceType.MN
	add_mn.amount = 1
	KarmanyEffectResolver.apply_effect(add_mn, player)

	if not _expect(
		hud.get_display_text() == "MN: 2 | MR: 3 | EK: 4 | FA: 2",
		"El HUD no reacciono al cambio de recursos."
	):
		test_passed = false

	if not _expect(
		_resource_change_count > 0,
		"ResourceInventory no emitio resource_changed."
	):
		test_passed = false

	print("")
	print("Inventario final: ", player.resource_inventory.get_debug_summary())
	print("Eventos resource_changed: ", _resource_change_count)
	print("Gasto individual: OK")
	print("Gasto multiple atomico: OK")
	print("Integracion EffectResolver: OK")
	print("Integracion KarmanyTileData: OK")
	print("HUD temporal: ", hud.get_display_text())
	print("")
	print("================================")

	if test_passed:
		print("FASE 8 OK - Inventario, ganancia, gasto y UI de recursos validados.")
	else:
		push_error("FASE 8 ERROR - Revisar sistema de recursos.")

	print("================================")


func _on_resource_changed(
	_resource_type: int,
	_previous_amount: int,
	_current_amount: int
) -> void:
	_resource_change_count += 1


func _snapshots_equal(
	a: Dictionary,
	b: Dictionary
) -> bool:
	for resource_type in [
		KarmanyEffectData.ResourceType.MN,
		KarmanyEffectData.ResourceType.MR,
		KarmanyEffectData.ResourceType.EK,
		KarmanyEffectData.ResourceType.FA
	]:
		if int(a.get(resource_type, -1)) != int(b.get(resource_type, -1)):
			return false

	return true


func _expect(
	condition: bool,
	message: String
) -> bool:
	if condition:
		return true

	push_error("FASE 8 ERROR: %s" % message)
	return false
