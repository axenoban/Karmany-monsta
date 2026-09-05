# F47.1 — Auditoría de persistencia actual

> Estado: **READY_FOR_VALIDATION**, pendiente de “prueba correcta”.
> Fecha: 2026-09-05 (America/La_Paz).
> Baseline auditado: `origin/dev/karmany-core` = `f8d0faae94279e906857bbcdb7a2db2bcd025263`.
> Rama: `feature/f47-1-save-persistence-audit`.
> Motor ejecutado: `4.7.1.stable.official.a13da4feb`.
> Alcance original: auditoría, diagnóstico automatizado, instrucciones operativas y metadatos. **No se implementa F47.2 ni se modifica gameplay.** La adenda §14 registra la corrección UI F46 solicitada después de la validación manual.

## 1. Conclusión y evidencia decisiva

F26 es reutilizable como servicio de captura/restauración de subsistemas, pero **no constituye un save de FullMatch F46**. Hay pérdidas de contenido incluso antes de considerar decisiones pendientes. Una restauración fallida puede modificar la sesión destino. No se debe conectar el botón Continuar directamente al servicio actual.

Evidencia obtenida en este workspace, sin sustituir código de gameplay:

| Evidencia | Resultado | Implicación |
|---|---|---|
| F26, escena histórica completa | Contrato funcional OK, sin errores de cierre en esta ejecución | Preservar esta prueba; su fixture F24 no representa FullMatch actual |
| FullMatch, seed `470047`, contexto F26 | 27 Resonancias de mano/robo sin `resource_path`; robo de 19 cartas se serializa como 4 | `_capture_resource_array` omite silenciosamente objetos generados |
| Misiones del mismo setup | Dos entradas con `data=""` | `load("")` falla en `_restore_objectives_missions`; hay definiciones generadas en memoria |
| Restauración completa intentada con claves de mazos normalizadas | `false`; mazo destino ya reducido de 19 a 4 | El fallo no revierte las mutaciones previas |
| BoardState restaurado | 36 celdas ocultas pierden `structural_level` y quedan en `-1` | El snapshot no representa toda la estructura MAP41 |
| Snapshot deliberadamente inválido: tablero vacío tras jugadores válidos | `restore=false`; MN destino conserva el valor introducido por el snapshot | Reproducción independiente de mutación parcial, sin errores de ResourceLoader |
| Contexto directo con `beast_decks_by_tier` | Error runtime `String(int)` en captura/restauración | F26 espera claves convertibles mediante `String`; FullMatch usa tiers enteros |
| Shell real en PLAYING | 0 instancias de `KarmanyPhase46AlphaHudController` | La escena F46 y la ruta del shell son montajes distintos en este baseline |

La sonda original `.godot/f47_1_audit_probe.gd` fue creada durante esta auditoría, no era código del propietario. Sus hallazgos se conservan aquí; sus tres defectos aislables se formalizan en `tests/phase_47_1_persistence_diagnostic_test.{gd,tscn}`. Se retira la sonda temporal antes del commit final. El diagnóstico formal caracteriza **gaps conocidos**, no exige que una implementación futura los conserve: F47-A debe sustituir esas expectativas por invariantes de conservación y atomicidad al cerrar cada gap.

## 2. Baseline, instrucciones y arqueología Git

Se verificaron estado, remoto, rama, fetch, SHA local/remoto e historia antes de modificar archivos; se volvió a hacer fetch al recibir la instrucción de continuación. El remoto es `https://github.com/axenoban/Karmany-monsta.git`; `dev/karmany-core` no avanzó respecto al SHA anterior. No se clonó otra copia ni se alteraron `main` o `dev`.

El worktree inicial no tenía modificaciones seguidas. Había 42 `.gd.uid` sin seguimiento correspondientes a scripts F44–F46 ya versionados; anteceden a esta auditoría. No había `AGENTS.md`, `CODEX.md`, `CLAUDE.md`, `.codex/` ni `.agents/` de instrucciones en el proyecto. No se encontraron instrucciones superiores en los paths de ancestros inspeccionados. Se crea `AGENTS.md` con reglas ya aprobadas. El conflicto documental encontrado fue el estado obsoleto de aprobación del Roadmap; se corrige sin cambiar decisiones funcionales.

La rama histórica `origin/feature/phase-47-save-load-continue` permanece **ARQUEOLOGÍA TÉCNICA**, no baseline ni autorización. HEAD `6582b6b9164d1abfa4de82cc2f1f0392322a0ed0`; ancestro común con dev `61012b1946b3b4f1672a09fa7dd4e1fc31a17921`. Se inspeccionaron sus cinco commits y el contenido final de sus cuatro archivos:

| Commit | Aporte inspeccionado | Disposición |
|---|---|---|
| `4cb0a06` | Adaptador FullMatch sobre Service F26; overlay de sesión, RNG, IA y decisiones | Reutilizar idea de adaptador, no copiar como solución validada |
| `40fb504` | Fachada de archivo, save/load/continue, ruta por defecto | No adoptar slot/ruta/política como decisión de producto |
| `8339c66` | Corrección de getters/openers Aeterna y firmas de rehidratación | Referencia para contratos F45; no resuelve pérdidas de F26 |
| `1ec253c` | Tests de request inicial, RNG, archivo y rollback | Casos útiles, pero no prueban todas las decisiones ni continuación hasta FINISHED |
| `6582b6b` | Escena ejecutable de ese test | Convención aprovechable; test no ejecutado en este baseline porque sus clases no están integradas |

Limitaciones demostrables de aquella implementación: mantiene tiers enteros al construir contexto; delega rutas de contenido, BoardState y fallos parciales al mismo F26; no captura asignaciones ocultas ni `_used_round_keys`; su rollback depende de un snapshot igualmente incompleto y no comprueba el resultado del segundo restore. Los descriptores de candidatos conservan tipo/destino/índice/etiqueta, no todo el payload ni sus valores aleatorios previos. Restaurar el estado RNG posterior a crear candidatos y regenerarlos desde ahí no recupera automáticamente los valores ya generados. El test compara descriptores de UI y el próximo RNG, no todos esos payloads. Ningún merge, rebase o cherry-pick de esta rama forma parte de F47.1.

## 3. Arquitectura F26 y mapa actual

### 3.1 Contrato histórico

- `scripts/save/save_game_context.gd`: referencias a BoardState, TurnManager, 2–4 PlayerState, mazos, mercado, PL, Objectives/Missions, MatchCoordinator y Dorian opcional. Valida existencia/tipos básicos, no coherencia completa.
- `save_game_service.gd`: `FORMAT_ID="karmany_monsta_save"`, versión `1`; diccionarios/arrays JSON. Recursos por `resource_path`; StringName a String, Vector2i a `[x,y]`; RNG de mazos/mercado como string decimal para conservar precisión entera.
- `save_game_facade.gd`: reutiliza el servicio y añade `trainer_runtime.dorian_pvp_used`. Llamar directamente a Service no conserva esa extensión.
- `scripts/ui/phase_26_save_bridge.gd`: escena F24 nueva, contexto de dos jugadores y mazos `basic`/`complex`; refresco visual de tablero/P1/HUD después de cargar. Archivo técnico `user://karmany_phase26_save.json`.
- `scripts/vertical_slice/vertical_slice_save_support.gd` y `vertical_slice_session.gd`: reutilizan Facade con contexto F24. `load_slice()` restaura sobre referencias existentes; no es una arquitectura alternativa para F46.

No existe un documento de fase F26 dedicado en `docs/` del baseline. Se usa como evidencia primaria el código, el test y las referencias F26 del Roadmap; no se inventa documentación histórica.

La captura incluye `turn`, `board`, `players`, `resonance_deck`, `equipment_market`, `beast_decks`, `legacy_points`, `objectives_missions`, `coordinator`; Facade agrega `trainer_runtime`. La restauración modifica, en orden: jugadores → tablero → mazo de Resonancias → mercado → mazos de Bestias → PL → objetivos/misiones → coordinador → turno. Si terminó la partida, recalcula `coordinator.final_evaluation`. Requiere un contexto previamente construido; no crea una FullMatchSession.

`is_supported_snapshot()` comprueba formato, versión y presencia de tres claves. No comprueba exhaustivamente tipos, IDs, referencias cruzadas, conservación de cartas, límites o secretos. `_json_safe()` no es una garantía general de datos puros: los tipos no reconocidos se devuelven sin rechazo. `FileAccess.WRITE` escribe directamente el destino; no hay escritura atómica, validación integral previa ni recuperación transaccional. La política de producto ante corrupción sigue pendiente.

### 3.2 Fuente de verdad actual

```text
Main/GameShell → Phase41HumanSetupBridge → HumanSetupFlow
                                      → KarmanyFullMatchSession
                                        → MultiAiAlphaRuntime
                                          ├─ LocalMultiplayerSession / TurnManager / PL
                                          ├─ BoardState + Map41ContentSession privado
                                          ├─ MatchCoordinator / resolvers / mazos / mercado
                                          └─ AI controllers / cerebros / RNG

Escena F46 → Phase38FullMatchBridge → misma clase FullMatchSession
           → HUD bridge / choice router / presentation-safe controller
           → compuerta visual F35/F36
```

Cadena de herencia de la sesión: Base → Setup → ActionCore → Special → Action → HumanCombatChoice → HumanInstinctRoll → HumanAeterna → Result → FullMatchSession. Conserva autoridad de gameplay; el shell gobierna montaje/navegación.

`FullMatchSession.configure()` exige runtime nuevo de cuatro jugadores, MAP41, R1 y dos acciones. Aplica setup, siembra RNG, configura Interactuar universal, guarda servicio en metadata del coordinador, instala Callables de movimiento/exploración y conecta observadores. **No es un método restore**: invocarlo sobre estado cargado puede resetear inventarios/setup/trackers o rechazar la fase.

F41 detiene TurnManager antes de la elección, lo inicia provisionalmente al confirmar para aplicar F38, vuelve a detenerlo y solo abre PLAYING al pulsar Iniciar. Antes de confirmar no hay FullMatchSession. F42 no tiene Guardar/Cargar/Continuar; instancia `phase_41_human_setup_prototype.tscn`, que hereda la lógica bridge F38 sobre la escena F37. `phase_46_alpha_hud_prototype.tscn` monta su propia raíz F38 y los presenters F46. No se debe confundir compartir clase de sesión con compartir la misma raíz de UI. Resolver el montaje común pertenece a F47-B, sin alterar el HUD aprobado.

## 4. Matriz de persistencia

Leyenda: **P** = PERSISTENTE; **D** = DERIVADO; **T** = TRANSITORIO; **N** = NO SERIALIZABLE; **I** = IDENTIDAD LÓGICA REQUERIDA; **B** = BLOQUEO DE DISEÑO. I/B son etiquetas complementarias. Un objeto runtime puede ser N aunque sus datos sean P. “Sin cobertura de carga” no significa que no haya tests de gameplay. T26/T38/T42/T45/T46 remiten a las escenas exactas de §10; F44.x son tests de familia, inspeccionados por sus contratos/código relacionado, no ejecutados en esta auditoría.

| Elemento | Propietario runtime | Serialización F26 | Restauración F26 | Clase | Cobertura / gap / riesgo |
|---|---|---|---|---|---|
| MatchSession | FullMatchSessionBase y capas | No seed, estado, configured ni identidad humana | No crea/vincula sesión | P/I; configured D | T38 sin carga; desincronización SETUP/PLAYING/FINISHED; crítico |
| BoardState / tiles | BoardState._cells | coord, ruta tile, revealed, occupant, Bestia bloqueante | clear + add_cell + ocupantes/Bestia | P/I | T26; falta structural_level; diagnóstico F47.1; alto |
| MAP41 estructural | CanonicalMap41Layout + BoardCellState | No structural_level ni ID/versionado de layout | Nivel inferido solo si existe tile_data | D desde layout identificado; I | 36 niveles ocultos perdidos en seed probada; alto |
| Identidad lógica de losetas | Map41ContentSession._hidden_content/_fixed_content | No asignación oculta; solo tile público en board | No reconstruye content_session | P/I | F32/F40/F38 gameplay; seed sola depende de catálogo/generador; crítico |
| Revelación lógica | BoardCellState.revealed | Bool | set al crear celda | P | T26/T38; no equivale a publicación visual; alto |
| Revelación publicada | F35._visually_revealed_coords | Nada | Nada | D/T; B si se permite salvar durante presentación | T46 scene; evitar revelación prematura; crítico |
| Posición de jugadores | PlayerState.current_coord + board occupancy | Coord e ID unidad | setup_new_game y set_unit_occupant | P/I | T26; verificar bijección player/unit/celda F33–F46; alto |
| Participantes, unidades, starts | LocalMultiplayerSession | Players por orden; no arrays unit_ids/starting_coords | Asume objetos/cantidad preparados | P/I; starts D según modo | T38/T42; reconstruir bindings concordantes; alto |
| Ronda | TurnManager.current_round | Sí | Asignación directa | P | T26; rangos/coherencia parcial; medio |
| Turno/jugador activo | TurnManager.active_player_index, players | Índice; no contador independiente de turnos reglamentarios | Asigna players e índice | P | T26; orden de players importa; alto |
| Acciones restantes / running | TurnManager | Sí | Asignación y validación parcial al final | P | T26; no emitir turn_started que reinicie trackers; alto |
| Action usage | TurnManager._action_usage_this_turn | Pares action_id/count | Reconstruye diccionario | P/I | T26 Interactuar; faltan invariantes cruzadas; medio |
| Límites de entrada/exploración | FullMatchSession._turn_start_coord_by_player, _entry_bonus_coords_by_player, _entry_bonus_count_by_player, _explored_this_turn_by_player, _last_coord_by_player | No | No | P | T38 gameplay; reinicia bonus/Explorar si se pierde; alto |
| Recursos MN/MR/EK | PlayerState.resource_inventory | Array resources posiciones 0..2 | set_resource tras reset | P | T26; emisión de cambios durante restore; alto |
| FA | Mismo inventario, posición 3 | Sí, separada semánticamente de básicos | set_resource | P | T26; doble pago Aeterna si se reejecuta acción; crítico |
| PL | LegacyPointsController | Modo/mapa/límites, totales, entries con unique_key | configure + entries; deriva _unique_awards | P; índice D/I | T26; proteger premios pendientes y deduplicación; alto |
| Libro | Coordinator._book_states | player_id + level | BookProgressState nuevo | P/I | T26 Libro II; referencias viejas a books quedan stale; medio |
| Karmany activo | PlayerState.karmany_roster | Runtime ID, ruta, owner, bond_state; active ID | Runtime nuevo y set_active_karmany | P/I | T26 roster en round-trip; no reusar referencia de objeto; alto |
| Reserva | Mismo roster | Todos los vinculados, orden | add_linked_karmany | P/I | T26; activo/reserva D desde roster, no duplicarlos; medio |
| Encuentros | Coordinator.encounter_resolver | ID, data, coord, rango, revelador, pending_player, status, expiración, secuencia, last_calls | EncounterState nuevo y mapas | P/I | T26 encuentro; no representa elección humana de combate; alto |
| Bestias en tablero | BoardCellState.beast_state | Solo is_blocking: instance_id/data/coord/defeated | Runtime nuevo; solo bloqueantes se reinsertan | P/I; derrotada retirada T | T26; Instinto puede haber materializado Bestia antes de gastar acción; alto |
| Resonancias/definiciones | Catalog + Resources generados | Solo rutas no vacías | load(path) | P/I para identidad; definición D desde catálogo versionado | 27 sin ruta en fixture: pérdida real; crítico |
| Mano y orden | ResonanceHand | Rutas, hand_limit, pending count | Reconstruye cartas/límite/count | P/I | T26; descarta silenciosamente cartas generadas al capturar; crítico |
| Descartes | ResonanceDeck / EquipmentMarket / BeastDeck | Arrays de rutas | Reconstruye orden | P/I | T26 parcial; pérdidas de identidad y conservación de cantidades; alto |
| Resonancias en combate | Coordinator.resonance_usage_tracker._combat_users/_in_play | No | No clear/rehidratación explícita | T dentro de ejecución síncrona; P/I si se admite esa frontera; B | F13 gameplay; no declarar guardable una pila de ejecución; alto |
| Equipamiento | PlayerState.equipment_inventory | Rutas ordenadas | add_equipment | P/I | T26; modificadores D, reemplazo pendiente F45 aparte; medio |
| Mercado | EquipmentMarket | visible, draw, discard, RNG | Arrays y RNG; emite market_changed | P/I | T26; conservar índice exacto/premio ancestral; alto |
| Crafting de Equipo | EquipmentCraftResolver/Context | Resultado ya aplicado vía recursos, inventario, mercado, acciones | Restaura esos datos, no ejecuta craft | P para resultado; contexto N/D; ejecución T | F12, T38; no nueva cola async hallada; replay duplicaría pago |
| Resonancias creadas/crafteadas | Catalog.build_full_resonance_pool | Objetos new sin ruta se omiten | No resolutor por resonance_id | P/I | Generación de catálogo sí existe; no se encontró sistema separado de crafting de Resonancias; no inventarlo |
| Forja/límite conversión | Coordinator.forge_controller._conversion_used_by_player | forge_usage | Diccionario StringName/bool | P | T26 captura; prueba focal F12/F38 futura para límites; medio |
| Objectives | ObjectiveMissionManager._objective_states | Ruta, claimant y ronda | configure + asignación de claims | P/I | T26 round-trip; selected_public_objectives de sesión no se sincroniza; alto |
| Secret Missions | Manager._mission_assignments + runtime.mission_by_player | Ruta, estado, completed_round, reward pending | load y assign_secret_mission | P/I; espejo runtime D | T26 fixture por ruta; dos misiones generadas fallan; privacidad + identidad; crítico |
| Progreso y premios | ProgressTracker / manager._pending_legacy_rewards | Eventos/payload, estados, premios/consumed | Reconstruye tracker y objetos premio | P/I | T26 round-trip; validar datos puros y no registrar eventos otra vez; alto |
| Missions completadas de sesión | FullMatchSession.completed_mission_players | No | No | D de assignments si contrato equivalente | T38 ranking; reconstrucción debe mantener desempates, no replay de signal; alto |
| Trainers/asignación/setup | FullMatchSession.trainer_by_player, starting_karmany_by_player, setup_choices_by_player, forced_starting_choice_by_player | No | No | P/I; proyecciones D | T38/F41; no volver a repartir al cargar; alto |
| Dorian histórico | DorianPvpController opcional | Facade: _used_round_by_player | clear + mark_special_pvp_used | P | T26 sí; FullMatch actual no posee ese controlador, F44.7 excluye activa/passiva pendientes; no inventar su activación |
| Runtimes especiales F44 | KarmanyAbilityRuntimeService._used_round_keys (static) | No | No | P/I; clave ObjectID N | F44.2/2b/2c; usos por ronda se pierden al recrear TurnManager; crítico |
| Otros servicios F44 | Beast/Equipment/Resonance/TrainerAbilityRuntimeService | No instancia persistida | Funciones/CONTRACTS reconstruibles | D/N | F44.3–7; no inventar trackers para hooks aún PARTIAL/DATA_ONLY |
| PvP y tregua | Coordinator.pvp_truce_tracker | last round por pareja | Diccionario string/int | P/I | T26 vía coordinator; atacante humano pendiente no capturado; T45.3 protege gameplay |
| Aeterna global | Coordinator.aeterna_state | defeated/by/round, attunement, sync, post_ek | reset + campos | P/I | T26 estructura; distinto de AeternaResult/consecuencias F45; crítico |
| Aeterna pendiente | HumanAeternaSession + AeternaResult | Nada salvo descarte genérico de mano | No | P/I; objetos N | T45.5/T46 router; pérdida de premio/recursos/prioridad; crítico |
| Mazos Bestia por tier | MultiAiAlphaRuntime.beast_decks_by_tier | tier, draw/discard, RNG; key con String(deck_id) | Busca mismas keys | P/I | T26 keys string; keys enteras actuales producen error; alto |
| Karmany pools | MultiAiAlphaRuntime.karmany_pools_by_rank | No | No | D de catálogo ordenado; selección RNG P | Se eligen dos por _content_rng, no mazo consumible; conservar orden de pool/versión; alto |
| RNG de sesión/contenido/IA | _setup_rng/_action_rng/_content_rng; AiBrain.rng | No | No | P (estado); objeto RNG N | T38 determinismo inicial, sin carga; seed sola insuficiente; alto |
| RNG de mazos/mercado | Sus _rng | String decimal state | int(String(...)) | P | T26 igualdad snapshot; probar próximo robo/reciclado tras disco; alto |
| Memoria/perfil IA | AiBrain.profile, _last_executed_signature, _same_action_streak | No | No | P para decisiones; controllers D/N | F25/F34/F36 gameplay; reanudar IA podría elegir distinto; alto |
| ChoiceRequest y candidatos | Capas ActionCore/Human* | No requests, contadores ni payloads | No | P/I para etapa/datos; objeto N | T45 one-shot; ver §7; crítico |
| Setup humano no confirmado | HumanSetupFlow: plan/candidatos/selección/confirmed/setup_state | No | No | P/I si guardable; selección sin confirmar T; B | F41/T42; sin FullMatch antes de confirmar; política pendiente |
| Resultado | FullMatchResultSession.final_result; coordinator.final_evaluation | Solo coordinator.is_finished + PL | Recalcula evaluación histórica; no final_result actual | D de gameplay/estadísticas; fase P; B para continuar FINISHED | T38/T42; no emitir otra victoria/contabilizar partida dos veces |
| Log/estadísticas | Session.alpha_log/statistics | No | No | statistics P para resultado; log T o P opcional/B | T38 log y resumen; no regenerar efectos para reconstruir historial |
| Restart/nueva | GameShell._destroy_active_match/start_new_match | No | F26 instancia otro prototipo | T comando; raíz N | T42 restart; nueva debe nacer limpia, no restaurar setup sobre sesión antigua |
| Shell/navegación | app_state/current_seed/final_result/referencias | No | No API de montaje de save | D desde estado validado; referencias N | T42 sin carga; integrar flujo real F41 + F46 en F47-B |
| HUD/inspectores/controladores | F46 bridge/router/controller/presenters | get_snapshot es read model, no formato save | Sin contrato load; configure y render | D/N | T46; texto, selección parcial, scroll y firmas de refresh T; no serializar UI |
| Animaciones/colas/temporizadores | F35/F38/presentation feedback | No | No | T/N; barrera visible B | T42/T46; cancelar trabajo antiguo y mantener secreto antes del primer frame |

## 5. Diferencias F26 → F46 y gaps cerrados por esta auditoría

Inventario de gaps (cerrado como identificación, **abierto como implementación**):

1. **G01 Identidades:** Resource sin ruta, contenido seleccionado por subconjuntos runtime y versiones de catálogo. Afecta cartas/mazos/misiones; no basta incorporar `.uid` de scripts.
2. **G02 MAP41:** nivel estructural, asignación oculta/fija y correspondencia con BoardState; evitar regeneración distinta o publicación de secretos.
3. **G03 FullMatch:** fase/seed/roles/orden, setup confirmado, trackers por turno y resultado/estadísticas/espejos.
4. **G04 RNG/IA:** estados exactos y memoria estratégica; distinguir generar opciones de ejecutar una elección.
5. **G05 Choices:** etapa, referencias lógicas, candidatos pendientes, dado ya lanzado, prioridad e idempotencia.
6. **G06 Uso especial:** clave estable para habilidades F44 por ronda y ámbitos de combate; no ObjectID como identidad guardada.
7. **G07 Adaptación F26:** tiers enteros, referencias cruzadas, missing fields, alias como `legacy_mode_config` local frente al objeto reconstruido del controller.
8. **G08 Atomicidad/validación:** fallo parcial, señales visibles durante carga, contenido/campos malformados, ausencia de rollback fiable.
9. **G09 Shell/F46:** carga/navegación/montaje del HUD común aún no existen; presentación protegida al reconstruir.
10. **G10 Archivo/compatibilidad:** formato, migración, rutas de archivo, escritura robusta y comportamiento ante error sujetos a contrato/política.
11. **G11 Lifecycle:** teardown visual existente más liberación del grafo RefCounted, estáticos y Callables; diagnósticos de cierre presentes.

F27 introduce performance (métricas T); F28–F30 reutilizan F26 con vertical slice/onboarding/telemetría (progreso pedagógico no equivale a partida); F31–F37 añaden MAP41/contenido oculto/cuatro jugadores/IA/presentación; F38 añade FullMatch y límites/resultado; F39–F40 amplían Interactuar y catálogo; F41–F42 añaden setup y shell; F43–F44 reconcilian contenido y hooks/runtime especial; F45 añade fronteras humanas; F46 presenta esas fronteras. La presencia de archivos canónicos completos no significa que `get_runtime_*` use todos: el catálogo F38 todavía fabrica Resonancias textuales y Misiones cuando faltan en el subconjunto activo.

## 6. Identidad y restauración transaccional propuesta

### 6.1 Identidades estables

Propuesta técnica para F47-A: mantener un solo sistema de persistencia, evolucionando Context/Service/Facade y añadiendo una adaptación FullMatch acotada. No adoptar automáticamente el segundo envelope de la rama histórica ni elegir aquí el número de nueva versión.

Cada referencia guardada necesita identidad de **definición** (`resonance_id`, `mission_id`, `tile_id`, etc.) distinta de identidad de **instancia** (Karmany vinculado, Bestia concreta, carta si algún contrato permite copias). Resolver contra el catálogo y factories vigentes; fallar si falta/duplica un ID o la definición no corresponde al contrato de contenido. No cargar rutas arbitrarias como sustituto de una validación de catálogo.

Las Resonancias generadas de `RESONANCE_DEFINITIONS` y Misiones `_build_maelis_first_mission/_build_saira_first_mission` deben reconstruirse por su identidad y origen/factory versionado, preservando el comportamiento actual. Cambiarlas indiscriminadamente por Resources de `canonical_pending` podría alterar reglas/eligibilidad. No se encontró crafteo separado de Resonancias: si una futura creación aprobada produce variantes, harían falta definición base, identidad de instancia y parámetros estables, nunca serializar el objeto o inventar una receta. El crafting actual de Equipo retira una carta visible y modifica recursos/inventario/mercado; cargar debe restaurar el resultado, no volver a pagar ni volver a craftear.

Para MAP41, conservar asignación privada por coordenada e identidad de contenido, o un contrato determinista de generador/catálogo que demuestre la misma asignación. Recomendación: guardar asignaciones explícitas y validar layout/fingerprint; la seed queda como procedencia, no único respaldo. No exponer este bloque a snapshots públicos/HUD. Los IDs de losetas no sustituyen coordenadas porque puede haber repetición por fallback.

RNG: guardar estado como string decimal, junto con parámetros requeridos por el contrato, restaurarlo sin consumirlo y comprobar próximo resultado. Orden de cada draw/discard/visible/hand y del conjunto de opciones debe ser explícito. Los IDs opacos de una elección dependen de contador y orden; no recalcular opciones con efectos aleatorios no controlados. El RNG ya consumido para una opción y el resultado humano de Instinto pendiente de combate son datos distintos.

### 6.2 VALIDATE → BUILD/RESOLVE → COMMIT

**Sí, F47.2 necesita una restauración transaccional o equivalente.** Motivo: `_restore_players` modifica objetos antes de `_restore_board`, y la secuencia continúa alterando mazos antes de descubrir Misiones inválidas. Capturar el mismo formato incompleto como rollback no recupera cartas omitidas, RNG/choices ni señales ya observadas.

Recomendación, aún no implementada:

1. **VALIDATE:** analizar JSON sin mutar la sesión activa; validar esquema/tipos/rangos/versión y IDs; comprobar cantidad/orden de participantes, coordenadas/ocupación, inventarios, mazos, estado de turno, premios y etapas. No aceptar defaults silenciosos que conviertan corrupción en nueva partida.
2. **BUILD/RESOLVE:** construir un grafo candidato aislado y resolver todos los IDs; restaurar datos del contexto F26 y overlay FullMatch, RNG, límites y decisiones sin ejecutar setup/recompensas/acciones de nuevo. Reconciliar alias (players, modo, misiones, objetivos, books, coordinator), reponer Callables/meta/observadores mediante una frontera de binding. Toda referencia debe apuntar al grafo candidato.
3. **COMMIT:** solo si todo es válido, intercambiar la sesión y montar la presentación con input/IA todavía controlados. Emitir notificación de estado restaurado, no eventos históricos de gameplay. La sesión anterior permanece utilizable si falla validar/construir. El teardown antiguo y el primer frame nuevo deben ser explícitos; no capturar callbacks o Signals en JSON.

La atomicidad pertenece ya a F47-A como contrato del núcleo. F47-B materializa intercambio de raíces/UI y archivo; F47-C prueba repetición/limpieza. Si se elige mutar in-place, debe probar equivalencia total ante fallo de cada etapa y no publicar efectos intermedios; el código actual no lo demuestra. Esta recomendación reversible de diseño se entrega para validación; no se impone una arquitectura pública irreversible.

## 7. ChoiceRequest: qué se pierde y qué debe preservarse

F26 no rechaza explícitamente una elección pendiente: ni siquiera conoce esos campos. Si se adapta un contexto y se guarda, los datos de las requests no entran en el snapshot. Cargar a una sesión nueva las pierde; cargar in-place puede dejar candidatos/requests apuntando a objetos anteriores o invalidarlos por cambios de mano/presupuesto. El router puede fabricar una acción general cuando falta la request; las rutas legacy/Auto-P1 pueden auto-resolver donde la humana debería esperar. Son riesgos derivados del código, no una API de carga F46 ya existente.

| Frontera humana | Ya aplicado antes de esperar | Datos estables necesarios / acción prohibida al restaurar |
|---|---|---|
| Acción general (`ChoiceRequest`) | Generación de candidatos puede consumir RNG; no la acción elegida | ID/contador, jugador/ronda/presupuesto, opciones ordenadas y descriptores completos. No regenerar resultados aleatorios ni resolver primera opción |
| Descarte por límite de mano | Última acción ya gastada; mano overflow y pending_count; turno humano con 0 acciones | Mano exacta/orden, cantidad, request/option IDs. No auto-descartar, cambiar turno o duplicar descarte |
| Instinto humano Bestia/vínculo/Aeterna | Acción declarada; tirada legacy neutralizada; Bestia puede haberse sacado del mazo | Tipo/destino/identidad objetivo, candidato pendiente, RNG, etapa “sin lanzar”. No sacar otra Bestia ni lanzar D6 al cargar |
| Resonancia de combate | Instinto PvE ya lanzado; PvP no lo usa; acción aún no ejecutada | D6 resuelto, candidato completo, mano snapshot, opciones válidas y opción explícita “Sin Resonancia”. No relanzar dado ni conservar selección legacy del atacante |
| Sin Resonancia confirmada | Resolver actual aplica elección y ejecuta sin un await intermedio | No tratar ausencia de ID como request sin respuesta; distinguir fase elegida/acción completada si se admite una frontera interna |
| Victoria Aeterna: elección de recompensa | Combate, coste y 8 PL aplicados por resolver; recompensa pendiente | AeternaResult lógico (status/outcome, action_consumed, fa_spent, reward flags, cantidades/IDs), mercado y equipo actuales. No repetir combate/premio fijo |
| Premio de Resonancias Aeterna: descartar una de tres | Tres cartas ya robadas; reward_resolved y descarte pendiente | `_pending_human_aeterna_reward_drawn_ids` exactos; solo esas cartas elegibles. No robar otra vez ni ofrecer la mano previa |
| Premio ancestral Aeterna con inventario lleno | Antes de confirmar no se entrega Equipo; UI recoge reemplazo | Request ligada a cartas/índices visibles y equipo poseído; selección UI no confirmada es T. Confirmar solo una vez; no pagar crafting |
| Derrota Aeterna: recursos | Combate/coste/retroceso ya aplicados; recursos por elegir | Cantidad pendiente + snapshot de recursos; admite unidades repetidas. No cobrar de nuevo ni convertirlo en descarte de mano ordinario |
| Derrota Aeterna: Resonancia | Recursos resueltos si correspondían; Resonancia pendiente | AeternaResult y etapa restantes, IDs elegibles, pending_count; luego límite de mano general si corresponde |
| Setup inicial | Entrenador/3 candidatos privados; todavía sin FullMatch antes de confirmar | Plan/elección/fase si guardar setup se aprueba; no confirmar automáticamente ni redeal |

Prioridad F46 (`phase_46_choice_router.gd:get_pending_choice`): **premio Aeterna → recursos Aeterna → Resonancia Aeterna → Instinto → Resonancia de combate → límite de mano → acción general**. La rehidratación no debe reducir todo a un pending_count. Preservar resultado pendiente aun si un getter devuelve null por contexto inválido: los getters F45 pueden limpiar referencias; capturar mediante getters mutantes sin validar el estado completo puede perder evidencia. No usar callbacks de resolución para construir una request.

`_explicit_human_aeterna_in_progress` es una bandera transitoria que rodea una llamada síncrona; no debe interpretarse como una fase durable verdadera por sí sola. `_last_human_instinct_result` sirve de presentación; el dado requerido para continuar debe vivir en el descriptor de combate. Las requests son objetos one-shot con snapshots de mano/recursos/mercado; reconstruir esos datos y el estado de consumo, no serializar `_candidate_by_option_id` con sus Resources/Callables/contextos.

No se inventan nuevas ventanas humanas: la defensa de P1 ante PvP iniciado por IA sigue automatizada según F45.3; mirar/reordenar mazos de Trainers y elecciones aún excluidas/automáticas de F44 no tienen una request guardable que haya que “restaurar”. Se registran como deuda runtime previa, no autorización de nuevas reglas en F47.

Pruebas objetivo: invalid ID no consume; resolver dos veces no altera estado; mismo jugador/ronda/acciones; mismo D6; misma Bestia; mismo PL/FA; premio/descartes una vez; prioridad intacta incluyendo descarte general posterior; requests inválidas no desaparecen silenciosamente durante captura/carga.

## 8. Presentación, teardown y referencias

Verdad lógica: BoardState/FullMatch. Verdad publicable: `Map41ContentSession.get_public_tile_data` y reglas de privacidad. Momento de publicación: F35/F36. Proyección: F46. `get_snapshot()` del HUD no contiene todo el estado privado y **no es un save**.

F35 `_seed_reveal_snapshots()` marca como visualmente publicadas las celdas lógicamente reveladas al inicializar. Cargar durante una animación y llamar ese método sin contrato de reconstrucción adelantaría información. F46 protege zona, efectos, historial, inspector y choices mediante la compuerta existente. Si se admite esa frontera de guardado, hará falta una barrera de publicación estable o reconstrucción de presentación que conserve lo aún no publicado. Alternativa: puntos autorizados después de cerrar presentación. La elección de cuándo se guarda es B, no una restricción ya aprobada.

No serializar Nodes, SceneTree, señales conectadas, Callables, Timers/Tweens, coroutines, objetos de escena, Resources completos ni `get_instance_id()`. Deben reconstruirse servicios y referencias a partir de datos estables. Identidades lógicas de partida/combatientes no equivalen a ObjectID.

Riesgos concretos y contratos a preservar:

- `_destroy_active_match()` F42 desconecta sus señales, detiene TurnManager, llama `begin_teardown()`, oculta/deshabilita raíz y hace `queue_free()` **dentro del árbol**. No volver a `remove_child()` antes de terminar awaits. F35/F38 tienen guards tras timers y desconexiones; reutilizarlos.
- `_restore_players()` borra roster/mano/inventarios; `_restore_board()` sustituye celdas/Bestias; coordinator sustituye books/encounters. Requests, HUD, visuales y candidatos antiguos pueden quedar stale aunque PlayerState siga siendo el mismo objeto.
- `_restore_resonance_deck()`/mercado emiten señales durante restore y managers se reconfiguran. Un consumidor no debe actuar sobre un estado a medio cargar. No duplicar conexiones ni disparar observers de scoring/setup.
- FullMatch referencia runtime; coordinator contiene el servicio de Interactuar vía metadata; el servicio contiene runtime/Callables hacia la sesión. Hay referencias de vuelta y Callables fuertes que requieren inspección de liberación. Esto es una hipótesis de retención compatible con el grafo, no una atribución definitiva de todos los leaks.
- `_used_round_keys` de Karmany es static, tiene claves basadas en TurnManager ObjectID y `clear_test_tracking()` no es teardown de producto. Limpiar globalmente puede afectar otra sesión coexistente; rehidratar las claves viejas no preserva su ámbito nuevo. Necesita contrato lógico por partida/jugador/habilidad/ronda sin cambiar la semántica aprobada (incluido el alcance actual de cada clave).
- La deduplicación histórica de PL reconstruye `_unique_awards` desde entries. Algunas claves de recompensa de Riesgo incluyen ObjectID del resultado; no reproducir una consecuencia usando un resultado nuevo y esperar que esa clave la deduplique.
- Tras cargar FINISHED, reconstruir resultado desde datos, sin reemitir premios, reiniciar rondas ni incrementar otra vez `completed_match_count`. La retención temporal de raíz en RESULT protege callbacks del frame final.

## 9. Compatibilidad y decisiones pendientes del propietario

F26 versión 1 solo acepta exactamente su versión; no hay migración pública prometida. Algunos datos ausentes de un save antiguo no se pueden inferir fielmente. Mantener su test histórico no obliga a prometer que una partida F24 de dos jugadores se transforme en FullMatch MAP41 de cuatro. No declarar compatible un archivo únicamente porque pasa `is_supported_snapshot()`.

### DECISIONES PENDIENTES DEL PROPIETARIO

| Decisión | Alternativas e impacto | Riesgo / recomendación técnica | Cuándo bloquea |
|---|---|---|---|
| D47-01 Cuándo se permite guardar | Fronteras estables de turno/acción; incluir choices humanos estables; incluir presentación en curso | Cada opción amplía estados requeridos. Recomendar choices estables incluidos y no capturar mitad de llamada síncrona; no adoptar aún como política | F47-A: contrato final de fronteras y gate F47.3; identidad/validación/RNG pueden avanzar independientemente |
| D47-02 Setup y resultado | Solo PLAYING; también setup sin confirmar; también FINISHED/historial | Setup requiere estado sin FullMatch; FINISHED no debe reejecutar final. Recomendar definir primero continuación de PLAYING y resolver explícitamente las otras dos fases | Cobertura pública F47-A/B |
| D47-03 Compatibilidad de saves históricos | Rechazo explícito; migración limitada de saves recuperables; soporte de escenarios históricos por su propio contrato | No inventar datos faltantes. Recomendar documentar límites y no prometer conversión F24→MAP41 | Versión/migración final y mensajes F47-B |
| D47-04 UX/slots/automatización | Uno o varios slots; manual/autosave/quicksave; menú final | Afecta propiedad del archivo y sobrescrituras. Recomendar núcleo sin asumir cantidad ni triggers | F47-B; no bloquea serialización en memoria |
| D47-05 Corrupción/backup | Conservar y rechazar; ofrecer backup validado; política de recuperación aprobada | No descartar último save válido ni “reparar” silenciosamente. Recomendar validar y conservar origen, escritura temporal/replace; retención de backups por aprobar | F47-B; atomicidad de restore ya es requisito técnico |
| D47-06 Cloud | Solo local o proveedor futuro aprobado | Proveedor/conflictos/privacidad fuera del núcleo. Recomendar diferir hasta decidir plataforma; no integrar cloud ahora | Solo si se amplía alcance; no bloquea F47 local |

Persistir el log completo es opcional y debe acordarse si la experiencia lo requiere; las estadísticas utilizadas en resultado sí necesitan conservarse o derivarse de evidencia completa. No se solicita aprobar otra vez el Roadmap. Esta auditoría y recomendaciones esperan validación; no se implantan decisiones pendientes.

## 10. Verificación exacta y resultados

### 10.1 Entorno y comandos

`project.godot`: `config_version=5`, features `4.7`, `Forward Plus`, Jolt, D3D12 Windows; entrada `res://scenes/app/main.tscn`. `godot --version` y `where.exe godot` no encontraron PATH. Se localizó el proceso/executable existente mediante consulta de procesos y búsqueda de archivo; no se instaló ni cambió versión.

```powershell
$godotExe = 'C:\Users\PC\AppData\Local\Temp\24dbcb81-d733-47a8-a73d-3d912e9f4e85_Godot_v4.7.1-stable_win64.exe.zip.e85\Godot_v4.7.1-stable_win64.exe'
& $godotExe --version
& $godotExe --headless --path C:\Users\PC\Documents\Karmany-Monsta --editor --import --quit
& $godotExe --headless --path C:\Users\PC\Documents\Karmany-Monsta res://tests/phase_47_1_persistence_diagnostic_test.tscn
```

Para las 13 regresiones se ejecutó el equivalente a:

```powershell
& $godotExe --headless --path C:\Users\PC\Documents\Karmany-Monsta "res://tests/$testName.tscn" --quit-after 240 --max-fps 60
```

La ejecución real usó `Start-Process -WindowStyle Hidden -Wait -PassThru`, redirigiendo stdout/stderr por test. `--quit-after 240` cierra escenas históricas que no llaman quit; **no convierte exit=0 en PASS**. Se revisaron marcador final, errores y stderr completos. No se alteraron waits, watchdogs ni asserts. Las escenas F45/F46 que llaman quit lo hacen antes de ese límite. Ruta del ejecutable en Temp no es instalación permanente: si Windows la limpia, localizar el instalado otra vez.

Primera importación bajo sandbox: exit=0 pero errores de permisos de editor/cache/user:// y certificados; clasificada **entorno**, no PASS. Repetición con permisos normales: exit=0, stderr vacío, sin parser errors. El test F26 escribe su ruta técnica; se respaldó el save preexistente y se restauró después. Logs locales: `%TEMP%\karmany-f47-1-audit\<testName>.stdout.log` y `.stderr.log` (no versionados).

### 10.2 Escenas y resultados

Todas las filas son `res://tests/<nombre>.tscn`. “Objetos/recursos” recoge literalmente la cantidad reportada al salir; **ERROR resources still in use no se rebaja a un simple PASS ni se oculta**.

| Nombre | Contrato funcional observado | Exit | Diagnóstico al cerrar (objetos / recursos) |
|---|---|---|---|
| `phase_26_save_system_test` | Nueva limpia, checkpoint, disco/versión, round-trip y acción tras cargar: OK | 0 | Sin diagnósticos |
| `phase_38_full_match_test` | 5 seeds, cuatro jugadores, ocho rondas, FINISHED/resultado/privacidad: OK | 0 | WARNING 1090 / ERROR 206 |
| `phase_42_game_shell_test` | MAIN_MENU→SETUP→PLAYING→RESULT→MAIN_MENU y raíz dentro del árbol hasta queue_free: OK | 0 | WARNING 360 / ERROR 183 |
| `phase_42_restart_match_test` | Partida A→resultado→B sin estado compartido y teardown visual: OK | 0 | WARNING 555 / ERROR 198 |
| `phase_45_1_choice_request_core_test` | Opción exacta, inválida, one-shot y legacy: OK | 0 | WARNING 333 / ERROR 181 |
| `phase_45_2_human_hand_limit_choice_test` | Mano exacta/descarte múltiple, pausa a 0 acciones y legacy: OK | 0 | WARNING 333 / ERROR 181 |
| `phase_45_3_human_combat_resonance_choice_test` | Sin Resonancia/ID, filtros Bestia/PvP y defensor legacy: OK | 0 | Sin diagnósticos |
| `phase_45_4_human_instinct_roll_test` | D6/one-shot, secuencia PvE, ausencia PvP: OK | 0 | Sin diagnósticos |
| `phase_45_5_human_aeterna_decisions_test` | Instinto especializado, ancestral visible gratis/reemplazo, recursos: OK | 0 | Sin diagnósticos |
| `phase_45_5_aeterna_post_choice_flow_test` | Premio roba 3/descarta 1 y derrota/continuación: OK | 0 | Sin diagnósticos |
| `phase_46_alpha_hud_bridge_test` | Snapshot e inspectores completos: OK | 0 | WARNING 333 / ERROR 176 |
| `phase_46_choice_router_test` | Acción general y consecuencias Aeterna: OK | 0 | WARNING 659 / ERROR 203 |
| `phase_46_alpha_hud_scene_test` | Montaje F46 sobre F38, layout/input y simulación reveal gate: OK | 0 | WARNING 333 / ERROR 176 |
| `phase_47_1_persistence_diagnostic_test` | KNOWN GAP: robo 19→4, dos misiones sin ruta, 36 niveles perdidos; carga rechazada MN 2→9 | 0 | WARNING 321 / ERROR 176; diagnóstico, NO round-trip aprobado |

F45.2 `.tscn` usa el runner heredado `phase_45_2_human_hand_limit_choice_test_runner.gd`; se inspeccionaron ambos scripts. Los tests T45 de componentes no sustituyen una prueba de cada pausa sobre una sesión restaurada real. T46 scene prueba geometría/compuerta programáticamente en headless; esto no es una validación visual humana de render D3D12 ni una prueba F46 dentro del shell.

Investigación del primer error de cierre: se repitió F45.1 con `--verbose` (sin `--quit-after`), reproduciendo 333 objetos y 181 recursos retenidos. El listado incluye RefCounted, RandomNumberGenerator, Resources y scripts; no es un parser error ni un assert funcional fallido. Su causa completa no queda demostrada por el listado, pero el grafo de referencias descrito en §8 exige pruebas de liberación. F47.1 no cambia gameplay para hacer desaparecer esa deuda; el nuevo diagnóstico también construye ese grafo y reporta su retención.

Sondas anteriores: el contexto directo produjo primero `String(int)` en `save_game_service.gd:355/366`; se normalizaron **solo las keys de la sonda** para aislar el siguiente defecto. Luego `_restore_objectives_missions` falló al cargar la primera misión sin ruta (`:523`), después de perder cartas. No se atribuye el resto de la carga a éxito: `restore=false` y requests/RNG observados tras ella no prueban por sí solos un round-trip. Su ausencia del formato también está confirmada por lectura de código. El test formal aísla captura, BoardState y fallo temprano y no necesita provocar esas excepciones del motor.

### 10.3 Pruebas requeridas para migrar

- Conservar F26 con fixture histórica y extension Dorian; añadir round-trip actual **a disco y en proceso nuevo** con todos los IDs/definiciones generadas, conteo y orden exactos (sin comparar únicamente una captura ya incompleta).
- Conservar T38/T42/T45/T46. Añadir F32/F40/F41 y familias F12/F13/F15/F16/F17/F18/F44 afectadas conforme al cambio, sin declarar aquí que se ejecutaron todas.
- MAP41: igualdad de niveles, asignaciones privadas, reveladas, ocupación y futuras revelaciones; UI no filtra identidad o misión rival.
- RNG/IA: siguiente D6, siguiente llamada Karmany, robo/reciclado/mercado y siguiente acción IA equivalentes a sesión control sin cargar; conservar memoria de repetición.
- Todos los pasos de §7, incluyendo recurso repetido de Aeterna, ancestral con inventario lleno, paso al descarte general y reenvío de selección consumida.
- G06: uso de habilidad antes/después de carga en el mismo proceso y en otro; no reset de uso por ObjectID nuevo ni contaminación de otra partida.
- Transacción: datos inválidos en cada sección, ID ausente/duplicado, versiones incompatibles, orden/ocupación corruptos, fallo al construir referencias. La sesión y archivo válidos deben quedar intactos y sin señales observables intermedias.
- Lifecycle: cargar repetidamente, fallar carga con sesión activa, cargar→restart, salir durante presentación, resultado→menú→nueva; ausencia de callbacks/objetos antiguos y conteos estables con teardown explícito.
- E2E: inicio desde shell/setup humano → guardar → cerrar → continuar → FINISHED con HUD F46 real y privacidad; no solo comparación de diccionarios.

## 11. Clasificación de `.uid` y cambios entregados

Los 42 sidecars preexistentes corresponden a scripts `.gd` seguidos de F44–F46. Se validó presencia del script, formato `uid://...`, unicidad entre ellos y ausencia de colisiones con los `.uid` ya seguidos. Las importaciones Godot realizadas no produjeron cambios en scripts/escenas seguidos. Se incorporan como metadatos de identidad de recurso, no como estado de partida. Se incorpora también el sidecar que genera Godot para el test diagnóstico nuevo.

Godot genera sidecars para scripts y recomienda versionarlos para preservar las referencias al compartir/mover archivos; ver [explicación oficial de los UID](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/). Son distintos de la caché descartable `.godot/`, que permanece ignorada, y distintos de `resonance_id`/`mission_id` necesarios para el save. Las referencias actuales por ruta pueden funcionar sin sidecar, pero regenerar identidades en cada equipo no es una solución estable. No se borraron UID del propietario ni se reescribieron sus valores.

Cambios del bloque: `AGENTS.md`; esta auditoría; estado/evidencia mínimos del Roadmap; test diagnóstico `.gd/.tscn/.gd.uid`; 42 sidecars existentes validados. No cambia `project.godot`, gameplay, formato F26 o escenas aprobadas.

## 12. Alcance exacto propuesto F47.2 y criterio de salida F47.1

F47.2 debe definir e implementar el contrato de datos FullMatch sobre el servicio existente: identidades y factories, MAP41 privado, participantes/setup confirmado/fase, límites por turno/ronda, orden y contenido completos, RNG/IA y resultado reconstruible; validación integral y restauración transaccional aislada. Debe reservar un descriptor estable de continuación humana y probarlo con F47.3; no convertir la UI en estado persistente ni copiar objetos Godot. Las fases/fronteras públicas finales dependen de D47-01/02/03.

No incluye aún UI de slots, autosave, proveedor cloud, backup o menú final. La integración shell/archivo corresponde a F47.4/5. Las garantías básicas de no mutación ante carga fallida y no consumo al rehidratar son necesarias desde el núcleo, no una mejora opcional diferida a hardening.

Salida F47.1: quedan documentados qué guarda F26 (§3–4), qué se reutiliza (§3/6), diferencias/gaps (§4–5), datos persistentes/reconstruibles (§4/6), choices (§7), lifecycle (§8), compatibilidad/decisiones (§9), pruebas y limitaciones reales (§10), y siguiente bloque (§12–13). Entrega lista para validación de auditoría; **persistencia de producto todavía no aprobada ni implementada**. Publicar la feature y detenerse, sin integrar en dev, esperando “prueba correcta”.

## 13. Plan de ejecución acelerada — misiones autónomas propuestas

Se mantiene la agrupación solicitada; la única precisión de dependencia es que atomicidad del restore y binding sin efectos se inician en A, antes de conectar el shell en B. Las misiones no están iniciadas ni autorizan decisiones pendientes por el simple paso del tiempo.

| Misión | Alcance / checkpoints cohesionados | Pruebas y gate | Dependencias |
|---|---|---|---|
| **MISSION F47-A — Persistence Core (F47.2 + F47.3)** | A1 identidades/catalog factories + MAP41/orden + esquema; A2 estado FullMatch/RNG/IA/uso especial + VALIDATE/BUILD/COMMIT; A3 continuaciones humanas, prioridad y barrera de publicación para fronteras aprobadas | Convertir diagnóstico en conservación/atomicidad; round-trip completo + todas las pausas F45 + comparación con ejecución control; regresiones F26/F38/F45/F46 y familias afectadas | Primera misión recomendada tras validar F47.1; cerrar D47-01/02/03 antes de imponer alcance público; avanzar partes independientes |
| **MISSION F47-B — Shell / Continue / file robustness (F47.4 + F47.5)** | B1 montar sesión restaurada en flujo real F41/F42 con HUD F46; B2 comandos/menú de carga aprobados; B3 escritura/validación/errores/migración y backup solo según decisión | Shell nueva/continuar/fallo sin perder activa, archivo interrumpido/incompatible, secretos y primer frame; F42/F46/F47 | Núcleo A validado; D47-04/05 y cloud únicamente si se amplía alcance |
| **MISSION F47-C — Lifecycle / end-to-end / closure (F47.6 + F47.7)** | C1 teardown del grafo/timers/estáticos; C2 cargas/restarts repetidos y cierres; C3 E2E humano+IA hasta resultado y cierre documental | Sin callbacks/estado residual ni regresiones funcionales; investigar/resolver diagnósticos de retención aplicables; F26/F38/F42/F45/F46/F47 y pruebas de proceso nuevo | A/B validadas, políticas pendientes resueltas, revisión final del propietario |

Cada misión crea o continúa una `feature/*` válida tras verificar remoto/baseline; produce commits semánticos por checkpoint estable, pruebas focales y regresiones afectadas, y push después de cada checkpoint completo. Ante decisión de producto/canon se detiene ese punto y continúa lo independiente. **Nunca integra automáticamente en `dev/karmany-core`.** La ejecución de F47.2 no forma parte de esta entrega.

## 14. Adenda 2026-09-05 — discrepancia F46 y gate previo a F47-A

### Procedencia y reproducción anterior al cambio

El propietario informó `PlayerPanel se solapa con ChoicePanel` al ejecutar F6 con Godot 4.7.1. El resultado headless de §10 es evidencia histórica real, pero insuficiente para validar el layout interactivo: no registraba el viewport efectivo.

Se verificaron rama `feature/f47-1-save-persistence-audit`, HEAD `53651805c940a036970f120d3330f6ee612830d4`, remoto `axenoban/Karmany-monsta` y worktree inicialmente limpio. `origin/dev/karmany-core` continúa en `f8d0faae94279e906857bbcdb7a2db2bcd025263`. Entre ambos commits no hay diferencias en código HUD, escena F46, test F46 ni `project.godot`; solo sidecars `.uid` entre los archivos UI.

Se ejecutó el mismo probe de geometría sobre ambos HEAD, usando un worktree temporal detached para dev, sin modificar ni resetear la rama activa. Motor `4.7.1.stable.official.a13da4feb`; render real D3D12. Configuración intacta: `canvas_items`, aspecto `expand`, sin resolución explícita en `project.godot`. El monitor local informa 2560×1440; esto no identifica el viewport de F6 incrustado del propietario.

| Modo, en ambos HEAD | Window.size | Viewport efectivo | PlayerPanel | ChoicePanel | Resultado |
|---|---|---|---|---|---|
| `--headless --resolution 1152x648` | 64×64 | 1152×1152 | (12,66), 300×421 | (146,968), 860×172 | Exit 0, sin solapamiento |
| Render real `--resolution 1152x648` | 1152×648 | 1152×648 | (12,66), 300×421 | (146,464), 860×172 | Exit 1, mismo error del propietario |

La altura mínima acumulada del VBox del jugador es 421, superior a los 395 asignados; el panel termina en y=487 e invade 23 px de la franja de decisiones. El viewport cuadrado headless oculta el defecto. Además, el ajuste secundario escribía `position` negativa como si fuese offset de un anchor central: FeedbackBanner quedaba en x=-256 y ContextStrip en x=-260. Los asserts anteriores no comprobaban contención ni todas las parejas y se ejecutaban durante SETUP.

**Conclusión:** defecto preexistente en dev y dependiente del viewport, no introducido por F47.1. No es ruido del entorno: se reproduce con render real y las coordenadas demuestran el fallo.

### Corrección y cobertura

- PlayerPanel conserva sus controles y tamaños legibles dentro de un ScrollContainer; su altura externa puede ajustarse al espacio real.
- Una geometría en coordenadas del padre reserva primero ChoicePanel y calcula los laterales y la columna central en cada cambio efectivo de tamaño/contenido. Se eliminan los offsets negativos del ajuste secundario; feedback admite texto envuelto y contexto ocupa el ancho disponible.
- Se conserva el límite de 395 del panel derecho y todos los asserts previos, sin tolerancias. No se cambia gameplay, ChoiceRouter, privacidad ni compuerta visual; la raíz sigue ignorando mouse para dejar pasar clicks al tablero.
- El test inicia mediante el botón real de F38 y comprueba que su setup desaparece. En PLAYING fuerza viewports deterministas 1152×648, 1024×600, 1280×720 y 1920×1080, verifica su tamaño efectivo, contención de los seis paneles y ausencia de intersecciones entre todas las parejas, también tras redimensionar la misma sesión. Es una matriz técnica, no una resolución mínima comercial aprobada.
- Los cuatro tamaños pasan headless y con render D3D12. Se inspeccionó una captura real a 1152×648 después del inicio: paneles separados, avisos visibles, tablero y opciones accesibles. Esto no sustituye validación humana de cada interacción.

Se repitieron las **14 escenas de §10.2**: contratos funcionales OK, exit 0, mismos conteos de WARNING ObjectDB y ERROR resources retenidos que la tabla histórica. F26 preservó el archivo preexistente mediante copia de seguridad/restauración. No hay nuevos errores de parser ni asserts. F47.1 sigue siendo **KNOWN GAP**, no conservación/atomicidad aprobadas: mazo 19→4, dos misiones sin ruta, 36 niveles perdidos y MN 2→9 ante rechazo todavía corresponden a A1/A2.

Evidencia local no versionada: `%TEMP%\karmany-f46-layout\baseline-{headless,render}.{out,err}`, `fixed-{headless,render}.{out,err}`, `visual.{out,err}` y `<testName>.{out,err}`. El worktree detached y los probes se retiran después de extraer la evidencia.

### Gate exacto y autorización de continuación

Los gates automáticos de Stage 0/1 pasan; **falta conocer y probar el viewport exacto usado por el propietario**, requisito explícito de §0.4 del adjunto. Se solicitó tamaño de ventana y modalidad incrustada/separada, o resolución/escalado si no conoce ese tamaño. No se equipara la resolución del monitor al viewport del juego ni se declara satisfecha esta comprobación sin el dato. F47-A todavía no se inicia; no se integra en dev/main.

El nuevo adjunto autoriza D47-01/02/03 para la futura misión, reemplazando las recomendaciones pendientes de §9: estados estables PLAYING, incluidas choices completas; nunca mitad de llamada/pago/consecuencia; presentación no es fuente del snapshot; setup sin confirmar y FINISHED no son requisito inicial; saves históricos incompletos se rechazan sin migración silenciosa ni mutación de destino. D47-04/05/06 siguen pendientes para F47-B o posteriores.

Tras cerrar el dato de viewport, continuar desde el HEAD final de esta feature y crear `feature/f47-a-persistence-core` apilada, como autoriza expresamente el adjunto. A1/A2/A3 conservan el alcance de §13; no implementar F47-B ni integrar dev sin validación del propietario.
