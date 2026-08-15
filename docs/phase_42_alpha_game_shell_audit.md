# Fase 42 — Alpha Game Shell e integración del flujo completo

## Baseline auditado

Repositorio: `axenoban/Karmany-monsta`.

La auditoría previa a F42 confirmó:

- `dev/karmany-core` → `161947aabd90f8bd03d5f01246fb52912989fcad`.
- `feature/phase-39-universal-tile-interactions` → `161947aabd90f8bd03d5f01246fb52912989fcad`.
- `feature/phase-40-complete-map41-content` → `4fd3e7e91f9c7727c640c06708e211c1f46e1e29`.
- `feature/phase-41-human-setup-flow` → `97f02bba2772c22182976e3e67bcf4d37853b627`.
- no existían PR abiertos al iniciar F42.

F41 descendía linealmente de F40, que a su vez descendía de F39/dev. Por ello el baseline correcto de F42 es:

`97f02bba2772c22182976e3e67bcf4d37853b627` (`feature/phase-41-human-setup-flow`).

No se hizo merge ciego, rebase, force push ni integración a `dev/karmany-core` durante el desarrollo de F42.

## Objetivo de producto

F42 no añade reglas ni contenido. Convierte los prototipos funcionales F38–F41 en un ciclo de aplicación Alpha:

`MAIN_MENU -> SETUP -> PLAYING -> RESULT -> MAIN_MENU / NEW MATCH`

La escena principal real es `res://scenes/app/main.tscn` y la capa de aplicación es `KarmanyAlphaGameShell`.

## Arquitectura

La autoridad de aplicación queda separada de la autoridad de gameplay:

```text
KarmanyAlphaGameShell
        ↓ instancia / destruye
KarmanyPhase41HumanSetupBridge
        ↓
KarmanyHumanSetupFlow
        ↓
KarmanyFullMatchSession
        ↓
KarmanyMultiAiAlphaRuntime
        ↓
LocalMultiplayerSession / TurnManager / BoardState / MatchCoordinator / IA
```

El Game Shell no crea un segundo `TurnManager`, `BoardState`, `MatchCoordinator`, IA, setup o sistema de scoring. Instancia exactamente una raíz F41 por partida.

## Estados de aplicación

### MAIN_MENU

No existe partida activa. Se muestran solamente:

- `KARMANY MONSTA`;
- `NUEVA PARTIDA`;
- `SALIR`.

### SETUP

`NUEVA PARTIDA` instancia una raíz F41 nueva. F41 conserva la autoridad del setup humano:

- P1 recibe Entrenador;
- P1 ve exactamente 3 Karmany iniciales;
- selección y confirmación permanecen separadas;
- P2–P4 completan setup automáticamente;
- Objetivos Públicos se conservan;
- Misión Secreta y mano de Resonancias de P1 conservan privacidad;
- `TurnManager` permanece detenido y con 0 acciones consumibles.

### PLAYING

El shell escucha `KarmanyHumanSetupFlow.playing_started`. No inicia rondas por su cuenta. La transición sigue siendo responsabilidad de F41/F38, por lo que PLAYING comienza en Ronda 1, P1 y 2 acciones.

Toda la partida usa los sistemas existentes de F38/F39/F40/F41: MAP41, IA P2–P4, acciones, Interactuar universal, combate, Equipos/Forja, Resonancias soportadas, objetivos, misiones, PL y finalización.

### RESULT

El shell escucha el `result_ready` del mismo `KarmanyFullMatchSession` materializado por F41. Copia el resultado autoritativo y muestra:

- `PARTIDA FINALIZADA`;
- ganador(es);
- seed;
- rondas;
- PL de P1–P4;
- `NUEVA PARTIDA`;
- `MENÚ PRINCIPAL`.

Mientras RESULT está visible, la partida que acaba de terminar permanece temporalmente montada, pero está en `FINISHED` y su `TurnManager` ya está detenido. Esto evita invalidar callbacks/coroutines del mismo frame en el que se emitió `result_ready`.

La partida anterior se destruye de forma obligatoria al elegir `NUEVA PARTIDA` o `MENÚ PRINCIPAL`, antes de continuar al siguiente ciclo de aplicación.

## Lifecycle y limpieza

`KarmanyAlphaGameShell` mantiene como máximo una referencia activa a:

- raíz F41;
- `KarmanyHumanSetupFlow`;
- `KarmanyFullMatchSession`.

La implementación final de lifecycle corrige una regresión detectada durante la validación local: retirar manualmente la raíz con `remove_child()` antes de `queue_free()` podía dejar la cadena visual F35/F38 como `[Orphan]` mientras todavía existían coroutines suspendidas en presentación.

El teardown definitivo sigue este orden:

1. el Game Shell desconecta sus señales hacia `HumanSetupFlow` / `FullMatchSession`;
2. se detiene `TurnManager` si todavía estuviera activo;
3. `KarmanyPhase41HumanSetupBridge`, por herencia de F38, recibe `begin_teardown()`;
4. F38 cancela nuevos drivers visuales/asíncronos, desconecta señales de partida y propaga el teardown hacia F35;
5. F35 vacía colas de presentación, desconecta observadores de IA/TurnManager y hace que las coroutines pendientes terminen limpiamente en sus puntos de suspensión;
6. la raíz F41 se oculta y se desactiva para procesamiento;
7. la raíz se agenda mediante `queue_free()` **sin usar `remove_child()`**;
8. la jerarquía permanece dentro del `SceneTree` hasta la liberación diferida de fin de frame, evitando la ventana `[Orphan]`;
9. las referencias activas del shell se limpian y la siguiente partida crea una cadena F31–F41 nueva.

Las rutas asíncronas auditadas y protegidas incluyen `wait_for_presentation_idle()`, `_drain_external_steps()`, `_present_step()`, `_run_auto_match_visual()`, `_drive_ai_until_human()` y `_reconcile_visuals_to_logic()`.

Por diseño, la segunda partida no reutiliza jugadores, manos, señales, `BoardState`, IA, `TurnManager`, `FullMatchSession`, CanvasLayers ni callbacks de la partida anterior.

## Seed

F34 históricamente fijaba `34001`. F42 añade a `KarmanyPhase34MultiAiBridge` un único punto de inyección `requested_match_seed` antes de que el bridge entre al `SceneTree`.

- `requested_match_seed == 0` conserva exactamente el comportamiento histórico `34001`, protegiendo regresiones.
- Game Shell genera una seed Alpha automáticamente para Nueva Partida.
- tests y futuras UI pueden suministrar una seed explícita.

No se regenera un runtime después de haber comenzado el setup: la seed se inyecta antes de `_ready()` y el runtime nace ya con la seed correcta.

## Tests F42

### `tests/phase_42_game_shell_test.tscn`

Valida:

- arranque en MAIN_MENU;
- Nueva Partida crea exactamente una cadena de partida;
- SETUP no consume acciones;
- selección/confirmación F41;
- READY_TO_PLAY sigue con TurnManager detenido;
- PLAYING comienza R1/P1/2 acciones;
- el mismo FullMatchSession puede completarse automáticamente;
- FINISHED produce RESULT;
- RESULT conserva seed/rondas/resultado autoritativo;
- la partida retenida durante RESULT está detenida y FINISHED;
- al volver al menú, la raíz y F35 permanecen dentro del `SceneTree` mientras esperan `queue_free()`;
- tras el frame de liberación, raíz y F35 desaparecen;
- un frame adicional no reactiva callbacks de la partida anterior.

### `tests/phase_42_restart_match_test.tscn`

Ejecuta dos partidas consecutivas con seeds distintas. Verifica que Runtime, BoardState, TurnManager, PlayerState y FullMatchSession de A no sean reutilizados por B. También comprueba cuatro participantes, R1/2 acciones al reiniciar, una sola UI activa y exactamente un evento de resultado por partida.

El test final además comprueba expresamente que F35 de la Partida A no quede `[Orphan]` durante `RESULT -> NUEVA PARTIDA`, que la raíz anterior se libere al final del frame y que el mismo contrato se cumpla al destruir la Partida B al volver al menú.

### `tests/phase_42_game_shell_visual_probe.tscn`

Permite recorrer manualmente MAIN_MENU -> SETUP -> PLAYING -> RESULT. Añade únicamente para el probe un control `AUTO AL RESULTADO · ALPHA` para llegar rápidamente a FINISHED sin alterar el Game Shell normal.

## Regresiones obligatorias

La rama F42 conserva sin modificar los tests anteriores:

- `tests/phase_38_full_match_test.tscn`;
- `tests/phase_39_universal_tile_interaction_test.tscn`;
- `tests/phase_40_map41_content_test.tscn`;
- `tests/phase_41_human_setup_test.tscn`.

F42 no aumenta watchdogs, no modifica tests antiguos para ocultar fallos y no reinterpreta reglas.

## Main scene

El baseline todavía arrancaba `tests/phase_4_turn_manager_test.tscn` desde `project.godot`.

F42 cambia `run/main_scene` a:

`res://scenes/app/main.tscn`

La ejecución normal del proyecto con F5 entra por el Game Shell Alpha.

## Verificación y cierre

Desde GitHub se verificó que:

- la rama F42 parte linealmente del HEAD aprobado de F41;
- F40 y F41 están contenidos en su historia;
- los archivos nuevos y modificados existen en la rama correcta;
- `project.godot` apunta a `res://scenes/app/main.tscn`;
- la corrección final de lifecycle elimina el `remove_child()` previo al `queue_free()` y protege la cadena asíncrona F35/F38;
- F42 no fue integrada a `dev/karmany-core` durante su desarrollo.

La validación local en Godot 4.7.1 fue realizada después de la corrección final de lifecycle y fue reportada como exitosa para F42 y sus regresiones F38–F41. Con esa validación, F42 queda cerrada técnicamente y lista para integración fast-forward a `dev/karmany-core` si la historia del repositorio continúa siendo lineal.

## Limitaciones Alpha preservadas

F42 no intenta resolver contenido no materializado ni automatizaciones ya documentadas como pendientes. Se conservan, entre otras, las 28 identidades de loseta pendientes de contenido canónico y las limitaciones Alpha preexistentes de algunas cartas/bonificaciones de Entrenador.

## Fuera de alcance / pendiente para F43+

F42 no incluye:

- las 28 losetas faltantes;
- nuevo Karmany/Bestias/Equipos/Resonancias;
- balance v0.74;
- rediseño de combate/PvP/Aeterna;
- nueva IA estratégica;
- arte final;
- audio/música;
- online/matchmaking;
- tutorial completo;
- perfiles/Steam/achievements.

F42 es exclusivamente integración de producto y lifecycle del Alpha.
