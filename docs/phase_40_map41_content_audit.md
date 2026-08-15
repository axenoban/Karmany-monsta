# Fase 40 — Auditoría canónica y variedad real MAP41

## Baseline inspeccionado antes de modificar F40

- Rama de trabajo: `feature/phase-40-complete-map41-content`.
- HEAD al iniciar la implementación F40: `161947aabd90f8bd03d5f01246fb52912989fcad`.
- Ese commit conserva F39 y únicamente mantiene `B-07 Terranuk` como fixture/runtime de Bestia Media requerido por la validación aprobada de F39.
- `dev/karmany-core` permanece como baseline anterior de F38; la rama F40 continúa sobre la línea aprobada de F39.
- `backup/local-content-before-phase39` fue comparada, pero **no fue mezclada**. La comparación no aporta identidades nuevas de loseta; modifica solamente tres Resources ya existentes y archivos F31/F32 antiguos.

## Fuentes canónicas inspeccionadas

Se revisaron antes de crear código F40:

- `data/tiles/`;
- `KarmanyTileData`;
- `KarmanyV074CanonicalRuntimeCatalog.TILE_IDS`;
- `KarmanyPhase37AlphaContentCatalog`;
- `KarmanyMap41TilePools`;
- `KarmanyMap41ContentGenerator`;
- `KarmanyAlphaTilePoolFallback`;
- `KarmanyMap41ContentSession`;
- geometría `KarmanyCanonicalMap41Layout`;
- `KarmanyUniversalTileInteractionService` de F39;
- `docs/phase_38_v074_content_audit.md`;
- `docs/phase_39_tile_interaction_audit.md`;
- búsqueda del repositorio por IDs pendientes como `N1-05` y `N3-01`.

El catálogo v0.74 sí declara los **41 IDs esperados**, pero el repositorio solamente contiene información materializada suficiente para 13 identidades. No se encontraron nombres, efectos, recompensas, costes y límites completos para las 28 identidades restantes.

## Inventario real F40

| Nivel | Posiciones MAP41 | IDs canónicos esperados | Resources materializados | Completos | Pendientes | Fallback | Repeticiones mínimas adicionales |
|---|---:|---:|---:|---:|---:|---|---:|
| I | 4 | 4 | 4 | 4 | 0 | No | 0 |
| N1 | 18 | 18 | 4 | 4 | 14 | Sí | 14 |
| N2 | 12 | 12 | 2 | 2 | 10 | Sí | 10 |
| N3 | 6 | 6 | 2 | 2 | 4 | Sí | 4 |
| L | 1 | 1 | 1 | 1 | 0 | No | 0 |
| **Total** | **41** | **41** | **13** | **13** | **28** | — | **28** |

Las 13 identidades materializadas son:

- Iniciales: `I-01`, `I-02`, `I-03`, `I-04`.
- N1: `N1-01`, `N1-02`, `N1-03`, `N1-04`.
- N2: `N2-01`, `N2-05`.
- N3: `N3-02`, `N3-03`.
- Legendaria: `L-01`.

Las 13 cumplen el contrato actual de `KarmanyTileData`, poseen Uso posterior y un `interaction_profile_id` interpretable por F39. F40 no crea versiones ficticias de las identidades pendientes.

## PENDIENTE DE CONTENIDO CANÓNICO

### N1

`N1-05`, `N1-06`, `N1-07`, `N1-08`, `N1-09`, `N1-10`, `N1-11`, `N1-12`, `N1-13`, `N1-14`, `N1-15`, `N1-16`, `N1-17`, `N1-18`.

### N2

`N2-02`, `N2-03`, `N2-04`, `N2-06`, `N2-07`, `N2-08`, `N2-09`, `N2-10`, `N2-11`, `N2-12`.

### N3

`N3-01`, `N3-04`, `N3-05`, `N3-06`.

Para materializar cualquiera de estas identidades faltan datos canónicos suficientes como mínimo para completar de forma coherente `display_name`, función, textos de Al explorar/Entrada/Uso posterior, límites y la lógica/efectos estructurados correspondientes. El ID por sí solo no es información suficiente para inventar esos datos.

## Fallback que sigue siendo necesario

F40 **no elimina ni aumenta** el fallback de F32.

Con los pools reales actuales:

- N1: 4 identidades para 18 slots → fallback necesario; al menos 14 colocaciones son reutilizaciones después de la primera aparición de cada identidad.
- N2: 2 identidades para 12 slots → fallback necesario; al menos 10 reutilizaciones.
- N3: 2 identidades para 6 slots → fallback necesario; al menos 4 reutilizaciones.

`KarmanyAlphaTilePoolFallback` sigue distribuyendo de forma balanceada los Resources reales disponibles y rebaraja cada ciclo con el RNG derivado de la seed. No se mezclan niveles.

## Variedad efectiva

La variedad máxima de identidad visible disponible en una sola partida, con el contenido materializado actual, es:

- N1: 4 identidades distintas sobre 18 posiciones (22,2 % de identidad única respecto de slots).
- N2: 2 sobre 12 (16,7 %).
- N3: 2 sobre 6 (33,3 %).

La seed sí cambia la asignación espacial de esas identidades y la generación continúa siendo determinista. F40 añade una prueba que exige:

- misma seed → mismo fingerprint de asignación;
- conjunto de seeds distintas → al menos dos fingerprints distintos;
- cada seed conserva 18/12/6 slots;
- cuando existe fallback, todas las identidades reales del pool participan en la distribución balanceada.

Por tanto, la limitación de variedad actual es de **contenido disponible**, no de geometría ni de la mecánica de seed.

## Privacidad

F40 no inspecciona `_hidden_content` ni introduce una API para hacerlo.

La prueba utiliza únicamente las fronteras públicas existentes:

- antes de revelar: `get_public_tile_data()` devuelve `null`, `BoardState.tile_data` permanece `null`, el snapshot público no contiene `tile_id`/nombre y F39 devuelve `OCULTA`;
- después de `reveal_into_board_state()`: la identidad se vuelve pública, mantiene el nivel estructural correcto y F39 puede presentar su Uso posterior.

## Implementación F40

Se añadió `KarmanyMap41ContentAudit` como herramienta de auditoría, no como una segunda fuente de gameplay. El listado de IDs esperados se toma directamente de `KarmanyV074CanonicalRuntimeCatalog.TILE_IDS`; los Resources materializados se toman del catálogo F37 y los tamaños de pool de `KarmanyMap41TilePools`.

El audit reporta por nivel:

- IDs esperados;
- IDs materializados;
- completos;
- incompletos y sus problemas;
- pendientes;
- tamaño real del pool;
- necesidad de fallback;
- número mínimo de colocaciones repetidas.

No se modificaron TurnManager, combate, PvP, scoring, IA estratégica, cámaras, geometría F31 ni multiplayer. Tampoco se modificó el algoritmo F32 de asignación por seed ni la fuente universal de legalidad de F39.

## Resultado arquitectónico

F40 no puede aumentar responsablemente de 13 a 41 Resources con la información que existe hoy en el repositorio. Hacerlo exigiría inventar contenido, lo cual contradice el requisito canónico de esta fase.

El avance seguro de F40 consiste en dejar formalizado y automatizado el límite real del catálogo, proteger la geometría/seed/privacidad, medir el fallback y hacer que futuras identidades canónicas puedan incorporarse sin ambigüedad. Cuando se proporcione el contenido canónico faltante, el mismo test aceptará el crecimiento de los pools sin requerir cambiar las reglas históricas.
