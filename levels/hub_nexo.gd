extends Node2D

@onready var left_door = $LeftDoor
@onready var right_door = $RightDoor
@onready var vault_gate = $VaultGate
@onready var vault_gate_collision = $VaultGate/CollisionShape2D
@onready var vault_drop_zone = $VaultDropZone
@onready var player = $Player

func _ready():
	# Connect transition signals
	left_door.body_entered.connect(_on_left_door_entered)
	right_door.body_entered.connect(_on_right_door_entered)
	vault_drop_zone.body_entered.connect(_on_vault_drop_entered)
	
	# Set player respawn point in this Hub
	GameState.respawn_position = Vector2(0, -60)
	
	# Check boss defeat status to unlock vault
	check_vault_status()

func _physics_process(_delta: float):
	# Keep checking just in case
	check_vault_status()
	queue_redraw()

func check_vault_status():
	var compass_dead = GameState.boss_compass_defeated
	var ruler_dead = GameState.boss_ruler_defeated
	
	if compass_dead and ruler_dead:
		# Disable gate, let player drop down
		if vault_gate_collision and not vault_gate_collision.disabled:
			vault_gate_collision.disabled = true
			# Spawn some ink particles when gate opens
			for i in range(10):
				var splat = Node2D.new()
				splat.global_position = vault_gate.global_position
				splat.set_script(load("res://effects/ink_splat.gd"))
				splat.color = Color(0.85, 0.08, 0.52) # Magenta open gate color
				add_child(splat)

func _on_left_door_entered(body: Node2D):
	if body.is_in_group("player"):
		left_door.get_node("CollisionShape2D").set_deferred("disabled", true)
		get_tree().call_deferred("change_scene_to_file", "res://levels/straight_wing.tscn")

func _on_right_door_entered(body: Node2D):
	if body.is_in_group("player"):
		right_door.get_node("CollisionShape2D").set_deferred("disabled", true)
		get_tree().call_deferred("change_scene_to_file", "res://levels/curve_wing.tscn")

func _on_vault_drop_entered(body: Node2D):
	if body.is_in_group("player"):
		vault_drop_zone.get_node("CollisionShape2D").set_deferred("disabled", true)
		get_tree().call_deferred("change_scene_to_file", "res://levels/victory_screen.tscn")

func _draw():
	# Draw level borders and aesthetic vector elements
	# Background page borders
	var limit = 600.0
	draw_rect(Rect2(-limit, -limit, limit*2.0, limit*2.0 + 800.0), Color(0.96, 0.96, 0.96), true) # page background
	
	# Draw solid ground/walls (sketch style black lines)
	draw_line(Vector2(-500, 80), Vector2(-60, 80), Color.BLACK, 3.0)
	draw_line(Vector2(60, 80), Vector2(500, 80), Color.BLACK, 3.0)
	draw_line(Vector2(-500, 80), Vector2(-500, -400), Color.BLACK, 3.0)
	draw_line(Vector2(500, 80), Vector2(500, -400), Color.BLACK, 3.0)
	draw_line(Vector2(-500, -400), Vector2(500, -400), Color.BLACK, 3.0)
	
	# Draw pit vertical outlines
	draw_line(Vector2(-60, 80), Vector2(-60, 300), Color.BLACK, 3.0)
	draw_line(Vector2(60, 80), Vector2(60, 300), Color.BLACK, 3.0)
	draw_line(Vector2(-60, 300), Vector2(-80, 300), Color.BLACK, 3.0)
	draw_line(Vector2(60, 300), Vector2(80, 300), Color.BLACK, 3.0)
	draw_line(Vector2(-80, 300), Vector2(-80, 340), Color.BLACK, 3.0)
	draw_line(Vector2(80, 300), Vector2(80, 340), Color.BLACK, 3.0)
	
	# Draw vault gate if locked
	if not (GameState.boss_compass_defeated and GameState.boss_ruler_defeated):
		draw_line(Vector2(-60, 80), Vector2(60, 80), Color.BLACK, 5.0)
	
	# Draw lock indicator above vault gate
	var indicator_pos = Vector2(0, 50)
	
	# Left lock (Blue pigment)
	var left_lock_color = Color(0.1, 0.5, 0.9) if GameState.boss_compass_defeated else Color(0.4, 0.4, 0.4)
	draw_circle(indicator_pos + Vector2(-20, 0), 8.0, Color.WHITE)
	draw_circle(indicator_pos + Vector2(-20, 0), 8.0, left_lock_color, false, 2.0)
	if GameState.boss_compass_defeated:
		draw_circle(indicator_pos + Vector2(-20, 0), 4.0, left_lock_color)
		
	# Right lock (Yellow pigment)
	var right_lock_color = Color(0.9, 0.8, 0.1) if GameState.boss_ruler_defeated else Color(0.4, 0.4, 0.4)
	draw_circle(indicator_pos + Vector2(20, 0), 8.0, Color.WHITE)
	draw_circle(indicator_pos + Vector2(20, 0), 8.0, right_lock_color, false, 2.0)
	if GameState.boss_ruler_defeated:
		draw_circle(indicator_pos + Vector2(20, 0), 4.0, right_lock_color)
		
	# A line connecting them
	draw_line(indicator_pos + Vector2(-12, 0), indicator_pos + Vector2(12, 0), Color.BLACK, 1.5)
	
	# Draw instructions on the background
	var font = ThemeDB.fallback_font
	if font:
		# Draw Hub Title
		draw_string(font, Vector2(-100, -220), "EL NEXO", HORIZONTAL_ALIGNMENT_CENTER, 200, 24, Color.BLACK)
		
		# Draw Wing labels
		draw_string(font, Vector2(-420, -130), "<-- WING 1\n(Rey Compás)", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, Color.BLACK)
		draw_string(font, Vector2(260, -130), "WING 2 -->\n(Regla Articulada)", HORIZONTAL_ALIGNMENT_CENTER, 160, 14, Color.BLACK)
		
		# Locked vault instructions
		if not (GameState.boss_compass_defeated and GameState.boss_ruler_defeated):
			draw_string(font, Vector2(-150, 20), "VAULT LOCKED: Defeat both bosses to proceed", HORIZONTAL_ALIGNMENT_CENTER, 300, 11, Color(0.4, 0.4, 0.4))
		else:
			draw_string(font, Vector2(-150, 20), "VAULT OPEN: Drop down below!", HORIZONTAL_ALIGNMENT_CENTER, 300, 11, Color(0.85, 0.08, 0.52))
			
		# Controls cheat sheet
		draw_string(font, Vector2(-200, -320), "CONTROLS:\nMove: A/D or Arrow Keys\nJump: Space / W / Up\nMelee: Z / J\nShoot: X / K or Left Mouse Click\nDash: Shift / C (unlocked by Wing 1)", HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color(0.3, 0.3, 0.3))
