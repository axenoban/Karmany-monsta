# Contrato operativo de Karmany Monsta

- Trabajar en este workspace Godot/GDScript; no duplicar el repositorio ni crear otro proyecto.
- Antes de cada misión: revisar `git status`, rama, diff y remoto; ejecutar `git fetch origin --prune` y verificar el HEAD real de `origin/dev/karmany-core`. Preservar cambios locales e inspeccionar features existentes antes de reutilizarlas.
- `main` contiene versiones publicables; `dev/karmany-core`, el baseline validado; `feature/*`, trabajo pendiente de validación. Crear features desde el baseline remoto vigente. Nunca force-push, reset hacia atrás para coincidir con un prompt, rebase/squash de trabajo aprobado ni reescritura de historia.
- Leer `docs/roadmap_to_1_0.md` y documentación, código y tests de la fase antes de programar. Respetar su jerarquía de verdad: canon y decisiones aprobadas, catálogo reconciliado, tests aprobados, runtime estable, documentación de fase, roadmap. El comportamiento accidental no redefine esas fuentes.
- No inventar reglas, balance, nombres, contenido ni lore. Proteger F1–F46; evitar refactors oportunistas y sistemas paralelos cuando exista uno reutilizable.
- Mantener `KarmanyFullMatchSession` como fuente actual de gameplay salvo decisión aprobada demostrable. La UI es una proyección; nunca fuente de verdad. Respetar privacidad y compuerta de revelación visual.
- Separar datos persistentes, derivados y transitorios. No guardar Nodes, SceneTree, conexiones de señales, Timers, Callables, coroutines ni identidades de objetos Godot como estado de partida. Reconstruir referencias con contratos explícitos.
- Godot local es el entorno real de validación. Verificar versión/configuración sin cambiar el proyecto para acomodar el entorno. Ejecutar pruebas focales y regresiones afectadas; distinguir contratos funcionales, errores, deuda de lifecycle y ruido de entorno.
- Investigar el primer error real. No eliminar ni debilitar asserts, aumentar waits arbitrariamente o añadir watchdogs para ocultar fallos. Documentar causa, evidencia y limitaciones.
- Trabajar en bloques cohesionados. Tras cada checkpoint completo y estable, crear un commit semántico y hacer push a la feature; revisar exactamente qué archivos se incluyen. Preservar y clasificar los `.uid` de Godot, sin borrarlos o incorporarlos a ciegas.
- Ante una decisión real de producto/canon o una operación destructiva/arquitectónica irreversible, detener ese punto y pedir decisión; continuar las partes independientes. No introducir políticas de guardado no aprobadas.
- Entregar evidencia, pruebas y siguiente alcance para validación. No integrar en `dev/karmany-core` sin la validación del propietario (**“prueba correcta”**) ni publicar en `main` automáticamente. Si el bloque exige detenerse, no implementar el siguiente.
