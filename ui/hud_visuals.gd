extends Control

var current_health: int = 5
var current_ink: float = 100.0

var boss_active: bool = false
var boss_health: int = 15
var boss_max_health: int = 15
var boss_name: String = ""

func _ready():
	# Connect to GameState signals
	GameState.player_health_changed.connect(_on_health_changed)
	GameState.player_ink_changed.connect(_on_ink_changed)
	
	current_health = GameState.health
	current_ink = GameState.ink
	
	# Connect buttons programmatically
	get_node("../PauseOverlay/CenterContainer/VBoxContainer/ResumeButton").pressed.connect(toggle_pause)
	get_node("../PauseOverlay/CenterContainer/VBoxContainer/RestartButton").pressed.connect(_on_restart_pressed)
	get_node("../PauseOverlay/CenterContainer/VBoxContainer/QuitButton").pressed.connect(_on_quit_pressed)
	
func _on_health_changed(new_health: int):
	current_health = new_health
	queue_redraw()

func _on_ink_changed(new_ink: float):
	current_ink = new_ink
	queue_redraw()

func show_boss_bar(name_str: String, max_hp: int):
	boss_name = name_str
	boss_max_health = max_hp
	boss_health = max_hp
	boss_active = true
	queue_redraw()

func update_boss_health(curr_hp: int):
	boss_health = curr_hp
	if curr_hp <= 0:
		boss_active = false
	queue_redraw()

func hide_boss_bar():
	boss_active = false
	queue_redraw()

func _process(_delta: float):
	# Periodically check for active bosses in the tree to hook signals
	if not boss_active:
		var boss = get_tree().get_first_node_in_group("bosses")
		if boss and is_instance_valid(boss) and not boss.boss_hp_changed.is_connected(update_boss_health):
			boss.boss_hp_changed.connect(update_boss_health)
			boss.boss_died.connect(hide_boss_bar)
			var b_name = "EL REY COMPÁS" if "Compass" in boss.name else "LA REGLA ARTICULADA"
			show_boss_bar(b_name, boss.max_health)
			
	queue_redraw()

func _draw():
	# 1. DRAW PLAYER HEALTH (Top-Left)
	# Draw 5 ink-bottle/heart shapes
	var start_x = 24.0
	var start_y = 28.0
	var spacing = 26.0
	
	for i in range(GameState.max_health):
		var pos = Vector2(start_x + i * spacing, start_y)
		var is_full = i < current_health
		
		# Draw outline (ink droplet)
		# A circle at the bottom, and a sharp top
		var pts = PackedVector2Array([
			pos + Vector2(0, -10),
			pos + Vector2(7, -2),
			pos + Vector2(8, 6),
			pos + Vector2(0, 10),
			pos + Vector2(-8, 6),
			pos + Vector2(-7, -2),
		])
		
		# Draw white fill first
		draw_colored_polygon(pts, Color.WHITE)
		# Draw black outline or filled interior
		if is_full:
			draw_colored_polygon(pts, Color.BLACK)
		else:
			draw_polyline(PackedVector2Array(Array(pts) + [pts[0]]), Color.BLACK, 2.0)
			
	# 2. DRAW INK PROGRESS BAR (Below hearts)
	var bar_pos = Vector2(16.0, 48.0)
	var bar_size = Vector2(130.0, 10.0)
	# Draw white background, black outline
	draw_rect(Rect2(bar_pos, bar_size), Color.WHITE)
	draw_rect(Rect2(bar_pos, bar_size), Color.BLACK, false, 2.0)
	# Draw fill
	var fill_width = (current_ink / GameState.max_ink) * bar_size.x
	if fill_width > 0:
		draw_rect(Rect2(bar_pos + Vector2(2, 2), Vector2(max(0.0, fill_width - 4.0), bar_size.y - 4.0)), Color.BLACK)
		
	# 3. DRAW POWERUPS STATUS (Top-Right)
	# We can draw icons near the top-right corner (1280 - 150)
	var screen_width = get_viewport_rect().size.x
	var icon_x = screen_width - 45.0
	
	# Dash Icon (Blue)
	if GameState.has_dash:
		# Draw blue icon box
		var rect = Rect2(icon_x, 16.0, 30.0, 30.0)
		draw_rect(rect, Color.WHITE)
		draw_rect(rect, Color(0.1, 0.5, 0.9), false, 2.5)
		# Draw small dash arrow symbol
		draw_line(Vector2(icon_x + 8, 31), Vector2(icon_x + 22, 31), Color(0.1, 0.5, 0.9), 2.5)
		draw_line(Vector2(icon_x + 16, 25), Vector2(icon_x + 22, 31), Color(0.1, 0.5, 0.9), 2.5)
		draw_line(Vector2(icon_x + 16, 37), Vector2(icon_x + 22, 31), Color(0.1, 0.5, 0.9), 2.5)
		icon_x -= 40.0
		
	# Double Jump Icon (Yellow)
	if GameState.has_double_jump:
		var rect = Rect2(icon_x, 16.0, 30.0, 30.0)
		draw_rect(rect, Color.WHITE)
		draw_rect(rect, Color(0.9, 0.8, 0.1), false, 2.5)
		# Draw double upward arrow symbol
		draw_line(Vector2(icon_x + 15, 36), Vector2(icon_x + 15, 22), Color(0.9, 0.8, 0.1), 2.5)
		# Top arrow head
		draw_line(Vector2(icon_x + 9, 27), Vector2(icon_x + 15, 21), Color(0.9, 0.8, 0.1), 2.5)
		draw_line(Vector2(icon_x + 21, 27), Vector2(icon_x + 15, 21), Color(0.9, 0.8, 0.1), 2.5)
		# Lower arrow head
		draw_line(Vector2(icon_x + 9, 32), Vector2(icon_x + 15, 26), Color(0.9, 0.8, 0.1), 2.5)
		draw_line(Vector2(icon_x + 21, 32), Vector2(icon_x + 15, 26), Color(0.9, 0.8, 0.1), 2.5)
		
	# 4. DRAW BOSS HP BAR (Bottom-Center)
	if boss_active:
		var view_size = get_viewport_rect().size
		var bbar_width = 400.0
		var bbar_height = 14.0
		var bbar_x = (view_size.x - bbar_width) / 2.0
		var bbar_y = view_size.y - 45.0
		
		# Boss name text drawing
		# Drawing text in _draw() is slightly involved, but we can do it using draw_string,
		# or just let a standard Label node handle the text inside the HUD. Let's use draw_string!
		# Godot 4 has ThemeDB.get_default_font()
		var default_font = ThemeDB.fallback_font
		if default_font:
			draw_string(default_font, Vector2(bbar_x, bbar_y - 8.0), boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.08, 0.52))
			
		# Draw bar frame
		var b_rect = Rect2(bbar_x, bbar_y, bbar_width, bbar_height)
		draw_rect(b_rect, Color.WHITE)
		draw_rect(b_rect, Color(0.85, 0.08, 0.52), false, 2.5)
		
		# Draw fill
		var pct = float(boss_health) / float(boss_max_health)
		var b_fill_width = pct * bbar_width
		if b_fill_width > 0:
			draw_rect(
				Rect2(bbar_x + 2, bbar_y + 2, max(0.0, b_fill_width - 4), bbar_height - 4),
				Color(0.85, 0.08, 0.52)
			)

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P)):
		# Prevent pausing in victory screen or main menu
		if get_tree().current_scene.name != "VictoryScreen":
			toggle_pause()

func toggle_pause():
	var overlay = get_node("../PauseOverlay")
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	overlay.visible = is_paused
	
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		# Hide cursor or leave visible depending on project default
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://levels/hub_nexo.tscn")
