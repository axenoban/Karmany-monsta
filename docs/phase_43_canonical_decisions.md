# Fase 43 — Decisiones canonicas vigentes

Fecha de decision original: 2026-08-15.
Actualizado al cierre de F43.

## Regla de precedencia

1. El **documento maestro reciente v0.74** es la fuente canonica principal para contenido, nombres, valores, textos, costes, recompensas, condiciones y comportamiento documentado.
2. Si existe una desigualdad entre el maestro reciente y contenido previo del repositorio, **prevalece v0.74**, salvo una excepcion explicita registrada por el autor.
3. No se reconstruye informacion ausente desde memoria, conversaciones anteriores ni IDs del repositorio. Un dato realmente ausente o ambiguo se marca pendiente en lugar de inventarse.

## Excepcion canonica — repeticion de Explorar

La unica excepcion explicita registrada durante F43 es la repeticion de `Explorar`:

- `Explorar` **puede realizarse mas de una vez en un mismo turno**.
- Cada uso debe ser legal y consumir una de las acciones disponibles.
- Se conserva el comportamiento aprobado de F38–F42.
- Esta decision prevalece sobre la frase contradictoria del documento maestro que indica `excepto Explorar` / `No se repite en el mismo turno`.
- F44 tampoco debe introducir un limitador de una sola exploracion por turno.

## Resonancias R-06 y R-07 — resueltas

### R-06

Canónico y ya alineado en F43.5:

- ID: `R-06`
- Nombre: `Chispa del Libro`
- Tipo/ventana: Ataque / Combate
- Poder impreso: `+3`
- Efecto: si tienes Libro II o III, roba 2 Resonancias y descarta 1.

El nombre anterior `Eco del Libro` queda obsoleto.

### R-07

Canonico y ya alineado en F43.5:

- ID: `R-07`
- Nombre: `Golpe Certero`
- Tipo/ventana: Ataque / Combate
- Poder impreso: `+4`
- Efecto: si esta carta hace que el Poder iguale exactamente la Defensa, roba 1 Resonancia.

El nombre anterior `Filo Exacto` queda obsoleto.

## Misiones corregidas al maestro

- `ME-M1` — `Resonancia Decisiva`.
- `ME-S1` — `Cartografia Viva`.

Los fallbacks runtime asociados fueron alineados al maestro durante F43.6 sin ampliar artificialmente su cobertura logica.

## Estado al cierre

F43 deja materializadas las ocho categorias canonicas v0.74:

- 8 Entrenadores;
- 41 Losetas MAP41;
- 28 Karmany;
- 24 Bestias;
- 36 Equipos;
- 40 Resonancias;
- 12 Objetivos Publicos;
- 16 Misiones de Entrenador.

Total: **205 identidades canonicas**.

La existencia de un Resource no implica automatizacion completa. El contenido `canonical_pending` permanece aislado hasta que F44 implemente y pruebe su logica correspondiente.

Documento de auditoria final: `docs/phase_43_canonical_content_audit.md`.
Test transversal de cierre: `res://tests/phase_43_closure_audit_test.tscn`.
