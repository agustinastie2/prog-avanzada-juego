extends Node

signal player_health_changed(new_health: int)
signal player_ink_changed(new_ink: float)
signal ability_unlocked(ability_name: String)
signal boss_defeated(boss_name: String)
signal player_died

var max_health: int = 3
var health: int = 3:
	set(value):
		health = clamp(value, 0, max_health)
		player_health_changed.emit(health)
		if health <= 0:
			player_died.emit()

var max_ink: float = 100.0
var ink: float = 100.0:
	set(value):
		ink = clamp(value, 0.0, max_ink)
		player_ink_changed.emit(ink)

# Unlocks
var has_dash: bool = false:
	set(value):
		has_dash = value
		if value:
			ability_unlocked.emit("dash")

var has_double_jump: bool = false:
	set(value):
		has_double_jump = value
		if value:
			ability_unlocked.emit("double_jump")

# Bosses
var boss_compass_defeated: bool = false:
	set(value):
		boss_compass_defeated = value
		if value:
			boss_defeated.emit("compass_king")

var boss_ruler_defeated: bool = false:
	set(value):
		boss_ruler_defeated = value
		if value:
			boss_defeated.emit("articulated_ruler")

var respawn_position: Vector2 = Vector2.ZERO

func reset_game():
	health = max_health
	ink = max_ink
	has_dash = false
	has_double_jump = false
	boss_compass_defeated = false
	boss_ruler_defeated = false
