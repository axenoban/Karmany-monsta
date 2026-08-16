# Fase 44.0 — Auditoría de cobertura lógica

## Baseline

Rama de trabajo: `feature/phase-44-full-content-logic`.

Baseline aprobado: `dev/karmany-core` @ `1f2fd013788e1166d3cdc7346e81a2543d1e4bf5`.

Fuente canónica: **Karmany Monsta: Forja de Resonancia — Libro de Reglas v0.74** y la materialización cerrada en F43.

F44.0 no modifica gameplay, pools, IA, Game Shell, TurnManager ni Resources canónicos. Su función es fijar una línea base reproducible de cobertura lógica antes de promover contenido `canonical_pending`.

## Criterio de certificación

La clasificación es deliberadamente conservadora:

- `FULLY_EXECUTABLE`: toda la regla canónica está demostrablemente representada por datos estructurados + trigger/resolver + integración runtime, sin cláusulas text-only sin resolver. Un marcador histórico como `runtime-safe` o `AUTOMATED_*` por sí solo **no** certifica cobertura total.
- `PARTIAL`: existe integración directa/runtime y lógica estructurada o histórica suficiente para jugar parte del comportamiento, pero F44.0 todavía no certifica que todas las cláusulas canónicas estén cubiertas.
- `DATA_ONLY`: la identidad/regla canónica está materializada, pero no debe anunciarse como lógica ejecutable. Incluye `canonical_pending` y los Entrenadores que F43 dejó explícitamente como `DATA_ONLY`.
- `PENDING`: identidad no materializada o imposible de clasificar. Tras el cierre 205/205 de F43, el baseline esperado es 0.

**Regla importante:** F44.0 no asciende automáticamente ningún componente a `FULLY_EXECUTABLE`. Esa certificación se obtiene por grupos durante F44.1–F44.7 con tests de comportamiento canónico end-to-end.

## Cobertura reproducible del baseline

| Categoría | Total | Directos | `canonical_pending` | Evidencia runtime actual | FULLY | PARTIAL | DATA_ONLY | PENDING |
|---|---:|---:|---:|---|---:|---:|---:|---:|
| Entrenadores | 8 | 8 | 0 | 8 identidades; F41 automatiza parte del setup de E-03/E-05/E-08 | 0 | 3 | 5 | 0 |
| Losetas | 41 | 13 | 28 | 13 directas interpretadas por F39; pools seguros N1=4/N2=2/N3=2 + fallback F40 | 0 | 13 | 28 | 0 |
| Karmany | 28 | 13 | 15 | 13 directos; setup expone 8 iniciales | 0 | 13 | 15 | 0 |
| Bestias | 24 | 7 | 17 | pool seguro: B-01, B-02, B-04, B-15, B-22 | 0 | 7 | 17 | 0 |
| Equipo | 36 | 9 | 27 | mercado seguro: EQ-01, EQ-02, EQ-03, EQ-05, EQ-08, EQ-09 | 0 | 9 | 27 | 0 |
| Resonancias | 40 | 13 | 27 | catálogo runtime representa 40 identidades; 13 IDs históricos marcados automatizados | 0 | 13 | 27 | 0 |
| Objetivos Públicos | 12 | 8 | 4 | 8 directos con condiciones estructuradas históricas | 0 | 8 | 4 | 0 |
| Misiones | 16 | 9 | 7 | 9 directas + fallbacks runtime de ME-M1/ME-S1 | 0 | 9 | 7 | 0 |
| **TOTAL** | **205** | **80** | **125** | — | **0** | **75** | **130** | **0** |

La diferencia entre 80 Resources directos y 75 `PARTIAL` se debe a los cinco Entrenadores directos que F43 dejó explícitamente `DATA_ONLY`.

## Evidencia por categoría

### Entrenadores

F43.7 dejó el campo `automation_status` como fuente explícita de cobertura:

- `PARTIAL`: E-03 Dorian, E-05 Maelis, E-08 Oryn.
- `DATA_ONLY`: E-01 Alderion, E-02 Lyra, E-04 Nara, E-06 Kael, E-07 Saira.
- `FULLY_EXECUTABLE`: ninguno.

Dependencias F44: pasivas, activas, límites y bonus de setup con consulta/reordenamiento privado.

### Losetas

Las 28 `canonical_pending` usan `interaction_profile_id = pending_f44` y no contienen efectos estructurados ficticios. Las 13 directas conservan el contrato F39 de `Uso posterior == Interactuar`, pero la certificación `FULLY_EXECUTABLE` se pospone hasta comprobar todas las cláusulas `Al explorar`, `Entrada`, `Uso posterior`, límites, encuentros y decisiones.

Dependencias F44: primitivas de recurso, movimiento, robo/descarte, spawn/encuentro, conversiones, información privada, condiciones y límites.

### Karmany

Los 15 `canonical_pending` conservan habilidad canónica con `trigger_id = pending_f44` y `effects` vacío. Los 13 directos tienen integración histórica, pero F44 debe comprobar habilidad completa, trigger, límite de uso, combate/vínculo y efectos posteriores.

Dependencias F44: router de triggers de habilidad, estado por turno/ronda/combate/partida, Dado de Riesgo, modificadores de Poder, economía, vínculo y elecciones.

### Bestias

Los 17 `canonical_pending` usan `special_rule_ids = pending_f44` y no inventan `reward_effects`/`defeat_effects`. De los 7 directos, solo 5 forman el pool seguro actual; B-07 y B-23 siguen con integración histórica pendiente.

Dependencias F44: efectos de victoria/derrota, consecuencias especiales, condiciones por tipo de Karmany, bloqueo y jefes.

### Equipo

Los 27 `canonical_pending` usan `trigger_tags = pending_f44` y `modifiers` vacío. De los 9 directos, 6 forman el mercado seguro actual. Un `modifier` existente no certifica que todas las cláusulas del texto canónico estén automatizadas.

Dependencias F44: triggers persistentes/consumibles, modificadores de combate, exploración/movimiento, economía, Dado y límites de uso.

### Resonancias

El catálogo v0.74 representa las 40 identidades, incluso mediante fallback text-only. La lista `AUTOMATED_RESONANCE_IDS` contiene 13 cartas, pero F44.0 la considera evidencia de integración parcial, no prueba de fidelidad completa. Las 27 `canonical_pending` mantienen `modifiers` y `effect_blocks` vacíos.

Dependencias F44: ventanas de reacción, postcombate, movimiento/exploración, PvP, vínculo, Dado, robo/descarte, elecciones y orden de resolución.

### Objetivos y Misiones

Los 4 Objetivos y 7 Misiones `canonical_pending` conservan texto/recompensa pero no inventan `conditions`. Los directos poseen trackers/condiciones históricas que deben verificarse contra cada cláusula v0.74.

Dependencias F44: vocabulario común de eventos de progreso, contadores, campos, timing de reclamación y privacidad de Misiones.

## Infraestructura reutilizable a auditar durante F44

F44 debe preferir extender contratos existentes antes que crear sistemas paralelos:

- `KarmanyEffectData` y resolvers de efectos.
- interacción universal F39 para Losetas.
- resolvers/controladores de combate, vínculo, Bestias, Equipo/Forja y Resonancias.
- `KarmanyV074CanonicalRuntimeCatalog` como catálogo de identidad/fallback, sin confundir fallback textual con ejecución.
- condiciones de progreso de Objetivos/Misiones.
- runtime 4P e IA F38–F42 como consumidor de acciones legales.

El probe F44.0 inspecciona también la presencia de infraestructura por nombres de scripts (`resolver`, `controller`, `interaction`, `objective/mission/tracker`, `ai`) como **evidencia**, no como certificación por componente.

## Decisiones humanas

F44.0 marca como candidatos a decisión humana los Resources cuyo texto contiene verbos/ventanas como `elige`, `puedes`, `mira`, `devuelve`, `reordena`, `cambia` o descartes/selecciones contextuales. Esta detección es heurística y no altera la clasificación.

La lógica de una elección puede necesitar modelarse en F44, pero la interfaz completa de elección para P1 pertenece a F45.

## Familias de lógica faltantes prioritarias

1. **Efectos simples y economía:** ganar/perder recursos, robar/descartar, PL y conversiones.
2. **Triggers y límites:** turno, ronda, combate, partida, entrada/exploración/interacción y postresultado.
3. **Combate condicional:** Poder por tags, rival, Bestia/Jefe, empate, victoria/derrota, Dado de Riesgo.
4. **Movimiento/exploración/reacción:** movimiento adicional, evitar retroceso/combate, mirar losetas ocultas sin filtrar información.
5. **Vínculo y mazos privados:** mirar N cartas, elegir/devolver/reordenar, descuentos y cambio de activo/reserva.
6. **Progreso:** eventos/contadores para Objetivos y Misiones sin aproximaciones textuales.
7. **Entrenadores:** pasivas, activas y setup avanzado, respetando privacidad.

## Orden de implementación recomendado

Para acelerar F44 sin crear un cambio monolítico:

- **F44.1A — Losetas simples/economía:** 8–15 losetas que compartan primitivas de recurso/robo/descarte/conversión.
- **F44.1B — Losetas condicionales:** movimiento, encuentros, información privada y límites.
- **F44.1C — N3/legendario:** reglas especiales y dependencias Aeterna.
- **F44.2 — Karmany:** grupos por familia de trigger/habilidad.
- **F44.3 — Bestias:** grupos por recompensa/derrota/regla especial.
- **F44.4 — Equipo:** grupos por trigger/modificador.
- **F44.5 — Resonancias:** grupos por ventana de uso; es la categoría con más variedad de reacción/elección.
- **F44.6 — Objetivos + Misiones:** completar vocabulario de progreso y trackers.
- **F44.7 — Entrenadores:** pasivas/activas/setup avanzado.
- **F44.8 — cierre transversal:** 205/205 clasificados de nuevo y promoción a `FULLY_EXECUTABLE` solo de contenido demostrado.

Cada grupo debe seguir: `implementar → test de grupo → push feature → validación local → fast-forward a dev/karmany-core`.

## Criterios de aceptación F44.0

- 205 Resources cargables y sin IDs duplicados.
- 80 directos / 125 `canonical_pending`.
- clasificación baseline exacta: 0 FULLY / 75 PARTIAL / 130 DATA_ONLY / 0 PENDING.
- los cinco Entrenadores `DATA_ONLY` y los tres `PARTIAL` coinciden con `automation_status`.
- ningún `canonical_pending` se promociona por existir físicamente.
- se reporta evidencia estructurada, candidatos de elección e infraestructura de scripts sin modificar gameplay.
- F38–F43 permanecen intactas.

Test local: `res://tests/phase_44_logic_coverage_test.tscn`.
