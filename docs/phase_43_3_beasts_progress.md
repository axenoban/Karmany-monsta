# Fase 43.3 — Bestias

Fuente canonica: documento maestro v0.74, seccion 16.10 `Bestias - 24 cartas`.

## Alcance

Tras validar F43.2 localmente, F43.3 materializa la categoria Bestias completa sin ampliar de forma prematura el pool runtime seguro.

Cobertura fisica final: **24/24 Bestias canonicas**.

- 7 Resources preexistentes permanecen directamente en `res://data/beasts`.
- 17 identidades faltantes se materializan en `res://data/beasts/canonical_pending`.
- `KarmanyPhase37AlphaContentCatalog.load_category()` solo enumera archivos `.tres` directamente presentes en el directorio de categoria, por lo que la subcarpeta pendiente no entra accidentalmente al runtime.

## Identidades pendientes materializadas

B-03 Raicillo Feral, B-05 Cuernillo Verde, B-06 Limo de Runa, B-08 Brumacerno, B-09 Garraespina, B-10 Vigia de Atalaya, B-11 Escarabajo Runico, B-12 Aullador de Bruma, B-13 Raptor de Ruinas, B-14 Feraluz, B-16 Colmillo de Ceniza, B-17 Guardian del Umbral, B-18 Cervix de Obsidiana, B-19 Brumagor, B-20 Raiz Devora, B-21 Centinela Runico y B-24 Eco de Aeterna.

Cada Resource conserva ID, nombre, clasificacion, nivel, Defensa base, PL de recompensa, texto de Recompensa, texto de Derrota y Efecto v0.74.

Las 17 nuevas Bestias usan `special_rule_ids = PackedStringArray("pending_f44")` y no contienen `reward_effects` ni `defeat_effects` ejecutables inventados. La automatizacion de reglas complejas queda explicitamente pendiente para F44.

## Normalizacion maestro -> repositorio

Se corrigieron dos Resources preexistentes sin cambiar su alcance runtime:

- B-07 Terranuk: la recompensa base queda separada del Efecto v0.74; el texto canonico es `2 PL + 2 MR`, y el bono de Karmany Estable queda en `rules_text`.
- B-22 Custodio del Santuario: se normaliza la redaccion de derrota a `retrocedes 1 loseta` como figura en el maestro.

No se agregaron nuevas automatizaciones de combate.

## Estado de runtime

F43.3 mantiene **7 Resources directos** y conserva el pool seguro de F37 en exactamente **5 Bestias**: B-01, B-02, B-04, B-15 y B-22.

B-07 y B-23 siguen siendo Resources directos con integracion pendiente segun el catalogo previo. Las 17 nuevas identidades quedan aisladas en `canonical_pending`.

## Test integral

Escena:

`res://tests/phase_43_3_beasts_complete_test.tscn`

Comprueba:

1. 24/24 Resources Bestia cargables y validos;
2. IDs unicos B-01..B-24;
3. nombre, clasificacion, nivel, Defensa, PL, Recompensa, Derrota y Efecto v0.74;
4. exactamente 17 Bestias pendientes F44;
5. ningun pendiente contiene efectos ejecutables inventados;
6. el catalogo directo permanece en 7 Resources;
7. el pool runtime seguro permanece exactamente en B-01, B-02, B-04, B-15 y B-22.

Resultado esperado:

`FASE 43.3 OK - 24/24 Bestias canonicas materializadas; pendientes aisladas del runtime hasta F44.`

F43.4 Equipo no se inicia hasta completar la validacion local de F43.3 y sus regresiones.
