extends Node


@export var tile: KarmanyTileData


func _ready() -> void:

	if tile == null:
		push_error("FASE 1B ERROR: No se asignó TileData.")
		return


	var player := KarmanyPlayerState.new()
	player.setup_new_game()


	print("================================")
	print("KARMANY MONSTA - EFFECT TEST")
	print("================================")

	print("Loseta: ", tile.tile_id, " - ", tile.display_name)

	print("")
	print("RECURSOS INICIALES")
	print("MN: ", player.mn)
	print("MR: ", player.mr)
	print("EK: ", player.ek)
	print("FA: ", player.fa)


	print("")
	print("ACTIVANDO BONIFICACION DE ENTRADA...")


	for effect: KarmanyEffectData in tile.entry_effects:
		KarmanyEffectResolver.apply_effect(effect, player)


	print("")
	print("RECURSOS DESPUES DE ENTRAR")
	print("MN: ", player.mn)
	print("MR: ", player.mr)
	print("EK: ", player.ek)
	print("FA: ", player.fa)


	print("================================")


	if player.mn == 3:
		print("FASE 1B OK - I-01 entrego correctamente +1 MN.")
	else:
		push_error(
			"FASE 1B ERROR: Se esperaban 3 MN y se obtuvieron %s."
			% player.mn
		)
