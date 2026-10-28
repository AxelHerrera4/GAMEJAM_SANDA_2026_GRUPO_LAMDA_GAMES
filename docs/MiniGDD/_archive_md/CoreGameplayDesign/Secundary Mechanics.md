# Secondary Mechanics — I Am...?

Mecánicas de soporte que expanden los sistemas centrales de sigilo y narrativa, implementadas en los módulos globales del juego.

---

## 1. Sistema de Fragmentos de Memoria (`FragmentManager.gd`)

Cada fragmento representa una parte recuperada de la mente del Paciente 6174 que desbloquea capacidades en tiempo real.

| ID del Fragmento | Nombre en Juego | Descripción Narrativa | Impacto Mecánico Directo |
| :--- | :--- | :--- | :--- |
| `hack` | **Fragmento de Hackeo** | *"Un retazo de código capaz de forzar cerraduras electrónicas."* | Permite abrir consolas de seguridad y paneles de celdas mediante minijuegos. |
| `attack` | **Fragmento de Ataque** | *"Código de combate desbloqueado. Ahora puedes defenderte."* | Desbloquea la acción `attack` (`_can_attack = true`) para asesinar guardias por la espalda. |
| `camouflage` | **Fragmento de Camuflaje** | *"Un patrón capaz de doblar la luz a tu alrededor."* | Habilita el despertar del 3er bucle y reduce la percepción de conos de visión enemigos. |

---

## 2. Minijuegos de Hacking y Destreza

### A. Minijuego de Hackeo de Cables (`HackMinigame.gd` / `HackBoard.gd`)
- **Propósito:** Se activa al interactuar con puertas electrónicas bloqueadas o terminales de pasillo.
- **Mecánica:** El jugador debe conectar cables desordenados arrastrándolos hasta su borne correspondiente basándose en códigos de color.
- **Audio y Feedback:**
  - SFX al mostrar el tablero (`show_sfx`), zumbido constante de corriente (`loop_sfx`).
  - Sonido de acierto (`solve_sfx`) o chispazo de fallo (`fail_sfx`).
  - Al completar todos los cables, emite `finished(true)` y abre el cerrojo de la puerta asociada.

### B. Minijuego de Precisión y Reflejos (`PrecisionMinigame.gd` / `PrecisionBoard.gd`)
- **Propósito:** Se utiliza en terminales de alta seguridad o sabotajes de infraestructura.
- **Mecánica:** Un cursor oscila horizontalmente a través de una barra. El jugador debe presionar `Espacio` en el instante preciso en que el cursor pasa sobre la **zona verde**.
- **Resultado:** Acierto desbloquea el dispositivo; fallar reinicia la oscilación o bloquea momentáneamente el acceso.
---
