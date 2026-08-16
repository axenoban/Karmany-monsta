# Fase 43 — Auditoria canonica final v0.74

## Fuente de verdad

Fuente primaria: **Karmany Monsta: Forja de Resonancia — Libro de Reglas v0.74, Movimiento, Progresion e Instinto**.

Baseline historico de F43: `dev/karmany-core` @ `de5ff2c5cd11710c333eaea449694a9c452ae3d1`.

Rama de trabajo: `feature/phase-43-canonical-content`.

Esta version del documento reemplaza la matriz preliminar de F43.0. La auditoria inicial contenia etiquetas provisionales anteriores al contraste completo con las tablas maestras; esas etiquetas se eliminan aqui para que la documentacion F43 quede sincronizada con v0.74.

## Regla de precedencia

1. El documento maestro v0.74 reciente prevalece sobre contenido previo del repositorio para nombres, valores, textos, costes, recompensas, condiciones y comportamiento documentado.
2. Excepcion explicita del autor: **Explorar puede repetirse mas de una vez en el mismo turno**, siempre que cada uso sea legal y consuma una accion. Esta decision prevalece sobre la frase contradictoria del maestro que limita Explorar a una vez por turno.
3. No se inventa contenido que el maestro no defina. La materializacion de F43 no equivale a automatizacion completa; lo no automatizado permanece aislado para F44.

## Cobertura final

| Categoria | Canonico v0.74 | Materializado F43 | Estado al cierre |
|---|---:|---:|---|
| Entrenadores | 8 | 8 | 3 PARTIAL / 5 DATA_ONLY; ninguna carta declarada totalmente EXECUTABLE |
| Losetas MAP41 | 41 | 41 | 13 runtime previas + 28 `canonical_pending` |
| Karmany | 28 | 28 | 13 directos + 15 `canonical_pending` |
| Bestias | 24 | 24 | 7 directas + 17 `canonical_pending`; 5 en pool seguro actual |
| Equipo | 36 | 36 | 9 directos + 27 `canonical_pending`; 6 en mercado seguro actual |
| Resonancias | 40 | 40 | 13 directas + 27 `canonical_pending`; R-06/R-07 alineadas al maestro |
| Objetivos Publicos | 12 | 12 | 8 directos + 4 `canonical_pending` |
| Misiones de Entrenador | 16 | 16 | 9 directas + 7 `canonical_pending` |
| **TOTAL** | **205** | **205** | **205 identidades canonicas materializadas** |

## Contrato comprobado por categoria

- Entrenadores: ID, entrenador/titulo, estilo/dificultad, pasiva, activa, bonificacion inicial y funcion/balance.
- Losetas: ID, nombre, funcion, iconos/tags, Al explorar, Uso posterior, Bonificacion de entrada y limite.
- Karmany: ID, nombre, subtitulo, nivel, tipo, Poder, Defensa de vinculo, PL directo, obtencion y habilidad.
- Bestias: ID, nombre, clasificacion, nivel, Defensa base, recompensa, derrota y efecto.
- Equipo: ID, nombre, rareza, coste y efecto.
- Resonancias: ID, nombre, tipo, valor, uso y efecto.
- Objetivos: ID, nombre, condicion y recompensa.
- Misiones: ID, entrenador/mision, condicion, recompensa y marca recomendada de primera partida.

Las pruebas F43.1–F43.7 verifican estos contratos contra los Resources. El test final `phase_43_closure_audit_test.tscn` agrega la comprobacion transversal de conteos, set exacto de IDs y duplicados entre las ocho categorias.

## Inventario canonico de identidades

### Entrenadores — 8

- E-01 — Alderion, Explorador Errante
- E-02 — Lyra, Guardiana de Vinculo
- E-03 — Dorian, Duelista de Vael
- E-04 — Nara, Forjadora Karmica
- E-05 — Maelis, Tejedora de Resonancia
- E-06 — Kael, Cazador del Umbral
- E-07 — Saira, Cartografa de Terrenos
- E-08 — Oryn, Apostador del Eco

### Losetas MAP41 — 41

- I-01 — Refugio del Valle Jade
- I-02 — Campamento del Rio Bruma
- I-03 — Puesto Rocoso
- I-04 — Sendero del Primer Vinculo
- N1-01 — Bosque de Raices
- N1-02 — Mina Pequena
- N1-03 — Arroyo Karmico
- N1-04 — Campamento Antiguo
- N1-05 — Sendero Verde
- N1-06 — Claro de Resonancia
- N1-07 — Ruinas del Eco
- N1-08 — Puente de Musgo
- N1-09 — Pradera de Luma
- N1-10 — Pozo de Bruma
- N1-11 — Rocas del Alba
- N1-12 — Sendero Partido
- N1-13 — Refugio Menor
- N1-14 — Hierbas de Vael
- N1-15 — Taller Improvisado
- N1-16 — Fuente Serena
- N1-17 — Colina de Guardia
- N1-18 — Cruce de Raices
- N2-01 — Nido de Bruma
- N2-02 — Bosque de Vinculo
- N2-03 — Ruinas del Eco
- N2-04 — Atalaya Exterior
- N2-05 — Paso de Cristal
- N2-06 — Santuario Quebrado
- N2-07 — Garganta del Aullido
- N2-08 — Refugio de Karmany
- N2-09 — Mercado de Ruinas
- N2-10 — Puente de Atalaya
- N2-11 — Nido Salvaje
- N2-12 — Obelisco Menor
- N3-01 — Arena de Ruinas
- N3-02 — Forja Antigua
- N3-03 — Cueva de Cristal Ancestral
- L-01 — Santuario de Aeterna
- N3-04 — Puerta del Santuario
- N3-05 — Santuario del Eco Ancestral
- N3-06 — Fisura Ancestral

### Karmany — 28

- K-01 — Terrakor
- K-02 — Aquaris
- K-03 — Pyrox
- K-04 — Lumirra
- K-05 — Floravia
- K-06 — Brisu
- K-07 — Rocerno
- K-08 — Mistolin
- K-09 — Verdan
- K-10 — Brumak
- K-11 — Rauk Colmillo
- K-12 — Nimbara
- K-13 — Ferrak
- K-14 — Selenix
- K-15 — Lignar
- K-16 — Volcrin
- K-17 — Orial
- K-18 — Torkal
- K-19 — Velkar
- K-20 — Dravok
- K-21 — Celestia
- K-22 — Runakar
- K-23 — Eryndra
- K-24 — Aeterna Draconis
- K-25 — Zephyr
- K-26 — Umbrio
- K-27 — Gemmir
- K-28 — Vulkai

### Bestias — 24

- B-01 — Garravol
- B-02 — Picorroca
- B-03 — Raicillo Feral
- B-04 — Murcielago Bruma
- B-05 — Cuernillo Verde
- B-06 — Limo de Runa
- B-07 — Terranuk
- B-08 — Brumacerno
- B-09 — Garraespina
- B-10 — Vigia de Atalaya
- B-11 — Escarabajo Runico
- B-12 — Aullador de Bruma
- B-13 — Raptor de Ruinas
- B-14 — Feraluz
- B-15 — Vermis de Cristal
- B-16 — Colmillo de Ceniza
- B-17 — Guardian del Umbral
- B-18 — Cervix de Obsidiana
- B-19 — Brumagor
- B-20 — Raiz Devora
- B-21 — Centinela Runico
- B-22 — Custodio del Santuario
- B-23 — Drakmaw
- B-24 — Eco de Aeterna

### Equipo — 36

- EQ-01 — Cristal de Crecimiento
- EQ-02 — Guante Runico
- EQ-03 — Baculo de Bruma
- EQ-04 — Daga de Resonancia
- EQ-05 — Nucleo Luminico
- EQ-06 — Sello de Impacto
- EQ-07 — Anillo del Eco
- EQ-08 — Prisma Ancestral
- EQ-09 — Catalizador de Aeterna
- EQ-10 — Armadura de Terracota
- EQ-11 — Capa de Bruma
- EQ-12 — Escudo de Raiz
- EQ-13 — Brazal de Piedra
- EQ-14 — Manto de Serenidad
- EQ-15 — Coraza Runica
- EQ-16 — Guardia del Libro
- EQ-17 — Placa Ancestral
- EQ-18 — Velo de Aeterna
- EQ-19 — Pico Runico
- EQ-20 — Botas Ligeras
- EQ-21 — Brujula de Vael
- EQ-22 — Mochila Reforzada
- EQ-23 — Lampara de Ruinas
- EQ-24 — Cuerda de Atalaya
- EQ-25 — Kit de Artesano
- EQ-26 — Taladro de Cristal
- EQ-27 — Mapa de las Derivas
- EQ-28 — Colgante de Armonia
- EQ-29 — Piedra de Calma
- EQ-30 — Amuleto de Raiz
- EQ-31 — Medallon del Eco
- EQ-32 — Reliquia de Vinculo
- EQ-33 — Totem del Guardian
- EQ-34 — Sello del Santuario
- EQ-35 — Fragmento del Libro
- EQ-36 — Corona de Resonancia

### Resonancias — 40

- R-01 — Impulso Luminico
- R-02 — Golpe Salvaje
- R-03 — Corte de Bruma
- R-04 — Embate de Raiz
- R-05 — Furia Controlada
- R-06 — Chispa del Libro
- R-07 — Golpe Certero
- R-08 — Resonancia Creciente
- R-09 — Ruptura Runica
- R-10 — Pulso de Batalla
- R-11 — Destello Final
- R-12 — Ira del Santuario
- R-13 — Defensa Instintiva
- R-14 — Guardia de Raiz
- R-15 — Reflejo Karmico
- R-16 — Escudo Breve
- R-17 — Paso Cubierto
- R-18 — Calma Interior
- R-19 — Piel de Bruma
- R-20 — Ultima Defensa
- R-21 — Paso Silencioso
- R-22 — Mirada del Sendero
- R-23 — Visita Segura
- R-24 — Avance Ligero
- R-25 — Rastreo de Vael
- R-26 — Eco del Bosque
- R-27 — Brujula Espiritual
- R-28 — Camino Abierto
- R-29 — Pulso de Vinculo
- R-30 — Llamado Sereno
- R-31 — Cambio de Guardia
- R-32 — Resonancia Compartida
- R-33 — Marca de Confianza
- R-34 — Eco de Compania
- R-35 — Contraimpulso
- R-36 — Mano Rapida
- R-37 — Instinto de Caza
- R-38 — Reserva Oculta
- R-39 — Destino Cambiante
- R-40 — Ultimo Aliento

### Objetivos Publicos — 12

- OP-E01 — Cartografo Experto
- OP-E02 — Explorador de Ruinas
- OP-E03 — Caminante de Vael
- OP-D01 — Primer Vinculo
- OP-D02 — Forja Consistente
- OP-D03 — Libro Despierto
- OP-C01 — Cazador de Bruma
- OP-C02 — Mano Resonante
- OP-C03 — Duelista del Eco
- OP-A01 — Dominio Territorial
- OP-A02 — Rumbo al Santuario
- OP-A03 — Preparacion Final

### Misiones de Entrenador — 16

El asterisco de la tabla maestra es metadato `recommended_first_game`; no forma parte de `mission_id`.

- ME-A1* — Alderion - Cartografo del Primer Eco
- ME-A2 — Alderion - Mapa de Legado
- ME-L1* — Lyra - Vinculos del Camino
- ME-L2 — Lyra - Guardian de Dos Ecos
- ME-D1* — Dorian - Rival de Vael
- ME-D2 — Dorian - Duelo Preparado
- ME-N1* — Nara - Forja Personal
- ME-N2 — Nara - Arsenal Escalonado
- ME-M1* — Maelis - Resonancia Decisiva
- ME-M2 — Maelis - Eco Transformado
- ME-K1* — Kael - Cazador del Umbral
- ME-K2 — Kael - Camino del Cazador
- ME-S1* — Saira - Cartografia Viva
- ME-S2 — Saira - Ruta al Centro
- ME-O1* — Oryn - Apuesta Victoriosa
- ME-O2 — Oryn - Riesgo Calculado

## Resoluciones canonicas cerradas durante F43

- R-06 se corrigio a **Chispa del Libro**, Ataque +3, Combate; con Libro II o III roba 2 Resonancias y descarta 1.
- R-07 se corrigio a **Golpe Certero**, Ataque +4, Combate; si hace igualar exactamente la Defensa, roba 1 Resonancia.
- ME-M1 se alinea a **Resonancia Decisiva**.
- ME-S1 se alinea a **Cartografia Viva**.
- Los textos abreviados o campos mal separados detectados en Resources anteriores se normalizaron en sus subfases correspondientes usando el maestro v0.74.

## IDs y duplicados

El set canonico esperado contiene **205 IDs**. El cierre exige:

1. exactamente 205 Resources canónicos entre las ocho categorias;
2. ningun ID repetido dentro de una categoria;
3. ningun ID repetido entre categorias;
4. igualdad exacta entre los IDs materializados y los IDs definidos por v0.74.

Test transversal: `res://tests/phase_43_closure_audit_test.tscn`.

Resultado esperado:

`FASE 43 OK - 205/205 identidades canonicas, 8 categorias y 0 IDs duplicados; listo para F44.`

## Limite de F43 y entrada a F44

F43 certifica **contenido canonico materializado**, no automatizacion total. Los Resources `canonical_pending` continúan fuera de los pools runtime donde corresponde. F44 debe implementar y certificar la logica pendiente de forma incremental, sin inventar reglas ni contaminar los sistemas aprobados de F38–F42.
