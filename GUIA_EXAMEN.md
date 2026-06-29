# Guía Técnica Completa de Modificaciones: Trazos del Destino 2

Esta guía contiene la documentación exhaustiva de **todos los archivos de código (`.gd`)** de tu proyecto de Godot 4. Está diseñada específicamente para que durante el examen puedas buscar el archivo solicitado por el profesor, entender cómo funciona y aplicar cambios en segundos.

---

## 📁 1. SISTEMA GLOBAL (AUTOLOADS)

### 1.1 `global/game_state.gd`
* **Tipo:** Singleton Autoload (extiende de `Node`).
* **Propósito:** Centraliza el estado persistente de la partida. Esto evita que la salud, tinta o habilidades del jugador se reinicien al cambiar de escena o nivel.

#### ⚙️ Lógica y Funcionamiento:
* **Setters (`set(value)`):** Godot ejecuta este código cada vez que se intenta modificar una variable.
  - Al cambiar `health`, el setter la limita (`clamp`) entre `0` y `max_health`, emite `player_health_changed` y, si la vida llega a `0`, emite `player_died`.
  - Al cambiar `ink`, la limita entre `0.0` y `max_ink` y emite `player_ink_changed`.
  - Habilidades como `has_dash` y `has_double_jump` emiten `ability_unlocked` para notificar al HUD.
* **`respawn_position`:** Almacena un vector con las coordenadas donde el jugador volverá a crearse al morir.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Iniciar con más vida máxima (ej. 5 vidas):**
  * *Original:*
    ```gdscript
    var max_health: int = 3
    var health: int = 3:
    ```
  * *Modificado:*
    ```gdscript
    var max_health: int = 5
    var health: int = 5:
    ```
* **Comenzar con habilidades ya desbloqueadas (Modo Sandbox):**
  * *Original:*
    ```gdscript
    var has_dash: bool = false
    var has_double_jump: bool = false
    ```
  * *Modificado:*
    ```gdscript
    var has_dash: bool = true
    var has_double_jump: bool = true
    ```
* **Desactivar la muerte del jugador (Inmortalidad global):**
  En el setter de `health` (línea ~14), puedes comentar el disparador de muerte:
  ```gdscript
  # if health <= 0:
  #     player_died.emit()
  ```

---

### 1.2 `global/test_runner.gd`
* **Tipo:** Singleton Autoload (extiende de `Node`).
* **Propósito:** Automatiza flujos para realizar pruebas de integración de punta a punta (End-to-End).

#### ⚙️ Lógica y Funcionamiento:
* En `_ready()`, busca si existe el archivo `res://.run_tests` en el disco.
* Si existe, ejecuta `run_tests()`, que realiza una simulación controlada:
  1. Espera a que cargue la escena del Nexo.
  2. Teletransporta al jugador a la puerta de Wing 2 y espera la carga de `CurveWing`.
  3. Lo teletransporta a la arena de la Regla Articulada, le inflige daño al jefe hasta matarlo, simula agarrar el pigmento amarillo y espera el retorno automático al Hub.
  4. Repite el proceso para Wing 1 y el Rey Compás.
  5. Verifica que la bóveda final se abra, mueve al jugador al foso y valida que cargue la pantalla de victoria antes de cerrar el juego con `get_tree().quit(0)`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que los tests de daño fallen o pasen de largo:**
  Si el profesor te pide que cambies la vida de un jefe pero quieres que la prueba automática pase sin problemas, cambia el daño infligido al jefe (líneas ~66 y ~130):
  ```gdscript
  boss.take_damage(999) # Mata instantáneamente a cualquier jefe en los tests
  ```

---

## 🏃 2. JUGADOR (PLAYER)

### 2.1 `player/player.gd`
* **Tipo:** `CharacterBody2D`.
* **Propósito:** Script principal del jugador. Controla el movimiento horizontal, saltos, rebotes en elementos magenta, deslizamiento por paredes, combate cuerpo a cuerpo y a distancia.

#### ⚙️ Lógica y Funcionamiento:
* **`_physics_process(delta)`**:
  - Resta tiempo a los temporizadores de Coyote Time, Jump Buffer, inmunidad y aturdimiento (`is_hurt`).
  - Si el jugador no está atacando y su tinta no está llena, regenera tinta pasivamente sumando `15.0 * delta`.
  - Si está en el suelo, restablece el doble salto (`can_double_jump_air = true`) y el dash (`can_dash_air = true`).
  - **Gravedad y Deslizamiento por Pared (`wall_slide_speed`):** Si está pegado a una pared lateral y cayendo, limita la velocidad de caída a `wall_slide_speed`.
  - **Doble Salto y Salto en Pared:** Si pulsa saltar cerca de una pared, aplica una fuerza en dirección contraria a la pared. Si pulsa saltar en el aire (y tiene el poder desbloqueado), aplica un salto extra y consume una carga de doble salto.
  - **Ataque Melee (Z o J):** Comprueba solapamientos de cuerpos en `MeleeArea`. A los enemigos les hace daño. Si choca con proyectiles en el grupo `"magenta"`, llama a `trigger_parry_bounce()`.
  - **Ataque a Distancia (Clic Izq, X o K):** Genera la escena `projectile.tscn` y le asigna velocidad. Si el jugador está cargado de pigmento (`is_pigment_charged`), el proyectil sale rosa y hace el doble de daño.
* **`trigger_parry_bounce()` (Rebote Parry):**
  - Impulsa al jugador hacia arriba (`jump_velocity * 1.25`).
  - Restablece el doble salto y dash en el aire.
  - Pone `is_pigment_charged = true` (potencia el siguiente golpe).
* **`take_damage(...)`**:
  - Si el jugador está en su periodo de frames de invencibilidad (`invincible_timer > 0`), en medio de un dash o aturdido, ignora el daño.
  - De lo contrario, resta vida en `GameState.health`, aplica fuerza de retroceso (`velocity = knockback`) y activa invencibilidad por `1.0` segundo.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Cambiar controles de movimiento (ej. usar W/S/A/D estrictos):**
  * *Original (Movimiento Izquierda/Derecha):*
    ```gdscript
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direction -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direction += 1.0
    ```
  * *Modificación (si te pide usar solo Flechas o teclas específicas):* Cambia los valores de `KEY_...` por los deseados.
* **Cambiar el costo de tinta de las habilidades:**
  * *Melee (línea ~195):*
    ```gdscript
    func trigger_melee_attack():
        if GameState.ink < 10.0: return # Cambiar 10.0 por el costo deseado (0.0 para gratis)
        GameState.ink -= 10.0           # Cambiar 10.0 por el costo deseado
    ```
  * *Disparo (línea ~206):*
    ```gdscript
    func shoot_ink():
        if GameState.ink < 5.0: return  # Cambiar 5.0 por el costo deseado (0.0 para gratis)
        GameState.ink -= 5.0            # Cambiar 5.0 por el costo deseado
    ```
* **Hacer al jugador inmune al daño (Modo Dios):**
  Añade un `return` al inicio de la función `take_damage` (línea ~248):
  ```gdscript
  func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO):
      return # <-- AGREGAR ESTO PARA MODO DIOS
  ```
* **Alterar las propiedades de movimiento físico:**
  Ajusta los valores `@export` al inicio del archivo:
  ```gdscript
  @export var speed: float = 350.0          # Correr más rápido (Default: 250)
  @export var jump_velocity: float = -500.0 # Saltar más alto (Default: -380)
  @export var gravity: float = 1200.0       # Gravedad aumentada (Default: 900)
  ```

---

### 2.2 `player/projectile.gd`
* **Tipo:** `Area2D`.
* **Propósito:** Lógica y movimiento de la bala de tinta disparada por el jugador.

#### ⚙️ Lógica y Funcionamiento:
* **Movimiento:** En `_physics_process(delta)`, desplaza su posición global según `direction * speed * delta`.
* **Colisión de Cuerpo (`_on_body_entered`):**
  - Si choca contra la Capa 1 (escenario sólido), genera una salpicadura negra y se destruye (`queue_free()`).
  - Si choca contra un cuerpo con el método `take_damage` (enemigos), le aplica el daño del proyectil, salpica y se destruye.
* **Colisión de Área (`_on_area_entered`):** Hace lo mismo si choca con un `Area2D` enemiga (como partes de jefes).

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que las balas inflijan mucho daño:**
  Modifica la variable `damage` (línea 5):
  ```gdscript
  var damage: int = 5 # Cambiar de 1 a 5
  ```
* **Modificar la velocidad del proyectil:**
  ```gdscript
  @export var speed: float = 800.0 # Balas más rápidas (Default: 500)
  ```
* **Hacer que el disparo atraviese paredes (no se destruya al tocar terreno):**
  * *Original (línea ~20):*
    ```gdscript
    func _on_body_entered(body: Node2D):
        if body.collision_layer & 1:
            spawn_splat()
            queue_free()
    ```
  * *Modificado (comentando la colisión del terreno):*
    ```gdscript
    func _on_body_entered(body: Node2D):
        # if body.collision_layer & 1:
        #     spawn_splat()
        #     queue_free()
        if body.has_method("take_damage"):
            # ...
    ```

---

## 👾 3. ENEMIGOS COMUNES

### 3.1 `enemies/walking_smudge.gd`
* **Tipo:** `CharacterBody2D`.
* **Propósito:** Inteligencia artificial básica para el enemigo que camina sobre plataformas y rebota en paredes o bordes de abismos.

#### ⚙️ Lógica y Funcionamiento:
* **RayCasts Programáticos:** En `_ready()`, crea e instala dos nodos `RayCast2D`:
  - `wall_ray`: Apunta hacia adelante para detectar colisión con paredes.
  - `floor_ray`: Apunta hacia abajo en diagonal adelante para verificar si hay suelo.
* **IA de Patrulla:** En `_physics_process()`, si el enemigo está en el suelo y detecta colisión en `wall_ray` o la ausencia de suelo en `floor_ray`, cambia su dirección multiplicándola por `-1.0` (se da la vuelta).
* **Daño al jugador:** Revisa las colisiones del frame físico. Si colisiona con un cuerpo del grupo `"player"`, calcula el vector de empuje y llama a `take_damage(1, ...)` en el jugador.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Aumentar la vida del enemigo:**
  ```gdscript
  var health: int = 5 # Más resistente (Default: 2)
  ```
* **Hacer que camine muy rápido:**
  ```gdscript
  @export var speed: float = 180.0 # Patrulla veloz (Default: 60.0)
  ```
* **Desactivar que se dé la vuelta al llegar a un borde (hacer que se caiga):**
  Modifica la condición de cambio de dirección en la línea ~48:
  * *Original:*
    ```gdscript
    if wall_hit or not floor_hit:
        direction *= -1.0
    ```
  * *Modificado:*
    ```gdscript
    if wall_hit: # Solo da la vuelta si choca con una pared, se caerá si llega a un abismo
        direction *= -1.0
    ```

---

### 3.2 `enemies/flying_spark.gd`
* **Tipo:** `CharacterBody2D`.
* **Propósito:** Enemigo volador que patrulla, persigue al jugador y dispara proyectiles magenta parreables.

#### ⚙️ Lógica y Funcionamiento:
* En cada frame físico, busca al jugador en el grupo `"player"`.
* Si el jugador se encuentra a una distancia menor a `detect_radius`, ajusta su vector `velocity` para avanzar hacia él a velocidad `speed`.
* **Disparo:** El temporizador `shoot_timer` decrementa. Al llegar a `0`, genera un proyectil magenta (`magenta_projectile.tscn`) apuntando directamente al jugador y se reinicia el temporizador según `attack_cooldown`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que dispare extremadamente rápido (ej. cada medio segundo):**
  ```gdscript
  @export var attack_cooldown: float = 0.5 # Cambiar de 2.4 a 0.5
  ```
* **Aumentar el rango de visión para que detecte al jugador desde lejos:**
  ```gdscript
  @export var detect_radius: float = 800.0 # Cambiar de 280.0 a 800.0
  ```
* **Hacer que no se mueva hacia el jugador (enemigo torreta fijo):**
  En `_physics_process`, comenta la asignación de velocidad de persecución (línea ~42):
  ```gdscript
  # velocity = dir * speed # Comentar para que se quede flotando fijo en su sitio
  ```

---

### 3.3 `enemies/magenta_projectile.gd`
* **Tipo:** `Area2D`.
* **Propósito:** Proyectil enemigo parreable. Al pertenecer al grupo `"magenta"`, permite al jugador rebotar sobre él.

#### ⚙️ Lógica y Funcionamiento:
* En `_ready()`, se añade automáticamente a los grupos `"enemy_projectiles"` y `"magenta"`.
* Avanza en línea recta en su dirección inicial (`direction * speed * delta`).
* Si entra en contacto con el jugador, le inflige 1 punto de daño y se destruye.
* Tiene un temporizador de autodestrucción automática de 4 segundos.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que el proyectil sea el doble de rápido:**
  ```gdscript
  @export var speed: float = 460.0 # Cambiar de 230.0 a 460.0
  ```
* **Convertir la bala en no parreable (quitar el color magenta):**
  Cambia la variable `is_magenta` a `false`:
  ```gdscript
  var is_magenta: bool = false # El proyectil se vuelve negro y no se puede parrear
  ```

---

## 👑 4. JEFES (BOSSES)

### 4.1 `bosses/boss_compass_king.gd`
* **Tipo:** `CharacterBody2D`.
* **Propósito:** Lógica, ataques y renderizado de "El Rey Compás" (Jefe del Sector Tecnológico).

#### ⚙️ Lógica y Funcionamiento:
* **Estado `BOUNCE` (Rebote):** Se mueve en diagonal. Utiliza `move_and_collide()`. Si detecta una colisión, rebota usando `velocity.bounce()`. Si el impacto fue contra el suelo (vector normal Y menor a -0.7), genera dos ondas de choque terrestres que viajan a la izquierda y derecha.
* **Estado `SHOOT` (Disparo):** Se detiene en el aire y flota simulando una onda senoidal. Cada 40 frames físicos, llama a `shoot_burst()`, disparando 8 proyectiles en círculo (3 de ellos son magenta/parreables y 5 son negros/dañinos).
* **Muerte (`die()`):** Instancia un pigmento azul de tipo `"dash"` en su posición y se elimina de escena.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Reducir o aumentar la vida del jefe para pruebas:**
  ```gdscript
  @export var max_health: int = 1 # Muere de un solo golpe (Default: 15)
  ```
* **Hacer que dispare solo proyectiles normales inbloqueables (Dificultad alta):**
  En la función `shoot_burst` (línea ~98), fuerza a que ninguna bala sea magenta:
  ```gdscript
  # Quitar o comentar la condición de hacer algunas balas magenta
  proj.is_magenta = false
  ```
* **Hacer que las ondas de choque en el suelo sean ultrarrápidas:**
  Modifica la velocidad en `spawn_floor_shockwaves` (línea ~82):
  ```gdscript
  proj.speed = 400.0 # Cambiar de 180.0 a 400.0
  ```

---

### 4.2 `bosses/boss_articulated_ruler.gd`
* **Tipo:** `CharacterBody2D`.
* **Propósito:** Lógica de movimiento multi-segmento (tipo serpiente), embestidas y proyectiles de "La Regla Articulada" (Jefe del Sector Orgánico).

#### ⚙️ Lógica y Funcionamiento:
* **Historial de Posiciones (`history`):** Al moverse, guarda su posición global al inicio del array `history`. Los 5 segmentos traseros leen este array en intervalos de 12 frames para posicionarse en pantalla.
* **Colisión de Segmentos:** La función `check_segment_player_collision()` calcula de forma manual la distancia del jugador a cada segmento. Si es menor a 24 píxeles, daña al jugador y le aplica empuje.
* **Estado `PATROL` (Patrulla):** Camina horizontalmente aplicando gravedad en su eje Y. Si colisiona con una pared lateral detectada por su `wall_ray`, invierte la dirección de avance.
* **Estado `CHARGE` (Embestida):** Gira hacia la dirección X del jugador, aumenta su velocidad a `220.0` y embiste. Durante la carga, cada 30 frames dispara proyectiles magenta verticales hacia arriba desde algún segmento aleatorio de su cuerpo.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer la serpiente extremadamente larga:**
  Aumenta el número de segmentos (línea ~14):
  ```gdscript
  var num_segments: int = 12 # Dibuja y calcula colisión para 12 piezas (Default: 5)
  ```
* **Hacer que el ataque de carga sea súper veloz:**
  Modifica la velocidad en el cambio de estado (línea ~63):
  ```gdscript
  speed = 450.0 # Carga rápida (Default: 220.0)
  ```
* **Hacer que no dispare proyectiles durante la embestida:**
  Comenta la llamada a disparo en la línea ~71:
  ```gdscript
  # if Engine.get_physics_frames() % 30 == 0:
  #     shoot_upward_magenta()
  ```

---

## 🗺️ 5. NIVELES Y MECÁNICAS

### 5.1 `levels/hub_nexo.gd`
* **Tipo:** `Node2D`.
* **Propósito:** Controlador del nivel central (Nexus) que gestiona el acceso a las alas laterales y abre el foso de victoria final al derrotar a ambos jefes.

#### ⚙️ Lógica y Funcionamiento:
* En `_ready()`, fija la posición de respawn de este nivel en `Vector2(0, -60)`.
* **`check_vault_status()`**: En cada frame, comprueba si `boss_compass_defeated` y `boss_ruler_defeated` son verdaderos en `GameState`. Si es así, desactiva la colisión del suelo central (`vault_gate_collision.disabled = true`) para abrir el foso.
* Maneja las transiciones al colisionar con las puertas:
  - Puerta Izquierda (`LeftDoor`) -> Carga `levels/straight_wing.tscn`.
  - Puerta Derecha (`RightDoor`) -> Carga `levels/curve_wing.tscn`.
  - Foso de Caída (`VaultDropZone`) -> Carga `levels/victory_screen.tscn`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Abrir el foso de victoria desde el principio (sin vencer jefes):**
  Modifica la condición en la línea ~31:
  ```gdscript
  if true: # Forzar apertura inmediata de la bóveda
  ```
* **Cambiar el nivel al que te manda la puerta izquierda:**
  Modifica la ruta del archivo en la línea ~46:
  ```gdscript
  get_tree().call_deferred("change_scene_to_file", "res://levels/TU_NUEVO_NIVEL.tscn")
  ```

---

### 5.2 `levels/boss_compass_level.gd`
* **Tipo:** `Node2D`.
* **Propósito:** Configura los parámetros iniciales para la arena de combate del Rey Compás.

#### ⚙️ Lógica y Funcionamiento:
* En `_ready()`, establece la reaparición del jugador en `Vector2(0, 40)`.
* Escucha la señal `ability_unlocked`. Si el jugador recoge el pigmento azul de dash liberado por el jefe, espera 2 segundos y lo teletransporta automáticamente de regreso al Nexo.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Teletransportar al jugador al Nexo inmediatamente tras derrotar al jefe (sin esperar 2 segundos):**
  Modifica la línea ~10:
  ```gdscript
  await get_tree().create_timer(0.0).timeout # Espera 0 segundos
  ```

---

### 5.3 `levels/boss_ruler_level.gd`
* **Tipo:** `Node2D`.
* **Propósito:** Inicializa las condiciones físicas y plataformas estáticas de la arena de la Regla Articulada.

#### ⚙️ Lógica y Funcionamiento:
* Establece la posición de respawn en `Vector2(-300, 40)`.
* Al desbloquear el doble salto, espera 2 segundos y cambia la escena a `hub_nexo.tscn`.
* En `_draw()`, pinta el fondo gris claro y dibuja dos plataformas estáticas blancas con bordes negros usando funciones de dibujo vectorial de Godot.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Añadir una tercera plataforma en medio de la pantalla:**
  En `_draw()` (línea ~32), puedes copiar la estructura e introducir nuevas coordenadas:
  ```gdscript
  var plat3 = Rect2(-50, -100, 100, 12) # Coordenadas X, Y, Ancho, Alto
  draw_rect(plat3, Color.WHITE)
  draw_rect(plat3, Color.BLACK, false, 2.0)
  ```

---

### 5.4 `levels/straight_wing.gd`
* **Tipo:** `Node2D`.
* **Propósito:** Gestiona el Sector Tecnológico (nivel de plataformas previo al primer jefe).

#### ⚙️ Lógica y Funcionamiento:
* Fija la posición de reaparición inicial del nivel en `Vector2(-400, 40)`.
* Conecta las señales de entrada de cuerpo de la puerta de salida (regresar al Hub) y la puerta final (ir a la arena de combate del Rey Compás).

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Cambiar el punto de reaparición predeterminado del nivel:**
  Modifica las coordenadas en la línea ~12:
  ```gdscript
  GameState.respawn_position = Vector2(200, 40) # Aparece más adelante en el mapa
  ```

---

### 5.5 `levels/curve_wing.gd`
* **Tipo:** `Node2D`.
* **Propósito:** Gestiona el Sector Orgánico (nivel vertical previo a la Regla Articulada).

#### ⚙️ Lógica y Funcionamiento:
* Fija el punto de reaparición inicial del nivel en `Vector2(-400, 40)`.
* Dibuja los contornos estéticos y físicos de las colisiones del mapa mediante líneas negras en `_draw()`.
* Vincula las puertas de salida e ingreso a la arena de la Regla Articulada.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Modificar las dimensiones visuales del mapa:**
  Modifica las variables de límite en las líneas 26 y 27 para redimensionar el espacio de dibujado de la página:
  ```gdscript
  var limit_x = 1500.0 # Hacer el mapa más largo horizontalmente
  var limit_y = 800.0  # Hacer el mapa más alto verticalmente
  ```

---

### 5.6 `levels/checkpoint.gd`
* **Tipo:** `Area2D`.
* **Propósito:** Al ser cruzado por el jugador, establece su posición como el nuevo punto de reaparición del juego.

#### ⚙️ Lógica y Funcionamiento:
* **Detección:** Al detectar la colisión del jugador, llama a `deactivate` en todos los checkpoints del nivel usando `get_tree().call_group`.
* **Activación:** Cambia su variable `active` a `true`, asigna `GameState.respawn_position` a su propia posición global (restando 10 píxeles en el eje Y para evitar atascos en el suelo) y genera partículas visuales.
* **Dibujo:** Si está inactivo, dibuja el banderín blanco con borde negro; si está activo, rellena el triángulo con su color configurado (`active_color`).

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que un checkpoint te cure al tocarlo:**
  Añade una línea en `_on_body_entered` (línea ~17):
  ```gdscript
  GameState.health = GameState.max_health # Llena la vida al tocar el checkpoint
  ```

---

### 5.7 `levels/hazard_spikes.gd`
* **Tipo:** `Area2D`.
* **Propósito:** Área de peligro que castiga al jugador al tocar pinchos.

#### ⚙️ Lógica y Funcionamiento:
* **Colisión Dinámica:** En `_ready()`, crea un `CollisionPolygon2D` programático en base a las dimensiones configuradas de `width` y `height`.
* **Penalización:** Si el jugador toca el área, le inflige 1 de daño y teletransporta sus coordenadas globales inmediatamente a la última posición de reaparición registrada en `GameState.respawn_position`.
* **Dibujo procedural:** Divide su ancho en secciones de 16 píxeles para dibujar triángulos individuales alineados.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Desactivar la teletransportación automática al checkpoint (hacer que solo dañe):**
  Comenta la línea ~23 en `_on_body_entered`:
  ```gdscript
  func _on_body_entered(body: Node2D):
      if body.is_in_group("player") and body.has_method("take_damage"):
          body.take_damage(1, Vector2.UP * 250)
          # body.global_position = GameState.respawn_position # Comentar esto
  ```
* **Hacer que los pinchos maten al jugador al instante (Muerte Súbita):**
  Reemplaza el daño de 1 por la vida máxima del jugador en la línea ~22:
  ```gdscript
  body.take_damage(GameState.max_health, Vector2.UP * 250)
  ```

---

### 5.8 `levels/moving_platform.gd`
* **Tipo:** `AnimatableBody2D`.
* **Propósito:** Plataforma móvil que permite crear desafíos de salto. El uso de `AnimatableBody2D` asegura que la física del jugador se mueva de manera uniforme junto con la plataforma al pararse sobre ella.

#### ⚙️ Lógica y Funcionamiento:
* En `_ready()`, instala un `CollisionShape2D` con forma de rectángulo basado en las variables `width` y `height`.
* En `_physics_process(delta)`:
  - Incrementa la variable `timer`.
  - Calcula el factor de oscilación usando `sin(tiempo * velocidad_angular)`.
  - Mueve la posición de la plataforma aplicando `start_pos + offset * progress`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que la plataforma se mueva el doble de rápido:**
  Reduce la variable `duration` (línea 4):
  ```gdscript
  @export var duration: float = 1.5 # Ciclo completo en 1.5s en vez de 3.0s
  ```
* **Hacer que el recorrido sea vertical (arriba y abajo):**
  Modifica la dirección del offset vector en la línea 3:
  ```gdscript
  @export var offset: Vector2 = Vector2(0, -180) # Se mueve 180 píxeles hacia arriba (Default: 150, 0)
  ```

---

### 5.9 `levels/updraft_wind.gd`
* **Tipo:** `Area2D`.
* **Propósito:** Zona que ejerce una fuerza de viento ascendente continua sobre el jugador y le recarga las habilidades aéreas.

#### ⚙️ Lógica y Funcionamiento:
* Genera su caja física en base a `width` y `height`.
* En `_physics_process()`, busca cualquier nodo en el grupo `"player"` que colisione con el área.
* Si el jugador está dentro:
  - Modifica su velocidad vertical en su física hacia `-450.0` (velocidad de ascenso del viento) a un ritmo determinado por la constante `wind_force`.
  - Vuelve a poner en `true` las variables `can_dash_air` y `can_double_jump_air` del jugador para que no se quede sin recursos al flotar.
* Dibuja líneas grises/celestes que suben a velocidades aleatorias simulando corrientes de aire.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Aumentar la velocidad a la que el viento te hace flotar hacia arriba:**
  Modifica el valor objetivo en la línea ~32:
  ```gdscript
  body.velocity.y = move_toward(body.velocity.y, -700.0, wind_force * delta) # Te impulsa más rápido (Default: -450)
  ```
* **Hacer que el viento te empuje hacia la derecha (viento lateral):**
  Ajusta el eje X en lugar de modificar la velocidad vertical en Y (líneas ~32 a ~36):
  ```gdscript
  body.velocity.x = move_toward(body.velocity.x, 400.0, wind_force * delta) # Viento hacia la derecha
  ```

---

### 5.10 `levels/pigment_pickup.gd`
* **Tipo:** `Area2D`.
* **Propósito:** Coleccionable de pigmento que desbloquea habilidades permanentes al jugador.

#### ⚙️ Lógica y Funcionamiento:
* **Efecto de flotación:** En `_process()`, calcula `sin(bob_timer)` para aplicar un leve movimiento vertical oscilatorio constante al sprite del objeto.
* **Recolección:** Si colisiona con el jugador:
  - Si es tipo `"dash"`, pone `GameState.has_dash = true` y crea un texto flotante `"DASH UNLOCKED..."`.
  - Si es tipo `"double_jump"`, activa `GameState.has_double_jump = true` y crea el texto de doble salto.
  - Instancia 12 salpicaduras de partículas de tinta de su color y se auto-elimina de la escena.
* **`spawn_text(...)`**: Crea un nodo de tipo `Label` dinámico en pantalla y usa un `Tween` para animarlo desplazándose hacia arriba mientras se desvanece de forma gradual antes de llamar a `queue_free()`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que un pigmento desbloquee todas las habilidades al mismo tiempo:**
  Modifica `_on_body_entered` (línea ~17):
  ```gdscript
  func _on_body_entered(body: Node2D):
      if body.is_in_group("player"):
          GameState.has_dash = true
          GameState.has_double_jump = true
          spawn_text("¡TODAS LAS HABILIDADES UNLOCKED!")
          # ... código de partículas y queue_free()
  ```

---

### 5.11 `levels/victory_screen.gd`
* **Tipo:** `CanvasLayer`.
* **Propósito:** Muestra el menú de fin de juego tras completar con éxito la aventura.

#### ⚙️ Lógica y Funcionamiento:
* En `_ready()`, asegura que el puntero del ratón sea visible para que el jugador pueda hacer clic en los botones de la interfaz gráfica.
* Vincula los botones usando código programático:
  - El botón de reiniciar limpia los datos llamando a `GameState.reset_game()` y cambia de escena a `hub_nexo.tscn`.
  - El botón de salir cierra la ventana del juego con `get_tree().quit()`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que al reiniciar no se borren tus poderes:**
  Comenta la llamada a reiniciar el estado en la línea ~12:
  ```gdscript
  func _on_restart_pressed():
      # GameState.reset_game() # Comentar esto para mantener tus habilidades desbloqueadas
      get_tree().change_scene_to_file("res://levels/hub_nexo.tscn")
  ```

---

## 🎨 6. INTERFAZ Y EFECTOS

### 6.1 `ui/hud_visuals.gd`
* **Tipo:** `Control`.
* **Propósito:** Maneja el HUD en pantalla, dibujando de manera vectorial la vida y tinta del jugador, la vida del jefe activo y controlando el menú de pausa del juego.

#### ⚙️ Lógica y Funcionamiento:
* **Escucha de Señales:** Se suscribe a `player_health_changed` y `player_ink_changed` de `GameState` para redibujar la interfaz en pantalla.
* **Barra de Jefe Dinámica:** En `_process()`, si no hay un jefe activo registrado en la UI, busca si existe en escena algún nodo del grupo `"bosses"`. Si lo encuentra, conecta sus señales de vida, detecta si es el Compás o la Regla y activa el dibujo de la barra inferior con su nombre correspondiente.
* **Dibujado Vectorial (`_draw()`):**
  - **Vida del jugador:** Dibuja hasta `GameState.max_health` siluetas de gotas de tinta (línea ~74). Si la salud del jugador cubre ese índice, las dibuja rellenas de negro sólido; si no, dibuja solo la línea de borde exterior vacía.
  - **Barra de tinta:** Dibuja un rectángulo proporcional al porcentaje actual de tinta del jugador.
  - **Iconos de habilidades:** Si `GameState.has_dash` o `has_double_jump` son verdaderos, dibuja sus respectivos iconos vectoriales (una flecha de dash azul y flechas dobles amarillas de doble salto) arriba a la derecha.
  - **Vida del jefe:** Si un jefe está activo, dibuja una barra rosa con bordes en la parte inferior de la pantalla.
* **Menú de Pausa:** En `_input()`, si detecta `Escape` o `P`, llama a `toggle_pause()`, que detiene el juego en el motor estableciendo `get_tree().paused` y hace visible el menú de pausa.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Hacer que las botellas de vida vacías tengan color gris y las llenas color azul:**
  Busca las líneas ~87 y ~89 en `_draw()` e introduce colores personalizados:
  ```gdscript
  if is_full:
      draw_colored_polygon(pts, Color(0.1, 0.5, 0.9)) # Relleno Azul (Default: Color.BLACK)
  else:
      draw_colored_polygon(pts, Color(0.8, 0.8, 0.8)) # Relleno Gris cuando está vacío (Default: Color.WHITE)
      draw_polyline(PackedVector2Array(Array(pts) + [pts[0]]), Color.BLACK, 2.0)
  ```
* **Cambiar el tamaño de la barra de vida del jefe:**
  Ajusta las variables de dimensiones en la línea ~136:
  ```gdscript
  var bbar_width = 600.0 # Barra más ancha para ver mejor (Default: 400.0)
  var bbar_height = 20.0 # Más alta (Default: 14.0)
  ```

---

### 6.2 `effects/ink_splat.gd`
* **Tipo:** `Node2D`.
* **Propósito:** Genera y anima partículas físicas simulando salpicaduras de tinta de colores para efectos visuales.

#### ⚙️ Lógica y Funcionamiento:
* **Generación:** En `_ready()`, genera un bucle de 8 iteraciones para crear 8 partículas. A cada una le asigna una velocidad inicial en base a un ángulo aleatorio entre `0` y `2 * PI` y una magnitud aleatoria, además de un tamaño de radio de partícula aleatorio.
* **Simulación de Físicas:** En `_process(delta)`:
  - Actualiza la posición global sumando la velocidad física.
  - Añade gravedad sumando `200.0 * delta` a la velocidad en Y de cada partícula, provocando una caída curva natural.
  - Reduce paulatinamente el tamaño del radio de cada partícula con el paso del tiempo.
  - Cuando se cumple el tiempo límite de `lifetime` (0.4s), destruye el emisor de partículas.
* **Dibujado:** En `_draw()`, calcula la atenuación de transparencia (alfa) de las partículas según el tiempo transcurrido y las dibuja usando `draw_circle`.

#### 🛠️ Recetario de Modificaciones para el Examen:
* **Aumentar la cantidad de partículas para hacer un efecto explosivo gigante:**
  Aumenta el bucle de creación en `_ready()` (línea ~10):
  ```gdscript
  for i in range(35): # Generar 35 partículas en vez de 8
  ```
* **Hacer que las partículas duren más tiempo flotando antes de desaparecer:**
  Ajusta la variable `lifetime` (línea 5):
  ```gdscript
  var lifetime: float = 1.2 # Mayor duración en pantalla (Default: 0.4)
  ```
* **Quitar la gravedad para que las partículas salgan volando flotando al espacio:**
  Comenta la suma de gravedad en la línea ~30:
  ```gdscript
  # p.vel.y += 200.0 * delta # Quitar gravedad en partículas
  ```
