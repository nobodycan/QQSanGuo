extends SceneTree

const EnemyDefinition = preload("res://actors/EnemyDefinition.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var definitions = EnemyDefinition.new()
	var snake = definitions.normalize({"id": "enemy.snake", "max_health": 80, "damage": 8, "aggro_range": 120.0, "attack_range": 20.0, "ai_role": "skirmisher", "telegraph": "lunge", "loot_id": "loot.snake"})
	var guard = definitions.normalize({"id": "enemy.guard", "max_health": 180, "damage": 15, "aggro_range": 160.0, "attack_range": 35.0, "ai_role": "bruiser", "telegraph": "windup", "loot_id": "loot.guard"})
	test.expect(not snake.empty() and not guard.empty(), "pilot definitions normalize")
	test.expect(definitions.primary_difference(snake, guard) != "", "pilots have a primary encounter difference")
	test.expect(definitions.normalize({"id": "bad", "max_health": 1}).empty(), "incomplete definition is rejected")
	test.finish(self, "enemy_definition")
