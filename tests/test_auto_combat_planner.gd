extends SceneTree

const AutoCombatPlanner = preload("res://actors/AutoCombatPlanner.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var planner = AutoCombatPlanner.new()
	var context = {"has_reachable_target":true,"basic_skill_id":"skill.basic","active_skills":[{"id":"skill.low","available":true,"priority":1},{"id":"skill.high","available":true,"priority":3}]}
	test.expect(planner.decide(context).skill_id == "skill.high", "chooses the highest-priority available skill")
	context.active_skills = [{"id":"skill.low","available":false,"priority":3}]
	test.expect(planner.decide(context).skill_id == "skill.basic", "falls back to the basic skill when actives are unavailable")
	context.has_reachable_target = false
	test.expect(planner.decide(context).action == "idle", "does not plan attacks without a reachable target")
	test.finish(self, "auto_combat_planner")
