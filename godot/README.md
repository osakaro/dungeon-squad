# ⚔️ DungeonSquad: versión Godot 4

Versión en **Godot 4** del juego, con iluminación dinámica, sombras, bloom, partículas, física y modelos animados.

![Menú](../docs/godot-menu.png)

## ▶️ Cómo abrirlo

1. Instala **Godot 4.3 o superior** (la versión estándar, no hace falta la de .NET): https://godotengine.org/download
2. Abre Godot, pulsa **Importar** y elige el archivo `godot/project.godot` de este repositorio.
3. Pulsa **▶ Ejecutar** (F5).

## 🎮 Controles

| Acción | Teclado | Mando | Móvil |
|---|---|---|---|
| Moverse | WASD / flechas | Stick izquierdo | Arrastra el dedo (joystick virtual) |
| Atacar | Quédate quieto | Quédate quieto | Suelta el dedo |
| Pausa | Esc / P | Start | Botón II |

Las **habilidades se lanzan solas** cuando termina su cooldown.

## ✨ Qué incluye

- **5 héroes** con modelo, arma, ataque y 2 habilidades propias: Arquero, Mago, Guerrero, Asesino y Nigromante.
- **5 tipos de enemigo:**
  - **Slime:** salta hacia ti.
  - **Murciélago:** vuela en zigzag.
  - **Cristal:** torreta que dispara.
  - **Orco:** carga contra ti tras avisar en rojo.
  - **Demonio:** jefe con 3 patrones de ataque que se enfurece a mitad de vida.
- **10 niveles** en 2 mundos (la mazmorra y el abismo), con jefe en los niveles 5 y 10.
- Las **salas se generan al azar**: columnas, cajas y barriles que bloquean el paso y los disparos.
- **Cartas de mejora** entre niveles: pasivas, desbloquear o subir habilidades.
- **Mejora permanente de armas** con las monedas. El progreso se guarda.
- **Efectos:**
  - números de daño (críticos en amarillo);
  - temblor de cámara y retroceso de los enemigos al golpearlos;
  - antorchas con luz que parpadea;
  - portal animado;
  - monedas que vuelan hacia ti.

![Sala](../docs/godot-sala.png)
![Mundo 2](../docs/godot-mundo2.png)

## 🗂️ Estructura

```
godot/
├── project.godot
├── scenes/main.tscn        # escena principal
└── scripts/
    ├── game_data.gd        # datos de héroes/habilidades + guardado (autoload)
    ├── main.gd             # estados, niveles, cámara
    ├── player.gd           # héroe: movimiento, ataque y habilidades
    ├── enemy.gd            # IA de enemigos y jefe
    ├── projectile.gd       # proyectiles
    ├── minion.gd           # esqueletos invocados
    ├── coin.gd             # monedas
    ├── arena.gd            # generación de la mazmorra
    ├── builder.gd          # modelos 3D de personajes
    ├── rig.gd              # esqueleto y animación procedural
    ├── fx.gd               # partículas y efectos
    └── ui.gd               # menús y HUD
```

**¿Quieres añadir un héroe?** Añádelo en `HEROES` dentro de `game_data.gd`, crea su modelo en `builder.gd` y sus habilidades en `player.gd` (función `cast`).

## 📦 Exportar (PC, Android, web o itch.io)

1. En Godot: **Editor → Gestionar plantillas de exportación → Descargar**.
2. Ve a **Proyecto → Exportar → Añadir…** y elige *Windows*, *Linux*, *Android* o *Web*.
3. Para la **web** o móviles flojos, cambia el renderizador a **Compatibility** (arriba a la derecha del editor). Algunos efectos como el SSAO se desactivan, pero el juego funciona igual.
4. Para **itch.io**, exporta a *Web*, comprime la carpeta en un `.zip` y súbela como juego HTML5.

## 🔜 Siguientes pasos

- [ ] Sustituir los modelos por personajes `.glb` animados (KayKit / Quaternius, gratis)
- [ ] Música y efectos de sonido
- [ ] Más mundos y jefes
- [ ] Árbol de talentos permanente
