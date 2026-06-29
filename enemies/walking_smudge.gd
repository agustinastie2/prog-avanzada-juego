extends CharacterBody2D

@export var speed: float = 60.0
@export var gravity: float = 800.0

var health: int = 2
var direction: float = 1.0
var bounce_timer: float = 0.0

# Raycasts for edge/wall detection
var wall_ray: RayCast2D
var floor_ray: RayCast2D

func _ready():
	add_to_group("enemies")
	
	# Setup RayCasts programmatically
	wall_ray = RayCast2D.new()
	wall_ray.target_position = Vector2(20, 0)
	wall_ray.collision_mask = 1 # detects world
	add_child(wall_ray)
	
	floor_ray = RayCast2D.new()
	floor_ray.position = Vector2(16, 0)
	floor_ray.target_position = Vector2(0, 24)
	floor_ray.collision_mask = 1 # detects world
	add_child(floor_ray)

func _physics_process(delta: float):
	bounce_timer += delta * 12.0
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
	# Ledge & wall detection
	wall_ray.target_position = Vector2(direction * 20.0, 0)
	floor_ray.position = Vector2(direction * 16.0, 0)
	
	# Small delay to ensure physics state updates
	if is_on_floor():
		var wall_hit = wall_ray.is_colliding()
		var floor_hit = floor_ray.is_colliding()
		
		# If hit wall or no floor ahead, reverse
		if wall_hit or not floor_hit:
			direction *= -1.0
			
	velocity.x = direction * speed
	
	move_and_slide()
	
	# Damage player on contact
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			var kb_dir = (collider.global_position - global_position).normalized()
			if kb_dir == Vector2.ZERO: kb_dir = Vector2.UP
			collider.take_damage(1, kb_dir * 250.0 + Vector2.UP * 100.0)
			
	queue_redraw()

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO):
	health -= amount
	velocity += knockback * 0.5
	
	# Spawn black splat
	var splat = Node2D.new()
	splat.global_position = global_position
	splat.set_script(load("res://effects/ink_splat.gd"))
	splat.color = Color.BLACK
	get_parent().add_child(splat)
	
	if health <= 0:
		queue_free()

func _draw():
	# Draw little patrolling droplet
	var walk_bounce = abs(sin(bounce_timer)) * 4.0
	
	# Scale matrix for squash & stretch
	var squish = Vector2(1.1, 0.9) if walk_bounce > 2.0 else Vector2(0.9, 1.1)
	draw_set_transform(Vector2(0, -14 + walk_bounce), 0.0, squish)
	
	# Body
	var points = get_droplet_points(14.0, 8.0)
	draw_colored_polygon(points, Color.BLACK)
	
	# Tiny eyes looking in movement direction
	var eye_x = direction * 4.0
	draw_circle(Vector2(eye_x, -2), 3.0, Color.WHITE)
	draw_circle(Vector2(eye_x, -2) + Vector2(direction * 1.0, 0), 1.0, Color.BLACK)

func get_droplet_points(rad: float, top_pull: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var num_pts = 16
	for i in range(num_pts):
		var angle = i * 2.0 * PI / num_pts
		var x = cos(angle) * rad
		var y = sin(angle) * rad
		var top_factor = 0.0
		var diff = abs(angle - 1.5 * PI)
		if diff < PI/2:
			top_factor = cos(diff * 2.0)
		y -= top_factor * top_pull
		pts.append(Vector2(x, y))
	return pts
