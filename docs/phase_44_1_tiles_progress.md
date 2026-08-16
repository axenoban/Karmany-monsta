# Fase 44.1 — Losetas

## F44.1A — Uso posterior simple y Resonancia

Baseline aprobado: F44.0 integrado en `dev/karmany-core` tras validacion local.
Rama de trabajo: `feature/phase-44-full-content-logic`.

### Objetivo

Primer bloque de implementacion real de F44.1. Se automatiza exclusivamente el **Uso posterior / Interactuar** de ocho losetas que comparten operaciones ya soportadas por F39 y el adaptador de Resonancias. No se declara que la loseta completa sea `FULLY_EXECUTABLE` mientras `Al explorar` o `Entrada` mantengan decisiones/reglas pendientes.

### Primitiva comun nueva

Se incorpora `KarmanyEffectData.EffectType.DRAW_DISCARD_CARDS` con:

- `amount`: cartas robadas;
- `secondary_amount`: cartas que deben descartarse;
- `card_source_id = resonance`.

`KarmanyEffectResolver` delega el robo y la solicitud de descarte a los handlers ya existentes de `KarmanyResonanceEffectAdapter`. El descarte queda registrado como decision pendiente en `KarmanyResonanceHand`; F44 resuelve la regla logica y F45 sera responsable de presentar la eleccion humana cuando corresponda.

### Losetas del bloque — 8

1. `N1-06` Claro de Resonancia — roba 1 Resonancia y descarta 1.
2. `N1-10` Pozo de Bruma — +2 EK **o** roba 1 y descarta 1.
3. `N1-11` Rocas del Alba — +2 MR.
4. `N1-16` Fuente Serena — +2 EK **o** roba 2 y descarta 1.
5. `N1-18` Cruce de Raices — +2 MN.
6. `N2-03` Ruinas del Eco — Bestia Media mediante perfil existente **o** roba 2 y descarta 1.
7. `N2-07` Garganta del Aullido — Bestia Media mediante perfil existente **o** roba 2 y descarta 1.
8. `N2-11` Nido Salvaje — Bestia Media mediante perfil existente **o** roba 2 y descarta 1.

Los perfiles `effect` y `beast_medium` reutilizan la fuente universal F39. No se crea un segundo sistema de Interactuar.

### Aislamiento de runtime

Los ocho Resources permanecen fisicamente en `canonical_pending` durante este bloque. Esto es deliberado: F44.1A automatiza su Uso posterior, pero no promociona la loseta completa al MAP41 mientras `Al explorar` y/o `Entrada` no tengan cobertura logica suficiente.

Por tanto:

- mejora la cobertura estructurada real;
- no altera todavia los pools F40;
- no modifica geometria, seed ni privacidad;
- no introduce contenido parcialmente resuelto en una partida normal.

### Test

Escena:

`res://tests/phase_44_1a_tiles_simple_interactions_test.tscn`

Comprueba:

1. las 8 identidades cargan correctamente;
2. ninguna conserva `interaction_profile_id = pending_f44` para Uso posterior;
3. los perfiles usados son reconocidos por F39;
4. las opciones estructuradas coinciden con ADD_RESOURCE o DRAW_DISCARD_CARDS segun la regla;
5. el robo/descarte usa el origen `resonance`;
6. cada loseta ejecuta una opcion representativa contra TurnManager + EffectContext reales;
7. Interactuar consume exactamente una accion;
8. recursos se suman correctamente;
9. robo de Resonancias y descarte pendiente se registran con sus cantidades canonicas.

Resultado esperado:

`FASE 44.1A OK - 8 losetas con Uso posterior simple/resonante ejecutable sin promover aun Al explorar/Entrada.`

### Pendiente para F44.1B+

Quedan por agrupar reglas de loseta que requieren movimiento/peek, vinculo guiado, crafteo/mercado, conversiones, elecciones de recurso, combate especial, N3 y otras decisiones. Esos bloques se implementaran por familias antes de promover contenido completo a los pools MAP41.
