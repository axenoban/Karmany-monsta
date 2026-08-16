# Fase 43.5 — Resonancias

Fuente canonica: documento maestro v0.74, seccion 16.12 `Resonancias - 40 cartas`.

## Alcance

Tras validar localmente F43.4, F43.5 materializa la categoria Resonancias completa en un solo lote controlado.

Cobertura fisica final: **40/40 Resonancias canonicas**.

- 13 Resources preexistentes permanecen directamente en `res://data/resonances` para conservar el baseline runtime.
- 27 identidades faltantes se materializan en `res://data/resonances/canonical_pending`.
- `KarmanyPhase37AlphaContentCatalog.load_category()` no recorre la subcarpeta pendiente, por lo que las nuevas cartas no entran accidentalmente al runtime directo.

## Identidades pendientes materializadas

R-10, R-11, R-12, R-14, R-15, R-16, R-17, R-18, R-19, R-21, R-23, R-24, R-25, R-26, R-27, R-28, R-29, R-30, R-31, R-32, R-33, R-34, R-35, R-36, R-38, R-39 y R-40.

Cada Resource conserva ID, nombre, tipo, valor impreso, ventana de uso y texto completo del efecto v0.74. Los 27 nuevos usan `tags = PackedStringArray("canonical_v074", "pending_f44")` y mantienen `modifiers` y `effect_blocks` vacios: la identidad/regla queda materializada sin declarar automatizacion inexistente.

## Correcciones canonicas y normalizacion de Resources existentes

Por decision explicita del autor, el documento maestro reciente prevalece sobre los Resources antiguos.

Correcciones de identidad:

- R-06 se corrige de `Eco del Libro` a **`Chispa del Libro`**, +3, Combate, con efecto `Si tienes Libro II o III, roba 2 Resonancias y descarta 1.`
- R-07 se corrige de `Filo Exacto` a **`Golpe Certero`**, +4, Combate, con efecto `Carta segura de buen valor. Si esta carta te hace igualar exactamente la Defensa, roba 1 Resonancia.`

Ademas, durante la auditoria completa de los 13 Resources preexistentes se detectaron textos resumidos respecto del campo `Efecto v0.74`. Se normalizaron sin eliminar sus estructuras automatizadas existentes:

- R-02 Golpe Salvaje: recupera el texto completo del Dado de Riesgo 2.0 y su prohibicion de repeticion/modificacion.
- R-05 Furia Controlada: recupera la redaccion completa de uso PvP, penalizacion y autorizacion del Dado de Riesgo.
- R-20 Ultima Defensa: recupera la condicion canonica `Si pierdes de todos modos`.
- R-22 Mirada del Sendero: el `rules_text` queda alineado literalmente con el efecto del maestro.
- R-37 Instinto de Caza: el `rules_text` queda alineado literalmente con `En un combate contra Bestia, gana +2 Poder.`

R-01, R-03, R-04, R-08, R-09 y R-13 ya contenian el efecto completo del maestro dentro de su `rules_text`; sus estructuras automatizadas se preservan.

Se conservan los IDs y las rutas fisicas actuales de los 13 Resources directos para evitar churn de referencias. Ninguna de estas normalizaciones agrega automatizacion nueva: solo alinea identidad/texto con v0.74 y conserva los `modifiers`/`effect_blocks` ya existentes.

## Runtime y fallback

F43.5 no reemplaza los resolvers existentes ni automatiza las 27 cartas nuevas. El directorio directo permanece en 13 Resources. `KarmanyV074CanonicalRuntimeCatalog` ya contiene las 40 definiciones canonicas y mantiene la lista historica de 13 Resonancias identificadas como automatizadas; F43.5 no modifica esa arquitectura.

## Test integral

Escena:

`res://tests/phase_43_5_resonances_complete_test.tscn`

Comprueba:

1. 40/40 Resources cargables y validos;
2. IDs unicos R-01..R-40;
3. nombre, tipo, valor, ventanas y texto de efecto contra las definiciones canonicas v0.74;
4. exactamente 13 Resources directos y 27 en `canonical_pending`;
5. todos los pendientes marcados `pending_f44`;
6. ningun pendiente contiene `modifiers` o `effect_blocks` ejecutables inventados;
7. el fallback canonico sigue construyendo 40 identidades;
8. la lista de 13 Resonancias automatizadas no cambia;
9. R-06 y R-07 usan definitivamente los nombres y efectos del maestro reciente.

Resultado esperado:

`FASE 43.5 OK - 40/40 Resonancias canonicas materializadas; R-06/R-07 corregidas y pendientes aisladas hasta F44.`

F43.6 Objetivos/Misiones no se inicia hasta completar la validacion local de F43.5 y sus regresiones.
