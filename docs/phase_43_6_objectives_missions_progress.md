# Fase 43.6 — Objetivos Publicos y Misiones de Entrenador

Fuente canonica: documento maestro v0.74, secciones 16.13, 16.14, 16.15 y 16.16. Las imagenes adjuntas por el autor se usan como segunda comprobacion visual; el documento maestro reciente sigue siendo la fuente primaria.

## Cobertura final de contenido

- Objetivos Publicos: **12/12 materializados**.
  - 8 Resources directos preexistentes.
  - 4 nuevos en `res://data/objectives/canonical_pending`: OP-E03, OP-C02, OP-A01 y OP-A02.
- Misiones de Entrenador: **16/16 materializadas**.
  - 9 Resources directos preexistentes.
  - 7 nuevos en `res://data/missions/canonical_pending`: ME-N2, ME-M1, ME-M2, ME-K2, ME-S1, ME-S2 y ME-O2.

## Separacion F43 / F44

Los 4 Objetivos nuevos conservan identidad, familia, condicion textual, recompensa de PL y `map_41_only` cuando corresponde. Sus `conditions` permanecen vacias deliberadamente: no se inventan eventos ni aproximaciones de progreso antes de F44.

Las 7 Misiones nuevas conservan identidad de Entrenador, nombre, marca de primera partida, condicion textual y recompensa canonica de **4 PL + 1 FA**. La recompensa simple +1 FA queda representada de forma exacta; la deteccion de cumplimiento permanece sin `conditions` hasta F44.

Por esta razon los nuevos Resources son contenido canonico materializado, pero no se declaran `is_valid_definition()` para runtime todavia. La subcarpeta `canonical_pending` los mantiene fuera de los catalogos directos.

## Auditoria de contenido preexistente

Se contrastaron los 8 Objetivos y 9 Misiones ya materializados contra v0.74. Sus IDs, nombres, condiciones textuales y recompensas coinciden con el maestro reciente.

Se detecto una desigualdad en los dos fallbacks runtime que completan las misiones recomendadas de Maelis y Saira cuando no existe Resource directo:

- ME-M1 usaba el nombre anterior `Eco Victorioso`; el maestro exige `Resonancia Decisiva`.
- ME-S1 usaba el nombre anterior `Ruta de los Tres Niveles`; el maestro exige `Cartografia Viva`.

F43.6 corrige esos dos nombres y sus textos visibles en `KarmanyV074CanonicalRuntimeCatalog` sin cambiar los eventos/condiciones estructuradas ya aprobados. Asi el runtime conserva 11 Misiones disponibles actualmente, pero las identidades visibles de M1/S1 obedecen v0.74.

## Regla de seleccion de Misiones

El maestro establece que cada Entrenador mantiene sus 2 Misiones propias; en primera partida se usa la marcada con `*`, y en partida normal se elige secretamente 1 de las 2 despues de conocer Entrenador, Karmany inicial y Objetivos Publicos. La otra se retira boca abajo.

F43.6 materializa las 16 cartas y su marca `recommended_first_game`; no modifica todavia el flujo Alpha de seleccion humana identificado como gap de setup.

## Test integral

Escena:

`res://tests/phase_43_6_objectives_missions_complete_test.tscn`

Comprueba 12/12 Objetivos, 16/16 Misiones, IDs unicos, datos v0.74, recompensas, marcas de primera partida, aislamiento de `canonical_pending`, conservacion de 8 Objetivos y 9 Misiones directas runtime-safe, y los fallbacks canonicos ME-M1/ME-S1.

Resultado esperado:

`FASE 43.6 OK - 12/12 Objetivos y 16/16 Misiones canonicos materializados; pendientes aislados hasta F44.`

F43.7 Entrenadores no se inicia hasta completar la validacion local de F43.6 y sus regresiones.
