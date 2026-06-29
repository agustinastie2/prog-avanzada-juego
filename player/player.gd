extends CharacterBody2D

# Physics parameters
@export var speed: float = 250.0
@export var gravity: float = 900.0
@export var jump_velocity: float = -380.0
@export var wall_slide_speed: float = 80.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2

# State variables
var is_facing_right: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_dash_air: bool = true
var can_double_jump_air: bool = true
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_hurt: bool = false
var hurt_timer: float = 0.0
var invincible_timer: float = 0.0

# Melee parameters
var is_melee_attacking: bool = false
var melee_timer: float = 0.0
var melee_radius: float = 50.0
var melee_visual_radius: float = 0.0

# Pigment charge (from magenta parry)
var is_pigment_charged: bool = false

# Visual squash & stretch
var scale_offset: Vector2 = Vector2.ONE
var last_velocity: Vector2 = Vector2.ZERO

# Projectile scene
var projectile_scene = preload("res://player/projectile.tscn")

@onready var collision_shape = $CollisionShape2D
@onready var melee_area = $MeleeArea
@onready var melee_collision = $MeleeArea/CollisionShape2D

func _ready():
	GameState.respawn_position = global_position
	GameState.player_died.connect(_on_player_died)

func _physics_process(delta: float):
	# Timers
	if coyote_timer > 0: coyote_timer -= delta
	if jump_buffer_timer > 0: jump_buffer_timer -= delta
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_hurt = false
	if invincible_timer > 0: invincible_timer -= delta
	
	# Ink Regeneration
	if not is_melee_attacking and GameState.ink < GameState.max_ink:
		GameState.ink += 15.0 * delta # regenerate ink over time
	
	# Reset states on ground
	if is_on_floor():
		coyote_timer = 0.1
		can_dash_air = true
		can_double_jump_air = true
		# Landing squash
		if last_velocity.y > 100:
			scale_offset = Vector2(1.3, 0.7)
	
	# Dash state
	if is_dashing:
		dash_timer -= delta
		velocity.y = 0
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		queue_redraw()
		return
	
	# Gravity & Wall slide
	var on_wall = is_on_wall() and (Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT))
	if not is_on_floor():
		if on_wall and velocity.y > 0:
			velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
			scale_offset = Vector2(0.8, 1.2)
		else:
			velocity.y += gravity * delta
	
	# Horizontal movement input
	var direction = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction += 1.0
	
	if direction != 0:
		velocity.x = direction * speed
		is_facing_right = direction > 0
		# Walking stretch
		scale_offset = scale_offset.lerp(Vector2(1.15, 0.85), 10 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 12.0 * delta)
		scale_offset = scale_offset.lerp(Vector2.ONE, 10 * delta)
	
	# Wall jump
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		jump_buffer_timer = 0.1
	
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0:
			velocity.y = jump_velocity
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
			scale_offset = Vector2(0.7, 1.3) # Jump stretch
		elif on_wall:
			# Wall jump away
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * speed * 1.2
			velocity.y = jump_velocity * 0.9
			is_facing_right = wall_normal.x > 0
			jump_buffer_timer = 0.0
			scale_offset = Vector2(0.7, 1.3)
		elif can_double_jump_air and GameState.has_double_jump:
			# Double jump
			velocity.y = jump_velocity * 0.95
			can_double_jump_air = false
			jump_buffer_timer = 0.0
			scale_offset = Vector2(0.6, 1.4)
			spawn_ink_splat(global_position + Vector2(0, 10), Color(0.9, 0.8, 0.1)) # Yellow jump particle
	
	# Dash input
	if (Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_C)) and GameState.has_dash and can_dash_air:
		is_dashing = true
		dash_timer = dash_duration
		if not is_on_floor():
			can_dash_air = false
		velocity.x = (1.0 if is_facing_right else -1.0) * dash_speed
		velocity.y = 0
		scale_offset = Vector2(1.5, 0.6)
		spawn_ink_splat(global_position, Color(0.1, 0.5, 0.9)) # Blue dash particle
	
	# Combat inputs
	# Melee
	if (Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_J)) and not is_melee_attacking:
		trigger_melee_attack()
	
	# Ranged Shooting
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_X) or Input.is_key_pressed(KEY_K):
		# Limit shoot rate using a simple timer or check
		if Engine.get_physics_frames() % 10 == 0:
			shoot_ink()

	# Process Melee active state
	if is_melee_attacking:
		melee_timer -= delta
		melee_visual_radius = lerp(melee_visual_radius, melee_radius, 15 * delta)
		# Check overlaps
		for body in melee_area.get_overlapping_bodies():
			if body.has_method("take_damage"):
				var dmg = 2 if is_pigment_charged else 1
				body.take_damage(dmg, (body.global_position - global_position).normalized() * 300)
				is_pigment_charged = false # consume charge
		
		# Also check areas for projectiles
		for area in melee_area.get_overlapping_areas():
			if area.is_in_group("enemy_projectiles"):
				# Parry magenta check
				if area.is_in_group("magenta"):
					trigger_parry_bounce()
				area.queue_free()
				
		if melee_timer <= 0:
			is_melee_attacking = false
			melee_collision.disabled = true
	
	# Save last velocity
	last_velocity = velocity
	
	# Apply movement
	move_and_slide()
	
	# Out of bounds safety net
	if global_position.y > 550.0 or global_position.y < -750.0 or global_position.x < -800.0 or global_position.x > 1200.0:
		take_damage(1, Vector2.ZERO)
		global_position = GameState.respawn_position
	
	# Parry check for floor/landing overlap on magenta hazards/projectiles
	# We can check if we overlap Area2D magenta elements from above
	check_landing_parry()
	
	# Redraw vector visuals
	queue_redraw()

func trigger_melee_attack():
	if GameState.ink < 10.0:
		return
	GameState.ink -= 10.0
	is_melee_attacking = true
	melee_timer = 0.15
	melee_visual_radius = 10.0
	melee_collision.disabled = false
	scale_offset = Vector2(1.2, 1.2)
	spawn_ink_splat(global_position, Color.BLACK)

func shoot_ink():
	if GameState.ink < 5.0:
		return
	GameState.ink -= 5.0
	
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position - Vector2(0, 20)
	
	var dir = Vector2.ZERO
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dir = (get_global_mouse_position() - proj.global_position).normalized()
	else:
		dir = Vector2.RIGHT if is_facing_right else Vector2.LEFT
		
	proj.direction = dir
	proj.damage = 2 if is_pigment_charged else 1
	if is_pigment_charged:
		proj.is_magenta = true
		is_pigment_charged = false
		
	get_parent().add_child(proj)
	scale_offset = Vector2(0.9, 1.1)

func check_landing_parry():
	# Check if overlapping a magenta projectile/hazard while falling
	if velocity.y >= 0:
		# Check for Area2D overlaps that are magenta
		for area in melee_area.get_overlapping_areas():
			if area.is_in_group("magenta"):
				trigger_parry_bounce()
				if area.is_in_group("enemy_projectiles"):
					area.queue_free()
				return

func trigger_parry_bounce():
	velocity.y = jump_velocity * 1.25 # high bounce
	can_double_jump_air = true
	can_dash_air = true
	is_pigment_charged = true
	scale_offset = Vector2(0.6, 1.6)
	# Spawn a nice bright magenta blast/splat
	spawn_ink_splat(global_position + Vector2(0, 10), Color(0.85, 0.08, 0.52))

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO):
	if invincible_timer > 0 or is_dashing or is_hurt:
		return
	
	GameState.health -= amount
	is_hurt = true
	hurt_timer = 0.5
	invincible_timer = 1.0
	velocity = knockback
	scale_offset = Vector2(1.4, 0.6)
	spawn_ink_splat(global_position, Color(0.8, 0.1, 0.1))

func _on_player_died():
	# Fade and respawn
	visible = false
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	GameState.health = GameState.max_health
	GameState.ink = GameState.max_ink
	global_position = GameState.respawn_position
	visible = true
	set_physics_process(true)
	is_hurt = false
	is_pigment_charged = false

func spawn_ink_splat(pos: Vector2, color: Color):
	# Draw particles using transient nodes
	var splat = Node2D.new()
	splat.global_position = pos
	splat.set_script(load("res://effects/ink_splat.gd"))
	splat.color = color
	get_parent().add_child(splat)

func _draw():
	var look_dir = Vector2.RIGHT if is_facing_right else Vector2.LEFT
	
	# Apply scale offset
	draw_set_transform(Vector2(0, -20), 0.0, scale_offset)
	
	# Draw droplet outline
	var radius = 18.0
	# Draw magenta charged outline if charged
	if is_pigment_charged:
		var charge_points = get_droplet_points(radius + 4.0, 12.0)
		draw_colored_polygon(charge_points, Color(0.85, 0.08, 0.52, 0.5))
	
	# Draw main black droplet body
	var points = get_droplet_points(radius, 10.0)
	draw_colored_polygon(points, Color.BLACK)
	
	# Draw eyes
	var eye_y = -4.0
	var eye_offset_x = 6.0
	var eye_radius = 4.0
	var pupil_radius = 1.5
	
	# Left Eye
	draw_circle(Vector2(-eye_offset_x, eye_y), eye_radius, Color.WHITE)
	var pupil_left = Vector2(-eye_offset_x, eye_y) + look_dir * 1.5
	draw_circle(pupil_left, pupil_radius, Color.BLACK)
	
	# Right Eye
	draw_circle(Vector2(eye_offset_x, eye_y), eye_radius, Color.WHITE)
	var pupil_right = Vector2(eye_offset_x, eye_y) + look_dir * 1.5
	draw_circle(pupil_right, pupil_radius, Color.BLACK)
	
	# If hurt, draw Xs instead of normal eyes
	if is_hurt:
		draw_rect(Rect2(-20, -40, 40, 40), Color(0.8, 0.1, 0.1, 0.25))
	
	# Draw Melee Visual Swipe if attacking
	if is_melee_attacking:
		# Reset transform for global coordinate drawing or keep it relative
		draw_set_transform(Vector2(0, -20), 0.0, Vector2.ONE)
		# Draw an arc representing the swipe
		var arc_color = Color(0.85, 0.08, 0.52) if is_pigment_charged else Color.BLACK
		draw_arc(Vector2.ZERO, melee_visual_radius, -PI, PI, 32, arc_color, 4.0)

func get_droplet_points(rad: float, top_pull: float) -> PackedVector2Array:
	var pts = PackedVector2Array()
	var num_pts = 24
	for i in range(num_pts):
		var angle = i * 2.0 * PI / num_pts
		var x = cos(angle) * rad
		var y = sin(angle) * rad
		
		# The top is at angle 1.5 * PI (which has sin = -1)
		# We pull points near the top upwards
		var top_factor = 0.0
		# Measure closeness to 1.5 * PI
		var diff = abs(angle - 1.5 * PI)
		if diff < PI/2:
			top_factor = cos(diff * 2.0) # Peaks at 1 at 1.5*PI
		elif angle < PI/2: # handle wrap around
			var diff2 = abs((angle + 2.0*PI) - 1.5 * PI)
			if diff2 < PI/2:
				top_factor = cos(diff2 * 2.0)
				
		y -= top_factor * top_pull
		pts.append(Vector2(x, y))
	return pts
