extends Area2D

@export var speed: float = 230.0
var direction: Vector2 = Vector2.ZERO
var is_magenta: bool = true

func _ready():
	add_to_group("enemy_projectiles")
	if is_magenta:
		add_to_group("magenta")
	body_entered.connect(_on_body_entered)
	
	# Self destroy
	await get_tree().create_timer(4.0).timeout
	queue_free()

func _physics_process(delta: float):
	global_position += direction * speed * delta
	queue_redraw()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		var kb = (body.global_position - global_position).normalized()
		if kb == Vector2.ZERO: kb = Vector2.UP
		body.take_damage(1, kb * 200.0)
		queue_free()

func _draw():
	if is_magenta:
		# Magenta pigment bullet
		draw_circle(Vector2.ZERO, 10.0, Color(0.85, 0.08, 0.52, 0.35))
		draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.08, 0.52))
		draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	else:
		# Normal black ink bullet
		draw_circle(Vector2.ZERO, 6.0, Color.BLACK)
