extends CharacterBody2D

@export var max_health: int = 15
var health: int = 15
var speed: float = 160.0
var bounce_direction: Vector2 = Vector2(1, -0.6).normalized()

var state: String = "BOUNCE" # BOUNCE, SHOOT, DEFEATED
var state_timer: float = 4.0
var hover_timer: float = 0.0

var magenta_projectile_scene = preload("res://enemies/magenta_projectile.tscn")
var pigment_pickup_scene = preload("res://levels/pigment_pickup.tscn")

signal boss_hp_changed(current: int, max_hp: int)
signal boss_died

func _ready():
	add_to_group("enemies")
	# Register boss health
	health = max_health
	velocity = bounce_direction * speed

func _physics_process(delta: float):
	if state == "DEFEATED":
		return
		
	state_timer -= delta
	hover_timer += delta * 5.0
	
	if state == "BOUNCE":
		# Move and bounce off walls/floors
		var collision = move_and_collide(velocity * delta)
		if collision:
			# Bounce velocity
			velocity = velocity.bounce(collision.get_normal()).normalized() * speed
			
			# Trigger shockwaves along the floor if hit ground
			if collision.get_normal().y < -0.7:
				spawn_floor_shockwaves(collision.get_position())
				
		if state_timer <= 0:
			state = "SHOOT"
			state_timer = 2.5
			velocity = Vector2.ZERO
	
	elif state == "SHOOT":
		# Hover in place and shoot
		velocity = Vector2(0, sin(hover_timer) * 20.0 * delta)
		move_and_slide()
		
		# Shoot burst
		if Engine.get_physics_frames() % 40 == 0:
			shoot_burst()
			
		if state_timer <= 0:
			state = "BOUNCE"
			state_timer = 5.0
			# Pick direction towards player
			var player = get_tree().get_first_node_in_group("player")
			if player:
				velocity = (player.global_position - global_position).normalized() * speed
			else:
				velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
				
	# Contact damage with player
	for i in range(get_slide_collision_count() if state == "SHOOT" else 0):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			collider.take_damage(1, (collider.global_position - global_position).normalized() * 200.0)
			
	# Update visual drawing
	queue_redraw()

func spawn_floor_shockwaves(pos: Vector2):
	# Spawn two horizontal projectiles moving left and right
	for dir in [Vector2.LEFT, Vector2.RIGHT]:
		var proj = magenta_projectile_scene.instantiate()
		proj.global_position = pos - Vector2(0, 10)
		proj.direction = dir
		proj.speed = 180.0
		get_parent().add_child(proj)

func shoot_burst():
	# Shoot 8 projectiles in a circle
	# 2 of them are magenta (parryable), others are black (non-parryable)
	for i in range(8):
		var angle = i * PI / 4.0
		var dir = Vector2(cos(angle), sin(angle))
		
		var proj = magenta_projectile_scene.instantiate()
		proj.global_position = global_position
		proj.direction = dir
		proj.speed = 180.0
		
		# Make alternate ones non-magenta to mix it up
		if i % 3 != 0:
			proj.is_magenta = false
			
		get_parent().add_child(proj)

func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO):
	if state == "DEFEATED": return
	
	health -= amount
	boss_hp_changed.emit(health, max_health)
	
	# Ink splash
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
	
	# Spawn pigment pickup (blue for dash)
	var pickup = pigment_pickup_scene.instantiate()
	pickup.global_position = global_position
	pickup.pigment_type = "dash"
	pickup.color = Color(0.1, 0.5, 0.9) # Blue
	get_parent().call_deferred("add_child", pickup)
	
	# Big splat explosion
	for i in range(4):
		var splat = Node2D.new()
		splat.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		splat.set_script(load("res://effects/ink_splat.gd"))
		splat.color = Color(0.1, 0.5, 0.9)
		get_parent().add_child(splat)
		
	queue_free()

func _draw():
	# Draw giant math compass tool (Rey Compás)
	# It consists of a top pivot point, two long legs, and a needle/pencil.
	# Pivot is at Vector2(0, -50)
	# Leg 1 ends at Vector2(-20, 0)
	# Leg 2 ends at Vector2(20, 0)
	
	var pivot = Vector2(0, -60)
	var leg_left = Vector2(-24, 0)
	var leg_right = Vector2(24, 0)
	
	# Wobble legs slightly based on time/movement
	if state == "BOUNCE":
		var wobble = sin(hover_timer * 1.5) * 8.0
		leg_left.x += wobble
		leg_right.x += wobble
	elif state == "SHOOT":
		# Open legs wide
		leg_left.x = -36.0
		leg_right.x = 36.0
		
	# Draw background fill (white)
	var poly = PackedVector2Array([pivot, leg_left, leg_right])
	draw_colored_polygon(poly, Color.WHITE)
	
	# Draw legs (thick black lines)
	draw_line(pivot, leg_left, Color.BLACK, 4.0)
	draw_line(pivot, leg_right, Color.BLACK, 4.0)
	draw_line(leg_left, leg_right, Color.BLACK, 2.0) # compass cross-beam
	
	# Draw joint circle at pivot
	draw_circle(pivot, 8.0, Color.BLACK)
	draw_circle(pivot, 4.0, Color.WHITE)
	
	# Draw angry eye in the middle of the joint
	var eye_offset = Vector2.ZERO
	var player = get_tree().get_first_node_in_group("player")
	if player:
		eye_offset = (player.global_position - (global_position + pivot)).normalized() * 2.0
	draw_circle(pivot + eye_offset, 2.0, Color(0.85, 0.08, 0.52) if state == "SHOOT" else Color.BLACK)
