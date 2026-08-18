# F45.1 - ChoiceRequest core

## Objetivo

Introducir una frontera de seleccion humana que reutilice exactamente los candidatos legales ya construidos por el runtime. F45.1 no cambia reglas, contenido canonico, balance ni ejecutores.

## Contrato implementado

- `KarmanyChoiceRequest` recibe una lista ya validada de `KarmanyAiActionCandidate`.
- Cada opcion obtiene un `option_id` opaco y unico dentro de la solicitud.
- La capa consumidora recibe descriptores seguros; no recibe ni modifica el `payload` interno del candidato.
- Un `option_id` valido devuelve la misma instancia de candidato almacenada al crear la solicitud.
- Un `option_id` desconocido no consume la solicitud.
- Una solicitud resuelta no puede reutilizarse.
- `KarmanyFullMatchActionCoreSession` conserva una solicitud estable mientras no cambien jugador, ronda o presupuesto de acciones.
- La resolucion usa `_execute_candidate()` existente y conserva `full_action_resolved`, estadisticas y cierre de turno.

## Compatibilidad preservada

F45.1 no elimina ni sustituye `execute_human_special()`, `run_automated_current_turn()` ni `finish_human_turn_if_ready()`. El flujo automatico de P1/IA sigue disponible para las escenas y pruebas anteriores.

## Auto-selecciones detectadas y diferidas

La inspeccion del runtime actual identifica decisiones automaticas que no se migran en F45.1:

- seleccion de accion por `_auto_human_brain`/controladores IA en `run_automated_current_turn()`;
- seleccion automatica de Resonancia de combate en `_choose_automated_combat_resonance()`;
- tiradas preconstruidas por `_action_rng` en candidatos de combate;
- descarte automatico por limite de mano en `_end_turn_with_hand_limit()`;
- resolucion automatica de la recompensa de Resonancias y del descarte de recursos de Aeterna.

Estas rutas permanecen sin cambios para evitar regresiones. F45.1 solo crea el contrato reutilizable que permitira migrar elecciones humanas explicitas en subfases posteriores.
