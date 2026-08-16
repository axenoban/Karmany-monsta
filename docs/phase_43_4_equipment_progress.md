# Fase 43.4 — Equipo

Fuente canónica: documento maestro v0.74, sección 16.11 `Equipo - 36 cartas`.

## Alcance

Tras validar localmente F43.3, F43.4 materializa la categoría Equipo completa en un solo lote controlado.

Cobertura física final: **36/36 Equipos canónicos**.

- 9 Resources preexistentes permanecen directamente en `res://data/equipment` para conservar el baseline runtime.
- 27 identidades que faltaban se materializan en `res://data/equipment/canonical_pending`.
- `KarmanyPhase37AlphaContentCatalog.load_category()` solo enumera archivos `.tres` directamente presentes en el directorio de categoría, por lo que la subcarpeta pendiente no entra accidentalmente en el mercado/runtime.

## Identidades pendientes materializadas

EQ-06, EQ-07, EQ-10, EQ-11, EQ-12, EQ-13, EQ-14, EQ-15, EQ-16, EQ-17, EQ-18, EQ-20, EQ-21, EQ-22, EQ-23, EQ-24, EQ-25, EQ-26, EQ-27, EQ-28, EQ-29, EQ-30, EQ-31, EQ-32, EQ-33, EQ-35 y EQ-36.

Cada Resource conserva ID, nombre, rareza, costo v0.74 y texto completo del efecto v0.74.

Los 27 nuevos Resources usan `trigger_tags = PackedStringArray("pending_f44")` y mantienen `modifiers` vacío. Esto materializa la identidad/regla sin declarar automatización que todavía no existe.

## Auditoría de los 9 Resources preexistentes

Se contrastaron EQ-01, EQ-02, EQ-03, EQ-04, EQ-05, EQ-08, EQ-09, EQ-19 y EQ-34 contra la tabla 16.11 del maestro v0.74.

Sus IDs, nombres, rarezas, costos y `rules_text` ya coinciden con el maestro, por lo que F43.4 no necesitó reescribir esos nueve Resources. Los modificadores ya existentes permanecen sin cambios.

## Estado de runtime

F43.4 no amplía el directorio runtime directo: permanece en **9 Resources**.

El conjunto considerado runtime-safe por F37 permanece exactamente en **6 Equipos**:

- EQ-01 Cristal de Crecimiento
- EQ-02 Guante Runico
- EQ-03 Baculo de Bruma
- EQ-05 Nucleo Luminico
- EQ-08 Prisma Ancestral
- EQ-09 Catalizador de Aeterna

EQ-04, EQ-19 y EQ-34 continúan materializados directamente pero con su estado histórico de integración pendiente. Los 27 nuevos quedan aislados en `canonical_pending` hasta F44.

## Test integral

Escena:

`res://tests/phase_43_4_equipment_complete_test.tscn`

Comprueba:

1. 36/36 Resources cargables y válidos;
2. IDs únicos EQ-01..EQ-36;
3. nombre, rareza, costo y efecto v0.74 de las 36 identidades;
4. exactamente 9 Resources en el directorio runtime directo;
5. exactamente 27 Resources en `canonical_pending`;
6. todos los pendientes usan `pending_f44`;
7. ningún pendiente contiene `modifiers` ejecutables inventados;
8. el pool runtime-safe permanece exactamente en EQ-01, EQ-02, EQ-03, EQ-05, EQ-08 y EQ-09.

Resultado esperado:

`FASE 43.4 OK - 36/36 Equipos canonicos materializados; pendientes aislados del runtime hasta F44.`

F43.5 Resonancias no se inicia hasta completar la validación local de F43.4 y sus regresiones.
