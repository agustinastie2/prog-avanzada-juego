# Trazos del Destino (Inkwell: The Lost Margins)

A minimal, vector-style 2D Action-Platformer prototype built in **Godot 4.6**. The game utilizes a hand-drawn sketchbook aesthetic (black ink strokes and outline shapes on a white paper background) with colored accent pigments representing powers and hazards.

---

## 🎮 Game Controls & Mechanics

### Movement
* **Move Left / Right:** `A` / `D` or `Left` / `Right` Arrow keys.
* **Jump / Wall Jump:** `Spacebar` / `W` / `Up` Arrow.
  * Hold movement against a wall to slide, and press jump to spring away.
* **Dash:** `Shift` or `C` keys.
  * *Requirement:* Unlock the **Blue Pigment** by defeating Boss 1. Gives invincibility frames and high speed horizontal dash.
* **Double Jump:** Press Jump in mid-air.
  * *Requirement:* Unlock the **Yellow Pigment** by defeating Boss 2.

### Combat
* **Ranged Ink Bullet:** Click **Left Mouse Button** (aims at screen cursor) or press **K / X** (shoots straight ahead). Consumes 5% ink.
* **Melee Swipe:** Press **J / Z**. Creates a circular ink-splatter arc around the player, damaging and knocking back enemies in close range. Consumes 10% ink.
* **Ink Pool:** Your ink tank regenerates automatically over time when you are not attacking.

### 💖 Magenta Parry & Bounce
* **Hazards & Projectiles** colored **Magenta/Purple** can be parried!
* **How to perform:** Jump directly onto any magenta bullet or spike hazard.
* **Effect:** You automatically bounce high into the air, reset your air dash and double jump, and gain a **Pigment Charge** (glowing magenta outline). Your next melee or ranged attack will deal **Double Damage**.

---

## 🏰 World Structure & Level Flow

The game is structured as a hub-and-spoke mini-Metroidvania:

1. **El Nexo (The Hub):** The starting safe room. 
   * Left exit goes to **Sector Tecnológico (Wing 1)**.
   * Right exit goes to **Sector Orgánico (Wing 2)**.
   * A central vault gate lies in the floor. Once both boss pigments are collected, the locks glow in their respective colors and open the vault, dropping you into the **Victory Screen**.
2. **Sector Tecnológico (Wing 1):** A precision platforming sector with spikes on the ground and horizontally moving platforms. At the end is a gateway to the **Boss 1 Arena**.
3. **Sector Orgánico (Wing 2):** A vertical climbing sector utilizing upward wind currents (updrafts) that launch the player. At the end is a gateway to the **Boss 2 Arena**.
4. **Boss Arenas (Separate Rooms):**
   * **Boss 1: El Rey Compás (The Compass King):** A giant math compass that bounces off the walls, sending shockwaves along the floor on impact. Defeating it drops the **Blue Pigment (Dash)**.
   * **Boss 2: La Regla Articulada (The Articulated Ruler):** A segmented crawling snake rule that patrolls and charges at high speed, launching vertical magenta bullets. Defeating it drops the **Yellow Pigment (Double Jump)**.
   * *Flow:* Defeating a boss and collecting their pigment automatically teleports the player back to **El Nexo** after a 2-second celebration window.

---

## 🛡️ Robustness & Safety Nets

* **Pause Menu:** Press **Escape** or **P** at any time to open the pause menu. It pauses the game world and allows you to **Resume**, **Restart Room** (reloads the current scene at your last checkpoint), or **Quit to Hub**.
* **Visual Checkpoints:** Outlined flagpoles are placed throughout the levels. Touching one activates it (turns it solid color) and sets your checkpoint.
* **Infinite Fall Protection:** If you clip through solid geometry or fall off the level bounds, you instantly take `1 HP` of damage and teleport safely back to your active checkpoint, preventing infinite falling.

---

## 🤖 Automated Integration Testing

An automated integration test runner is implemented in [test_runner.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/global/test_runner.gd):
* **Triggering Tests:** Create an empty file named `.run_tests` in the project root.
* **Behavior:** When the game starts and detects the `.run_tests` file, it runs in automated test mode. It automatically loads each wing, teleports to the boss, simulates defeat, picks up the pigments, verifies the hub gate unlocks, drops through the vault, and asserts successful transition to the Victory Screen.
* **Safety:** When the `.run_tests` file is absent (default), the game starts in normal gameplay mode for the player.

---

## 📂 Codebase File Architecture

Below is a detailed description of the project structure and the specific role of each script and scene file:

### ⚙️ Global & System Files
* **[game_state.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/global/game_state.gd) (Autoload Singleton):**
  Tracks global gameplay variables, such as player health (`health`), current ink pool (`ink`), unlocked pigments/powers (`has_dash`, `has_double_jump`), and boss defeat flags. It exposes signals that the HUD and level elements listen to.
* **[test_runner.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/global/test_runner.gd) (Autoload integration test runner):**
  If `.run_tests` exists in the project root, this script automatically conducts an end-to-end traversal of the entire game (testing loading wings, boss fights, pigment collecting, vault unlocking, and reaching the victory screen) and terminates with a success exit code.

### 👤 Player & Attacks
* **[player.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/player/player.tscn) & [player.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/player/player.gd):**
  The main playable droplet. Implements basic physics, Coyote time jump, wall-sliding, wall-jumping, dash, double-jump, melee checks, mouse/keyboard shooting, and out-of-bounds safety net. Visuals are drawn procedurally via vector curves inside the `_draw()` function (squashing and stretching based on velocity).
* **[projectile.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/player/projectile.tscn) & [projectile.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/player/projectile.gd):**
  The player's ink bullet. Flies at constant velocity in the chosen direction and triggers ink splash particles upon hitting walls or enemies.

### 🖥️ User Interface (UI)
* **[hud.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/ui/hud.tscn) & [hud_visuals.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/ui/hud_visuals.gd):**
  Renders the vector UI overlays including the 5 player health hearts, ink pool gauge, unlocked powerup badges (Blue/Yellow), and the active boss HP bar. It also manages input detection (Escape/P) to show/hide the **Pause Menu** overlay.
* **[victory_screen.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/victory_screen.tscn) & [victory_screen.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/victory_screen.gd):**
  Displayed upon falling into the final vault, offering simple flat RESTART or QUIT buttons.

### 🚩 Environmental Elements
* **[checkpoint.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/checkpoint.tscn) & [checkpoint.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/checkpoint.gd):**
  Save flags. Touching them activates their respective pigment color (Blue/Yellow/Black) and updates `GameState.respawn_position` to prevent infinite falls.
* **[hazard_spikes.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/hazard_spikes.tscn) & [hazard_spikes.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/hazard_spikes.gd):**
  Triangular spike obstacles. Touching them damages the player and teleports them back to the active checkpoint.
* **[updraft_wind.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/updraft_wind.tscn) & [updraft_wind.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/updraft_wind.gd):**
  Lifting wind currents. Applies a smooth upward velocity to the player and draws procedural rising wind lines.
* **[moving_platform.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/moving_platform.tscn) & [moving_platform.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/moving_platform.gd):**
  Horizontally oscillating platforms drawn as wooden sketch rulers.
* **[pigment_pickup.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/pigment_pickup.tscn) & [pigment_pickup.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/pigment_pickup.gd):**
  Vibrant rotating pigment pick-ups dropped by defeated bosses to unlock abilities.
* **[ink_splat.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/effects/ink_splat.gd) (Script only):**
  A script loaded dynamically on transient `Node2D` nodes to draw physics-based ink splash particle bursts.

### 👾 Enemies & Hazards
* **[walking_smudge.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/enemies/walking_smudge.tscn) & [walking_smudge.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/enemies/walking_smudge.gd):**
  Patrolling ground enemy (2 HP). Walks left/right and reverses at edges/walls.
* **[flying_spark.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/enemies/flying_spark.tscn) & [flying_spark.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/enemies/flying_spark.gd):**
  Floating diamond enemy (2 HP). Chases player when nearby and fires magenta parryable bullets.
* **[magenta_projectile.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/enemies/magenta_projectile.tscn) & [magenta_projectile.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/enemies/magenta_projectile.gd):**
  Parryable enemy bullet. Can be configured via `is_magenta` to behave/draw as either a magenta parry-bounce bullet or a normal black damage bullet.

### 👑 Bosses & Arenas
* **[boss_compass_king.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/bosses/boss_compass_king.tscn) & [boss_compass_king.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/bosses/boss_compass_king.gd):**
  Boss 1 (Compass King - 15 HP). Bounces off walls, launches ground shockwaves, and shoots projectile circles. Defeat drops the Dash pigment.
* **[boss_articulated_ruler.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/bosses/boss_articulated_ruler.tscn) & [boss_articulated_ruler.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/bosses/boss_articulated_ruler.gd):**
  Boss 2 (Segmented Ruler Snake - 15 HP). Crawls on the ground using segment trailing history and charges at the player. Uses a `RayCast2D` to avoid getting stuck on walls. Defeat drops the Double Jump pigment.
* **[boss_compass_level.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/boss_compass_level.tscn) & [boss_compass_level.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/boss_compass_level.gd):**
  Dedicated boss room for Boss 1. Handles spawning, boundaries, and returns the player to El Nexo.
* **[boss_ruler_level.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/boss_ruler_level.tscn) & [boss_ruler_level.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/boss_ruler_level.gd):**
  Dedicated boss room for Boss 2. Handles platform arrangements and Hub return transitions.

### 🗺️ Wing Levels
* **[hub_nexo.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/hub_nexo.tscn) & [hub_nexo.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/hub_nexo.gd):**
  The central hub scene that connects the wings and Vault door.
* **[straight_wing.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/straight_wing.tscn) & [straight_wing.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/straight_wing.gd):**
  Wing 1 platforming level leading to the Compass King's arena door.
* **[curve_wing.tscn](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/curve_wing.tscn) & [curve_wing.gd](file:///c:/Users/Agustin/Documents/trazos-del-destino-2/levels/curve_wing.gd):**
  Wing 2 climbing level leading to the Ruler Snake's arena door.

