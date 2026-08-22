# F45.5 - Decisiones humanas de Aeterna / climax

## Objetivo

Cerrar el flujo humano explicito de Aeterna Draconis sin alterar la ruta automatizada de IA/Auto-P1 ni las fases F45.3 y F45.4 ya aprobadas.

## Secuencia humana

La ruta de P1 queda:

`Elegir Combatir Aeterna -> lanzar Dado de Instinto -> elegir Resonancia/Sin Resonancia -> resolver combate -> resolver consecuencias de Aeterna -> continuar turno`.

Aeterna utiliza el mismo D6 canonico de Instinto que el resto de objetivos PvE. F45.5 agrega una solicitud especializada para Aeterna; la solicitud base de F45.4 sigue rechazando Aeterna para conservar su frontera y su prueba de regresion.

## Victoria

El resolver existente mantiene el premio fijo de 8 PL y deja la recompensa final pendiente.

P1 recibe `KarmanyAeternaRewardChoiceRequest` con opciones legales en el estado actual:

- `Resonancias`: roba 3 y debe elegir 1 de esas 3 cartas recien robadas para descartar, conservando exactamente las otras 2. Las Resonancias que ya estaban en la mano antes de cobrar la recompensa no son opciones de este descarte.
- `Equipo ancestral`: solo se ofrecen Equipos de rareza Ancestral que esten dentro de las 4 cartas visibles del mercado.

### Equipo ancestral visible

`KarmanyAeternaMarketRewardService` aplica la regla acordada:

1. valida que la carta seleccionada siga en el indice visible elegido;
2. exige rareza Ancestral;
3. no ejecuta crafteo ni cobra MN/MR/EK/FA;
4. retira la carta mediante `EquipmentMarket.take_visible()`;
5. el mercado repone inmediatamente la posicion;
6. entrega el Equipo al inventario;
7. si el inventario ya contiene 3 Equipos, P1 debe indicar cual de sus Equipos descarta antes de recibir el premio;
8. el Equipo reemplazado va al descarte del mercado.

Los Ancestrales que esten en el mazo, descarte o fuera de las cuatro cartas visibles no aparecen como opciones.

## Derrota

El resolver de Aeterna sigue aplicando el coste del intento, el resultado de combate y el retroceso ya existentes. F45.5 elimina las selecciones automaticas de P1 posteriores al combate:

- el descarte de hasta 2 recursos basicos disponibles se resuelve mediante `KarmanyAeternaResourceDiscardRequest`;
- si Aeterna dejo un descarte de Resonancia pendiente, P1 elige explicitamente la carta mediante `KarmanyResonanceDiscardChoiceRequest`;
- una seleccion invalida no consume la solicitud.

Mientras exista una consecuencia de Aeterna pendiente no se puede construir otra solicitud de accion ni finalizar manualmente el turno.

## Compatibilidad

- IA y Auto-P1 conservan `_resolve_aeterna_post_result()` automatizado porque la nueva ruta solo se activa durante `_complete_explicit_human_action()` de AETERNA.
- PvP sigue sin Dado de Instinto.
- F45.3 mantiene la eleccion humana de Resonancia.
- F45.4 mantiene su request base para Bestias/Jefes y vinculacion por combate.
- El mercado normal, crafteo y costes de Equipo no se modifican.

## Pruebas

Escena de componentes y contratos:

`res://tests/phase_45_5_human_aeterna_decisions_test.tscn`

Escena de integracion del flujo post-combate:

`res://tests/phase_45_5_aeterna_post_choice_flow_test.tscn`

Cobertura:

- request especializado de Instinto para Aeterna sin ampliar el request F45.4;
- adaptador de Instinto en el candidato AETERNA;
- reward request limitado a Ancestrales visibles;
- premio de Equipo sin gasto de recursos;
- retirada del mercado y reposicion de la cuarta carta;
- inventario lleno y descarte humano previo;
- validacion del descarte de recursos tras derrota;
- bloqueo de nuevas acciones mientras existe una consecuencia de Aeterna pendiente;
- ciclo de victoria Resonancias: roba 3 -> P1 solo puede descartar 1 de esas 3 -> conserva exactamente las otras 2 -> continua;
- ciclo de derrota: P1 elige recursos -> se aplican -> continua;
- superficie de compatibilidad de `KarmanyFullMatchSession` con F45.3/F45.4 y automatizacion legacy.

Regresiones obligatorias locales:

- `res://tests/phase_45_4_human_instinct_roll_test.tscn`
- `res://tests/phase_45_3_human_combat_resonance_choice_test.tscn`
