extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var is_magenta: bool = false

func _ready():
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Self-destroy after 3 seconds to avoid leaking memory
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float):
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D):
	# If hits solid ground/wall (Layer 1)
	if body.collision_layer & 1:
		spawn_splat()
		queue_free()
	# If hits enemy (Layer 3)
	elif body.has_method("take_damage"):
		body.take_damage(damage, direction * 150)
		spawn_splat()
		queue_free()

func _on_area_entered(area: Area2D):
	if area.has_method("take_damage"):
		area.take_damage(damage, direction * 150)
		spawn_splat()
		queue_free()

func spawn_splat():
	var splat = Node2D.new()
	splat.global_position = global_position
	splat.set_script(load("res://effects/ink_splat.gd"))
	splat.color = Color(0.85, 0.08, 0.52) if is_magenta else Color.BLACK
	get_parent().add_child(splat)

func _draw():
	if is_magenta:
		# Draw outer glowing ring
		draw_circle(Vector2.ZERO, 9.0, Color(0.85, 0.08, 0.52, 0.4))
		draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.08, 0.52))
	else:
		draw_circle(Vector2.ZERO, 6.0, Color.BLACK)
