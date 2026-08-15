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

No se hizo merge ciego, rebase, force push ni integración a `dev/karmany-core`.

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

El shell escucha `KarmanyHumanSetupFlow.playing_started`. No inicia rondas por su cuenta. La transición sigue siendo responsabilidad de F41/F38, por lo que PLAYING debe comenzar en Ronda 1, P1 y 2 acciones.

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

Después de copiar el resultado, la raíz completa de la partida se retira de `MatchHost` y se agenda para liberación. El resultado no depende de mantener vivo el runtime anterior.

## Lifecycle y limpieza

`KarmanyAlphaGameShell` mantiene como máximo una referencia activa a:

- raíz F41;
- `KarmanyHumanSetupFlow`;
- `KarmanyFullMatchSession`.

Al terminar, volver al menú o iniciar una nueva partida:

1. se detiene `TurnManager` si todavía estuviera activo;
2. se eliminan las referencias del shell;
3. la raíz F41 se retira inmediatamente de `MatchHost`;
4. la raíz se libera mediante `queue_free()`;
5. la siguiente partida instancia una cadena F31–F41 completamente nueva.

Esto evita reutilizar jugadores, manos, señales, BoardState, IA, CanvasLayers o callbacks de la partida anterior.

## Seed

F34 históricamente fijaba `34001`. F42 añade a `KarmanyPhase34MultiAiBridge` un único punto de inyección `requested_match_seed` antes de que el bridge entre al `SceneTree`.

- `requested_match_seed == 0` conserva exactamente el comportamiento histórico `34001`, protegiendo regresiones.
- Game Shell genera una seed Alpha automáticamente para Nueva Partida.
- tests y futuras UI pueden suministrar una seed explícita.

No se regenera un runtime después de haber comenzado el setup: la seed se inyecta antes de `_ready()` y el runtime nace ya con la seed correcta.

## Tests F42

### `tests/phase_42_game_shell_test.tscn`

Valida lógicamente:

- arranque en MAIN_MENU;
- Nueva Partida crea exactamente una cadena de partida;
- SETUP no consume acciones;
- selección/confirmación F41;
- READY_TO_PLAY sigue con TurnManager detenido;
- PLAYING comienza R1/P1/2 acciones;
- el mismo FullMatchSession puede completarse automáticamente;
- FINISHED produce RESULT;
- RESULT conserva seed/rondas/resultado autoritativo;
- la partida se desmonta;
- volver al menú deja cero partidas activas.

### `tests/phase_42_restart_match_test.tscn`

Ejecuta dos partidas consecutivas con seeds distintas y verifica que Runtime, BoardState, TurnManager, PlayerState y FullMatchSession de A no sean reutilizados por B. También comprueba cuatro participantes, R1/2 acciones al reiniciar y exactamente un evento de resultado por partida.

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

El último paso técnico de F42 cambia `run/main_scene` a:

`res://scenes/app/main.tscn`

La validación final de usuario pasa a ser F5.

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
