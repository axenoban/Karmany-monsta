# F45.2 - Eleccion humana de descarte por limite de mano

## Objetivo

Sustituir la auto-seleccion de Resonancias unicamente en el flujo humano explicito de F45 cuando la ultima accion deja la mano por encima de su limite. F45.2 no modifica la regla de limite, el mazo, los efectos de cartas ni el resolver de descarte.

## Regla reutilizada

El runtime vigente define `KarmanyResonanceHand.BASE_HAND_LIMIT = 5`. `request_end_turn_discard()` calcula el overflow y `resolve_pending_discard()` ya exige exactamente esa cantidad de IDs distintos y envia las cartas seleccionadas al descarte del mazo.

F45.2 conserva ese contrato y solo materializa quien elige los IDs en un turno humano interactivo.

## Contrato implementado

- `KarmanyResonanceDiscardChoiceRequest` captura la mano exacta cuando nace la solicitud.
- Cada carta recibe un `option_id` opaco y unico dentro de la solicitud.
- La UI recibe descriptores seguros; no recibe referencias mutables a Resources.
- La solicitud soporta seleccion multiple segun `required_count`.
- Cantidad incorrecta, `option_id` desconocido o opcion duplicada son rechazados sin consumir la solicitud.
- Una seleccion valida devuelve los `resonance_id` exactos almacenados y vuelve la solicitud one-shot.
- Si cambia jugador, ronda, presupuesto, cantidad pendiente o snapshot de mano, la solicitud deja de ser vigente.

## Flujo humano explicito

Cuando `resolve_human_action_choice()` consume la ultima accion:

1. Se solicita al `ResonanceHand` el overflow reglamentario.
2. Si no existe overflow, el turno termina como antes.
3. Si existe overflow, el jugador permanece activo con 0 acciones y se crea la solicitud de descarte.
4. Una seleccion invalida no modifica mano, mazo ni turno.
5. Una seleccion valida reutiliza `MatchCoordinator.resolve_pending_resonance_discard()`.
6. Solo despues de resolver el descarte se llama a `end_turn()`.

## Compatibilidad preservada

Para no introducir regresiones en escenas y simulaciones anteriores, F45.2 no altera el comportamiento determinista de:

- `run_automated_current_turn()`;
- `execute_human_special()`;
- `finish_human_turn_if_ready()`;
- `_end_turn_with_hand_limit()`.

Esas rutas mantienen el auto-descarte por menor poder ya existente. La nueva pausa de decision pertenece exclusivamente al flujo humano explicito basado en `ChoiceRequest`.

## Fuera de alcance

F45.2 no migra todavia otras auto-selecciones humanas: Resonancia de combate, tiradas preconstruidas, recompensa de Aeterna ni descartes de derrota. Esas decisiones requieren bloques posteriores y no se mezclan con el limite de mano.
