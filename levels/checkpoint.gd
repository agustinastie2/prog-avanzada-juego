extends Area2D

var active: bool = false
@export var active_color: Color = Color.BLACK

func _ready():
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not active:
		# Deactivate all other checkpoints in the level
		get_tree().call_group("checkpoints", "deactivate")
		
		# Activate this one
		active = true
		GameState.respawn_position = global_position - Vector2(0, 10) # safety offset above ground
		
		# Spawn small ink splat
		var splat = Node2D.new()
		splat.global_position = global_position - Vector2(0, 20)
		splat.set_script(load("res://effects/ink_splat.gd"))
		splat.color = active_color
		get_parent().add_child(splat)
		
		queue_redraw()

func deactivate():
	if active:
		active = false
		queue_redraw()

func _draw():
	# Draw flagpole
	draw_line(Vector2(0, 0), Vector2(0, -36), Color.BLACK, 2.0)
	
	# Draw flag triangle pointing to the right
	var flag_pts = PackedVector2Array([
		Vector2(0, -36),
		Vector2(16, -28),
		Vector2(0, -20)
	])
	
	if active:
		draw_colored_polygon(flag_pts, active_color)
	else:
		draw_colored_polygon(flag_pts, Color.WHITE)
		draw_polyline(PackedVector2Array(Array(flag_pts) + [flag_pts[0]]), Color.BLACK, 1.5)
		
	# Draw a tiny base circle at floor
	draw_circle(Vector2.ZERO, 4.0, Color.BLACK)
