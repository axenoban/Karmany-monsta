extends Node


const SHELL_SCENE: PackedScene = preload("res://scenes/app/main.tscn")
const SEED_A: int = 42101
const SEED_B: int = 42102


func _ready() -> void:
	print("")
	print("================================")
	print("KARMANY MONSTA - FASE 42 RESTART TEST")
	print("================================")
	var ok: bool = await _run_test()
	print("")
	print("================================")
	if ok:
		print("FASE 42 RESTART OK - Partida A -> RESULT -> Partida B sin estado compartido.")
	else:
		push_error("FASE 42 RESTART ERROR - revisar el primer fallo real.")
	print("================================")


func _run_test() -> bool:
	var shell := SHELL_SCENE.instantiate() as KarmanyAlphaGameShell
	if shell == null:
		return _fail("No se pudo instanciar Game Shell.")
	add_child(shell)
	await get_tree().process_frame

	if not shell.start_new_match(SEED_A):
		return _fail("No se pudo crear Partida A: %s" % shell.last_error)
	await get_tree().process_frame
	var runtime_a := shell.get_active_runtime()
	var setup_a := shell.get_active_human_setup()
	if runtime_a == null or setup_a == null:
		return _fail("Partida A no creo runtime/setup.")
	var board_a := runtime_a.board_state
	var turn_manager_a := runtime_a.local_session.turn_manager
	var player_a := runtime_a.local_session.get_player_by_id(&"player_1")
	if runtime_a.local_session.get_player_count() != 4:
		return _fail("Partida A no tiene 4 jugadores.")
	if not shell.select_starting_karmany(0) or not shell.confirm_starting_karmany():
		return _fail("Partida A no completo eleccion/confirmacion F41.")
	if not shell.start_current_match():
		return _fail("Partida A no entro a PLAYING.")
	var session_a := shell.get_active_full_session()
	if session_a == null or not shell.auto_complete_active_match():
		return _fail("Partida A no llego a FINISHED.")
	await get_tree().process_frame
	if shell.app_state != KarmanyAlphaGameShell.AppState.RESULT:
		return _fail("Partida A no llego a RESULT.")
	if shell.completed_match_count != 1:
		return _fail("Partida A disparo result_ready una cantidad inesperada de veces.")
	var result_a: Dictionary = shell.final_result.duplicate(true)
	if int(result_a.get("seed", 0)) != SEED_A:
		return _fail("Resultado A perdio su seed.")
	if shell.has_active_match() or shell.get_match_host_child_count() != 0:
		return _fail("Partida A sigue montada despues de RESULT.")

	if not shell.start_new_match(SEED_B):
		return _fail("No se pudo crear Partida B: %s" % shell.last_error)
	await get_tree().process_frame
	var runtime_b := shell.get_active_runtime()
	var setup_b := shell.get_active_human_setup()
	if runtime_b == null or setup_b == null:
		return _fail("Partida B no creo runtime/setup.")
	if runtime_a == runtime_b:
		return _fail("Runtime A fue reutilizado en Partida B.")
	if board_a == runtime_b.board_state:
		return _fail("BoardState A fue reutilizado en Partida B.")
	if turn_manager_a == runtime_b.local_session.turn_manager:
		return _fail("TurnManager A fue reutilizado en Partida B.")
	if player_a == runtime_b.local_session.get_player_by_id(&"player_1"):
		return _fail("PlayerState P1 de A fue reutilizado en B.")
	if runtime_b.local_session.get_player_count() != 4:
		return _fail("Partida B contiene jugadores duplicados o incompletos.")
	if runtime_b.match_seed != SEED_B or shell.current_seed != SEED_B:
		return _fail("Partida B no usa una seed independiente.")
	var manager_b := runtime_b.local_session.turn_manager
	if manager_b.is_running or manager_b.actions_remaining != 0:
		return _fail("Partida B heredo una ronda/acciones antes de terminar SETUP.")
	if not shell.final_result.is_empty():
		return _fail("Nueva Partida B conserva informacion de resultado privada/publica de A.")
	if shell.get_match_host_child_count() != 1:
		return _fail("Partida B no es la unica UI de partida montada.")

	if not shell.select_starting_karmany(1) or not shell.confirm_starting_karmany():
		return _fail("Partida B no completo setup F41.")
	if not shell.start_current_match():
		return _fail("Partida B no entro a PLAYING.")
	if manager_b.current_round != 1 or manager_b.actions_remaining != KarmanyTurnManager.ACTIONS_PER_TURN:
		return _fail("Partida B no reinicia en R1 con 2 acciones.")
	var session_b := shell.get_active_full_session()
	if session_b == null or session_a == session_b:
		return _fail("FullMatchSession A fue reutilizada en B.")
	if not shell.auto_complete_active_match():
		return _fail("Partida B no llego a FINISHED.")
	await get_tree().process_frame
	if shell.app_state != KarmanyAlphaGameShell.AppState.RESULT:
		return _fail("Partida B no llego a RESULT.")
	if shell.completed_match_count != 2:
		return _fail("Las dos partidas no produjeron exactamente dos resultados.")
	if int(shell.final_result.get("seed", 0)) != SEED_B:
		return _fail("Resultado B contiene seed/estado de A.")
	if shell.has_active_match() or shell.get_match_host_child_count() != 0:
		return _fail("Partida B queda montada despues de FINISHED.")

	shell.return_to_main_menu()
	await get_tree().process_frame
	if shell.app_state != KarmanyAlphaGameShell.AppState.MAIN_MENU:
		return _fail("No se pudo regresar al menu tras la segunda partida.")
	if shell.has_active_match() or shell.get_match_host_child_count() != 0:
		return _fail("Menu final conserva UI/runtime de alguna partida.")

	print("F42 RESTART | A=%d | B=%d | runtimes_distintos=true | resultados=%d" % [
		SEED_A,
		SEED_B,
		shell.completed_match_count
	])
	return true


func _fail(message: String) -> bool:
	push_error("FASE 42 RESTART TEST ERROR: %s" % message)
	return false
