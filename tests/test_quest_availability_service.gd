extends SceneTree

const QuestAvailabilityService = preload("res://actors/QuestAvailabilityService.gd")
const QuestState = preload("res://actors/QuestState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var quest_state = QuestState.new()
	var root = quest_state.new_state("quest.root")
	root = quest_state.apply(root, "root.unlock", "unlock").state
	root = quest_state.apply(root, "root.accept", "accept").state
	root = quest_state.apply(root, "root.objectives", "objectives_complete").state
	root = quest_state.apply(root, "root.turn_in", "turn_in").state
	var definitions = [{"id":"quest.root","prerequisites":[]},{"id":"quest.next","prerequisites":["quest.root"]}]
	var service = QuestAvailabilityService.new()
	var refreshed = service.refresh(definitions, {"quest.root":root})
	test.expect(refreshed.ok and refreshed.states["quest.next"].status == QuestState.AVAILABLE, "unlocks quests whose prerequisites are completed")
	var repeated = service.refresh(definitions, refreshed.states)
	test.expect(repeated.ok and repeated.states["quest.next"].events.size() == 1, "refreshing availability is idempotent")
	var invalid = service.refresh([{"id":"quest.loop","prerequisites":["quest.loop"]}], {})
	test.expect(not invalid.ok, "rejects invalid prerequisite graphs")
	test.finish(self, "quest_availability_service")
