extends SceneTree

const CombatAction = preload("res://actors/CombatAction.gd")
const SkillBook = preload("res://actors/SkillBook.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var trace = [_resolve("skill.basic_attack", 1, 0, 10, "enemy.snake", 80, 2), _resolve("skill.active_strike", 3, 5, 30, "enemy.snake", 80, 2), _resolve("skill.basic_attack", 1, 0, 10, "enemy.guard", 180, 8), _resolve("skill.active_strike", 3, 5, 30, "enemy.guard", 180, 8)]
	test.expect(trace[0] == 8 and trace[1] == 28 and trace[2] == 2 and trace[3] == 22, "fixed two-skill two-enemy trace is reproducible")
	test.finish(self, "combat_matrix")

func _resolve(skill_id, unlock_level, magic_cost, damage, enemy_id, enemy_health, defense):
	var book = SkillBook.new()
	book.add_definition({"id": skill_id, "unlock_level": unlock_level, "magic_cost": magic_cost, "cooldown_ticks": 0, "damage": damage})
	book.unlock(skill_id, unlock_level)
	var cast = book.cast(skill_id, 10)
	var combat = CombatAction.new()
	var result = combat.resolve({"id": skill_id + ":" + enemy_id, "attacker": {"id": "player", "faction": "player"}, "defender": {"id": enemy_id, "faction": "enemy"}, "damage": {"base_damage": cast.damage, "defense": defense}}, combat.vitals.new_state(enemy_health, 0))
	return result.damage if cast.ok and result.ok else -1
