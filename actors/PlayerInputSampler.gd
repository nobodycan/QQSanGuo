extends Reference

const PlayerIntent = preload("res://actors/PlayerIntent.gd")

func sample_manual() -> Reference:
	var intent = PlayerIntent.new()
	intent.horizontal = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	intent.vertical = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
	intent.jump_pressed = Input.is_action_just_pressed("jump")
	intent.jump_held = Input.is_action_pressed("jump")
	return intent

func resolve(manual: Reference, automation: Reference) -> Reference:
	if manual != null and not manual.is_idle():
		return manual
	if automation != null:
		return automation.copy()
	return PlayerIntent.new()
