extends SceneTree

const AutoCombatService = preload("res://actors/AutoCombatService.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var service = AutoCombatService.new()
	var context = {"map_allows_auto":true,"player_alive":true,"manual_stop":false,"inventory_full":false,"quest_complete":false,"has_reachable_target":true,"basic_skill_id":"skill.basic","active_skills":[{"id":"skill.active","available":true,"priority":1}]}
	var action = service.decide(context)
	test.expect(action.ok and action.action == "cast" and action.skill_id == "skill.active", "plans actions only after passing safety policy")
	context.inventory_full = true
	var stopped = service.decide(context)
	test.expect(not stopped.ok and stopped.reason == "inventory_full" and stopped.action == "idle", "safety stop overrides action planning")
	test.finish(self, "auto_combat_service")
