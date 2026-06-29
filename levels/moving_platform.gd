extends AnimatableBody2D

@export var offset: Vector2 = Vector2(150, 0)
@export var duration: float = 3.0
@export var width: float = 80.0
@export var height: float = 16.0

var start_pos: Vector2
var timer: float = 0.0

func _ready():
	start_pos = global_position
	# Create collision shape programmatically
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, height)
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float):
	timer += delta
	var progress = sin(timer * (2.0 * PI / duration))
	global_position = start_pos + offset * progress
	queue_redraw()

func _draw():
	# Draw outlined white block
	var rect = Rect2(-width/2.0, -height/2.0, width, height)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-width/2.0, -height/2.0),
		Vector2(width/2.0, -height/2.0),
		Vector2(width/2.0, height/2.0),
		Vector2(-width/2.0, height/2.0)
	]), Color.WHITE)
	draw_rect(rect, Color.BLACK, false, 2.0)
	
	# Draw small horizontal notches
	var spacing = 16.0
	var count = int(width / spacing)
	for i in range(count):
		var x = -width/2.0 + (i + 0.5) * spacing
		draw_line(Vector2(x, -height/2.0), Vector2(x, -height/2.0 + 4.0), Color.BLACK, 1.2)
