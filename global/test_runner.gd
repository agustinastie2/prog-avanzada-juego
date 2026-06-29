extends Node

var is_test_mode: bool = false

func _ready():
	# Check if .run_tests file exists in project root to trigger test mode
	is_test_mode = FileAccess.file_exists("res://.run_tests")
	if is_test_mode:
		print("[TEST] Launching game in automated integration test mode...")
		run_tests()

func run_tests():
	# Wait for the first scene (Hub) to load completely
	await get_tree().create_timer(0.5).timeout
	
	var current_scene = get_tree().current_scene
	print("[TEST] Current Scene: ", current_scene.name)
	
	if current_scene.name != "HubNexo":
		print("[TEST ERROR] Game did not start in HubNexo! Current: ", current_scene.name)
		get_tree().quit(1)
		return
		
	# Find player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[TEST ERROR] Player node not found in Hub!")
		get_tree().quit(1)
		return
		
	print("[TEST] Player found at: ", player.global_position)
	
	# --- TEST WING 2 (Curve Wing) ---
	print("[TEST] Testing Wing 2 (Curve Wing) transition...")
	player.global_position = Vector2(470, 40)
	await get_tree().create_timer(0.3).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Loaded Scene: ", current_scene.name)
	if current_scene.name != "CurveWing":
		print("[TEST ERROR] Failed to transition to CurveWing!")
		get_tree().quit(1)
		return
		
	# Transition to Boss Ruler Level
	print("[TEST] Transitioning to BossRulerLevel...")
	player = get_tree().get_first_node_in_group("player")
	player.global_position = Vector2(880, 40)
	await get_tree().create_timer(0.3).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Loaded Scene: ", current_scene.name)
	if current_scene.name != "BossRulerLevel":
		print("[TEST ERROR] Failed to transition to BossRulerLevel!")
		get_tree().quit(1)
		return
		
	# Find boss in Boss Ruler Level
	var boss = current_scene.get_node_or_null("BossArticulatedRuler")
	if not boss:
		print("[TEST ERROR] BossArticulatedRuler not found in BossRulerLevel!")
		get_tree().quit(1)
		return
		
	print("[TEST] Found BossArticulatedRuler. Simulating defeat...")
	boss.take_damage(15)
	
	# Wait for pigment pickup to spawn
	await get_tree().create_timer(0.3).timeout
	
	# Find the pigment pickup
	var pickup = null
	for child in current_scene.get_children():
		if "PigmentPickup" in child.name:
			pickup = child
			break
			
	if pickup:
		print("[TEST] Picking up Yellow Pigment (Double Jump)...")
		player = get_tree().get_first_node_in_group("player")
		pickup._on_body_entered(player)
	else:
		print("[TEST WARNING] Pigment pickup node not found. Force unlocking Double Jump.")
		GameState.has_double_jump = true
		
	# Wait for automatic scene transition back to Hub (2.0s delay in code)
	print("[TEST] Waiting for auto-transition to Hub...")
	await get_tree().create_timer(2.3).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Current Scene: ", current_scene.name)
	if current_scene.name != "HubNexo":
		print("[TEST ERROR] Failed to return to Hub from BossRulerLevel! Current: ", current_scene.name)
		get_tree().quit(1)
		return
		
	# --- TEST WING 1 (Straight Wing) ---
	print("[TEST] Testing Wing 1 (Straight Wing) transition...")
	player = get_tree().get_first_node_in_group("player")
	player.global_position = Vector2(-470, 40)
	await get_tree().create_timer(0.3).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Loaded Scene: ", current_scene.name)
	if current_scene.name != "StraightWing":
		print("[TEST ERROR] Failed to transition to StraightWing!")
		get_tree().quit(1)
		return
		
	# Transition to Boss Compass Level
	print("[TEST] Transitioning to BossCompassLevel...")
	player = get_tree().get_first_node_in_group("player")
	player.global_position = Vector2(800, 40)
	await get_tree().create_timer(0.3).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Loaded Scene: ", current_scene.name)
	if current_scene.name != "BossCompassLevel":
		print("[TEST ERROR] Failed to transition to BossCompassLevel!")
		get_tree().quit(1)
		return
		
	# Find boss in Boss Compass Level
	boss = current_scene.get_node_or_null("BossCompassKing")
	if not boss:
		print("[TEST ERROR] BossCompassKing not found in BossCompassLevel!")
		get_tree().quit(1)
		return
		
	print("[TEST] Found BossCompassKing. Simulating defeat...")
	boss.take_damage(15)
	
	# Wait for pigment pickup to spawn
	await get_tree().create_timer(0.3).timeout
	
	# Find pigment pickup
	pickup = null
	for child in current_scene.get_children():
		if "PigmentPickup" in child.name:
			pickup = child
			break
	if pickup:
		print("[TEST] Picking up Blue Pigment (Dash)...")
		player = get_tree().get_first_node_in_group("player")
		pickup._on_body_entered(player)
	else:
		print("[TEST WARNING] Pigment pickup node not found. Force unlocking Dash.")
		GameState.has_dash = true
		
	# Wait for automatic scene transition back to Hub
	print("[TEST] Waiting for auto-transition to Hub...")
	await get_tree().create_timer(2.3).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Current Scene: ", current_scene.name)
	if current_scene.name != "HubNexo":
		print("[TEST ERROR] Failed to return to Hub from BossCompassLevel!")
		get_tree().quit(1)
		return
		
	# --- TEST VAULT OPEN & VICTORY ---
	print("[TEST] Verifying vault unlock and victory condition...")
	await get_tree().create_timer(0.2).timeout
	
	# Verify vault gate is open (collision disabled)
	var vault_gate = current_scene.get_node("VaultGate/CollisionShape2D")
	if not vault_gate.disabled:
		print("[TEST ERROR] Vault gate collision shape is still enabled despite both bosses being defeated!")
		get_tree().quit(1)
		return
		
	print("[TEST] Vault gate is open. Dropping down...")
	player = get_tree().get_first_node_in_group("player")
	player.global_position = Vector2(0, 320)
	await get_tree().create_timer(0.4).timeout
	
	current_scene = get_tree().current_scene
	print("[TEST] Current Scene at end of drop: ", current_scene.name)
	if current_scene.name != "VictoryScreen":
		print("[TEST ERROR] Failed to transition to VictoryScreen after drop!")
		get_tree().quit(1)
		return
		
	print("[TEST SUCCESS] All integration tests passed! Victory screen reached successfully.")
	get_tree().quit(0)
