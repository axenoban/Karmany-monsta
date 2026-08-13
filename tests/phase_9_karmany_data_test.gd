extends Node

const TERRAKOR: KarmanyData = preload("res://data/karmanys/k_01_terrakor.tres")
const FLORAVIA: KarmanyData = preload("res://data/karmanys/k_05_floravia.tres")
const BRUMAK: KarmanyData = preload("res://data/karmanys/k_10_brumak.tres")

func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - PHASE 9 KARMANY DATA TEST")
	print("================================")

	var test_passed: bool = true

	if not _validate_terrakor():
		test_passed = false
	if not _validate_floravia():
		test_passed = false
	if not _validate_brumak():
		test_passed = false
	if not _validate_runtime_separation():
		test_passed = false
	if not _validate_affinity_field():
		test_passed = false

	print("")
	print("Fixtures cargados: ", TERRAKOR.display_name, ", ", FLORAVIA.display_name, ", ", BRUMAK.display_name)
	print("Datos compartidos separados del estado runtime: OK")
	print("Afinidad/resonancia preparada como dato opcional: OK")
	print("")
	print("================================")
	if test_passed:
		print("FASE 9 OK - Arquitectura de datos Karmany validada.")
	else:
		push_error("FASE 9 ERROR - Revisar arquitectura Karmany.")
	print("================================")

func _validate_terrakor() -> bool:
	var ok: bool = true
	ok = _expect(TERRAKOR.is_valid_definition(), "Terrakor no es una definicion valida.") and ok
	ok = _expect(TERRAKOR.karmany_id == &"K-01", "Terrakor debe ser K-01.") and ok
	ok = _expect(TERRAKOR.display_name == "Terrakor", "Nombre de Terrakor incorrecto.") and ok
	ok = _expect(TERRAKOR.rank == KarmanyData.Rank.INITIAL, "Terrakor debe tener rango INITIAL.") and ok
	ok = _expect(TERRAKOR.supports_rank(KarmanyData.Rank.INITIAL), "Terrakor debe soportar Inicial.") and ok
	ok = _expect(TERRAKOR.supports_rank(KarmanyData.Rank.N1), "Terrakor debe ser compatible con N1.") and ok
	ok = _expect(TERRAKOR.primary_type == KarmanyData.StrategicType.STABLE, "Terrakor debe ser Estable.") and ok
	ok = _expect(TERRAKOR.power == 6, "Terrakor debe tener Poder 6.") and ok
	ok = _expect(TERRAKOR.encounter_defense == -1, "Terrakor inicial no debe requerir Defensa de encuentro.") and ok
	ok = _expect(TERRAKOR.abilities.size() == 1, "Terrakor debe tener una habilidad de datos.") and ok

	if TERRAKOR.abilities.size() == 1:
		var ability := TERRAKOR.abilities[0]
		ok = _expect(ability.usage_limit == KarmanyAbilityData.UsageLimit.ONCE_PER_ROUND, "Terrakor debe limitar su habilidad a una vez por ronda.") and ok
		ok = _expect(ability.trigger_id == &"combat_vs_beast", "Trigger interno de Terrakor incorrecto.") and ok

	print("Terrakor K-01: ", "OK" if ok else "ERROR")
	return ok

func _validate_floravia() -> bool:
	var ok: bool = true
	ok = _expect(FLORAVIA.is_valid_definition(), "Floravia no es una definicion valida.") and ok
	ok = _expect(FLORAVIA.karmany_id == &"K-05", "Floravia debe ser K-05.") and ok
	ok = _expect(FLORAVIA.rank == KarmanyData.Rank.N1, "Floravia debe ser N1.") and ok
	ok = _expect(FLORAVIA.primary_type == KarmanyData.StrategicType.GATHERER, "Floravia debe ser Recolector.") and ok
	ok = _expect(FLORAVIA.power == 5, "Floravia debe tener Poder 5.") and ok
	ok = _expect(FLORAVIA.encounter_defense == 8, "Floravia debe tener Defensa 8.") and ok
	ok = _expect(FLORAVIA.acquisition_text == "Paga 2 MN + 1 EK o derrota Defensa 8", "Obtencion v0.74 de Floravia incorrecta.") and ok
	ok = _expect(FLORAVIA.abilities.size() == 1, "Floravia debe tener una habilidad.") and ok

	if FLORAVIA.abilities.size() == 1:
		var ability := FLORAVIA.abilities[0]
		ok = _expect(ability.effects.size() == 1, "Floravia debe describir +2 MN como efecto reutilizable.") and ok
		if ability.effects.size() == 1:
			var player := KarmanyPlayerState.new()
			player.setup_new_game(&"floravia_effect_probe")
			var result := KarmanyEffectResolver.apply_effect(ability.effects[0], player)
			ok = _expect(result.was_applied(), "El efecto de Floravia no fue aceptado por EffectResolver.") and ok
			ok = _expect(player.mn == 4, "Floravia +2 MN debia llevar MN 2 -> 4.") and ok

	print("Floravia K-05: ", "OK" if ok else "ERROR")
	return ok

func _validate_brumak() -> bool:
	var ok: bool = true
	ok = _expect(BRUMAK.is_valid_definition(), "Brumak no es una definicion valida.") and ok
	ok = _expect(BRUMAK.karmany_id == &"K-10", "Brumak debe ser K-10.") and ok
	ok = _expect(BRUMAK.rank == KarmanyData.Rank.N2, "Brumak debe ser N2.") and ok
	ok = _expect(BRUMAK.primary_type == KarmanyData.StrategicType.TACTICAL, "Brumak debe ser Tactico.") and ok
	ok = _expect(BRUMAK.power == 8, "Brumak debe tener Poder 8.") and ok
	ok = _expect(BRUMAK.encounter_defense == 12, "Brumak debe tener Defensa 12.") and ok
	ok = _expect(BRUMAK.acquisition_text == "Paga 3 EK o derrota Defensa 12", "Obtencion v0.74 de Brumak incorrecta.") and ok
	ok = _expect(BRUMAK.abilities.size() == 1, "Brumak debe tener una habilidad.") and ok

	print("Brumak K-10: ", "OK" if ok else "ERROR")
	return ok

func _validate_runtime_separation() -> bool:
	var first := KarmanyRuntimeState.new()
	var second := KarmanyRuntimeState.new()
	var ok: bool = true

	ok = _expect(first.configure(TERRAKOR, &"terrakor_instance_a"), "No se pudo configurar la primera instancia.") and ok
	ok = _expect(second.configure(TERRAKOR, &"terrakor_instance_b"), "No se pudo configurar la segunda instancia.") and ok
	ok = _expect(first.karmany_data == second.karmany_data, "Las instancias deben poder compartir KarmanyData inmutable.") and ok
	ok = _expect(not first.is_linked() and not second.is_linked(), "Las instancias deben iniciar UNBOUND.") and ok

	second.set_owner_player_id(&"player_2")
	ok = _expect(second.set_bond_state(KarmanyRuntimeState.BondState.LINKED), "No se pudo cambiar el estado de vinculo runtime.") and ok
	ok = _expect(second.is_linked(), "La segunda instancia debe quedar LINKED.") and ok
	ok = _expect(second.owner_player_id == &"player_2", "Owner runtime incorrecto.") and ok
	ok = _expect(not first.is_linked(), "Modificar una instancia no debe modificar otra.") and ok
	ok = _expect(first.owner_player_id == &"", "La primera instancia no debe adquirir owner por compartir Resource.") and ok
	ok = _expect(TERRAKOR.display_name == "Terrakor", "El Resource Terrakor no debe mutar al cambiar runtime.") and ok

	print("Separacion Data/Runtime: ", "OK" if ok else "ERROR")
	return ok

func _validate_affinity_field() -> bool:
	var probe := KarmanyData.new()
	probe.resonance_affinity_id = &"phase_9_test_affinity"
	probe.resonance_affinity_tags = PackedStringArray(["test", "resonance"])

	var ok: bool = true
	ok = _expect(probe.resonance_affinity_id == &"phase_9_test_affinity", "No se puede almacenar afinidad/resonancia.") and ok
	ok = _expect(probe.resonance_affinity_tags.has("resonance"), "No se pueden almacenar tags de afinidad/resonancia.") and ok
	ok = _expect(TERRAKOR.resonance_affinity_id == &"", "No debe inventarse afinidad canonica para Terrakor sin fuente.") and ok

	return ok

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FASE 9 ERROR: %s" % message)
	return false
