extends CharacterBody2D

@export var max_health: int = 15
var health: int = 15
var speed: float = 90.0
var direction: float = 1.0

var state: String = "PATROL" # PATROL, CHARGE, DEFEATED
var state_timer: float = 3.0
var walk_bounce_timer: float = 0.0

# Snake trailing logic
var history: Array = []
var num_segments: int = 5
var segment_spacing: int = 12 # frames between segments

var magenta_projectile_scene = preload("res://enemies/magenta_projectile.tscn")
var pigment_pickup_scene = preload("res://levels/pigment_pickup.tscn")

signal boss_hp_changed(current: int, max_hp: int)
signal boss_died

var wall_ray: RayCast2D

func _ready():
	add_to_group("enemies")
	health = max_health
	
	# Setup RayCast2D for wall detection
	wall_ray = RayCast2D.new()
	wall_ray.target_position = Vector2(22, 0)
	wall_ray.collision_mask = 1 # detects world
	add_child(wall_ray)
	
	# Initialize history with starting position
	for i in range(num_segments * segment_spacing + 5):
		history.append(global_position)

func _physics_process(delta: float):
	if state == "DEFEATED":
		return
		
	state_timer -= delta
	walk_bounce_timer += delta * 10.0
	
	# Gravity on head (standard character gravity application)
	velocity.y += 800.0 * delta
		
	# Update wall ray direction
	wall_ray.target_position = Vector2(direction * 22.0, 0)
	
	# State machine
	if state == "PATROL":
		velocity.x = direction * speed
		if wall_ray.is_colliding():
			direction *= -1.0
			state_timer = randf_range(1.5, 3.0)
			
		if state_timer <= 0:
			state = "CHARGE"
			state_timer = 2.0 # charge duration
			direction = 1.0 if (global_position.x < get_player_x()) else -1.0
			speed = 220.0
			
	elif state == "CHARGE":
		# Dash forward!
		velocity.x = direction * speed
		
		# Shoot magenta projectile straight up from segments occasionally during charge
		if Engine.get_physics_frames() % 30 == 0:
			shoot_upward_magenta()
			
		if state_timer <= 0 or wall_ray.is_colliding():
			state = "PATROL"
			state_timer = randf_range(2.0, 4.0)
			speed = 90.0
			direction *= -1.0 # turn around after charge
			
	# Move head
	move_and_slide()
	
	# Update position history for trailing body
	history.push_front(global_position)
	if history.size() > num_segments * segment_spacing + 10:
		history.pop_back()
		
	# Check contact with player on head
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			collider.take_damage(1, (collider.global_position - global_position).normalized() * 200.0)
			
	# Manual collision checks for trailing body segments with the player
	check_segment_player_collision()
	
	queue_redraw()

func get_player_x() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.global_position.x
	return global_position.x

func shoot_upward_magenta():
	# Find a random segment position to shoot from
	var seg_index = randi_range(1, num_segments)
	var seg_pos = get_segment_pos(seg_index)
	
	var proj = magenta_projectile_scene.instantiate()
	proj.global_position = seg_pos - Vector2(0, 10)
	proj.direction = Vector2.UP
	proj.speed = 200.0
	get_parent().add_child(proj)

func get_segment_pos(idx: int) -> Vector2:
	var history_index = idx * segment_spacing
	if history_index < history.size():
		return history[history_index]
	return global_position

func check_segment_player_collision():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
		
	# Check distance to each segment
	for i in range(1, num_segments + 1):
		var seg_pos = get_segment_pos(i)
		# Each segment is roughly a 20x20 box
		if player.global_position.distance_to(seg_pos - Vector2(0, 10)) < 24.0:
			player.take_damage(1, (player.global_position - seg_pos).normalized() * 200.0)
			break

func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO):
	if state == "DEFEATED": return
	
	health -= amount
	boss_hp_changed.emit(health, max_health)
	
	# Splash
	var splat = Node2D.new()
	splat.global_position = global_position
	splat.set_script(load("res://effects/ink_splat.gd"))
	splat.color = Color.BLACK
	get_parent().add_child(splat)
	
	if health <= 0:
		die()

func die():
	state = "DEFEATED"
	boss_died.emit()
	
	# Spawn pigment pickup (yellow for double jump)
	var pickup = pigment_pickup_scene.instantiate()
	pickup.global_position = global_position
	pickup.pigment_type = "double_jump"
	pickup.color = Color(0.9, 0.8, 0.1) # Yellow
	get_parent().call_deferred("add_child", pickup)
	
	# Big splat explosion
	for i in range(4):
		var splat = Node2D.new()
		splat.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		splat.set_script(load("res://effects/ink_splat.gd"))
		splat.color = Color(0.9, 0.8, 0.1)
		get_parent().add_child(splat)
		
	queue_free()

func _draw():
	# Draw Head
	draw_set_transform(Vector2(0, -12), 0.0, Vector2.ONE)
	
	# We draw the head as a large block shape or rectangular head with angry red/magenta eyes
	var head_color = Color(0.85, 0.08, 0.52) if state == "CHARGE" else Color.BLACK
	
	# Head outline & fill
	var head_poly = PackedVector2Array([
		Vector2(-14, -12),
		Vector2(14, -12),
		Vector2(14, 12),
		Vector2(-14, 12)
	])
	draw_colored_polygon(head_poly, Color.WHITE)
	draw_rect(Rect2(-14, -12, 28, 24), head_color, false, 3.0)
	
	# Eyes looking in direction
	var eye_x = direction * 5.0
	draw_circle(Vector2(eye_x, -3), 4.0, Color.WHITE)
	draw_circle(Vector2(eye_x, -3) + Vector2(direction * 1.5, 0), 1.5, head_color)
	
	# Reset transform for body drawing (drawn in global space or relative offset)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# Draw body segments
	for i in range(1, num_segments + 1):
		var seg_pos = get_segment_pos(i)
		# Convert to local position relative to head
		var local_seg_pos = seg_pos - global_position
		
		# Animate segment size / shape slightly (e.g. trailing boxes)
		var width_w = 20.0 - i * 1.5
		var height_h = 16.0 - i * 1.0
		
		# Segment outline & fill
		var seg_rect = Rect2(local_seg_pos.x - width_w / 2.0, local_seg_pos.y - height_h, width_w, height_h)
		draw_rect(seg_rect, Color.WHITE)
		draw_rect(seg_rect, Color.BLACK, false, 2.5)
		
		# Draw horizontal rule marks on the body (it's La Regla / The Ruler!)
		# Small black dash lines to look like millimeter notches!
		var y_top = local_seg_pos.y - height_h
		var step = width_w / 4.0
		for j in range(5):
			var x_mark = local_seg_pos.x - width_w / 2.0 + j * step
			draw_line(Vector2(x_mark, y_top), Vector2(x_mark, y_top + 4.0), Color.BLACK, 1.2)
