# Fase 41 — Auditoría de setup humano y preparación Alpha

## Baseline

F41 nace desde el HEAD aprobado de F40 (`4fd3e7e91f9c7727c640c06708e211c1f46e1e29`) porque F40 todavía no estaba integrado en `dev/karmany-core` al iniciar esta fase. No se forzó ningún merge.

Se preservan como regresiones obligatorias:

- F38: partida completa 4P / 1 humano + 3 IA / MAP41 / 8 rondas.
- F39: Uso posterior = Interactuar y una misma fuente de preview/legalidad/ejecución.
- F40: geometría 41, pools reales, seed, privacidad y fallback; siguen pendientes 28 identidades de loseta y F41 no las materializa.

## Auditoría de setup encontrada

### Automático / determinado por seed

1. **Entrenadores**
   - Existen 8 Entrenadores canónicos materializados.
   - F38 baraja los 8 y asigna 4 únicos por seed.
   - La auditoría v0.74 no define un draft humano de Entrenadores para este flujo Alpha.
   - F41 conserva la asignación determinista y únicamente presenta a P1 su Entrenador, pasiva, activa y bonus de setup.

2. **P2, P3 y P4**
   - Continúan resolviendo automáticamente su Karmany inicial.
   - La selección usa el mismo plan determinista de setup y el mismo RNG de F38.
   - La elección humana de P1 sustituye exclusivamente el `randi_range(0, 2)` que antes elegía por P1; las decisiones posteriores siguen siendo reproducibles para una misma seed + misma elección humana.

3. **Objetivos Públicos**
   - Se selecciona un Objetivo ejecutable de cada una de las cuatro familias.
   - Son información pública.
   - F41 no cambia evaluación, reclamación ni PL.

4. **Misión Secreta**
   - F38 la asigna automáticamente según el Entrenador; prioriza la misión recomendada de primera partida y usa alternativa ejecutable si corresponde.
   - Es privada para su propietario mientras permanece secreta.
   - F41 muestra únicamente la misión de P1 mediante la frontera de privacidad ya existente.

5. **Mano inicial de Resonancias**
   - El mazo runtime completo contiene 40 identidades canónicas.
   - Cada jugador recibe 5 cartas; Dorian/Oryn reciben la carta adicional ya automatizada.
   - Maelis mantiene el filtro inicial automatizado de F38.
   - F41 no cambia cantidades ni reparto y solo expone a la UI la mano de P1.

6. **Recursos iniciales y posiciones**
   - Los `PlayerState` conservan sus posiciones iniciales MAP41 ya configuradas por multiplayer/runtime.
   - F38 restablece recursos de setup y F41 reutiliza esa misma aplicación al confirmar.

### Decisión humana canónica confirmada

**Karmany inicial de P1: revelar exactamente 3 y conservar 1.**

Antes de F41, F38 ya ejecutaba esa regla pero escogía el índice mediante RNG. F41 separa ahora:

`plan determinista de opciones -> decisión privada de P1 -> confirmación -> aplicación por el setup F38 existente`

Un clic de selección no vincula nada. La aplicación ocurre solo al confirmar.

Los otros dos candidatos vuelven al mazo de iniciales mediante exactamente la misma semántica F38: se retira el elegido y se colocan al final los dos no elegidos.

## Bonificaciones de Entrenador aún pendientes

La auditoría F38 ya documentaba que las bonificaciones de **Alderion, Lyra, Nara, Kael y Saira** requieren mirar/reordenar mazos. El runtime todavía no expone una API privada segura de `peek/reorder` para esos mazos.

F41 no inventa una resolución. La UI presenta el texto canónico de la bonificación y marca explícitamente:

`PENDIENTE ALPHA: requiere API privada segura; no se simula.`

Dorian, Oryn y Maelis mantienen las automatizaciones existentes.

## Privacidad F41

Las tres opciones de Karmany de P1 viven en `KarmanyHumanSetupFlow` / `KarmanyStartingKarmanySetupPlan`, no en snapshots públicos del runtime ni en `BoardState`.

Fronteras utilizadas:

- `get_human_starting_candidates(viewer)` solo devuelve opciones cuando `viewer == player_1`.
- `get_human_private_snapshot(viewer)` solo existe para P1.
- `get_private_mission_for_viewer(viewer, target)` exige `viewer == target` y delega en la privacidad de Misiones existente.
- `get_private_resonance_hand_for_viewer(viewer, target)` en F41 solo expone la propia mano humana.
- `get_public_setup_snapshot()` no incluye candidatos, IDs de misión ni IDs de Resonancias.

La IA rival nunca recibe el objeto que contiene las tres opciones privadas de P1.

## Separación SETUP / PLAYING

F41 no se limita a ocultar botones.

Al entrar en setup humano:

- `TurnManager.stop_match()` deja `is_running = false`;
- `actions_remaining = 0`;
- no puede gastarse una acción;
- P1 todavía no tiene Karmany activo;
- `KarmanyHumanSetupFlow` queda en `AWAITING_STARTING_KARMANY`.

Al confirmar:

- se reinicia temporalmente Ronda 1 para que `KarmanyFullMatchSession.configure()` aplique el setup completo usando la elección humana inyectada;
- inmediatamente se vuelve a detener TurnManager;
- el Karmany elegido ya es el activo de P1;
- P2-P4, Objetivos, Misiones, manos y bonuses quedan resueltos;
- el flujo queda en `READY_TO_PLAY`, todavía no en PLAYING.

Solo `start_playing()` vuelve a iniciar TurnManager y después cambia `KarmanyFullMatchSession` a PLAYING. La aceptación exige entonces:

- Ronda 1;
- P1 activo;
- 2 acciones.

Esto evita una partida que ya esté corriendo por debajo de un overlay de setup.

## Arquitectura

### `KarmanyStartingKarmanySetupPlan`

Fuente compartida de la regla de preparación de Entrenadores + revelar 3/conservar 1. F38 y F41 consumen el mismo algoritmo; la UI no replica esa regla.

Permite:

- selección automática histórica cuando no existe elección forzada;
- detener el plan justo antes de la decisión de P1 para presentar sus tres opciones;
- inyectar una identidad confirmada y validar que realmente pertenecía a esas tres opciones.

### `KarmanyHumanSetupFlow`

Autoridad lógica F41. Posee estado, selección pendiente, confirmación, privacidad y transición a PLAYING. No depende de nodos UI.

### `KarmanyPhase41HumanSetupBridge`

Presentación Alpha. Consume exclusivamente la API de `KarmanyHumanSetupFlow`, usa layout de `Container` + `ScrollContainer`, mantiene confirmación separada de selección y reutiliza la capa de gameplay F38/F39 una vez empieza Ronda 1.

## UI Alpha

El prototipo presenta:

- Entrenador asignado y sus textos canónicos;
- tres tarjetas funcionales de Karmany con marcador Alpha, nombre, poder, tipo y habilidad materializada;
- selección visual independiente de confirmación;
- Objetivos Públicos en sección separada;
- `Tu Misión Secreta` únicamente para P1;
- `Tu Mano Inicial de Resonancias` únicamente para P1;
- estado de bonus de Entrenador automatizado o pendiente;
- botón separado `INICIAR PARTIDA · RONDA 1`.

El contenido central tiene scroll y los botones críticos quedan en un footer fijo para mantener operabilidad aproximadamente a `1152x648`.

## Pruebas F41

`tests/phase_41_human_setup_test.tscn` valida lógicamente, sin UI:

- SETUP antes de PLAYING;
- TurnManager detenido y sin acciones consumibles;
- 3 candidatos válidos, iniciales y únicos;
- privacidad de candidatos;
- elección inválida rechazada;
- selección sin aplicación prematura;
- elección controlada de índice 1;
- activo de P1 igual al candidato confirmado;
- candidatos no elegidos fuera del roster de P1;
- confirmación idempotente;
- P2-P4 con setup automático válido;
- misión de P1 visible y misiones rivales ocultas;
- mano de P1 privada;
- 4 Objetivos Públicos;
- READY_TO_PLAY todavía con TurnManager detenido;
- PLAYING inicia Ronda 1 con P1 y 2 acciones.

`tests/phase_41_human_setup_visual_probe.tscn` inicia en `1152x648` y permite alternar con tecla `2` a `1280x720` (`1` vuelve a `1152x648`).

## Fuera de alcance respetado

F41 no:

- materializa las 28 losetas pendientes F40;
- cambia geometría MAP41;
- cambia combate, PvP, scoring o balance;
- rediseña IA estratégica;
- implementa online/matchmaking;
- añade arte final;
- implementa F42.
