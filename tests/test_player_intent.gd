extends SceneTree

const PlayerIntent = preload("res://actors/PlayerIntent.gd")
const PlayerInputSampler = preload("res://actors/PlayerInputSampler.gd")
const PlayerMovementModel = preload("res://actors/PlayerMovementModel.gd")
const PlayerAnimationAdapter = preload("res://actors/PlayerAnimationAdapter.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var sampler = PlayerInputSampler.new()
	var model = PlayerMovementModel.new()
	var animations = PlayerAnimationAdapter.new()
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
	test.expect(animations.movement_animation(walking, true) == "run", "walking selects run animation")
	test.expect(animations.movement_animation(climbing, true) == "jump", "climb jump selects jump animation")
	test.expect(animations.movement_animation(locked, true) == "idle", "locked idle state selects idle animation")
	var is_climbing = false
	for frame in range(600):
		var intent = PlayerIntent.new()
		intent.horizontal = -1 if frame % 4 == 0 else 1 if frame % 4 == 1 else 0
		intent.vertical = -1 if frame % 4 == 2 else 1 if frame % 4 == 3 else 0
		intent.jump_pressed = frame % 17 == 0
		var locked_frame = frame % 29 == 0
		var next = model.next_state(intent, is_climbing, locked_frame)
		if not locked_frame:
			is_climbing = next.climbing
		if next.jump:
			is_climbing = false
		test.expect(not locked_frame or (next.direction == 0 and not next.jump), "locked frame has no movement at frame " + str(frame))
	test.expect(model.next_state(automation, false, false).direction == 1, "movement lock does not persist after 600 frames")
	test.finish(self, "player_intent")
