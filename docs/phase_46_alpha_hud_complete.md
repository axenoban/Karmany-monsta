# F46 - HUD Alpha completo

## Objetivo

Eliminar la dependencia del backend, consola y controles de depuracion para jugar la partida humana. La F46 no modifica reglas: proyecta el estado real de `KarmanyFullMatchSession` y convierte sus `ChoiceRequest` humanos en controles visibles.

## Arquitectura

La fase se implementa como una capa de presentacion sobre el baseline F38/F45 aprobado:

- `KarmanyPhase46AlphaHudBridge`: read model de solo lectura. Reune la informacion critica sin duplicar estado de juego.
- `KarmanyPhase46ChoiceRouter`: adapta las solicitudes humanas del FullMatchSession a un formato comun de HUD y devuelve las elecciones al resolver canonico correspondiente.
- `KarmanyPhase46AlphaHudController`: HUD visible, inspector contextual, historial y panel de decisiones.
- `phase_46_alpha_hud_prototype.tscn`: escena jugable que conserva el tablero F38 y sustituye sus controles Alpha obsoletos.

No se introducen costes, recompensas, efectos, objetivos, cartas ni reglas nuevas.

## Informacion critica visible

El HUD muestra durante PLAYING:

- ronda;
- acciones restantes;
- jugador activo y si corresponde al turno humano;
- MN, MR, EK y FA de P1;
- PL de P1;
- nivel del Libro;
- posicion y zona actual;
- textos publicos de efecto de la zona actual;
- Karmany activo y poder;
- cuatro Objetivos Publicos con estado de reclamacion;
- Mision secreta del propio P1 y su estado;
- mano de Resonancias;
- Equipos del jugador;
- las cuatro cartas visibles del mercado de Equipo;
- los cuatro participantes y su PL en el read model;
- ultimos eventos del `alpha_log` de la partida completa.

La informacion secreta de otros jugadores no se expone.

## Decisiones humanas

`KarmanyPhase46ChoiceRouter` respeta esta prioridad de solicitudes pendientes:

1. recompensa de victoria contra Aeterna;
2. descarte de recursos por derrota contra Aeterna;
3. descarte de Resonancia de Aeterna;
4. lanzamiento de Dado de Instinto;
5. Resonancia/Sin Resonancia de combate;
6. descarte por limite de mano;
7. eleccion de accion legal general.

Mientras una consecuencia prioritaria esta pendiente, el HUD no fabrica una accion alternativa. La resolucion vuelve a los metodos `resolve_human_*` ya aprobados en F45.

El descarte de recursos de Aeterna admite seleccionar mas de una unidad del mismo tipo cuando el inventario real lo permite. La recompensa de Equipo ancestral conserva la seleccion de reemplazo cuando el inventario esta lleno.

## Inspector y ayuda contextual

El HUD incorpora inspector modal para:

- loseta actual;
- Karmany activo;
- Resonancias de la mano;
- Equipos propios;
- Equipos del mercado visible.

Los botones de cartas y decisiones exponen `tooltip_text` con sus reglas o contexto. Esta fase prioriza legibilidad y funcionalidad; arte final, animacion, audio y polish pertenecen a F50.

## Compatibilidad

- El tablero 3D y la infraestructura F38 permanecen intactos.
- Los controles Alpha anteriores de F36/F38 se ocultan en la escena F46 para evitar dos fuentes de input simultaneas.
- `KarmanyFullMatchSession` sigue siendo la unica fuente de verdad.
- IA/Auto-P1 no se reinterpreta.
- F45.1-F45.5 conservan sus requests y resolvers; F46 solo los presenta.
- El overlay de setup F38 se mantiene para iniciar la partida y el overlay de resultado F38 conserva prioridad visual sobre el HUD F46.

## Pruebas

### Read model

`res://tests/phase_46_alpha_hud_bridge_test.tscn`

Valida que todas las familias de informacion obligatoria esten disponibles y que los inspectores consuman datos reales.

### Choice router

`res://tests/phase_46_choice_router_test.tscn`

Valida accion humana general y ciclos de Aeterna, incluida recompensa de Resonancias y descarte de recursos elegido por P1.

### Escena integrada

`res://tests/phase_46_alpha_hud_scene_test.tscn`

Valida montaje real sobre F38, sustitucion de controles Alpha anteriores, presencia de paneles criticos y creacion de un ChoiceRequest jugable durante el turno humano.

## Regresiones requeridas

Ademas de las tres pruebas F46, mantener:

- `res://tests/phase_45_5_human_aeterna_decisions_test.tscn`
- `res://tests/phase_45_5_aeterna_post_choice_flow_test.tscn`
- `res://tests/phase_45_4_human_instinct_roll_test.tscn`
- `res://tests/phase_45_3_human_combat_resonance_choice_test.tscn`

## Criterio de salida

F46 puede aprobarse cuando la escena integrada permite consultar la informacion critica y resolver las decisiones humanas sin depender del Output de Godot ni de controles de depuracion. La validacion visual debe comprobar que la informacion se mantiene legible a la resolucion Alpha actual antes de avanzar a F47 (guardado/carga).
