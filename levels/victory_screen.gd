extends CanvasLayer

func _ready():
	# Configure mouse mode so the player can click buttons
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Connect buttons programmatically
	$Control/CenterContainer/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Control/CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_restart_pressed():
	GameState.reset_game()
	get_tree().change_scene_to_file("res://levels/hub_nexo.tscn")

func _on_quit_pressed():
	get_tree().quit()
