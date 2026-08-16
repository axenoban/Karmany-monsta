# Fase 43.1 — Losetas

## Bloque F43.1A: N1-05 a N1-08

Fuente canónica: documento maestro v0.74, tablas 16.3 y 16.4 de losetas.

Este bloque inicia F43.1 de forma incremental. No intenta completar las 28 losetas faltantes de una vez.

## Decisión de arquitectura F43 vs F44

Las cuatro identidades de este bloque están completamente definidas en el documento maestro, pero sus efectos contienen decisiones/encuentros que la automatización actual no representa de forma íntegra sin ampliar resolvers:

- N1-05 `Sendero Verde`: Bestia Básica o movimiento.
- N1-06 `Claro de Resonancia`: robo + descarte como una única resolución.
- N1-07 `Ruinas del Eco`: Bestia Básica o elección de recurso.
- N1-08 `Puente de Musgo`: Vínculo guiado N1 y peek privado de Karmany.

Por la regla F43/F44, se materializan como contenido canónico **sin introducirlas todavía en el pool runtime**. No se inventan resolvers para hacerlas pasar como ejecutables.

Los Resources se guardan en:

`res://data/tiles/canonical_pending/`

`KarmanyMap41TilePools` solo carga archivos `.tres` directamente presentes en `res://data/tiles`, por lo que la subcarpeta pendiente no altera F32/F40 ni el fallback actual.

Cada Resource contiene:

- `tile_id`;
- `display_name`;
- `level`;
- `function_tags`;
- `icon_tags`;
- `on_explore_text`;
- `entry_bonus_text`;
- `later_use_text`;
- `limit_text`;
- `starts_revealed`;
- `interaction_profile_id = pending_f44`.

`pending_f44` es una marca técnica deliberadamente desconocida para `KarmanyUniversalTileInteractionService`: permite que el Resource conserve explícitamente el campo de perfil exigido por F43.1, pero F39 lo rechaza como definición ejecutable hasta que F44 implemente el comportamiento real. Los `later_use_effects` permanecen vacíos para no anunciar opciones falsas.

## Estado del bloque

| ID | Nombre canónico | Materializado | Pool runtime | Automatización |
|---|---|---:|---:|---|
| N1-05 | Sendero Verde | Sí | No | Pendiente F44 |
| N1-06 | Claro de Resonancia | Sí | No | Pendiente F44 |
| N1-07 | Ruinas del Eco | Sí | No | Pendiente F44 |
| N1-08 | Puente de Musgo | Sí | No | Pendiente F44 |

Cobertura física de Resources de loseta tras F43.1A: **17/41** (13 runtime existentes + 4 canónicas pendientes).

Cobertura runtime segura permanece: **13/41 identidades materializadas dentro de los pools actuales**, con fallback F40 sin cambios.

## Test

Escena:

`res://tests/phase_43_1_tiles_n1_base_test.tscn`

Comprueba:

1. existencia y carga de los cuatro Resources;
2. identidad y textos exactos del maestro para N1-05..N1-08;
3. `Uso posterior` no vacío;
4. marca `pending_f44`;
5. ausencia de efectos estructurados ficticios;
6. rechazo explícito por F39 como definición ejecutable;
7. ausencia de estas cuatro identidades en `KarmanyMap41TilePools`;
8. conservación del pool N1 runtime anterior.

Resultado esperado:

`FASE 43.1A OK - N1-05..N1-08 materializadas canonicamente y aisladas del runtime hasta F44.`

## Siguiente bloque

No avanzar automáticamente. Tras validación local de F43.1A, continuar con el siguiente grupo de losetas N1 definido por el maestro, manteniendo la misma separación entre materialización canónica y automatización real.
