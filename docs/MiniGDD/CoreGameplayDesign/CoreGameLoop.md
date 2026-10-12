# Core Game Loop — I Am...?

## Flujo Completo del Juego (Bucle General de Campaña)

El juego se organiza en torno a **bucles temporales/psicológicos progresivos** (`1th_time`, `2th_time`, `3th_time`), donde cada ciclo arranca en la celda y profundiza el conocimiento, la habilidad y la conciencia de la realidad del Paciente 6174.

```
┌─────────────────────────────────────────────────────────┐
│          FASE 1: DESPERTAR EN CELDA (El Asilo)          │
│  • Despertar amnésico     │
│  • Inspeccionar entorno: Foto de la mujer, notas, pared │
│  • Evento de memoria: Recuperación de un FRAGMENTO      │
│  • Resolución de minijuego para abrir la puerta sellada │
└─────────────────────────┬───────────────────────────────┘
                          │ Cruzar puerta de celda
                          ▼
┌─────────────────────────────────────────────────────────┐
│          FASE 2: INFILTRACIÓN Y PASILLOS (Sigilo)       │
│  • Patrullaje de guardias (cuerpo a cuerpo y pistolas)  │
│  • Navegación en sombras y administración de Stamina    │
│  • Hackeo de terminales de acceso en el pasillo         │
│  • Si el jugador es descubierto y abatido: REINICIO     │
└─────────────────────────┬───────────────────────────────┘
                          │ Acceso a Sala Clave (Oficina / Security Hub)
                          ▼
┌─────────────────────────────────────────────────────────┐
│        FASE 3: SALA CLAVE Y REVELACIÓN DE IDENTIDAD     │
│  • Interacción con terminal principal / archivos de PC  │
│  • Efecto de ruptura mental (Shatter Effect + Sonido)   │
│  • Revelación de rol previo (¿Capitán de las FFAA?)     │
│  • Asimilación del Fragmento de ATAQUE permanente       │
└─────────────────────────┬───────────────────────────────┘
                          │ Cruce de puerta
                          ▼
┌─────────────────────────────────────────────────────────┐
│           FASE 4: BUCLE / AVANCE DE CONCIENCIA          │
│  • Retorno a la celda con nuevo diálogo de despertar    │
│  • Reconocimiento progresivo del númer
│  • Superación del Hub de Seguridad y Puerta de Escape   │
└─────────────────────────┬───────────────────────────────┘
                          │ Atravesar Puerta de Salida Final
                          ▼
┌─────────────────────────────────────────────────────────┐
│          FASE 5: CLÍMAX Y DESENLACE (Ending)            │
│  • Cinemática del recorte de periódico giratorio        │
│  • Revelación de la tragedia de la mujer                │
│  • Mensaje "To be continued..." + SFX de frustración    │
│  • Pantalla de créditos del equipo Lamda Games          │
└─────────────────────────────────────────────────────────┘
```

## ¿Qué lo hace rejugable y atractivo?

1. **Evolución del Despertar en la Celda:**  
   Cada vez que el paciente despierta en la celda, las interacciones cambian (`awakening`, `awakening_2`, `awakening_3` en Dialogic). Ya no es una víctima perdida, sino un sujeto que sabe que está en un bucle y busca romperlo.
2. **Misterio Psicológico Abierto:**  
   El final con el recorte del periódico deja incógnitas deliberadas sobre si el protagonista es un criminal, un héroe caído o una mente fragmentada intentando procesar una tragedia.

---

## Duración Estimada de Sesión
- **Tiempo medio por bucle:** ~3–6 minutos.
- **Partida completa:** ~12–18 minutos.

