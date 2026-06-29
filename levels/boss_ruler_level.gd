extends Node2D

func _ready():
	GameState.respawn_position = Vector2(-300, 40)
	GameState.ability_unlocked.connect(_on_ability_unlocked)

func _on_ability_unlocked(ability_name: String):
	if ability_name == "double_jump":
		# Auto-teleport back to Hub after 2 seconds
		await get_tree().create_timer(2.0).timeout
		get_tree().call_deferred("change_scene_to_file", "res://levels/hub_nexo.tscn")

func _draw():
	# Draw boss arena
	var limit_x = 450.0
	var limit_y = 300.0
	draw_rect(Rect2(-limit_x, -limit_y, limit_x * 2.0, limit_y * 2.0), Color(0.96, 0.96, 0.96), true)
	
	# Outlines
	draw_line(Vector2(-limit_x + 30, 80), Vector2(limit_x - 30, 80), Color.BLACK, 3.0) # floor
	draw_line(Vector2(-limit_x + 30, 80), Vector2(-limit_x + 30, -limit_y + 30), Color.BLACK, 3.0) # left wall
	draw_line(Vector2(limit_x - 30, 80), Vector2(limit_x - 30, -limit_y + 30), Color.BLACK, 3.0) # right wall
	draw_line(Vector2(-limit_x + 30, -limit_y + 30), Vector2(limit_x - 30, -limit_y + 30), Color.BLACK, 3.0) # ceiling
	
	# Draw platforms
	var plat1 = Rect2(-150, -10, 80, 12)
	draw_rect(plat1, Color.WHITE)
	draw_rect(plat1, Color.BLACK, false, 2.0)
	
	var plat2 = Rect2(100, -40, 80, 12)
	draw_rect(plat2, Color.WHITE)
	draw_rect(plat2, Color.BLACK, false, 2.0)
	
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(0, -180), "BOSS ARENA\nLA REGLA ARTICULADA", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.85, 0.08, 0.52))
