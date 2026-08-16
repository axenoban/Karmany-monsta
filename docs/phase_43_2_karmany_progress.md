# Fase 43.2 — Karmany

Fuente canónica: documento maestro v0.74, sección 16.9 `Karmany - 28 cartas`.

## Alcance

Tras validar F43.1 localmente, F43.2 materializa la categoría Karmany completa en un solo lote controlado.

Cobertura física final: **28/28 Karmany canónicos**.

- 13 Resources preexistentes permanecen directamente en `res://data/karmanys` para conservar el baseline runtime.
- 15 identidades que faltaban se materializan en `res://data/karmanys/canonical_pending`.
- `KarmanyPhase37AlphaContentCatalog.load_category()` solo enumera archivos `.tres` directamente presentes en el directorio de categoría, por lo que la subcarpeta pendiente no se incorpora accidentalmente al runtime.

## Identidades pendientes materializadas

K-06 Brisu, K-07 Rocerno, K-08 Mistolin, K-12 Nimbara, K-13 Ferrak, K-14 Selenix, K-15 Lignar, K-16 Volcrin, K-17 Orial, K-18 Torkal, K-19 Velkar, K-20 Dravok, K-21 Celestia, K-22 Runakar y K-23 Eryndra.

Cada una conserva nombre, subtítulo, nivel, tipo, Poder, Defensa de vínculo, PL directo, métodos/costos de obtención y texto completo de Habilidad v0.74. Su `KarmanyAbilityData` usa `trigger_id = pending_f44` y `effects` vacío: la identidad/regla está materializada, pero no se anuncia una automatización inexistente.

## Correcciones maestro → repositorio

Se normalizaron Resources preexistentes donde la tabla v0.74 contenía información más precisa:

- K-03 Pyrox: texto completo de la habilidad, incluyendo el impacto alto de las caras 5-6.
- K-04 Lumirra: habilidad separada correctamente de `acquisition_text` y preservada completa.
- K-09 Verdan: el texto de Habilidad v0.74 queda preservado explícitamente aunque no otorgue un efecto adicional.
- K-11: nombre canónico `Rauk Colmillo`, subtítulo `Depredador Salvaje` y habilidad separada de obtención.
- K-24 Aeterna Draconis: condición de obtención completa de v0.74 y texto completo de su habilidad/condición legendaria.
- K-26 Umbrio y K-28 Vulkai: sus habilidades dejan de estar embebidas en obtención y pasan a `KarmanyAbilityData`.

No se inventaron `KarmanyEffectData` para estas reglas. La cobertura lógica completa de habilidades que aún no tengan resolver corresponde a F44.

## Estado de runtime

F43.2 no amplía el directorio runtime directo: permanece en **13 Resources**. El setup continúa exponiendo exactamente los **8 Karmany iniciales**: K-01, K-02, K-03, K-04, K-25, K-26, K-27 y K-28.

Los 15 nuevos Resources canónicos permanecen aislados hasta que F44 pueda automatizar correctamente sus habilidades y decisiones.

## Test integral

Escena:

`res://tests/phase_43_2_karmany_complete_test.tscn`

Comprueba:

1. 28/28 Resources cargables y válidos;
2. IDs únicos K-01..K-28;
3. nombre, subtítulo, nivel, Poder, Defensa, PL directo y Habilidad v0.74 de las 28 identidades;
4. conjunto inicial exacto de 8 Karmany;
5. exactamente 15 pendientes F44;
6. todos los pendientes usan `trigger_id = pending_f44`;
7. ningún pendiente contiene efectos ejecutables inventados;
8. el catálogo directo de F37 permanece en 13 Resources y no recorre la subcarpeta pendiente.

Resultado esperado:

`FASE 43.2 OK - 28/28 Karmany canonicos materializados; pendientes aislados del runtime hasta F44.`

F43.3 Bestias no se inicia hasta completar la validación local de F43.2 y regresiones correspondientes.
