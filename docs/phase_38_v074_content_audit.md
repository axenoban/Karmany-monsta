# Fase 38 — Auditoría de contenido canónico v0.74

Fuente: `Karmany Monsta: Forja de Resonancia — Libro de Reglas e Información Completa v0.74`.

Esta auditoría separa **contenido canónico documentado**, **Resource materializado en el repositorio** y **automatización digital**. La ausencia de un `.tres` no autoriza inventar reglas; la presencia de texto canónico tampoco implica que su efecto secundario ya esté automatizado.

| Categoría | Canónico v0.74 | Materializado antes de F38 | Tratamiento F38 |
|---|---:|---:|---|
| trainers | 8 | 8 | 8 disponibles; F38 asigna 4 únicos por seed. |
| tiles | 41 | 13 | Se conserva F32 fallback para completar mapa 41; no se inventan 28 losetas. |
| karmanys | 28 | 13 | 8 iniciales ya existen; pool no inicial usa solo Resources seguros. |
| beasts | 24 | 7 | Se usan mazos reales por tier con los Resources seguros existentes. |
| equipment | 36 | 9 | Mercado real de 4 desde Resources seguros existentes. |
| resonances | 40 | 13 | F38 construye el catálogo canónico 40: Resources existentes prevalecen; faltantes se materializan como `KarmanyResonanceData` de texto canónico en memoria. Efectos secundarios no estructurados NO se autoejecutan. |
| objectives | 12 | 8 | F38 revela 1 por cada familia entre los Objetivos ejecutables materializados. |
| missions | 16 | 9 | F38 usa Misiones existentes y añade fallback canónico ejecutable solo para las recomendadas de Maelis/Saira necesarias para permitir los 8 Entrenadores. |

## IDs canónicos aún no materializados como `.tres` antes de F38

### trainers
Ninguno.

### tiles
`N1-05`, `N1-06`, `N1-07`, `N1-08`, `N1-09`, `N1-10`, `N1-11`, `N1-12`, `N1-13`, `N1-14`, `N1-15`, `N1-16`, `N1-17`, `N1-18`, `N2-02`, `N2-03`, `N2-04`, `N2-06`, `N2-07`, `N2-08`, `N2-09`, `N2-10`, `N2-11`, `N2-12`, `N3-01`, `N3-04`, `N3-05`, `N3-06`

### karmanys
`K-06`, `K-07`, `K-08`, `K-12`, `K-13`, `K-14`, `K-15`, `K-16`, `K-17`, `K-18`, `K-19`, `K-20`, `K-21`, `K-22`, `K-23`

### beasts
`B-03`, `B-05`, `B-06`, `B-08`, `B-09`, `B-10`, `B-11`, `B-12`, `B-13`, `B-14`, `B-16`, `B-17`, `B-18`, `B-19`, `B-20`, `B-21`, `B-24`

### equipment
`EQ-06`, `EQ-07`, `EQ-10`, `EQ-11`, `EQ-12`, `EQ-13`, `EQ-14`, `EQ-15`, `EQ-16`, `EQ-17`, `EQ-18`, `EQ-20`, `EQ-21`, `EQ-22`, `EQ-23`, `EQ-24`, `EQ-25`, `EQ-26`, `EQ-27`, `EQ-28`, `EQ-29`, `EQ-30`, `EQ-31`, `EQ-32`, `EQ-33`, `EQ-35`, `EQ-36`

### resonances
`R-10`, `R-11`, `R-12`, `R-14`, `R-15`, `R-16`, `R-17`, `R-18`, `R-19`, `R-21`, `R-23`, `R-24`, `R-25`, `R-26`, `R-27`, `R-28`, `R-29`, `R-30`, `R-31`, `R-32`, `R-33`, `R-34`, `R-35`, `R-36`, `R-38`, `R-39`, `R-40`

### objectives
`OP-E03`, `OP-C02`, `OP-A01`, `OP-A02`

### missions
`ME-N2`, `ME-M1`, `ME-M2`, `ME-K2`, `ME-S1`, `ME-S2`, `ME-O2`

## Regla de integración

- El documento maestro v0.74 es la fuente canónica de cantidades, nombres, costes, defensas, recompensas y textos.
- Los sistemas digitales continúan usando `Karmany*Data`, resolvers y controladores existentes.
- F38 no marca como ejecutable un efecto secundario que solo existe como texto.
- El mazo inicial 4P sí requiere 20 cartas distintas; por eso F38 importa la identidad/poder/ventana/texto de las 40 Resonancias canónicas en el catálogo runtime, manteniendo una lista explícita de las Resonancias cuya automatización ya estaba materializada.
- Las Resonancias con restricciones contextuales que el resolver todavía no puede demostrar de forma genérica no se eligen automáticamente desde un combate incompatible.
- El setup Alpha aplica directamente las bonificaciones de Dorian/Oryn (+1 Resonancia) y el filtro inicial de Maelis. Las bonificaciones de mirar/reordenar mazos de Alderion, Lyra, Nara, Kael y Saira permanecen como datos canónicos hasta disponer de una API privada de peek/reorder que no filtre información.
- La elección de Karmany inicial sigue la regla de revelar 3 y conservar 1, pero el controlador Alpha elige de forma determinista durante el setup automático; la selección visual manual de esos tres candidatos no se finge como implementada.
- La materialización completa de Karmanys, Bestias, Equipos, losetas y cartas restantes queda separada de la lógica de partida para no mezclar expansión de contenido con invención de comportamiento.
