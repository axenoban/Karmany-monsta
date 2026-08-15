extends Node


const SHELL_SCENE: PackedScene = preload("res://scenes/app/main.tscn")
const TEST_SEED: int = 42042


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 42 GAME SHELL TEST")
	print("================================")
	var ok: bool = await _run_test()
	print("")
	print("================================")
	if ok:
		print("FASE 42 OK - MAIN_MENU -> SETUP -> PLAYING -> RESULT -> MAIN_MENU validado.")
	else:
		push_error("FASE 42 ERROR - revisar el primer fallo real antes de errores en cascada.")
	print("================================")


func _run_test() -> bool:
	var shell := SHELL_SCENE.instantiate() as KarmanyAlphaGameShell
	if shell == null:
		return _fail("No se pudo instanciar Main/GameShell.")
	add_child(shell)
	await get_tree().process_frame

	if shell.app_state != KarmanyAlphaGameShell.AppState.MAIN_MENU:
		return _fail("Game Shell no inicia en MAIN_MENU.")
	if shell.has_active_match() or shell.get_match_host_child_count() != 0:
		return _fail("MAIN_MENU contiene una partida residual.")

	if not shell.start_new_match(TEST_SEED):
		return _fail("Nueva partida fallo: %s" % shell.last_error)
	await get_tree().process_frame
	if shell.app_state != KarmanyAlphaGameShell.AppState.SETUP:
		return _fail("Nueva partida no llega a SETUP.")
	if shell.current_seed != TEST_SEED:
		return _fail("Game Shell no conserva la seed solicitada.")
	if not shell.has_active_match() or shell.get_match_host_child_count() != 1:
		return _fail("SETUP no contiene exactamente una partida visual/logica.")

	var runtime := shell.get_active_runtime()
	var setup := shell.get_active_human_setup()
	if runtime == null or setup == null:
		return _fail("SETUP no expone runtime/HumanSetupFlow existentes.")
	if runtime.match_seed != TEST_SEED:
		return _fail("La seed no llego al runtime F34/F41.")
	if runtime.local_session.get_player_count() != 4:
		return _fail("La partida no tiene exactamente 4 participantes.")
	var manager := runtime.local_session.turn_manager
	if manager.is_running or manager.actions_remaining != 0:
		return _fail("TurnManager consume gameplay durante SETUP.")
	if setup.get_human_starting_candidates(&"player_1").size() != 3:
		return _fail("P1 no recibe exactamente 3 candidatos iniciales.")

	if not shell.select_starting_karmany(1):
		return _fail("Game Shell no pudo conducir la seleccion F41.")
	if not shell.confirm_starting_karmany():
		return _fail("Game Shell no pudo confirmar el Karmany F41.")
	if not setup.is_ready_to_play():
		return _fail("Confirmar no deja F41 en READY_TO_PLAY.")
	if manager.is_running or manager.actions_remaining != 0:
		return _fail("Confirmar el setup inicio acciones antes de INICIAR PARTIDA.")

	if not shell.start_current_match():
		return _fail("No se pudo entrar a PLAYING.")
	if shell.app_state != KarmanyAlphaGameShell.AppState.PLAYING:
		return _fail("Shell no refleja PLAYING.")
	if not manager.is_running or manager.current_round != 1:
		return _fail("PLAYING no comienza en Ronda 1.")
	var active := manager.get_active_player()
	if active == null or active.player_id != &"player_1":
		return _fail("PLAYING no comienza con P1.")
	if manager.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _fail("P1 no recibe exactamente 2 acciones.")

	var full_session := shell.get_active_full_session()
	if full_session == null:
		return _fail("Game Shell no reutiliza FullMatchSession de F38/F41.")
	if not shell.auto_complete_active_match():
		return _fail("La partida no alcanzo FINISHED: %s" % full_session.last_error)
	await get_tree().process_frame
	if shell.app_state != KarmanyAlphaGameShell.AppState.RESULT:
		return _fail("FINISHED no conduce a RESULT.")
	if String(shell.final_result.get("state", "")) != "FINISHED":
		return _fail("RESULT no conserva el resultado autoritativo FINISHED.")
	var result_rounds: int = int(shell.final_result.get("rounds", 0))
	if result_rounds != 8:
		return _fail("Resultado no informa 8 rondas.")
	if shell.completed_match_count != 1:
		return _fail("result_ready fue procesado mas o menos de una vez.")
	if not shell.has_active_match() or shell.get_match_host_child_count() != 1:
		return _fail("RESULT perdio la partida FINISHED antes de una decision de navegacion.")
	if manager.is_running or full_session.match_state != KarmanyFullMatchSession.MatchState.FINISHED:
		return _fail("La partida retenida en RESULT no esta realmente detenida/FINISHED.")

	var finished_root := shell.active_match_root
	if finished_root == null or not finished_root.is_inside_tree():
		return _fail("La raiz FINISHED no esta dentro del SceneTree antes de navegar.")
	var finished_phase_35 := finished_root.phase_37.phase_36.phase_35
	if finished_phase_35 == null or not finished_phase_35.is_inside_tree():
		return _fail("F35 no esta dentro del SceneTree antes del teardown.")
	shell.return_to_main_menu()
	if not is_instance_valid(finished_root):
		return _fail("Teardown libero la raiz de forma inmediata en vez de usar queue_free seguro.")
	if not finished_root.is_queued_for_deletion():
		return _fail("Teardown no marco la raiz anterior para queue_free.")
	if not finished_root.is_inside_tree():
		return _fail("Teardown convirtio la raiz anterior en [Orphan] antes de queue_free.")
	if not is_instance_valid(finished_phase_35) or not finished_phase_35.is_inside_tree():
		return _fail("F35 quedo [Orphan] mientras la raiz esperaba queue_free.")
	await get_tree().process_frame
	if is_instance_valid(finished_root):
		return _fail("La raiz anterior sigue viva despues del frame de liberacion diferida.")
	if is_instance_valid(finished_phase_35):
		return _fail("F35 sigue vivo despues de liberar la raiz de partida.")
	if shell.app_state != KarmanyAlphaGameShell.AppState.MAIN_MENU:
		return _fail("MENÚ PRINCIPAL no recupera MAIN_MENU.")
	if shell.has_active_match() or shell.get_match_host_child_count() != 0:
		return _fail("Volver al menu conserva runtime/UI de partida.")

	# Un frame adicional deja oportunidad a cualquier callback/coroutine vieja de
	# reanudarse. Si conservase acceso huérfano a SceneTree, Godot reportaría el
	# error de lifecycle que este test protege.
	await get_tree().process_frame
	if shell.get_match_host_child_count() != 0:
		return _fail("Un callback tardio volvio a montar estado de la partida retirada.")

	print("F42 SHELL | seed=%d | rounds=%d | completed=%d | teardown_orphan=false" % [
		TEST_SEED,
		result_rounds,
		shell.completed_match_count
	])
	return true


func _fail(message: String) -> bool:
	push_error("FASE 42 TEST ERROR: %s" % message)
	return false
