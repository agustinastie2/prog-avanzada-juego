extends Area2D

@export var width: float = 64.0
@export var height: float = 24.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Dynamically set CollisionShape based on width/height
	var shape = CollisionPolygon2D.new()
	var points = PackedVector2Array([
		Vector2(-width/2, 0),
		Vector2(-width/2, -height * 0.7),
		Vector2(width/2, -height * 0.7),
		Vector2(width/2, 0)
	])
	shape.polygon = points
	add_child(shape)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, Vector2.UP * 250)
		body.global_position = GameState.respawn_position

func _draw():
	# Draw spikes hand-drawn style (black lines, simple triangles)
	var num_spikes = int(width / 16.0)
	if num_spikes < 1: num_spikes = 1
	var spike_width = width / num_spikes
	
	for i in range(num_spikes):
		var start_x = -width/2 + i * spike_width
		var end_x = start_x + spike_width
		var mid_x = start_x + spike_width / 2.0
		
		# Draw a triangle outline
		var points = PackedVector2Array([
			Vector2(start_x, 0),
			Vector2(mid_x, -height),
			Vector2(end_x, 0)
		])
		
		# Draw solid white inside first, then black outline
		draw_colored_polygon(points, Color.WHITE)
		draw_polyline(PackedVector2Array([Vector2(start_x, 0), Vector2(mid_x, -height), Vector2(end_x, 0)]), Color.BLACK, 2.0)
