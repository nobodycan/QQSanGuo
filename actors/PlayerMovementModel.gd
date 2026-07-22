extends Reference

const PlayerIntent = preload("res://actors/PlayerIntent.gd")

func next_state(intent: Reference, climbing: bool, movement_locked: bool) -> Dictionary:
	var result = {
		"direction": 0,
		"climbing": climbing,
		"climb_direction": 0,
		"jump": false
	}
	if movement_locked or intent == null:
		return result
	result.direction = clamp(intent.horizontal, -1, 1)
	if climbing:
		result.climb_direction = clamp(intent.vertical, -1, 1)
		if intent.jump_pressed:
			result.climbing = false
			result.jump = true
	else:
		result.jump = intent.jump_pressed
	return result
