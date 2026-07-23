extends SceneTree

const QuestDefinition = preload("res://actors/QuestDefinition.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var definitions = QuestDefinition.new()
	test.expect(definitions.validate([{"id":"quest.a"},{"id":"quest.b","prerequisites":["quest.a"]}]).ok, "accepts an acyclic prerequisite DAG")
	test.expect(definitions.validate([{"id":"quest.a","prerequisites":["quest.missing"]}]).error == "missing_prerequisite", "rejects orphan prerequisites")
	test.expect(definitions.validate([{"id":"quest.a","prerequisites":["quest.b"]},{"id":"quest.b","prerequisites":["quest.a"]}]).error == "cycle", "rejects prerequisite cycles")
	test.finish(self, "quest_definition")
