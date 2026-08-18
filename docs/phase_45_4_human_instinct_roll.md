# F45.4 - Tirada humana del Dado de Instinto

## Objetivo

Materializar en el flujo humano explicito la secuencia canonica del Dado de Instinto antes de elegir Resonancia, sin alterar el calculo de combate ni la automatizacion usada por IA/Auto-P1.

La secuencia humana queda:

`Elegir combate PvE -> lanzar Dado de Instinto -> fijar ajuste de Defensa -> elegir Resonancia o Sin Resonancia -> ejecutar combate`.

## Base canonica v0.74

El Dado de Instinto usa un D6 con esta tabla:

- 1: -2 Defensa;
- 2: -1 Defensa;
- 3: +0 Defensa;
- 4: +0 Defensa;
- 5: +1 Defensa;
- 6: +2 Defensa.

Se lanza despues de declarar el combate y antes de elegir Resonancia. Se usa contra Bestias, Jefes, Aeterna y Karmany no vinculados enfrentados por combate. No se usa en PvP ni contra Karmany controlados por jugadores.

F45.4 materializa esta frontera para `FIGHT_BEAST` y `BOND_COMBAT`. Los Jefes resueltos por la familia `FIGHT_BEAST` quedan cubiertos por la misma arquitectura.

Aeterna conserva temporalmente su ruta previa y se reserva para F45.5, evitando mezclar en esta subfase las decisiones del climax.

## Arquitectura

Se agrega `KarmanyInstinctRollRequest` como solicitud one-shot de tirada. La UI futura no entrega un resultado elegido por el jugador: solo solicita resolver la tirada y `KarmanyFullMatchHumanInstinctRollSession` obtiene el valor desde `_action_rng`.

La solicitud conserva:

- jugador;
- ronda;
- acciones restantes;
- tipo y etiqueta de accion;
- coordenada objetivo;
- resultado D6 resuelto;
- ajuste de Defensa derivado por `KarmanyCombatResolver.get_instinct_adjustment()`.

`KarmanyFullMatchHumanInstinctRollSession` se inserta entre `KarmanyFullMatchHumanCombatChoiceSession` y `KarmanyFullMatchResultSession`.

F45.3 recibe un unico hook protegido, `_begin_human_combat_decision()`, que conserva exactamente su comportamiento anterior. F45.4 lo extiende para interponer Instinto solo en los combates que lo requieren. Esto evita duplicar el resolver de Resonancias y mantiene la prueba F45.3 como regresion directa.

## Flujo humano

Al declarar `FIGHT_BEAST` o `BOND_COMBAT`:

1. se elimina cualquier Resonancia preseleccionada por la construccion IA/legacy;
2. se neutraliza la tirada de Instinto preconstruida;
3. se crea `KarmanyInstinctRollRequest`;
4. no se consume accion;
5. `resolve_human_instinct_roll()` genera exactamente un D6 usando el RNG de la partida;
6. el valor se inyecta en el mismo campo que ya consumen los resolvers existentes;
7. solo entonces F45.3 abre la seleccion de Resonancia;
8. el combate se ejecuta despues de cerrar esas decisiones.

Si una accion `FIGHT_BEAST` necesita revelar una Bestia antes del combate, el objetivo se materializa al declarar la accion y antes de la tirada, evitando lanzar Instinto contra una identidad todavia inexistente.

## PvP

PvP no abre `KarmanyInstinctRollRequest`.

Su flujo sigue siendo el de F45.3:

`Elegir PvP -> elegir Resonancia del atacante humano -> resolver`.

No se modifica la automatizacion legacy de la Resonancia del defensor IA.

## Compatibilidad

No se modifican:

- `KarmanyCombatResolver`;
- la tabla ni el efecto del Dado de Instinto;
- `run_automated_current_turn()`;
- `execute_human_special()`;
- la seleccion automatica usada por IA/Auto-P1;
- PvP;
- la resolucion de Aeterna.

La ruta automatica sigue usando los candidatos preconstruidos como antes. La nueva pausa existe solo en el flujo humano explicito basado en `ChoiceRequest`.

## Prueba F45.4

`res://tests/phase_45_4_human_instinct_roll_test.tscn` valida:

- rango D6 1..6 y mapeo canonico -2/-1/0/0/+1/+2;
- solicitud one-shot y rechazo de resultados fuera de rango;
- Bestia: accion -> Instinto -> Resonancia -> ejecucion;
- no consumo de accion durante Instinto ni durante la seleccion de Resonancia;
- eliminacion de la tirada automatica preconstruida en el flujo humano;
- Vinculo por combate: Instinto antes de resolver;
- PvP: ausencia total de Dado de Instinto;
- Aeterna: no se incorpora a la frontera F45.4;
- `KarmanyFullMatchSession` hereda la nueva API sin perder F45.3 ni la ruta automatica.

Como regresion protegida debe seguir pasando tambien:

`res://tests/phase_45_3_human_combat_resonance_choice_test.tscn`.
