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

`pending_f44` es una marca técnica deliberadamente desconocida para `KarmanyUniversalTileInteractionService`. Así el Resource queda materializado sin ser anunciado falsamente como ejecutable por F39. No se añaden efectos estructurados ficticios para conseguir tests verdes.

## Bloque F43.1A — N1-05 a N1-08

| ID | Nombre canónico | Materializado | Pool runtime | Automatización |
|---|---|---:|---:|---|
| N1-05 | Sendero Verde | Sí | No | Pendiente F44 |
| N1-06 | Claro de Resonancia | Sí | No | Pendiente F44 |
| N1-07 | Ruinas del Eco | Sí | No | Pendiente F44 |
| N1-08 | Puente de Musgo | Sí | No | Pendiente F44 |

Test: `res://tests/phase_43_1_tiles_n1_base_test.tscn`

Resultado esperado: `FASE 43.1A OK - N1-05..N1-08 materializadas canonicamente y aisladas del runtime hasta F44.`

**Validación local:** reportada exitosa antes de iniciar F43.1B, incluyendo las regresiones solicitadas.

## Bloque F43.1B — N1-09 a N1-12

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

No se reinterpretó N1-12: `Al explorar` conserva exactamente la formulación del maestro, sin añadir `sin revelarla` donde la tabla no lo escribe explícitamente.

Test: `res://tests/phase_43_1_tiles_n1_additional_test.tscn`

Resultado esperado: `FASE 43.1B OK - N1-09..N1-12 materializadas canonicamente y aisladas del runtime hasta F44.`

**Validación local:** reportada exitosa antes de iniciar F43.1C.

## Bloque F43.1C — N1-13 a N1-16

Materializadas desde la tabla 16.4 del maestro:

| ID | Nombre canónico | Materializado | Pool runtime | Automatización |
|---|---|---:|---:|---|
| N1-13 | Refugio Menor | Sí | No | Pendiente F44 |
| N1-14 | Hierbas de Vael | Sí | No | Pendiente F44 |
| N1-15 | Taller Improvisado | Sí | No | Pendiente F44 |
| N1-16 | Fuente Serena | Sí | No | Pendiente F44 |

Contenido preservado:

- N1-13: Vínculo guiado N1, recolección de MN y peek privado de Karmany.
- N1-14: Bestia Básica o preparación mediante Resonancias, con bono de Poder de entrada.
- N1-15: crafteo básico o MN; entrada de información sobre Equipo; sin Equipo avanzado/ancestral.
- N1-16: EK/Resonancia con robo y descarte.

Resources:

- `res://data/tiles/canonical_pending/n1_13_refugio_menor.tres`
- `res://data/tiles/canonical_pending/n1_14_hierbas_de_vael.tres`
- `res://data/tiles/canonical_pending/n1_15_taller_improvisado.tres`
- `res://data/tiles/canonical_pending/n1_16_fuente_serena.tres`

Test: `res://tests/phase_43_1_tiles_n1_mid_test.tscn`

Comprueba:

1. existencia y carga de los cuatro Resources;
2. identidad, función, iconos y textos del maestro para N1-13..N1-16;
3. `Uso posterior` no vacío;
4. marca `pending_f44`;
5. ausencia de efectos estructurados ficticios;
6. rechazo explícito por F39 como definición ejecutable;
7. ausencia de estas identidades en `KarmanyMap41TilePools`;
8. conservación del pool N1 runtime anterior.

Resultado esperado:

`FASE 43.1C OK - N1-13..N1-16 materializadas canonicamente y aisladas del runtime hasta F44.`

## Cobertura tras F43.1C

Cobertura física de Resources de loseta: **25/41**.

- 13 Resources runtime preexistentes.
- 12 Resources canónicos pendientes F44 materializados durante F43.1A–C.

Cobertura runtime segura permanece: **13/41**, con fallback F40 sin cambios.

## Siguiente bloque

No avanzar automáticamente. Tras validación local de F43.1C, cerrar el anillo N1 con `N1-17` y `N1-18`, siempre utilizando exclusivamente el maestro v0.74 y la misma separación materialización/automatización.
