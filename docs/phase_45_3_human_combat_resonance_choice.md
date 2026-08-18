# F45.3 - Eleccion humana de Resonancia de combate

## Objetivo

Conectar el contrato `ChoiceRequest` de F45.1 con la eleccion reglamentaria de jugar hasta 1 Resonancia por jugador en combate, sin modificar resolvers, balance, contenido canonico ni la automatizacion usada por IA/regresiones.

El flujo humano explicito queda:

`Elegir accion de combate -> elegir Resonancia o Sin Resonancia -> ejecutar el candidato ya validado`.

## Alcance implementado

Los candidatos humanos de estos tipos se detienen antes de ejecutarse cuando existe al menos una Resonancia compatible:

- `FIGHT_BEAST`;
- `BOND_COMBAT`;
- `PVP` para el atacante humano activo;
- `AETERNA` para la Resonancia usada durante el combate.

La opcion `Sin Resonancia` siempre esta presente cuando se abre la solicitud, porque la regla permite jugar hasta 1 Resonancia y no obliga a jugar una.

Si la mano no contiene ninguna Resonancia compatible con el combate seleccionado, la accion se ejecuta directamente sin Resonancia y no se crea una decision vacia.

## Contrato de solicitud

`KarmanyCombatResonanceChoiceRequest`:

- conserva jugador, ronda, presupuesto, tipo de accion, etiqueta y destino del combate;
- genera `option_id` opacos;
- expone descriptores seguros de las cartas, no referencias mutables ni payloads de combate;
- incluye `Sin Resonancia` como opcion explicita;
- una opcion inexistente no consume la solicitud;
- una opcion valida es one-shot;
- conserva un snapshot completo de la mano y se invalida si la mano cambia antes de resolver.

## Frontera de ejecucion

`KarmanyFullMatchHumanCombatChoiceSession` se inserta entre `KarmanyFullMatchActionSession` y `KarmanyFullMatchResultSession`.

La capa intercepta solamente `resolve_human_action_choice()` del flujo humano explicito. Antes de abrir la subeleccion elimina del candidato la Resonancia que pudo haber preseleccionado `_choose_automated_combat_resonance()` al construir acciones para IA/legacy.

Al resolver la subeleccion, el ID humano se inyecta en la clave ya consumida por los ejecutores existentes:

- Bestia, Vinculo por combate y Aeterna: `payload["resonance_id"]`;
- PvP atacante: `payload["attacker_resonance_id"]`.

La seleccion automatica del defensor IA en `payload["defender_resonance_id"]` no se modifica.

## Legalidad contextual preservada

F45.3 no promueve Resonancias de `canonical_pending` ni amplia el catalogo runtime. Solo se ofrecen cartas que:

1. pertenecen al subconjunto ya soportado por `KarmanyV074CanonicalRuntimeCatalog.is_resonance_automated()`;
2. no estan excluidas por `KarmanyResonanceAbilityRuntimeService`;
3. admiten la ventana tecnica `combat`;
4. cumplen las restricciones contextuales ya conocidas.

Restricciones cerradas en esta frontera humana:

- R-05 / cartas marcadas `pvp`: solo se ofrecen en `PVP`;
- R-37 Instinto de Caza: solo se ofrece en `FIGHT_BEAST`.

La legalidad definitiva sigue perteneciendo a `KarmanyResonanceResolver` y a los resolvers de combate existentes.

## Compatibilidad preservada

No se modifican ni eliminan:

- `_choose_automated_combat_resonance()`;
- `run_automated_current_turn()`;
- `execute_human_special()`;
- `execute_human_combat_with_resonance()`;
- los resolvers de Bestia, Vinculo, PvP o Aeterna.

Por ello Auto-P1, IA y pruebas legacy mantienen su comportamiento anterior.

## Limite tecnico deliberado

F45.3 materializa la eleccion del **jugador humano activo que inicia el combate**. Cuando una IA inicia un PvP contra P1, la eleccion del defensor sigue la ruta automatica legacy. Convertir una respuesta fuera de turno en una eleccion humana requiere pausar y reanudar el bucle sincronico de turno IA; ese protocolo de interrupcion no se mezcla en esta fase porque seria una expansion arquitectonica distinta y aumentaria el riesgo de regresion de PvP.

Esto no cambia la regla de PvP: cada participante conserva como maximo 1 Resonancia por combate. Solo delimita que el punto de respuesta humana fuera de turno aun no esta expuesto a UI.

## Prueba F45.3

`res://tests/phase_45_3_human_combat_resonance_choice_test.tscn` valida:

- `Sin Resonancia`, ID exacto, one-shot y rechazo de IDs forjados;
- pausa real entre ChoiceRequest de accion y ejecucion;
- no consumo de accion mientras la Resonancia esta pendiente;
- Bestia: R-01 y R-37 disponibles, R-05 excluida;
- PvP: R-01 y R-05 disponibles, R-37 excluida;
- sustitucion de la auto-seleccion del atacante humano;
- preservacion de la seleccion legacy del defensor IA;
- compatibilidad de `KarmanyFullMatchSession` con las rutas legacy.
