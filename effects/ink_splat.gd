extends Node2D

var color: Color = Color.BLACK
var particles: Array = []
var lifetime: float = 0.4
var timer: float = 0.0

func _ready():
	# Generate 8 random splat particles
	for i in range(8):
		var angle = randf_range(0, 2.0 * PI)
		var speed = randf_range(50, 180)
		var p_vel = Vector2(cos(angle), sin(angle)) * speed
		var p_size = randf_range(3.0, 7.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": p_vel,
			"size": p_size
		})

func _process(delta: float):
	timer += delta
	if timer >= lifetime:
		queue_free()
		return
		
	# Update particles
	for p in particles:
		p.pos += p.vel * delta
		p.vel.y += 200.0 * delta # gravity on particles
		p.size = max(0.0, p.size - delta * 10.0)
		
	queue_redraw()

func _draw():
	var alpha = 1.0 - (timer / lifetime)
	var draw_color = Color(color.r, color.g, color.b, alpha)
	for p in particles:
		if p.size > 0:
			draw_circle(p.pos, p.size, draw_color)
