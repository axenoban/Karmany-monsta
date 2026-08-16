# Fase 43.7 — Entrenadores

Fuente canonica primaria: documento maestro v0.74, tabla de Entrenadores de las paginas 21–22. F43.7 alinea los 8 Resources existentes con esa fuente y no agrega Entrenadores nuevos.

## Cobertura

- Entrenadores canonicos: **8/8 materializados** directamente en `res://data/trainers`.
- IDs: E-01 Alderion, E-02 Lyra, E-03 Dorian, E-04 Nara, E-05 Maelis, E-06 Kael, E-07 Saira y E-08 Oryn.
- No existe `canonical_pending` para esta categoria porque las ocho identidades ya estaban materializadas.

## Regla de fuente

Se revisan nombre, titulo, estilo estrategico, dificultad, pasiva, activa, bonus de preparacion y nota de balance contra v0.74. Cuando una redaccion anterior era abreviada, se sustituye por la redaccion completa del maestro reciente sin inventar automatizacion.

## Cobertura digital

`automation_status` describe la cobertura real del Entrenador completo, no solo que su Resource exista.

- `PARTIAL`: E-03 Dorian, E-05 Maelis y E-08 Oryn. El setup aprobado de F41 ya automatiza sus bonos de Resonancia, pero sus pasivas/activas completas siguen fuera del alcance de F43.
- `DATA_ONLY`: E-01 Alderion, E-02 Lyra, E-04 Nara, E-06 Kael y E-07 Saira. Sus bonus de setup requieren mirar/reordenar informacion privada o losetas y no se declaran automatizados en F43.
- `EXECUTABLE`: ninguno. F43 no eleva artificialmente ningun Entrenador a cobertura total.

F44 queda como responsable de implementar la cobertura logica pendiente de pasivas, activas y setup complejo donde corresponda.

## Normalizaciones de texto

Se conserva el contenido ya coincidente y se completan redacciones de balance abreviadas de Alderion, Lyra, Nara y Saira para que coincidan con el maestro. Maelis y Oryn se marcan `PARTIAL` para reflejar el setup ya existente; Dorian ya tenia ese estado.

No se modifica TurnManager, MAP41, IA, combate, PvP, privacidad, Game Shell ni el flujo de seleccion de Mision.

## Test integral

Escena:

`res://tests/phase_43_7_trainers_complete_test.tscn`

Comprueba:

1. exactamente 8 Resources directos de Entrenador;
2. IDs de carta y `trainer_id` unicos;
3. identidad, titulo, estilo, dificultad, pasiva, activa, setup y balance contra v0.74;
4. `is_valid_definition()` para los ocho;
5. E-03/E-05/E-08 en `PARTIAL`, los otros cinco en `DATA_ONLY` y ninguno en `EXECUTABLE`;
6. no existe materializacion artificial adicional para esta categoria.

Resultado esperado:

`FASE 43.7 OK - 8/8 Entrenadores canonicos alineados; 3 parciales y 5 data-only hasta F44.`

## Validacion

Validacion local reportada por el autor: **exitosa**.

F43.7 queda cerrada y la siguiente comprobacion es el test transversal `res://tests/phase_43_closure_audit_test.tscn`, que certifica conteos, set exacto de IDs y ausencia de duplicados en las ocho categorias antes de iniciar F44.
