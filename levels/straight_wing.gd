extends Node2D

@onready var exit_door = $ExitDoor
@onready var boss_door = $BossDoor
@onready var player = $Player

func _ready():
	exit_door.body_entered.connect(_on_exit_door_entered)
	boss_door.body_entered.connect(_on_boss_door_entered)
	
	# Set initial respawn checkpoint
	GameState.respawn_position = Vector2(-400, 40)

func _on_exit_door_entered(body: Node2D):
	if body.is_in_group("player"):
		exit_door.get_node("CollisionShape2D").set_deferred("disabled", true)
		get_tree().call_deferred("change_scene_to_file", "res://levels/hub_nexo.tscn")

func _on_boss_door_entered(body: Node2D):
	if body.is_in_group("player"):
		boss_door.get_node("CollisionShape2D").set_deferred("disabled", true)
		get_tree().call_deferred("change_scene_to_file", "res://levels/boss_compass_level.tscn")

func _draw():
	# Draw level visual lines and aesthetics
	var limit_x = 1000.0
	var limit_y = 300.0
	draw_rect(Rect2(-540, -limit_y, limit_x + 540, limit_y * 2.0), Color(0.96, 0.96, 0.96), true)
	
	# Draw solid ground/walls
	draw_line(Vector2(-500, 80), Vector2(-200, 80), Color.BLACK, 3.0)
	draw_line(Vector2(-200, 80), Vector2(-200, 220), Color.BLACK, 3.0)
	draw_line(Vector2(-200, 220), Vector2(370, 220), Color.BLACK, 3.0)
	draw_line(Vector2(370, 220), Vector2(370, 80), Color.BLACK, 3.0)
	draw_line(Vector2(370, 80), Vector2(850, 80), Color.BLACK, 3.0)
	draw_line(Vector2(-500, 80), Vector2(-500, -300), Color.BLACK, 3.0)
	draw_line(Vector2(850, 80), Vector2(850, -300), Color.BLACK, 3.0)
	draw_line(Vector2(-500, -300), Vector2(850, -300), Color.BLACK, 3.0)
	
	# Draw background text guides
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(-400, -100), "SECTOR TECNOLÓGICO", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.BLACK)
		draw_string(font, Vector2(-400, -70), "Dash powerup ahead. Watch for spikes!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.4, 0.4))
		
		# Draw Hub return arrow
		draw_string(font, Vector2(-480, 0), "<-- EXIT TO HUB", HORIZONTAL_ALIGNMENT_CENTER, 100, 11, Color.BLACK)
		
		# Boss Arena text
		draw_string(font, Vector2(650, -100), "TO BOSS ARENA\nEL REY COMPÁS -->", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color(0.85, 0.08, 0.52))
