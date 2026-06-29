extends Area2D

@export var width: float = 80.0
@export var height: float = 300.0
@export var wind_force: float = 1400.0

var wind_lines: Array = []

func _ready():
	# Configure CollisionShape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	collision.shape = shape
	# Place collision relative to bottom-center of the area
	collision.position = Vector2(0, -height / 2.0)
	add_child(collision)
	
	# Initialize visual wind lines
	for i in range(5):
		wind_lines.append({
			"x": randf_range(-width/2.0, width/2.0),
			"y": randf_range(-height, 0.0),
			"length": randf_range(15.0, 40.0),
			"speed": randf_range(150.0, 300.0)
		})

func _physics_process(delta: float):
	# Apply force to player
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			body.velocity.y = move_toward(body.velocity.y, -450.0, wind_force * delta)
			# Reset air abilities so player can double jump/dash after leaving the wind
			if body.has_method("reset_air_abilities"):
				body.can_dash_air = true
				body.can_double_jump_air = true
			else:
				body.can_dash_air = true
				body.can_double_jump_air = true
				
	# Move visual lines upward
	for line in wind_lines:
		line.y -= line.speed * delta
		if line.y < -height:
			line.y = 0
			line.x = randf_range(-width/2.0, width/2.0)
			line.length = randf_range(15.0, 40.0)
			
	queue_redraw()

func _draw():
	# Draw thin black/gray dotted lines rising up
	for line in wind_lines:
		draw_line(
			Vector2(line.x, line.y), 
			Vector2(line.x, line.y + line.length), 
			Color(0.2, 0.6, 0.9, 0.5), # light blue/grey wind color
			1.5
		)
