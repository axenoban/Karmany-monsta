# Karmany Monsta — Roadmap de Alpha a versión pública 1.0

> Estado: **ROADMAP OPERATIVO — APROBADO E INTEGRADO en dev/karmany-core**\
> Baseline auditado: `dev/karmany-core` @ `61012b1`  
> Motor: Godot `4.7` · Forward Plus · Jolt Physics  
> Entrada actual: `res://scenes/app/main.tscn`  
> Última fase integrada en el baseline: F46 — HUD Alpha completo  
> Próxima fase ya definida por F46: F47 — guardado / carga / continuación  
> F50 permanece reservada para arte, animación, audio y polish.

---

## 1. Propósito

Este documento define el camino técnico y de producto desde el Alpha actual de **Karmany Monsta** hasta una versión **1.0 final, jugable, estable, presentable y preparada para distribución pública**.

No sustituye las reglas canónicas ni autoriza cambios de balance o contenido. Su función es ordenar el trabajo, establecer dependencias, definir criterios de salida y dar a Codex/Astra un contrato de ejecución verificable.

El roadmap se considera vivo: debe actualizarse después de cada bloque aprobado, pero ningún cambio de estado puede ocultar trabajo pendiente o reinterpretar contenido canónico.

### 1.1 Objetivo 1.0

La versión 1.0 se considerará terminada solamente cuando, dentro del alcance público aprobado:

- una persona pueda instalar/abrir el juego y completar el flujo completo sin herramientas de desarrollo;
- todas las decisiones humanas necesarias sean visibles y resolubles desde la interfaz;
- las reglas implementadas coincidan con la fuente canónica aprobada;
- el contenido incluido tenga comportamiento runtime explícitamente reconciliado;
- guardar, cerrar, cargar y continuar sea seguro;
- iniciar, reiniciar, terminar y abandonar partidas no deje estado residual;
- IA y modos públicos funcionen sin atajos de depuración;
- UX, controles, feedback, accesibilidad y configuración alcancen estándar de producto;
- arte, animación, audio y presentación sean coherentes y estén aprobados;
- no existan errores bloqueantes o críticos conocidos;
- los builds públicos sean reproducibles, identificables por versión y validados en los destinos aprobados;
- estén resueltos los requisitos de distribución, licencias, créditos, privacidad y materiales públicos aplicables.

No se fija una fecha artificial. El avance se gobierna por **gates de calidad**, no por calendario.

---

## 2. Jerarquía de verdad

Cuando dos fuentes entren en conflicto, utilizar este orden:

1. documento/regla canónica aprobada y decisiones registradas;
2. catálogo canónico y datos reconciliados del repositorio;
3. pruebas de regresión que expresan contratos ya aprobados;
4. implementación runtime estable integrada en `dev/karmany-core`;
5. documentación de fase;
6. este roadmap.

Este roadmap **nunca puede inventar** costes, recompensas, estadísticas, efectos, cantidades, condiciones, componentes o reglas faltantes.

Si una implementación requiere una decisión de reglas, balance, contenido, arquitectura crítica o alcance público que no esté resuelta:

- detener ese punto concreto;
- registrar la decisión pendiente;
- presentar alternativas y consecuencias;
- continuar solamente con trabajo independiente y seguro.

---

## 3. Baseline real al iniciar este roadmap

El proyecto ya es un Alpha funcional y no debe reiniciarse desde cero.

### 3.1 Producto actualmente integrado

El baseline F46 ya dispone de:

- shell de aplicación con flujo `menú → setup → partida → resultado`;
- tablero MAP41;
- P1 humano;
- P2–P4 automatizados en el flujo Alpha actual;
- partida completa basada en `KarmanyFullMatchSession`;
- HUD visible conectado al estado real;
- `ChoiceRequest` y resolvers explícitos para decisiones humanas cubiertas por F45/F46;
- separación entre revelación lógica y revelación visual;
- inspectores y feedback contextual;
- pruebas de reinicio, full match, setup, HUD, choices y regresiones de fases previas.

### 3.2 Sistemas existentes que deben evolucionar, no duplicarse

El repositorio ya contiene subsistemas para:

- IA y generación/ejecución de acciones legales;
- multijugador local/runtime multijugador previo;
- guardado/carga técnico de F26;
- performance baseline;
- onboarding y telemetría Alpha;
- tablero MAP41 y mapa aleatorio;
- mercado/equipo/crafteo;
- Resonancias;
- Bestias y combate;
- Karmany y encuentros;
- Entrenadores;
- Objetivos y Misiones;
- PvP;
- Aeterna;
- UI/HUD y bridges de presentación;
- vertical slice y full-match sessions.

Cualquier fase futura debe inspeccionar estos módulos antes de crear uno nuevo.

### 3.3 Estado de cobertura canónica

La auditoría final F44.8 reporta:

- `205/205` componentes reconciliados;
- `FULLY = 14`;
- `PARTIAL = 155`;
- `DATA_ONLY = 36`;
- `PENDING = 0`.

Esto significa que **el catálogo está reconciliado, pero el producto aún no tiene profundidad runtime completa para todos los componentes**. La deuda principal hacia 1.0 no es descubrir IDs faltantes; es revisar qué significa cada `PARTIAL` y `DATA_ONLY` en una partida pública y completar o justificar su disposición.

No se impondrá incorrectamente que los 205 componentes deban terminar como `FULLY`. Un elemento puede ser legítimamente pasivo o solo de datos si así lo determina su canon. Para 1.0, lo obligatorio es que no exista ningún `PARTIAL` o `DATA_ONLY` **sin explicación y aceptación explícita**.

---

## 4. Modelo de ramas e integración

Mantener la política del proyecto:

- `main`: únicamente versiones publicables/aprobadas;
- `dev/karmany-core`: último baseline completo validado;
- `feature/*`: trabajo pendiente de validación.

### 4.1 Flujo obligatorio por bloque

1. `git fetch origin`.
2. Verificar el HEAD real de `dev/karmany-core`.
3. Crear `feature/fXX-descripcion` desde ese HEAD.
4. Inspeccionar código, documentos canónicos y pruebas relevantes.
5. Implementar un bloque cohesivo, preferentemente de 8–15 componentes cuando se trate de contenido repetible.
6. Añadir/fortalecer pruebas sin debilitar contratos existentes.
7. Ejecutar pruebas focalizadas y regresiones afectadas.
8. Documentar qué cambió y qué quedó pendiente.
9. Entregar para validación local.
10. Tras “prueba correcta”, integrar pronto a `dev/karmany-core` si es seguro, preferentemente fast-forward.
11. Verificar el nuevo baseline antes del siguiente bloque.

Prohibido:

- force push;
- reescribir historia;
- merges ciegos;
- ocultar fallos aumentando watchdogs;
- eliminar asserts válidos para hacer pasar pruebas;
- convertir errores en warnings silenciosos;
- introducir datos canónicos inventados;
- modificar sistemas ya aprobados sin causa técnica y regresión correspondiente.

`main` no se actualiza por el simple cierre de una fase. Solo recibe una versión que haya superado el gate de Release Candidate/Gold correspondiente.

---

## 5. Gates globales de calidad

Todo bloque debe respetar estos principios, y 1.0 no puede liberarse sin satisfacer todos los aplicables.

### G0 — Integridad canónica

- `205/205` componentes continúan reconciliados o la cifra vigente está documentada si el canon aprobado cambia.
- Ningún contenido público queda con implementación ambigua.
- Cada comportamiento nuevo tiene evidencia de su fuente canónica.
- No hay “relleno” de reglas decidido por conveniencia de programación.

### G1 — Integridad del runtime

- una sola fuente de verdad por estado de gameplay;
- UI no duplica ni corrige reglas;
- IA no dispone de acciones ilegales que el runtime humano no tendría;
- las decisiones humanas no se auto-resuelven mientras requieran elección;
- transiciones de turno/fase no se ejecutan dos veces;
- teardown no deja nodos orphan, señales residuales ni coroutines que sobrevivan a la sesión.

### G2 — Persistencia

- guardar/cargar es versionado y verificable;
- carga incompatible o corrupta falla de forma segura;
- continuar no duplica efectos ni salta decisiones;
- nueva partida no hereda estado de un save anterior;
- restart/quit/load son rutas reproducibles.

### G3 — Experiencia de jugador

- jugar no requiere Output, debugger, Inspector ni controles internos;
- toda acción disponible tiene feedback suficiente;
- información secreta permanece secreta;
- el jugador entiende por qué una acción es válida/rechazada;
- UI se mantiene usable en resoluciones objetivo aprobadas;
- controles y accesibilidad del alcance 1.0 están implementados.

### G4 — Estabilidad y rendimiento

- cero bugs conocidos de severidad Blocker o Critical para Gold;
- regresiones críticas automatizadas/reproducibles;
- sesiones completas, reinicios y cargas repetidas sin degradación funcional;
- objetivos de FPS, memoria y hardware se fijan solo cuando se aprueben plataformas objetivo.

### G5 — Producción y distribución

- build identificable por versión;
- export reproducible para cada plataforma aprobada;
- licencias y créditos completos;
- materiales de tienda/descarga completos;
- configuración pública no expone herramientas de desarrollo;
- telemetría/crash reporting, si se usan, tienen decisión de privacidad explícita.

---

## 6. Mapa macro Alpha → 1.0

| Fase | Objetivo | Estado al crear este roadmap | Gate de salida |
|---|---|---|---|
| F1–F46 | Baseline histórico integrado | `INTEGRATED_BASELINE` | Protegido por regresiones |
| F47 | Guardar / cargar / continuar sobre el runtime actual | `PLANNED` | Continuación de partida real y segura |
| F48 | Campaña de cierre runtime canónico | `PLANNED` | Sin `PARTIAL/DATA_ONLY` inexplicados en alcance público |
| F49 | Integración Feature Complete | `PLANNED` | Todo el alcance 1.0 jugable sin debug |
| F50 | Arte, animación, audio y polish | `RESERVED / PLANNED` | Presentación audiovisual aprobada e integrada |
| F51 | UX final, input, settings, accesibilidad y localización | `PLANNED` | Experiencia de producto completa |
| F52 | Hardening: estabilidad, lifecycle, rendimiento y persistencia | `PLANNED` | Baseline técnicamente candidato a Beta |
| F53 | Beta, QA sistemático y Content Lock | `PLANNED` | Sin blockers/criticals; contenido bloqueado |
| F54 | Producción de release y salida pública | `PLANNED` | Builds + distribución + materiales listos |
| F55 | Release Candidate → Gold → 1.0 | `PLANNED` | Versión pública aprobada |
| 1.0.x | Soporte post-lanzamiento | `POST_RELEASE` | Hotfixes/regresiones controlados |

**Nota:** F47 y la reserva de F50 provienen del roadmap ya expresado en F46. Los nombres/alcances F48–F49 y F51–F55 son la propuesta operativa de este documento y pueden ajustarse antes de comenzar esas fases sin alterar canon.

---

# 7. F47 — Guardado, carga y continuación

## Objetivo

Transformar el guardado técnico existente de F26 en persistencia de producto para el runtime actual F46, sin crear un segundo sistema paralelo.

F26 ya demuestra round-trip técnico de tablero, jugadores, inventarios, mazos, ronda, PL, Libro, encuentros y runtime de Entrenador sobre una arquitectura anterior. F47 debe auditar ese contrato contra `KarmanyFullMatchSession` y el estado incorporado después de F26.

## Bloques propuestos

### F47.1 — Auditoría de persistencia actual

**Estado:** `READY_FOR_VALIDATION` — [auditoría F47.1](phase_47_1_save_persistence_audit.md), baseline `f8d0faa`. Auditoría y diagnóstico completados; adenda §14: defecto F46 preexistente corregido, matriz headless/render y regresiones OK, pendiente identificar viewport exacto del propietario. D47-01/02/03 autorizadas para F47-A; F47.2 aún no implementada.

- inventariar `scripts/save/*` y bridges de save existentes;
- comparar el snapshot F26 contra el grafo de estado de F46;
- clasificar campos como persistentes, derivados, transitorios o no serializables;
- identificar estados añadidos desde F26: decisiones pendientes, runtime canónico posterior, setup actual, presentación que deba reconstruirse y cualquier estado necesario para continuar;
- documentar incompatibilidades antes de modificar formato.

**Salida:** mapa de persistencia y lista cerrada de gaps, sin cambiar reglas.

### F47.2 — Contrato de snapshot actual

- mantener una única versión de formato explícita;
- serializar exclusivamente estado necesario y estable;
- reconstruir referencias runtime desde datos, no persistir identidades de objetos Godot;
- preservar orden/estado de colecciones cuya secuencia afecte gameplay;
- conservar el estado suficiente para reanudar exactamente el punto de juego permitido.

**Salida:** round-trip del `FullMatchSession` actual.

### F47.3 — Decisiones pendientes y puntos seguros de guardado

- determinar qué `ChoiceRequest` actuales pueden persistirse directamente y cuáles deben reconstruirse de forma determinista;
- impedir guardados que produzcan estados imposibles;
- al cargar, no duplicar una consecuencia ya aplicada ni avanzar una fase antes de resolver una elección humana pendiente;
- proteger compuertas de revelación visual.

Si la definición de “cuándo puede guardar el jugador” implica una decisión de diseño, registrarla y solicitar aprobación antes de imponer restricciones.

### F47.4 — Integración con shell

- exponer `Continuar` solo cuando exista un save válido y compatible;
- `Nueva partida` crea una sesión limpia;
- `Cargar/Continuar` reconstruye una sesión funcional;
- `Reiniciar` y volver al menú no reutilizan estado accidental;
- mensajes de error de save corrupto/incompatible son comprensibles y no destruyen silenciosamente datos válidos.

### F47.5 — Robustez del archivo

- escritura segura ante interrupciones según las capacidades elegidas;
- validación de versión/esquema;
- tratamiento explícito de corrupción;
- estrategia de migración para futuras versiones antes de declarar estabilidad del formato;
- no incluir datos personales innecesarios.

### F47.6 — Lifecycle y teardown

Probar secuencias repetidas:

- nueva → salir → nueva;
- nueva → guardar → salir → continuar;
- guardar durante punto permitido → cargar → terminar partida;
- cargar → reiniciar;
- varias cargas consecutivas;
- resultado → menú → continuar/nueva según corresponda.

No deben sobrevivir timers, señales, callbacks, coroutines ni nodos de la sesión anterior.

### F47.7 — Cierre y regresión

Como mínimo preservar:

- prueba F26 como contrato histórico del servicio que siga aplicando;
- F42 game shell/restart;
- F38 full match;
- F45 choices afectados;
- F46 HUD/choice router/scene;
- nuevas pruebas F47 específicas.

## Gate F47

F47 termina cuando una partida real iniciada desde el shell actual puede guardarse, cerrar la sesión, cargarse y finalizar normalmente, manteniendo estado canónico y decisiones pendientes sin duplicación, pérdida de información ni residuos de lifecycle.

---

# 8. F48 — Campaña de cierre runtime canónico

## Objetivo

Convertir la auditoría F44 en una matriz de producto y cerrar sistemáticamente los componentes que aún están `PARTIAL` o `DATA_ONLY` cuando el canon exige comportamiento observable.

Esta fase no debe convertirse en un cambio masivo de 191 elementos. Se trabaja en **bloques cohesionados de aproximadamente 8–15 componentes**, agrupados por arquitectura/comportamiento.

## F48.1 — Re-auditoría inicial

Antes de tocar contenido:

- ejecutar/inspeccionar F43 closure audit;
- ejecutar/inspeccionar F44 logic coverage/final runtime audit;
- generar inventario vigente por familia;
- para cada componente no `FULLY`, registrar:
  - ID/nombre canónico;
  - fuente canónica;
  - clasificación actual;
  - hooks runtime existentes;
  - gap real;
  - impacto humano;
  - impacto IA;
  - requisito de UI/feedback;
  - pruebas existentes;
  - disposición objetivo.

## Disposiciones permitidas

Cada componente debe terminar con una de estas conclusiones verificables:

- `FULL_RUNTIME`: el canon exige ejecución y está implementado/probado;
- `INTENTIONAL_PARTIAL`: solo parte del texto implica runtime y el resto es datos/presentación por diseño canónico;
- `INTENTIONAL_DATA_ONLY`: el componente legítimamente no requiere lógica runtime adicional;
- `BLOCKED_CANONICAL_DECISION`: la fuente es insuficiente/contradictoria y necesita decisión humana.

Para el gate de 1.0 no puede quedar ningún elemento simplemente `PARTIAL`/`DATA_ONLY` sin esa justificación.

## Orden de trabajo

Priorizar:

1. elementos alcanzables durante una partida MAP41 normal;
2. efectos que modifican decisiones, costes, combate, movimiento, recursos o puntuación;
3. elementos que hoy solo funcionan para IA o solo para humano;
4. hooks transversales compartidos por varias familias;
5. edge cases de menor frecuencia.

No usar el orden numérico de IDs si eso genera arquitecturas duplicadas.

## Contrato por bloque

Un bloque F48 aprobado debe incluir:

- implementación de los componentes seleccionados;
- reutilización del motor de efectos/hooks existentes cuando sea correcto;
- integración humana;
- tratamiento IA si aplica;
- feedback/UI si el jugador necesita percibir el resultado;
- tests unitarios/contractuales;
- regresiones de familia;
- actualización de la matriz de cobertura;
- ningún cambio canónico silencioso.

## Gate F48

- todos los componentes del alcance público poseen disposición explícita;
- no quedan gaps runtime conocidos ocultos por la etiqueta `PARTIAL`;
- la auditoría 205/205 permanece consistente con el canon vigente;
- cualquier bloqueo canónico está resuelto antes de avanzar a Feature Complete.

---

# 9. F49 — Feature Complete e integración total

## Objetivo

Demostrar que todas las funciones incluidas en el alcance 1.0 funcionan juntas desde el flujo real del jugador, no solamente en pruebas aisladas.

## Áreas

### F49.1 — Paridad de interacción humana

- todo comportamiento público alcanzable se puede ejecutar desde UI normal;
- ningún flujo depende de botones/probes/debug internos;
- choices anidados o consecuencias prioritarias mantienen orden correcto;
- los inspectores muestran información suficiente sin filtrar secretos.

### F49.2 — Paridad IA

- IA obtiene acciones desde reglas legales reales;
- no accede a información secreta no permitida;
- resuelve consecuencias obligatorias mediante contratos equivalentes;
- no bloquea la partida ante estados canónicos raros;
- estrategia y dificultad no deben corregirse alterando reglas.

El balance de dificultad requiere decisión aparte si cambia comportamiento estratégico significativo.

### F49.3 — Modos públicos

Auditar los modos existentes y decidir cuáles forman parte de 1.0.

El repositorio contiene infraestructura de multijugador local y multi-IA; esto **no implica** que multijugador online forme parte del alcance.

Para cada modo aprobado:

- setup válido;
- partida completa;
- finalización correcta;
- restart/exit;
- save/continue si aplica;
- presentación de información privada/pública correcta.

### F49.4 — Full-game integration matrix

Cubrir combinaciones críticas de:

- setup;
- exploración/movimiento/interacción;
- encuentros y combate;
- Bestias;
- Karmany;
- Resonancias;
- Equipo/mercado/crafteo;
- Objetivos/Misiones;
- Entrenadores;
- PvP;
- Aeterna;
- puntuación/finalización;
- IA;
- save/load/restart.

La matriz describe sistemas existentes; no define reglas nuevas.

## Gate Feature Complete

F49 termina cuando **todo el alcance funcional de 1.0 está dentro del juego** y puede completarse de extremo a extremo. Después de este gate, cambios de reglas/contenido deben tratarse como excepción controlada porque elevan el riesgo de F50–F55.

---

# 10. F50 — Arte, animación, audio y polish

F50 ya estaba reservada desde F46. Su objetivo es reemplazar la presentación Alpha por una identidad audiovisual apta para público **sin alterar el gameplay aprobado**.

## F50.1 — Dirección de arte aprobada

Antes de producción masiva definir y aprobar:

- lenguaje visual general;
- tratamiento del tablero y losetas;
- representación de Karmany, Bestias, Entrenadores y otros elementos visibles;
- UI, iconografía, tipografía y jerarquía;
- paleta y contraste;
- nivel de detalle 2D/3D;
- reglas de consistencia entre assets;
- pipeline de fuentes y licencias.

Codex/Astra no debe decidir unilateralmente estilo final, assets comerciales ni contenido visual canónico.

## F50.2 — Pipeline de assets

- convenciones de nombres y carpetas;
- formatos fuente y formatos importados;
- escalas/resoluciones objetivo;
- materiales/texturas;
- compresión/import settings;
- ownership/licencia por asset;
- placeholders claramente diferenciados de assets finales;
- política para reemplazo sin romper escenas.

## F50.3 — Tablero y mundo

- geometría/visual final de MAP41;
- estados oculto/revelado seleccionable;
- legibilidad de posiciones, participantes y contenido;
- feedback de hover/selección/acción;
- VFX que no filtren información ni oculten estado relevante.

## F50.4 — Cartas, componentes e inspectores

- layouts finales;
- ilustración aprobada;
- iconografía consistente;
- textos legibles;
- estados interactivos/deshabilitados;
- comportamiento responsive.

## F50.5 — Animación y VFX

- revelar/explorar;
- movimiento;
- combate;
- obtención/pérdida de recursos cuando corresponda;
- cartas/equipo;
- Aeterna y otros eventos relevantes;
- transiciones de ronda/turno/resultado.

Las animaciones nunca deben ser la fuente de verdad del gameplay. El runtime decide; la presentación representa.

## F50.6 — Audio

- arquitectura de buses;
- música;
- ambiente;
- SFX de UI;
- SFX de acciones/combate/eventos;
- feedback positivo/negativo;
- control de volumen por categoría;
- licencia/origen documentado.

## F50.7 — Polish

- timing de feedback;
- transiciones coherentes;
- microinteracciones;
- eliminación de placeholders visibles;
- corrección de clipping, z-order, solapamientos y textos;
- consistencia de cursor/focus;
- resultado de partida presentable.

## Gate F50

El juego es reconocible visualmente como producto final, el arte/audio aprobado está integrado y la presentación no rompe reglas, accesibilidad, secretos ni estabilidad.

---

# 11. F51 — UX final, controles, settings, accesibilidad y localización

## F51.1 — Navegación completa

- menú principal;
- nueva partida;
- continuar;
- configuración;
- pausa;
- abandonar/confirmar cuando sea necesario;
- resultado y volver a jugar;
- navegación sin callejones sin salida.

## F51.2 — Input

Definir primero `D-REL-INPUT` con los dispositivos públicos objetivo.

Para cada dispositivo aprobado:

- navegación consistente;
- foco visible;
- bindings centralizados;
- reentrada segura al cambiar escenas;
- prevención de doble input;
- instrucciones/contexto adaptados al dispositivo cuando sea necesario.

No asumir soporte de mando o touch hasta aprobarlo.

## F51.3 — Settings

Según alcance aprobado:

- audio;
- vídeo/resolución/pantalla;
- controles;
- accesibilidad;
- idioma;
- persistencia de preferencias independiente del save de partida cuando corresponda.

## F51.4 — Accesibilidad

Como mínimo auditar:

- tamaño/legibilidad de texto;
- contraste;
- información no dependiente únicamente del color;
- navegación por foco;
- posibilidad de reducir/manejar movimiento si la presentación lo necesita;
- volúmenes separados;
- claridad de estados bloqueados/disponibles;
- tiempos de lectura no forzados por animaciones no esenciales.

Las opciones finales dependen del diseño aprobado, pero la auditoría es obligatoria.

## F51.5 — Localización

- separar strings visibles de lógica;
- definir idioma(s) de lanzamiento mediante decisión de producto;
- evitar concatenaciones que impidan traducción;
- validar expansión de textos en UI;
- glosario de términos canónicos.

## Gate F51

Un jugador dentro de los dispositivos, idioma(s) y necesidades de accesibilidad aprobados puede operar el producto completo sin recurrir a controles de desarrollo.

---

# 12. F52 — Hardening técnico

## Objetivo

Convertir Feature Complete + presentación final en un baseline resistente a uso prolongado y repetido.

## F52.1 — Lifecycle

Pruebas repetidas de:

- entrar/salir de partida;
- restart;
- save/load;
- menú ↔ setup ↔ partida ↔ resultado;
- cambios de resolución/settings;
- cierre de aplicación durante rutas permitidas.

Buscar específicamente:

- orphan nodes;
- señales duplicadas;
- timers activos después del teardown;
- coroutines reanudadas sobre nodos liberados;
- referencias stale;
- dobles resoluciones;
- acumulación de handlers/UI.

## F52.2 — Determinismo y reproducibilidad

Cuando el sistema use azar:

- poder reproducir fallos con información suficiente para debugging;
- guardar/restaurar el estado requerido por persistencia;
- no sustituir azar canónico por hacks de test en producción.

## F52.3 — Rendimiento

Reutilizar la infraestructura de performance existente y actualizar el baseline con el contenido final.

Métricas finales solo se fijan cuando se resuelvan plataforma y hardware objetivo. Medir como mínimo:

- tiempo de carga relevante;
- frame time durante tablero/animaciones;
- memoria;
- picos durante revelaciones/combates;
- impacto de UI/inspectores;
- degradación tras partidas/restarts repetidos.

## F52.4 — Persistencia estable

- migración de saves si el formato cambia después de F47;
- compatibilidad dentro de la política aprobada;
- backups/recuperación si se adopta;
- settings separados del snapshot de partida;
- errores comprensibles.

## F52.5 — Logging de release

- eliminar ruido de debug no necesario;
- mantener diagnóstico útil sin filtrar secretos ni datos personales;
- crash reporting/analytics solo si `D-REL-TELEMETRY` está aprobado.

## Gate F52

Baseline técnicamente apto para Beta: ninguna ruta normal conocida corrompe sesión, deja lifecycle residual o degrada el producto de forma severa.

---

# 13. F53 — Beta, QA y Content Lock

## F53.1 — Matriz de QA

Crear una matriz reproducible por:

- plataforma aprobada;
- modo de juego;
- tipo de setup;
- resolución/configuración relevante;
- save nuevo/antiguo compatible;
- flujo completo de partida;
- sistemas canónicos críticos;
- restart/continue;
- casos de derrota/victoria/finalización aplicables.

## F53.2 — Severidades

Usar una clasificación consistente:

- **Blocker:** impide instalar, abrir, iniciar, continuar o completar el producto en un flujo principal; corrupción grave; pérdida crítica.
- **Critical:** gameplay/regla principal incorrecta, crash reproducible o fallo grave sin workaround aceptable.
- **Major:** función importante defectuosa con workaround o impacto limitado.
- **Minor:** defecto de baja severidad/presentación.
- **Cosmetic:** polish sin impacto funcional.

Gold requiere `Blocker = 0` y `Critical = 0`. Los demás defectos necesitan disposición explícita.

## F53.3 — Beta interna/externa

Si se aprueba distribución Beta:

- build identificable;
- canal de feedback;
- plantilla de reporte con versión, pasos y evidencia;
- no introducir fixes especulativos sin reproducción;
- priorizar primer error real;
- convertir bugs relevantes en regresiones automatizadas cuando sea viable.

## F53.4 — Content Lock

Al cerrar Beta:

- no añadir mecánicas, componentes o contenido no planificado;
- cambios canónicos solo por defecto demostrado y aprobación explícita;
- strings, assets y datos públicos se congelan progresivamente;
- cualquier excepción reinicia las regresiones afectadas.

## Gate F53

Producto funcionalmente estable, contenido bloqueado, sin Blockers/Criticals conocidos y con una matriz de QA ejecutada sobre el alcance de lanzamiento.

---

# 14. F54 — Producción de release y salida al público

Esta fase transforma el juego estable en un producto distribuible. No se puede completar hasta resolver las decisiones de plataforma/comercialización.

## F54.1 — Plataformas y export

Para cada plataforma aprobada:

- preset/export correcto;
- nombre, versión e identificadores finales;
- iconos y ejecutables;
- configuración gráfica compatible;
- rutas de save correctas;
- permisos necesarios y solo los necesarios;
- smoke test en build exportado, no únicamente dentro del editor.

## F54.2 — Versionado

Adoptar Semantic Versioning operativo como mínimo para releases públicas:

- `1.0.0` = primera versión pública aprobada;
- `1.0.x` = fixes compatibles;
- cambios mayores futuros se evalúan por alcance.

La política exacta de tags/RC debe aprobarse antes del primer RC. No crear nuevas familias de ramas que contradigan `main/dev/feature` sin decisión explícita.

## F54.3 — Build reproducible

- pasos de export documentados;
- versión de Godot fijada;
- dependencias/assets externos identificados;
- configuración pública separada de debug;
- hash/identificación del commit fuente del build;
- changelog de release.

CI puede incorporarse si aporta reproducibilidad, pero su proveedor/configuración se decide según el repositorio y destinos reales.

## F54.4 — Legal y licencias

Antes de distribuir:

- inventario de assets de terceros;
- fuentes;
- música/SFX;
- librerías/plugins;
- licencias y atribuciones;
- créditos;
- política de privacidad si existe telemetría/datos;
- términos/EULA solo si son necesarios para la vía de distribución elegida;
- requisitos de clasificación por edad/región/plataforma cuando apliquen.

No asumir requisitos legales concretos hasta elegir mercados/plataformas.

## F54.5 — Identidad pública

Aprobar:

- nombre comercial final;
- logo;
- key art;
- tagline/descripción corta;
- descripción larga;
- capturas finales reales;
- trailer/gameplay si el canal lo requiere;
- press kit si se decide utilizarlo.

## F54.6 — Página de producto / tienda

Según plataforma:

- cápsulas/banners en medidas requeridas;
- screenshots sin contenido debug;
- requisitos de sistema reales;
- idiomas soportados reales;
- features listadas solo si están en el build;
- precio/modelo comercial aprobado;
- política de demo si existe.

## Gate F54

Existe al menos un candidato de distribución reproducible por plataforma aprobada y todos sus materiales técnicos, comerciales y legales necesarios están listos para revisión final.

---

# 15. F55 — Release Candidate, Gold y versión 1.0

## F55.1 — RC1

Crear candidato desde el baseline validado sin añadir features nuevas.

Checklist:

- commit exacto identificado;
- build limpio;
- smoke test;
- full-match principal;
- save/load/continue;
- restart/quit;
- settings/input;
- auditoría canónica;
- auditoría de assets/licencias;
- QA de plataforma.

## F55.2 — Correcciones RC

Solo:

- Blockers;
- Criticals;
- Majors aprobados;
- defectos de cumplimiento/distribución;
- polish de riesgo bajo explícitamente aceptado.

Cada fix debe:

- reproducir el fallo;
- encontrar el primer error real;
- añadir regresión cuando sea razonable;
- reejecutar matriz afectada;
- producir un RC nuevo si modifica el build.

## F55.3 — Gold

Declarar Gold únicamente cuando:

- Blocker = 0;
- Critical = 0;
- canon y datos reconciliados;
- no existen decisiones públicas obligatorias pendientes;
- builds exportados pasan smoke + QA final;
- save/versionado definido;
- assets finales y créditos completos;
- materiales de distribución coinciden con el producto;
- el propietario del proyecto aprueba explícitamente la versión.

## F55.4 — Promoción a `main`

Solo después de Gold:

1. verificar HEAD de `dev/karmany-core` y commit Gold;
2. confirmar historia y ausencia de trabajo no aprobado;
3. integrar a `main` sin force push ni reescritura;
4. crear tag de release según política aprobada;
5. generar artefactos desde ese commit exacto;
6. ejecutar smoke final sobre artefactos distribuidos.

## F55.5 — Publicación

- subir/activar build aprobado;
- verificar que el artefacto público corresponde al commit Gold;
- conservar checksums/versiones si el canal lo permite;
- publicar changelog/notas;
- abrir proceso post-launch.

---

# 16. Post-lanzamiento 1.0.x

El lanzamiento no habilita cambios improvisados en `main`.

## Prioridades

1. crash/corrupción/bloqueo;
2. errores canónicos que cambien resultado de partida;
3. save incompatibility;
4. input/UI que impida jugar;
5. performance severa;
6. Major/Minor/Cosmetic.

Todo fix sale de un `feature/*`, se valida en `dev/karmany-core` y solo después se promociona a `main` como release pública.

Mantener compatibilidad de saves según la política que se apruebe en F47/F54.

---

# 17. Track paralelo de salida pública

Este track comienza antes de Gold, pero nunca debe bloquear ingeniería con assets prematuros ni anunciar features no confirmadas.

## Producto

- `D-REL-01` plataforma(s) inicial(es);
- `D-REL-02` canal(es) de distribución;
- `D-REL-03` modelo comercial/precio;
- `D-REL-04` idioma(s) de lanzamiento;
- `D-REL-05` modos incluidos en 1.0;
- `D-REL-06` demo sí/no y alcance;
- `D-REL-07` requisitos mínimos/recomendados tras profiling real.

## Marca y comunicación

- `D-REL-08` nombre/logo finales;
- `D-REL-09` dirección de arte pública;
- `D-REL-10` tono de descripción/marketing;
- screenshots finales;
- trailer o gameplay capture si aplica;
- press kit si aporta valor;
- página pública/tienda según canal.

## Tecnología y privacidad

- `D-REL-11` dispositivos de input soportados;
- `D-REL-12` telemetría pública: ninguna / local / servicio aprobado;
- `D-REL-13` crash reporting;
- `D-REL-14` cloud save si la plataforma elegida lo soporta y se decide usar;
- `D-REL-15` estrategia de actualizaciones.

## Producción audiovisual

- `D-REL-16` origen de arte y licencias;
- `D-REL-17` origen de música/SFX y licencias;
- `D-REL-18` créditos y atribución;
- `D-REL-19` clasificación de edad/regiones una vez definidas las tiendas/mercados.

Estas decisiones son de producto/negocio o diseño y no deben ser resueltas automáticamente por Codex/Astra.

---

# 18. Estrategia de pruebas hasta 1.0

## 18.1 Regla principal

Ante múltiples fallos, corregir **el primer error real**. No perseguir cascadas hasta resolver la causa raíz.

## 18.2 Niveles

### Nivel A — Test focalizado

La escena/test del componente modificado.

### Nivel B — Regresión de familia

Ejemplos: tiles, Karmany, Bestias, Equipo, Resonancias, Objetivos/Misiones, Entrenadores, choices, save, IA.

### Nivel C — Auditorías canónicas

Preservar especialmente:

- `phase_43_closure_audit_test.tscn`;
- `phase_44_logic_coverage_test.tscn`;
- `phase_44_8_final_runtime_audit_test.tscn`.

### Nivel D — Integración de partida

Preservar/regenerar cobertura de:

- full match;
- setup;
- game shell;
- restart;
- HUD F46;
- choices F45/F46;
- F47 save/load cuando exista.

### Nivel E — Soak / lifecycle

Repetición de partidas, restart, carga, cambio de escena y teardown buscando fugas de estado.

### Nivel F — Build exportado

Smoke y QA sobre el ejecutable real de cada plataforma de release.

## 18.3 Tests no son autorización para cambiar canon

Si una prueba contradice una fuente canónica aprobada, no modificar automáticamente el canon para hacer pasar el test. Identificar cuál contrato quedó obsoleto y elevar la inconsistencia.

---

# 19. Criterios de diseño de arquitectura

Hasta 1.0, favorecer:

- estado de gameplay fuera de la UI;
- servicios/resolvers reutilizables;
- datos canónicos separados de presentación;
- `ChoiceRequest`/resolvers explícitos para elecciones humanas;
- IA consumiendo acciones legales del mismo dominio;
- serialización basada en datos estables;
- escenas de UI como proyección/control, no como motor de reglas;
- lifecycle explícito;
- módulos pequeños pero no fragmentados artificialmente;
- pruebas sobre contratos observables.

Evitar:

- segunda fuente de verdad en HUD;
- bridges temporales que terminen siendo arquitectura paralela permanente;
- acceder a nodos por rutas frágiles cuando existe un contrato mejor;
- lógica canónica en animaciones;
- esperar tiempos arbitrarios para corregir race conditions;
- constantes con expresiones runtime inválidas;
- nombres que colisionen con métodos heredados de Godot;
- coroutines que puedan reanudarse después de teardown;
- conservar objetos runtime completos dentro del save.

---

# 20. Riesgos principales

| Riesgo | Impacto | Mitigación |
|---|---|---|
| 155 `PARTIAL` + 36 `DATA_ONLY` esconden trabajo de producto | Alto | F48 con disposición explícita por componente |
| Save F26 representa una arquitectura anterior | Alto | F47 audita y migra; no duplicar servicio |
| Bridges/UI acumulados generan fuentes paralelas | Alto | F49/F52 consolidan contratos y eliminan duplicación demostrada |
| Choices humanas incompletas pueden auto-resolverse | Crítico | Mantener patrón F45/F46 y pruebas específicas |
| Lifecycle tras restart/load | Alto | Soak tests y teardown explícito |
| IA diverge de reglas humanas | Alto | Acciones legales y resolvers compartidos |
| Arte final introduce problemas de legibilidad/performance | Medio/Alto | Pipeline + profiling en F50/F52 |
| Plataforma se decide demasiado tarde | Alto | Resolver D-REL-01/02 antes de cerrar F51/F52 |
| Scope creep después de Feature Complete | Alto | Content Lock y change control |
| Telemetría Alpha pasa inadvertidamente a público | Alto | Decisión D-REL-12 y auditoría de privacidad |
| Assets con licencias incompletas | Alto | Inventario desde F50, gate legal F54 |
| Debug/probes quedan en build público | Medio/Alto | configuración de release + smoke exportado |

---

# 21. Definition of Done por bloque

Un bloque no está terminado porque “compila”. Debe cumplir lo aplicable:

- objetivo delimitado;
- fuente canónica identificada;
- implementación sin duplicar arquitectura innecesariamente;
- test focalizado pasa;
- regresiones relevantes pasan;
- no aparecen errores nuevos de parser/runtime;
- no hay nodos orphan o teardown inválido provocado por el cambio;
- docs/estado actualizados;
- commit cohesivo;
- prueba local indicada;
- resultado esperado explícito;
- pendiente de aprobación hasta que el propietario diga “prueba correcta”.

---

# 22. Protocolo de trabajo para Codex / Astra

Antes de cada tarea, Codex/Astra debe seguir este contrato:

```text
1. Verifica el estado REAL del repositorio remoto.
2. Identifica dev/karmany-core y su HEAD actual; no dependas de memoria previa.
3. Lee docs/roadmap_to_1_0.md y la documentación de la fase afectada.
4. Inspecciona primero código, tests y datos canónicos existentes.
5. No inventes contenido ni reglas faltantes.
6. Si el cambio es técnico, claro y de bajo riesgo, impleméntalo en feature/*.
7. Si exige una decisión de canon, balance, alcance público o arquitectura crítica ambigua, detén solo ese punto y registra la decisión.
8. Trabaja en bloques cohesionados; para campañas de contenido, 8–15 componentes cuando sea razonable.
9. Encuentra el primer error real; no debilites pruebas ni ocultes errores con waits/watchdogs.
10. Ejecuta test focalizado + regresiones afectadas.
11. Reporta: HECHO / COMMIT-RAMA / PRUEBA LOCAL / RESULTADO ESPERADO / SIGUIENTE PASO.
12. No integres trabajo pendiente de validación a main.
13. Tras “prueba correcta”, integra de forma segura a dev/karmany-core, verifica el nuevo baseline y continúa con el siguiente bloque lógico si no hay decisión pendiente.
```

### 22.1 Inicio recomendado de cada fase

Codex/Astra debe producir primero un **Phase Audit** pequeño que confirme:

- baseline/HEAD;
- archivos que son fuente de verdad;
- contratos protegidos;
- gaps reales;
- pruebas que deben permanecer verdes;
- scope exacto del primer bloque.

Después implementa, en lugar de crear una planificación paralela extensa desconectada del repositorio.

---

# 23. Dashboard operativo

Actualizar esta tabla al aprobar bloques/fases.

| Hito | Estado | Evidencia/commit | Bloqueo |
|---|---|---|---|
| Baseline F46 | `INTEGRATED_BASELINE` | `61012b1` al crear roadmap | — |
| Roadmap 1.0 | `INTEGRATED_BASELINE` (aprobado) | `f8d0faae94279e906857bbcdb7a2db2bcd025263` | — |
| F47 | `IN_PROGRESS` | F47.1: [auditoría y diagnóstico](phase_47_1_save_persistence_audit.md) | decisiones de persistencia documentadas |
| F47.1 | `READY_FOR_VALIDATION` | `feature/f47-1-save-persistence-audit` | “prueba correcta” |
| F48 | `PLANNED` | — | decisiones canónicas que aparezcan |
| F49 | `PLANNED` | — | alcance 1.0 |
| F50 | `PLANNED` | — | dirección audiovisual |
| F51 | `PLANNED` | — | inputs/idiomas/plataformas |
| F52 | `PLANNED` | — | hardware/plataformas objetivo |
| F53 | `PLANNED` | — | canal Beta si se usa |
| F54 | `PLANNED` | — | D-REL-01..19 aplicables |
| F55 | `PLANNED` | — | aprobación Gold |
| 1.0.0 | `NOT_RELEASED` | — | F47–F55 |

Estados válidos recomendados:

- `PLANNED`
- `IN_PROGRESS`
- `BLOCKED_DECISION`
- `READY_FOR_VALIDATION`
- `APPROVED`
- `INTEGRATED_BASELINE`
- `CONTENT_LOCKED`
- `RC`
- `GOLD`
- `RELEASED`

---

# 24. Checklist final 1.0

## Canon y gameplay

- [ ] alcance 1.0 aprobado;
- [ ] auditoría canónica vigente consistente;
- [ ] todos los `PARTIAL/DATA_ONLY` del alcance tienen disposición explícita;
- [ ] ningún flujo humano esencial se auto-resuelve indebidamente;
- [ ] IA utiliza acciones/reglas válidas;
- [ ] partida completa termina correctamente;
- [ ] modos públicos aprobados validados.

## Persistencia

- [ ] save/load/continue actual;
- [ ] corrupción/incompatibilidad segura;
- [ ] restart limpio;
- [ ] nueva partida limpia;
- [ ] política de compatibilidad definida.

## UX

- [ ] menú/setup/partida/pausa/resultado completos;
- [ ] feedback de acciones;
- [ ] secretos protegidos;
- [ ] input aprobado completo;
- [ ] settings completos;
- [ ] accesibilidad auditada;
- [ ] idiomas aprobados validados.

## Audiovisual

- [ ] dirección final aprobada;
- [ ] placeholders públicos eliminados;
- [ ] arte integrado;
- [ ] animaciones integradas;
- [ ] VFX legibles;
- [ ] música/SFX integrados;
- [ ] mezcla/volúmenes configurables;
- [ ] licencias documentadas.

## Calidad técnica

- [ ] Blocker = 0;
- [ ] Critical = 0;
- [ ] regresiones críticas verdes;
- [ ] lifecycle/soak aprobado;
- [ ] performance aprobada en hardware objetivo;
- [ ] logs/configuración de release limpios.

## Distribución

- [ ] plataforma(s) aprobadas;
- [ ] exports reproducibles;
- [ ] build identifica commit/version;
- [ ] smoke test del artefacto real;
- [ ] licencias/créditos;
- [ ] privacidad/telemetría resuelta;
- [ ] requisitos de tienda cumplidos;
- [ ] iconos/key art/screenshots/descripciones finales;
- [ ] requisitos de sistema verificados;
- [ ] precio/modelo comercial resuelto.

## Gold

- [ ] Content Lock vigente;
- [ ] RC final aprobado;
- [ ] commit Gold identificado;
- [ ] promoción a `main` aprobada;
- [ ] tag/versionado aprobado;
- [ ] artefacto público coincide con Gold;
- [ ] plan post-launch activo.

---

# 25. Siguiente acción al aprobar este roadmap

La siguiente fase lógica es **F47 — guardado/carga/continuación**.

Primer bloque recomendado: **F47.1 Auditoría de persistencia actual**, partiendo del HEAD vigente de `dev/karmany-core`, comparando `scripts/save/*`, `phase_26_save_system_test` y la estructura real de `KarmanyFullMatchSession`/F45/F46.

Ese bloque debe terminar con un mapa explícito de qué estado ya se persiste, qué estado actual falta y qué datos son transitorios, antes de modificar el formato de save.

---

## Historial del roadmap

- `2026-09-04` — creación del roadmap Alpha → 1.0 a partir de `dev/karmany-core@61012b1`.
