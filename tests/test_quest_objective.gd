extends SceneTree

const QuestObjective = preload("res://actors/QuestObjective.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var objective = QuestObjective.new()
	var state = objective.new_state("kill", "enemy.snake", 2)
	state = objective.apply(state, "kill.1", "kill", "enemy.snake").state
	var duplicate = objective.apply(state, "kill.1", "kill", "enemy.snake")
	state = objective.apply(state, "kill.2", "kill", "enemy.snake").state
	test.expect(not objective.complete(duplicate.state) and duplicate.duplicate and objective.complete(state), "counts matching events once until the objective completes")
	test.expect(not objective.apply(state, "talk.1", "talk", "npc.elder").ok, "rejects mismatched objective events")
	test.finish(self, "quest_objective")
