# Fase 43.0 — Auditoría documento maestro ↔ repositorio

## Alcance

Esta auditoría compara exclusivamente el documento maestro **Karmany Monsta: Forja de Resonancia — Libro de Reglas e Información Completa v0.74, Movimiento, Progresión e Instinto** con el estado del repositorio al iniciar F43.

Baseline verificado: `dev/karmany-core` @ `de5ff2c5cd11710c333eaea449694a9c452ae3d1`.

Rama de auditoría: `feature/phase-43-canonical-content`, creada desde ese mismo SHA.

F43.0 no crea Resources, no modifica pools, fallback, gameplay, IA, mapa, scoring, lifecycle F42 ni `project.godot`.

## Criterio A/B/C/D

- **A** — Canónico + materializado + ejecutable, con automatización completa demostrable para el contrato actual.
- **B** — Canónico y materializable, pero falta Resource, integración o automatización total/parcial.
- **C** — Canónico pero el documento no aporta datos suficientes para materializar sin asumir.
- **D** — No canónico / no encontrado en el documento: no crear.

En F43.0 se aplica criterio conservador: que un Resource sea runtime-safe no basta para declararlo A si no se certificó la automatización completa de su habilidad/efecto.

## Resumen de cobertura

| Categoría | Canónico v0.74 | `.tres` actual | Runtime utilizable/identidad | Automatización completa certificada F43.0 | Pendiente principal |
|---|---:|---:|---:|---:|---|
| Entrenadores | 8 | 8 | 8 | 0 cartas completas* | 5 bonus de setup y cobertura integral de pasivas/activas |
| Losetas MAP41 | 41 | 13 | 13 | 0 integrales** | 28 `.tres`; revisar tres campos funcionales y efectos estructurados |
| Karmany | 28 | 13 | 13 | 0 habilidades integrales certificadas | 15 `.tres` + automatización de habilidades |
| Bestias | 24 | 7 | 5 en mazos seguros | 0 integrales certificadas | 17 `.tres`; 2 Resources existentes aún fuera del runtime seguro |
| Equipos | 36 | 9 | 6 en mercado seguro | 0 integrales certificadas | 27 `.tres`; 3 Resources existentes aún fuera del runtime seguro |
| Resonancias | 40 | 13 | 40 identidades / 13 marcadas automatizadas | 11 sin conflicto detectado | 27 `.tres`; R-06/R-07 tienen discrepancia de nombre del Resource |
| Objetivos Públicos | 12 | 8 | 8 | 8 | 4 `.tres` + tracker/eventos |
| Misiones | 16 | 9 | 11 (9 Resources + 2 fallbacks) | 9 Resources | 7 `.tres`; 2 de esos 7 tienen fallback runtime |

\* Dorian, Maelis y Oryn sí tienen bonificación inicial automatizada; esto no certifica toda su carta como A.

\** Las 13 losetas actuales sí tienen el contrato universal F39 de `Interactuar/Uso posterior`; F43.0 no equipara eso con automatización integral de todos los campos v0.74.

No se detectó ningún ID canónico del maestro que deba clasificarse D. Tampoco se ha necesitado C por falta de definición tabular: las tablas 16.1–16.13 aportan identidad y texto para las ocho categorías; los conflictos encontrados son documento ↔ repositorio y se mantienen como B hasta decisión/corrección en su subfase.

## Matrices por categoría

### Entrenadores

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| E-01 | Alderion, Explorador Errante | Sí | Sí | Sí | Sí | Parcial; setup peek pendiente | Bonificación inicial de peek + automatización integral no certificada | B |
| E-02 | Lyra, Guardiana de Vinculo | Sí | Sí | Sí | Sí | Parcial; setup peek pendiente | Bonificación inicial de peek + automatización integral no certificada | B |
| E-03 | Dorian, Duelista de Vael | Sí | Sí | Sí | Sí | Parcial; setup sí | Automatización integral pasiva/activa no certificada en F43.0 | B |
| E-04 | Nara, Forjadora Karmica | Sí | Sí | Sí | Sí | Parcial; setup peek pendiente | Bonificación inicial de peek + automatización integral no certificada | B |
| E-05 | Maelis, Tejedora de Resonancia | Sí | Sí | Sí | Sí | Parcial; setup sí | Automatización integral pasiva/activa no certificada en F43.0 | B |
| E-06 | Kael, Cazador del Umbral | Sí | Sí | Sí | Sí | Parcial; setup peek pendiente | Bonificación inicial de peek + automatización integral no certificada | B |
| E-07 | Saira, Cartografa de Terrenos | Sí | Sí | Sí | Sí | Parcial; setup peek pendiente | Bonificación inicial de peek + automatización integral no certificada | B |
| E-08 | Oryn, Apostador del Eco | Sí | Sí | Sí | Sí | Parcial; setup sí | Automatización integral pasiva/activa no certificada en F43.0 | B |

### Losetas

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| I-01 | Refugio del Valle Jade | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| I-02 | Campamento del Rio Bruma | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| I-03 | Atalaya de Neblina | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| I-04 | Puesto de Montana | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N1-01 | Bosque de Raices | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N1-02 | Mina Pequena | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N1-03 | Cristales Susurrantes | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N1-04 | Campamento Perdido | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N1-05 | Claro de Vinculo | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-06 | Sendero de Bruma | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-07 | Taller Abandonado | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-08 | Ruinas del Primer Eco | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-09 | Pradera de Luma | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-10 | Pozo de Bruma | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-11 | Arboleda del Eco | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-12 | Cantera Antigua | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-13 | Paso de Ceniza | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-14 | Manantial Karmico | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-15 | Refugio del Peregrino | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-16 | Santuario Menor | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-17 | Quebrada Resonante | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N1-18 | Linde de Vael | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-01 | Nido de Bruma | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N2-02 | Bosque de Vinculo | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-03 | Taller Runico | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-04 | Mirador del Eco | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-05 | Paso de Cristal | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N2-06 | Lago de Esencia | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-07 | Garganta del Aullido | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-08 | Refugio de Karmany | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-09 | Taller de Bronce | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-10 | Ruinas Resonantes | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-11 | Campo de Cristales | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N2-12 | Umbral de Bruma | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N3-01 | Arena de Ruinas | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N3-02 | Forja Antigua | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N3-03 | Cueva de Cristal | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| L-01 | Santuario de Aeterna | Sí | Sí | Sí | Sí | Parcial; Interactuar F39 sí | Fidelidad estructurada integral v0.74 por campo | B |
| N3-04 | Puerta del Santuario | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N3-05 | Santuario del Eco Ancestral | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |
| N3-06 | Cripta de los Primeros | Sí | No | - | No | No | Falta .tres y efectos estructurados | B |

### Karmany

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| K-01 | Terrakor | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-02 | Aquaris | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-03 | Flareon | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-04 | Zephyris | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-05 | Noctis | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-06 | Mossel | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-07 | Cindrel | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-08 | Bubbler | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-09 | Verdan | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-10 | Runix | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-11 | Brumak | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-12 | Pyral | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-13 | Lumira | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-14 | Thornix | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-15 | Glacir | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-16 | Voltra | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-17 | Nimbel | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-18 | Rokkarn | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-19 | Ferrox | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-20 | Sylphra | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-21 | Duskryn | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-22 | Ignivar | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-23 | Marinox | Sí | No | - | No | No | Falta .tres y automatización de habilidad | B |
| K-24 | Terralux | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-25 | Zephyr | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-26 | Umbrio | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-27 | Solara | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |
| K-28 | Aeterna Draconis | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de habilidad | B |

### Bestias

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| B-01 | Garravol | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de efecto/condición | B |
| B-02 | Picorroca | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de efecto/condición | B |
| B-03 | Musgardo | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-04 | Brumorro | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de efecto/condición | B |
| B-05 | Cangrox | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-06 | Fauzarin | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-07 | Terranuk | Sí | Sí | Sí | No | No | Resource existe pero no entra al mazo runtime seguro; automatización pendiente | B |
| B-08 | Luminox | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-09 | Aullador de Bruma | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-10 | Colmillo Runico | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-11 | Aracnida Karmica | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-12 | Caparazon de Cristal | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-13 | Rocabruta | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-14 | Sirena de Niebla | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-15 | Gargantuan | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de efecto/condición | B |
| B-16 | Espectro Runico | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-17 | Titan de Raiz | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-18 | Draco de Bruma | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-19 | Quimera Karmica | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-20 | Guardián de la Forja | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-21 | Leviatan del Eco | Sí | No | - | No | No | Falta .tres y automatización | B |
| B-22 | Centinela de Aeterna | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa de efecto/condición | B |
| B-23 | Devorador Ancestral | Sí | Sí | Sí | No | No | Resource existe pero no entra al mazo runtime seguro; automatización pendiente | B |
| B-24 | Coloso del Umbral | Sí | No | - | No | No | Falta .tres y automatización | B |

### Equipos

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| EQ-01 | Cristal de Crecimiento | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa del efecto/timing | B |
| EQ-02 | Guante Runico | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa del efecto/timing | B |
| EQ-03 | Botas de Bruma | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa del efecto/timing | B |
| EQ-04 | Amuleto de Vinculo | Sí | Sí | Sí | No | No | Resource existe pero no entra al mercado runtime seguro; automatización pendiente | B |
| EQ-05 | Casco de Raices | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa del efecto/timing | B |
| EQ-06 | Filo de Ceniza | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-07 | Orbe de Bruma | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-08 | Capa de Explorador | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa del efecto/timing | B |
| EQ-09 | Martillo Runico | Sí | Sí | Sí | Sí | Parcial/no certificada | Automatización completa del efecto/timing | B |
| EQ-10 | Brazalete Karmico | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-11 | Placa de Cristal | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-12 | Lente de Vael | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-13 | Collar del Eco | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-14 | Garra de Bestia | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-15 | Vial de Esencia | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-16 | Grebas del Sendero | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-17 | Medallon del Vinculo | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-18 | Escudo Runico | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-19 | Filo de Resonancia | Sí | Sí | Sí | No | No | Resource existe pero no entra al mercado runtime seguro; automatización pendiente | B |
| EQ-20 | Botas del Umbral | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-21 | Capa Ancestral | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-22 | Guantelete de Forja | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-23 | Corona de Bruma | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-24 | Coraza Karmica | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-25 | Prisma del Eco | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-26 | Hoja de Cristal | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-27 | Amuleto del Santuario | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-28 | Botas de Aeterna | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-29 | Baston Runico | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-30 | Orbe Ancestral | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-31 | Manto del Primer Eco | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-32 | Martillo de Aeterna | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-33 | Escudo del Umbral | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-34 | Corona del Legado | Sí | Sí | Sí | No | No | Resource existe pero no entra al mercado runtime seguro; automatización pendiente | B |
| EQ-35 | Prisma Ancestral | Sí | No | - | No | No | Falta .tres y automatización | B |
| EQ-36 | Reliquia de Vael | Sí | No | - | No | No | Falta .tres y automatización | B |

### Resonancias

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| R-01 | Impulso Luminico | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-02 | Golpe Salvaje | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-03 | Corte de Bruma | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-04 | Embate de Raiz | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-05 | Furia Controlada | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-06 | Chispa del Libro | Sí | Sí | Estructural sí / canónico no | Sí | Sí | Nombre del .tres no canónico; rules_text del Resource no expresa el efecto completo aunque catálogo runtime sí. | B |
| R-07 | Golpe Certero | Sí | Sí | Estructural sí / canónico no | Sí | Sí | Nombre del .tres no canónico; efecto coincide con v0.74. | B |
| R-08 | Resonancia Creciente | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-09 | Ruptura Runica | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-10 | Pulso de Batalla | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-11 | Destello Final | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-12 | Ira del Santuario | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-13 | Defensa Instintiva | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-14 | Guardia de Raiz | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-15 | Reflejo Karmico | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-16 | Escudo Breve | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-17 | Paso Cubierto | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-18 | Calma Interior | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-19 | Piel de Bruma | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-20 | Ultima Defensa | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-21 | Paso Silencioso | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-22 | Mirada del Sendero | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-23 | Visita Segura | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-24 | Avance Ligero | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-25 | Rastreo de Vael | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-26 | Eco del Bosque | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-27 | Brujula Espiritual | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-28 | Camino Abierto | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-29 | Pulso de Vinculo | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-30 | Llamado Sereno | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-31 | Cambio de Guardia | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-32 | Resonancia Compartida | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-33 | Marca de Confianza | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-34 | Eco de Compania | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-35 | Contraimpulso | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-36 | Reflejo de Apuesta | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-37 | Giro del Destino | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| R-38 | Eco de Oportunidad | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-39 | Ruptura del Azar | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |
| R-40 | Resonancia Ancestral | Sí | No | - | Parcial: identidad runtime | No; secundaria pendiente | Falta .tres y automatización secundaria. | B |

### Objetivos Públicos

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| OP-E01 | Cartografo Experto | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-E02 | Explorador de Ruinas | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-E03 | Caminante de Tres Niveles | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| OP-D01 | Maestro Artesano | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-D02 | Libro Avanzado | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-D03 | Coleccionista de Ecos | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-C01 | Cazador de Bestias | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-C02 | Duelista Victorioso | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| OP-C03 | Fuerza del Vinculo | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| OP-A01 | Dominio Territorial | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| OP-A02 | Rumbo al Santuario | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| OP-A03 | Forja del Legado | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |

### Misiones de Entrenador

| ID | Nombre canónico | Documento | `.tres` | Resource válido | Runtime ejecutable | Automatización completa | Datos faltantes / nota | Estado |
|---|---|---|---|---|---|---|---|:---:|
| ME-A1 | Alderion - Cartografo del Primer Eco | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-A2 | Alderion - Mapa de Legado | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-L1 | Lyra - Vinculos del Camino | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-L2 | Lyra - Guardian de Dos Ecos | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-D1 | Dorian - Rival de Vael | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-D2 | Dorian - Duelo Preparado | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-N1 | Nara - Forja Personal | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-N2 | Nara - Arsenal Escalonado | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| ME-M1 | Maelis - Resonancia Decisiva | Sí | No | - | Sí | Sí, fallback runtime | Falta .tres canónico | B |
| ME-M2 | Maelis - Eco Transformado | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| ME-K1 | Kael - Cazador del Umbral | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-K2 | Kael - Camino del Cazador | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| ME-S1 | Saira - Cartografia Viva | Sí | No | - | Sí | Sí, fallback runtime | Falta .tres canónico | B |
| ME-S2 | Saira - Ruta al Centro | Sí | No | - | No | No | Falta .tres + tracker/evento | B |
| ME-O1 | Oryn - Apuesta Victoriosa | Sí | Sí | Sí | Sí | Sí | Ninguno detectado en F43.0 | A |
| ME-O2 | Oryn - Riesgo Calculado | Sí | No | - | No | No | Falta .tres + tracker/evento | B |

## Conflictos canónicos detectados

### CONFLICTO CANÓNICO 1 — repetición de Explorar

**Documento maestro:** la secuencia de turno v0.74 indica que Acción 2 puede repetir una acción salvo Explorar; otras referencias del mismo documento también expresan que Explorar no se repite en el mismo turno.

**Repositorio aprobado F38–F42:** el baseline digital permite múltiples `Explorar` en un mismo turno cuando cada exploración es legal.

**Impacto:** diferencia de regla central de acciones. No debe alterarse en F43.0 porque rompería un baseline aprobado y porque F43 trata materialización de contenido, no rebalance/reglas.

**Recomendación:** decisión explícita del usuario antes de cualquier fase que pretenda alinear esta regla; no tocar F38–F42 desde F43.0.

### CONFLICTO CANÓNICO 2 — R-06

**Documento maestro:** `R-06 Chispa del Libro`, Ataque +3, Combate; si tienes Libro II o III, roba 2 Resonancias y descarta 1.

**Repositorio:** `R-06` existe como `data/resonances/r_06_eco_del_libro.tres`, cuyo `display_name` es `Eco del Libro`; el `rules_text` declara +3 y deriva el efecto adicional al controlador. El catálogo runtime sí conserva la definición canónica `Chispa del Libro`.

**Impacto:** el ID coincide y la definición runtime canónica existe, pero el Resource persistente no es canónicamente fiel en nombre/texto.

**Recomendación:** corregir de forma explícita en F43.5; no renombrar ni editar Resource en F43.0.

### CONFLICTO CANÓNICO 3 — R-07

**Documento maestro:** `R-07 Golpe Certero`, Ataque +4, Combate; si iguala exactamente la Defensa, roba 1 Resonancia.

**Repositorio:** `R-07` existe como `data/resonances/r_07_filo_exacto.tres`, con `display_name = Filo Exacto`; el efecto sí coincide semánticamente con v0.74. El catálogo runtime usa el nombre canónico `Golpe Certero`.

**Impacto:** discrepancia de identidad visible/nombre entre Resource y maestro, aunque la lógica textual coincide.

**Recomendación:** corregir explícitamente en F43.5, preservando ID y efecto; no tocar en F43.0.

## Gaps de cobertura (no son conflicto de identidad)

1. **Elección de Misión en setup:** el maestro da 2 Misiones del Entrenador y el jugador elige 1 en secreto; en primera partida recomienda la marcada `*`. F41 automatiza una recomendada para el Alpha y no presenta todavía esa elección 1-de-2.
2. **Mulligan suave:** el maestro permite descartar toda la mano inicial y robar 4 cuando hay más de 2 cartas situacionales sin uso inicial. El setup digital actual no expone esa decisión.
3. **Bonificaciones iniciales de Entrenador:** los 8 textos del Resource coinciden con la tabla v0.74 auditada; Dorian, Maelis y Oryn tienen resolución inicial automática. Alderion, Lyra, Nara, Kael y Saira siguen pendientes porque requieren peek/orden privado o una presentación segura de información.
4. **Resonancias faltantes como `.tres`:** el runtime conoce las 40 identidades canónicas y puede construir representación en memoria, pero eso no equivale a automatización completa ni a materialización persistente.
5. **Bestias/Equipos materializados pero fuera del pool seguro:** B-07 y B-23; EQ-04, EQ-19 y EQ-34. Se conservan fuera hasta que su efecto pueda ejecutarse sin mentir al runtime.

## Fuentes del repositorio inspeccionadas

- `data/tiles/`, `data/karmanys/`, `data/beasts/`, `data/equipment/`, `data/resonances/`, `data/objectives/`, `data/missions/`, `data/trainers/`.
- `scripts/content/v074_canonical_runtime_catalog.gd` (`KarmanyV074CanonicalRuntimeCatalog`).
- `scripts/content/phase_37_alpha_content_catalog.gd` (`KarmanyPhase37AlphaContentCatalog`).
- `scripts/content/phase_29_content_catalog.gd` y catálogos previos usados por F37/F38.
- `scripts/board/map_41_tile_pools.gd` (`KarmanyMap41TilePools`), `map_41_content_generator.gd`, `map_41_content_session.gd`, `canonical_map_41_layout.gd` y `alpha_tile_pool_fallback.gd`. El pool actual carga dinámicamente los `.tres` por nivel N1/N2/N3; F43.0 no lo modifica.
- Data classes en `scripts/data/`: Tile, Karmany, Ability, Beast, Equipment, Resonance, Objective, Mission, Trainer y Effect.
- Resolvers/controladores usados por F38–F42 para combate, contenido, objetivos/misiones, setup y acciones.
- Tests F38, F39, F40, F41, F42 Game Shell y F42 Restart.
- `docs/phase_38_v074_content_audit.md`, `docs/phase_39_tile_interaction_audit.md`, `docs/phase_40_map41_content_audit.md`, `docs/phase_41_human_setup_audit.md`, `docs/phase_42_alpha_game_shell_audit.md`.

## Orden recomendado después de F43.0

No se inicia ninguna subfase automáticamente. Si el usuario mantiene el orden previsto, la primera candidata es **F43.1 Losetas**, porque el déficit absoluto es 28/41 y F39 ya dejó un contrato de interacción común. Sin embargo, antes de materializar debe revisarse el conflicto de regla `Explorar` solo como dependencia de contrato, sin modificar el baseline de gameplay de manera silenciosa.

Luego: Karmany → Bestias → Equipos → Resonancias → Objetivos/Misiones → Entrenadores pendientes → auditoría final, siempre bloque por bloque con test y validación local.

## Resultado de F43.0

La fuente maestra v0.74 es suficientemente completa para iniciar materialización incremental sin inventar identidades. El repositorio conserva un subconjunto jugable deliberadamente conservador. F43.0 deja registrados los faltantes y conflictos, pero no crea `.tres`, no modifica pools y no cambia gameplay.