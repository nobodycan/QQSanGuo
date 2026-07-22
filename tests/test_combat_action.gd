extends SceneTree

const CombatAction = preload("res://actors/CombatAction.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var combat = CombatAction.new()
	var vitals = combat.vitals.new_state(10, 0)
	var action = {"id": "action.1", "attacker": {"id": "player", "faction": "player"}, "defender": {"id": "enemy", "faction": "enemy"}, "damage": {"base_damage": 12, "defense": 2}}
	var result = combat.resolve(action, vitals)
	test.expect(result.ok and result.damage == 10 and result.defeated, "combat action resolves damage into vitals")
	var duplicate = combat.resolve(action, result.vitals)
	test.expect(not duplicate.ok and duplicate.error == "duplicate_hit" and duplicate.vitals.death_count == 1, "duplicate action cannot resolve twice")
	test.finish(self, "combat_action")
