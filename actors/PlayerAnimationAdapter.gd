extends Reference

func movement_animation(movement: Dictionary, on_floor: bool) -> String:
	if movement.get("climbing", false):
		return "clim"
	if movement.get("jump", false) or not on_floor:
		return "jump"
	if movement.get("direction", 0) != 0:
		return "run"
	return "idle"
