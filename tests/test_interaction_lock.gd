extends SceneTree

const InteractionLock = preload("res://actors/InteractionLock.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var lock = InteractionLock.new()
	test.expect(lock.begin("npc.elder") and lock.blocked() and not lock.begin("npc.elder") and not lock.begin("npc.merchant"), "blocks duplicate and concurrent interactions")
	test.expect(not lock.release("npc.merchant") and lock.release("npc.elder") and not lock.blocked(), "only releases the active NPC interaction")
	test.finish(self, "interaction_lock")
