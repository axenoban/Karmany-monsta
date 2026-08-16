# Fase 43.1 — Losetas

Fuente canónica: documento maestro v0.74, tablas 16.2–16.8 de losetas.

## Criterio F43 vs F44

F43.1 materializa datos canónicos. Los Resources cuyo comportamiento todavía requiere decisiones, encuentros, movimiento, información privada, conversiones o resolvers no cubiertos de forma íntegra se guardan en:

`res://data/tiles/canonical_pending/`

Estos Resources conservan identidad y texto canónico, usan `interaction_profile_id = pending_f44`, no incluyen efectos estructurados ficticios y no entran en `KarmanyMap41TilePools`. La automatización completa queda para F44.

## Bloques validados localmente

### F43.1A — N1-05 a N1-08

- N1-05 Sendero Verde
- N1-06 Claro de Resonancia
- N1-07 Ruinas del Eco
- N1-08 Puente de Musgo

Test: `res://tests/phase_43_1_tiles_n1_base_test.tscn`

Validación local: exitosa.

### F43.1B — N1-09 a N1-12

- N1-09 Pradera de Luma
- N1-10 Pozo de Bruma
- N1-11 Rocas del Alba
- N1-12 Sendero Partido

Test: `res://tests/phase_43_1_tiles_n1_additional_test.tscn`

Validación local: exitosa.

### F43.1C — N1-13 a N1-16

- N1-13 Refugio Menor
- N1-14 Hierbas de Vael
- N1-15 Taller Improvisado
- N1-16 Fuente Serena

Test: `res://tests/phase_43_1_tiles_n1_mid_test.tscn`

Validación local: exitosa.

## F43.1D — materialización del resto de losetas

Tras validar los tres bloques pequeños anteriores, el resto de identidades faltantes se materializó en un único lote usando exclusivamente el documento maestro v0.74.

### Cierre N1

- N1-17 Colina de Guardia
- N1-18 Cruce de Raices

### N2 pendientes

- N2-02 Bosque de Vinculo
- N2-03 Ruinas del Eco
- N2-04 Atalaya Exterior
- N2-06 Santuario Quebrado
- N2-07 Garganta del Aullido
- N2-08 Refugio de Karmany
- N2-09 Mercado de Ruinas
- N2-10 Puente de Atalaya
- N2-11 Nido Salvaje
- N2-12 Obelisco Menor

### N3 pendientes

- N3-01 Arena de Ruinas
- N3-04 Puerta del Santuario
- N3-05 Santuario del Eco Ancestral
- N3-06 Fisura Ancestral

Todas estas identidades permanecen en `canonical_pending` y no se anuncian como ejecutables hasta F44.

## Cobertura física tras F43.1D

Cobertura de Resources de loseta: **41/41**.

Distribución materializada:

- Inicio: 4/4
- N1: 18/18
- N2: 12/12
- N3: 6/6
- Legendaria: 1/1

Composición técnica:

- 13 Resources runtime preexistentes y ya interpretados por F39.
- 28 Resources canónicos `pending_f44` materializados sin falsa automatización.

Cobertura runtime segura permanece deliberadamente sin cambios:

- N1 runtime: 4
- N2 runtime: 2
- N3 runtime: 2
- fallback F40: conservado

F43.1 no elimina el fallback ni modifica el generador MAP41; la sustitución del fallback por contenido plenamente ejecutable corresponde a la automatización posterior, no a esta materialización.

## Test integral F43.1

Escena:

`res://tests/phase_43_1_tiles_complete_test.tscn`

Comprueba:

1. fidelidad de identidad y textos v0.74 para las 16 identidades incorporadas en el lote final;
2. exactamente 41 Resources de loseta materializados entre `data/tiles` y `data/tiles/canonical_pending`;
3. ausencia de `tile_id` duplicados;
4. cobertura de todos los IDs declarados por `KarmanyV074CanonicalRuntimeCatalog.TILE_IDS`;
5. distribución exacta 4 Inicio / 18 N1 / 12 N2 / 6 N3 / 1 Legendaria;
6. exactamente 28 Resources pendientes;
7. todos los pendientes usan `pending_f44`;
8. ningún pendiente contiene efectos estructurados ficticios;
9. F39 rechaza correctamente esos pendientes como definición ejecutable;
10. los pools runtime continúan en N1=4, N2=2 y N3=2.

Resultado esperado:

`FASE 43.1 OK - 41/41 losetas canónicas materializadas; contenido pendiente aislado del runtime hasta F44.`

## Estado de F43.1

La materialización canónica de Losetas queda completa a nivel de datos: **41/41**.

F43.1 no debe darse por cerrada hasta completar la validación local del test integral y las regresiones F38–F42. No iniciar F43.2 antes de esa validación.