extends Reference

const SOURCE_MANUAL = "manual"
const SOURCE_AUTOMATION = "automation"

var horizontal := 0
var vertical := 0
var jump_pressed := false
var jump_held := false
var source := SOURCE_MANUAL

func is_idle() -> bool:
	return horizontal == 0 and vertical == 0 and not jump_pressed and not jump_held

func copy() -> Reference:
	var result = get_script().new()
	result.horizontal = horizontal
	result.vertical = vertical
	result.jump_pressed = jump_pressed
	result.jump_held = jump_held
	result.source = source
	return result
