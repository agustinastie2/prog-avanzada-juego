extends CharacterBody2D

@export var detect_radius: float = 280.0
@export var speed: float = 55.0
@export var attack_cooldown: float = 2.4

var health: int = 2
var player: Node2D = null
var shoot_timer: float = 0.0
var hover_timer: float = 0.0
var flash_timer: float = 0.0

var magenta_projectile_scene = preload("res://enemies/magenta_projectile.tscn")

func _ready():
	add_to_group("enemies")
	# Start cooldown with a bit of randomness so they don't sync up perfectly
	shoot_timer = randf_range(0.5, attack_cooldown)
	hover_timer = randf_range(0, PI * 2)

func _physics_process(delta: float):
	hover_timer += delta * 4.0
	shoot_timer -= delta
	
	if flash_timer > 0:
		flash_timer -= delta
		
	# Find player if not cached
	if not player or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	# Hover movement
	var hover_offset = Vector2(0, sin(hover_timer) * 12.0 * delta)
	
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= detect_radius:
			# Move towards player
			var dir = (player.global_position - global_position).normalized()
			velocity = dir * speed
			
			# Shooting behavior
			if shoot_timer <= 0:
				shoot_projectile()
				shoot_timer = attack_cooldown
				flash_timer = 0.35 # flash before/during shoot
		else:
			# Return/stay in place
			velocity = velocity.move_toward(Vector2.ZERO, speed * 2.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 2.0 * delta)
		
	velocity += hover_offset
	move_and_slide()
	
	# Damage player on contact
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			var kb_dir = (collider.global_position - global_position).normalized()
			if kb_dir == Vector2.ZERO: kb_dir = Vector2.UP
			collider.take_damage(1, kb_dir * 200.0)
			
	queue_redraw()

func shoot_projectile():
	if not player or not is_instance_valid(player):
		return
	var proj = magenta_projectile_scene.instantiate()
	# Spawn slightly lower towards player
	proj.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	proj.direction = dir
	get_parent().add_child(proj)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO):
	health -= amount
	velocity += knockback * 0.5
	
	# Spawn magenta ink splat (flying spark leaves magenta pigment ink on damage/death)
	var splat = Node2D.new()
	splat.global_position = global_position
	splat.set_script(load("res://effects/ink_splat.gd"))
	splat.color = Color(0.85, 0.08, 0.52)
	get_parent().add_child(splat)
	
	if health <= 0:
		queue_free()

func _draw():
	# Draw star/diamond shape
	# Outline is black; flashes magenta when charging attack
	var outline_color = Color(0.85, 0.08, 0.52) if (flash_timer > 0 or shoot_timer < 0.4) else Color.BLACK
	
	var r_outer = 16.0
	var r_inner = 7.0
	var points = PackedVector2Array()
	
	# Draw an 8-point star or 4-point diamond star
	for i in range(8):
		var angle = i * PI / 4.0
		var r = r_outer if i % 2 == 0 else r_inner
		points.append(Vector2(cos(angle), sin(angle)) * r)
		
	# Draw solid white background
	draw_colored_polygon(points, Color.WHITE)
	# Draw lines
	var line_points = Array(points)
	line_points.append(points[0]) # close loop
	draw_polyline(PackedVector2Array(line_points), outline_color, 2.5)
	
	# Draw central eye
	draw_circle(Vector2.ZERO, 3.0, outline_color)
