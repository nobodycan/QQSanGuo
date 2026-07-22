extends SceneTree

const CombatDriver = preload("res://actors/CombatDriver.gd")
const PlayerIntent = preload("res://actors/PlayerIntent.gd")
const SkillBook = preload("res://actors/SkillBook.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var manual = _intent(PlayerIntent.SOURCE_MANUAL)
	var automation = _intent(PlayerIntent.SOURCE_AUTOMATION)
	var manual_trace = _matrix(manual)
	var automation_trace = _matrix(automation)
	test.expect(manual_trace == [8, 28, 2, 22], "manual intent drives the two-skill by two-enemy matrix")
	test.expect(automation_trace == manual_trace, "automation intent uses the same skill and CombatAction pipeline")
	test.finish(self, "combat_driver")

func _intent(source):
	var intent = PlayerIntent.new()
	intent.source = source
	return intent

func _matrix(intent):
	return [
		_resolve(intent, "skill.basic", 1, 0, 10, "enemy.snake", 80, 2),
		_resolve(intent, "skill.active", 3, 5, 30, "enemy.snake", 80, 2),
		_resolve(intent, "skill.basic", 1, 0, 10, "enemy.guard", 180, 8),
		_resolve(intent, "skill.active", 3, 5, 30, "enemy.guard", 180, 8)
	]

func _resolve(intent, skill_id, unlock_level, magic_cost, damage, enemy_id, health, defense):
	var book = SkillBook.new()
	book.add_definition({"id": skill_id, "unlock_level": unlock_level, "magic_cost": magic_cost, "cooldown_ticks": 0, "damage": damage})
	book.unlock(skill_id, unlock_level)
	var driver = CombatDriver.new()
	var result = driver.execute(intent, book, skill_id, {"id": "player", "faction": "player", "magic": 10}, {"id": enemy_id, "faction": "enemy"}, driver.combat.vitals.new_state(health, 0), defense)
	return result.damage if result.ok else -1
