# Fase 43.1 — Losetas

Fuente canónica: documento maestro v0.74, tablas 16.2–16.8 de losetas.

F43.1 se ejecuta incrementalmente. No se materializan todas las identidades faltantes de una sola vez y no se adelanta la automatización completa reservada para F44.

## Decisión de arquitectura F43 vs F44

Los Resources canónicos que todavía contienen decisiones, encuentros, movimiento, peek privado, conversiones u otras operaciones no representadas íntegramente por los resolvers actuales se guardan en:

`res://data/tiles/canonical_pending/`

`KarmanyMap41TilePools` solo carga archivos `.tres` directamente presentes en `res://data/tiles`, por lo que esta subcarpeta no altera F32/F40 ni el fallback actual.

Cada Resource pendiente conserva el contrato documental requerido:

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

`pending_f44` es una marca técnica deliberadamente desconocida para `KarmanyUniversalTileInteractionService`. Así el Resource está materializado sin ser anunciado falsamente como ejecutable por F39. No se añaden efectos estructurados ficticios para conseguir tests verdes.

## Bloque F43.1A — N1-05 a N1-08

Materializadas:

| ID | Nombre canónico | Materializado | Pool runtime | Automatización |
|---|---|---:|---:|---|
| N1-05 | Sendero Verde | Sí | No | Pendiente F44 |
| N1-06 | Claro de Resonancia | Sí | No | Pendiente F44 |
| N1-07 | Ruinas del Eco | Sí | No | Pendiente F44 |
| N1-08 | Puente de Musgo | Sí | No | Pendiente F44 |

Razones principales para mantenerlas fuera del runtime seguro:

- N1-05: Bestia Básica o movimiento.
- N1-06: robo + descarte compuesto.
- N1-07: Bestia Básica o elección de recurso.
- N1-08: Vínculo guiado N1 y peek privado.

Test:

`res://tests/phase_43_1_tiles_n1_base_test.tscn`

Resultado esperado:

`FASE 43.1A OK - N1-05..N1-08 materializadas canonicamente y aisladas del runtime hasta F44.`

**Validación local:** reportada exitosa antes de iniciar F43.1B, incluyendo las regresiones solicitadas.

## Bloque F43.1B — N1-09 a N1-12

Materializadas desde la tabla 16.4 del maestro:

| ID | Nombre canónico | Materializado | Pool runtime | Automatización |
|---|---|---:|---:|---|
| N1-09 | Pradera de Luma | Sí | No | Pendiente F44 |
| N1-10 | Pozo de Bruma | Sí | No | Pendiente F44 |
| N1-11 | Rocas del Alba | Sí | No | Pendiente F44 |
| N1-12 | Sendero Partido | Sí | No | Pendiente F44 |

Contenido preservado:

- N1-09: movimiento/información, peek de N2 y Bonificación de entrada de información.
- N1-10: EK/Resonancia con robo y descarte.
- N1-11: MR/conversión 2 MN → 2 MR; Uso posterior de 2 MR.
- N1-12: movimiento/información y peek de N2.

No se ha reinterpretado el texto de N1-12: el campo `Al explorar` se materializa exactamente según el maestro, sin añadir `sin revelarla` donde el documento no lo escribe explícitamente.

Resources:

`res://data/tiles/canonical_pending/n1_09_pradera_de_luma.tres`

`res://data/tiles/canonical_pending/n1_10_pozo_de_bruma.tres`

`res://data/tiles/canonical_pending/n1_11_rocas_del_alba.tres`

`res://data/tiles/canonical_pending/n1_12_sendero_partido.tres`

Test:

`res://tests/phase_43_1_tiles_n1_additional_test.tscn`

Comprueba:

1. existencia y carga de los cuatro Resources;
2. identidad, función, iconos y textos exactos del maestro para N1-09..N1-12;
3. `Uso posterior` no vacío;
4. marca `pending_f44`;
5. ausencia de `on_explore_effects`, `entry_effects` y `later_use_effects` ficticios;
6. rechazo explícito por F39 como definición ejecutable;
7. ausencia de estas identidades en `KarmanyMap41TilePools`;
8. conservación del pool N1 runtime anterior.

Resultado esperado:

`FASE 43.1B OK - N1-09..N1-12 materializadas canonicamente y aisladas del runtime hasta F44.`

## Cobertura tras F43.1B

Cobertura física de Resources de loseta: **21/41**.

- 13 Resources runtime preexistentes.
- 8 Resources canónicos pendientes F44 materializados durante F43.1A–B.

Cobertura runtime segura permanece: **13/41**, con fallback F40 sin cambios.

## Siguiente bloque

No avanzar automáticamente. Tras validación local de F43.1B, continuar con el siguiente grupo N1 (`N1-13` en adelante) utilizando exclusivamente el maestro v0.74 y la misma separación materialización/automatización.
