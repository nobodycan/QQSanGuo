extends SceneTree

const QuestState = preload("res://actors/QuestState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var quest = QuestState.new()
	var state = quest.new_state("quest.pilot")
	for step in [["e1","unlock"],["e2","accept"],["e3","objectives_complete"],["e4","turn_in"]]:
		var result = quest.apply(state, step[0], step[1])
		state = result.state
	test.expect(state.status == QuestState.COMPLETED, "moves through the five quest states")
	test.expect(quest.apply(state, "e4", "turn_in").duplicate and not quest.apply(state, "e5", "accept").ok, "deduplicates events and rejects invalid transitions")
	test.finish(self, "quest_state")
