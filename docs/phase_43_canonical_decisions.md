# Fase 43 — Decisiones canónicas posteriores a F43.0

Fecha de decisión: 2026-08-15.

Este documento complementa `docs/phase_43_canonical_content_audit.md` y registra decisiones explícitas del autor posteriores a la auditoría F43.0. No crea Resources ni modifica gameplay por sí mismo.

## Regla de precedencia para F43

1. El **documento maestro más reciente v0.74** es la fuente canónica principal para contenido, nombres, valores, textos, costes, recompensas, condiciones y comportamiento documentado.
2. Si existe una desigualdad entre el documento maestro reciente y contenido ya presente en el repositorio, **se aplicará el documento maestro reciente**, salvo una excepción explícita registrada por el autor.
3. No se reconstruirá contenido ausente desde memoria, conversaciones anteriores ni IDs del repositorio. Si un dato no aparece o sigue siendo ambiguo en el maestro, se marcará como `PENDIENTE/CONFLICTO` y no se inventará.

## Excepción canónica explícita — repetición de Explorar

La redacción del documento maestro v0.74 que indica que `Explorar` no puede repetirse dentro del mismo turno se considera una aplicación incompleta/desactualizada de la regla prevista.

Decisión canónica del autor para el proyecto digital:

- `Explorar` **sí puede realizarse más de una vez en un mismo turno**, siempre que cada uso sea legal y consuma una de las acciones disponibles.
- Se preserva por tanto el comportamiento aprobado de F38–F42 que permite múltiples exploraciones legales en un turno.
- Esta decisión tiene prioridad sobre las líneas contradictorias del documento maestro que dicen `excepto Explorar` o `No se repite en el mismo turno`.
- F43 no debe introducir un limitador de una sola exploración por turno.

## Resolución de conflictos R-06 y R-07

Para estas dos Resonancias se aplica sin excepción el documento maestro v0.74.

### R-06

Canónico para F43:

- ID: `R-06`
- Nombre: `Chispa del Libro`
- Tipo/ventana: Ataque / Combate
- Poder impreso: `+3`
- Efecto: si tienes Libro II o III, roba 2 Resonancias y descarta 1.

El Resource persistente actual que usa el nombre `Eco del Libro` se considera no fiel al maestro y deberá corregirse en la subfase correspondiente, preservando el ID canónico `R-06`.

### R-07

Canónico para F43:

- ID: `R-07`
- Nombre: `Golpe Certero`
- Tipo/ventana: Ataque / Combate
- Poder impreso: `+4`
- Efecto: si esta carta hace que el Poder iguale exactamente la Defensa, roba 1 Resonancia.

El Resource persistente actual que usa el nombre `Filo Exacto` se considera no fiel al maestro y deberá corregirse en la subfase correspondiente, preservando el ID canónico `R-07`.

## Aplicación futura

Estas decisiones deben usarse como criterio de revisión en todas las subfases F43.x:

- Maestro v0.74 prevalece sobre contenido previo del repositorio.
- La única excepción registrada hasta ahora es la repetición de `Explorar`, que permanece permitida más de una vez por turno cuando cada uso sea legal.
- Cualquier nueva contradicción maestro ↔ repositorio se resolverá aplicando el maestro reciente, salvo que el autor dé una excepción explícita equivalente a la anterior.
- La automatización se realizará incrementalmente; esta decisión no autoriza implementar categorías no solicitadas ni inventar comportamiento ausente.

F43.1 no se inicia mediante este documento.