# Fase 39 — Auditoría de Uso posterior / Interactuar

Base real de F38 inspeccionada antes de la primera modificación F39: `82f0f3ad28fef491ab154bbc83eb744da59f76b8`. El primer commit de F39 tiene ese SHA como padre y `dev/karmany-core` continúa apuntando a ese mismo contenido aprobado. La rama `backup/local-content-before-phase39` **no fue mezclada**.

## Hallazgo principal

Antes de F39 existían dos caminos para el mismo concepto:

1. `KarmanyTileInteractionResolver` + `later_use_effects` producían `ActionType.INTERACT` para usos estructurados simples.
2. F38 interpretaba `later_use_text`/tags por separado para Craftear, Forja, Bestias y Aeterna, produciendo otros tipos de acción.

Eso permitía que el texto, el preview, la legalidad IA y el executor no compartieran siempre la misma fuente. F39 introduce `KarmanyUniversalTileInteractionService`: todo Uso posterior de una loseta se presenta a humano/IA como `INTERACT`, aunque internamente reutilice el resolver especializado ya existente.

## Identidades de loseta materializadas actualmente

El mapa de 41 posiciones sigue usando el mecanismo de fallback validado en F32: los pools actuales contienen **13 identidades materializadas**, que se repiten de forma determinista para cubrir las 41 posiciones. F39 no inventa identidades canónicas faltantes.

| ID | Uso posterior existente | Perfil F39 | Ejecución |
|---|---|---|---|
| I-01 | Recolectar 2 MN | `effect` | `KarmanyEffectResolver` |
| I-02 | Recolectar 2 EK | `effect` | `KarmanyEffectResolver` |
| I-03 | Recolectar 2 MR | `effect` | `KarmanyEffectResolver` |
| I-04 | Recolectar 2 MN o 2 EK | `effect` | `KarmanyEffectResolver` |
| N1-01 | Recolectar 2 MN | `effect` | `KarmanyEffectResolver` |
| N1-02 | Recolectar 2 MR | `effect` | `KarmanyEffectResolver` |
| N1-03 | Recolectar 2 EK | `effect` | `KarmanyEffectResolver` |
| N1-04 | Craftear Equipo básico o recolectar 2 MN | `camp_basic` | efecto + `MatchCoordinator.craft_from_market()` |
| N2-01 | Enfrentar Bestia Media o recolectar 2 EK | `beast_medium` | efecto + sistema de Bestias existente |
| N2-05 | Recolectar 2 MR o craftear Básico/Avanzado | `crystal_pass` | efecto + `MatchCoordinator.craft_from_market()` |
| N3-02 | Craftear Avanzado/Ancestral, mejorar Libro o convertir 2 comunes → 1 FA | `forge` | sistemas de Equipo, Libro y `ForgeInteractionController` existentes |
| N3-03 | Bestia Compleja, 2 MR o 1 FA | `crystal_cave` | sistema de Bestias + efectos; FA limitado a 1/jugador/ronda |
| L-01 | Aeterna, Sintonizar o +2 EK post-Aeterna | `aeterna` | `AeternaResolver` existente |

Todas estas identidades ya tenían `later_use_text` antes de F39. Los casos especializados que carecían de `later_use_effects` completos son precisamente los que antes quedaban fuera del botón genérico Interactuar.

## Contenido canónico aún no materializado

El repositorio aprobado de F38 todavía no contiene `.tres` para estas identidades del catálogo completo v0.74:

- N1: `N1-05` a `N1-18`.
- N2: `N2-02`, `N2-03`, `N2-04`, `N2-06`, `N2-07`, `N2-08`, `N2-09`, `N2-10`, `N2-11`, `N2-12`.
- N3: `N3-01`, `N3-04`, `N3-05`, `N3-06`.

F39 **no asigna Uso posterior inventado** a esas identidades porque no están presentes en los pools activos de esta rama. Cuando se materialicen, `KarmanyTileData.has_universal_interaction_definition()` y la prueba F39 exigirán `later_use_text` + `interaction_profile_id` antes de que puedan entrar al pool sin romper la validación. Además, `KarmanyFullMatchSession.configure()` rechaza el catálogo activo si alguna identidad START/L-01 o algún Resource N1/N2/N3 del pool carece de una definición universal válida; esta auditoría usa los pools públicos y nunca `_hidden_content`.

## Fuente de verdad F39

Flujo objetivo:

`KarmanyTileData` → `KarmanyUniversalTileInteractionService` → preview/requisitos → candidatos `INTERACT` → `KarmanyAiActionExecutor` → resolver existente → resultado.

El servicio vuelve a evaluar la misma opción inmediatamente antes de ejecutar. De este modo, una condición conocida (sin acciones, Bestia bloqueando, conversión de Forja ya usada, límite FA por ronda, coste/crafteo no disponible, etc.) no se ofrece como legal para luego ser rechazada por una comprobación que ya podía hacerse.

Los resolvers siguen haciendo validaciones defensivas al ejecutar. Para las dos subacciones heredadas de L-01 (`Sintonizar con Aeterna` y recolección post-Aeterna), el resolver existente todavía no expone un método de preflight no mutante; F39 mantiene una comprobación mínima equivalente antes de ofrecerlas y vuelve a resolver con `KarmanyAeternaResolver`. No se creó un segundo estado de Aeterna ni se modificó su regla histórica. El contexto local F39 usa explícitamente MAP_41 para no heredar el `MAP_22` histórico del constructor interno del coordinador.

## Privacidad

`get_public_preview()` comprueba primero `BoardState.is_revealed(coord)`. Solo después solicita `runtime.get_public_tile_data(coord)`. Para una posición oculta devuelve `OCULTA` y no publica `tile_id`, nombre ni Uso posterior.

## Compatibilidad

- No se reintroduce el antiguo límite de una sola acción Explorar por turno.
- No se incrementan watchdogs.
- No se cambia la política de ocupación de F38.
- La conversión de Forja sigue siendo una vez por jugador por partida.
- Los resolvers de Equipo, Bestias, Libro, Forja y Aeterna siguen siendo los resolvers de gameplay existentes; F39 solo unifica la puerta de entrada `Interactuar`.
- La presentación F39 observa/ejecuta candidatos legales; no mantiene un estado de gameplay paralelo.
