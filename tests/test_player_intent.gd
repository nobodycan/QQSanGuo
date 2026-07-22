extends SceneTree

const PlayerIntent = preload("res://actors/PlayerIntent.gd")
const PlayerInputSampler = preload("res://actors/PlayerInputSampler.gd")
const PlayerMovementModel = preload("res://actors/PlayerMovementModel.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var sampler = PlayerInputSampler.new()
	var model = PlayerMovementModel.new()
	var manual = PlayerIntent.new()
	var automation = PlayerIntent.new()
	automation.horizontal = 1
	automation.source = PlayerIntent.SOURCE_AUTOMATION
	test.expect(sampler.resolve(manual, automation).source == PlayerIntent.SOURCE_AUTOMATION, "automation intent drives idle manual input")
	manual.jump_pressed = true
	test.expect(sampler.resolve(manual, automation).source == PlayerIntent.SOURCE_MANUAL, "manual intent interrupts automation")
	var walking = model.next_state(automation, false, false)
	test.expect(walking.direction == 1 and not walking.climbing and not walking.jump, "walking intent produces horizontal movement")
	var climbing = model.next_state(manual, true, false)
	test.expect(climbing.jump and not climbing.climbing, "jump exits climbing state")
	var locked = model.next_state(automation, false, true)
	test.expect(locked.direction == 0 and not locked.jump, "movement lock suppresses intent")
	test.finish(self, "player_intent")
