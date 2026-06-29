extends Area2D

@export var pigment_type: String = "dash" # "dash" or "double_jump"
@export var color: Color = Color(0.1, 0.5, 0.9)

var bob_timer: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	bob_timer = randf_range(0, PI * 2)

func _process(delta: float):
	bob_timer += delta * 3.0
	position.y += sin(bob_timer) * 0.2
	queue_redraw()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if pigment_type == "dash":
			GameState.has_dash = true
			spawn_text("DASH UNLOCKED (Shift / C)")
		elif pigment_type == "double_jump":
			GameState.has_double_jump = true
			spawn_text("DOUBLE JUMP UNLOCKED (Space in air)")
			
		# Spawns a nice big ink explosion
		for i in range(12):
			var splat = Node2D.new()
			splat.global_position = global_position
			splat.set_script(load("res://effects/ink_splat.gd"))
			splat.color = color
			get_parent().add_child(splat)
			
		queue_free()

func spawn_text(text: String):
	# Create a floating label
	var label = Label.new()
	label.text = text
	# Center alignment
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = global_position - Vector2(100, 40)
	label.modulate = color
	get_parent().add_child(label)
	
	# Tween to animate upward and fadeout
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", label.global_position - Vector2(0, 50), 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)

func _draw():
	# Draw glowing pickup orb
	# Outer glow
	draw_circle(Vector2.ZERO, 18.0, Color(color.r, color.g, color.b, 0.3))
	# Core
	draw_circle(Vector2.ZERO, 10.0, color)
	# Center star/symbol
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
