extends Node

const CombatUiStub = preload("res://tests/fixtures/CombatUiStub.gd")
const Steve = preload("res://Character/Steve.tscn")
const Snake = preload("res://Enemy/Snake.tscn")
const TestProtocol = preload("res://tests/TestProtocol.gd")

var death_events = 0

func _init():
	call_deferred("_run")

func _run():
	var test = TestProtocol.new()
	var world = Node.new()
	world.name = "CombatFixtureWorld"
	get_tree().get_root().add_child(world)
	var user_interface = CombatUiStub.new()
	user_interface.name = "UserInterFace"
	world.add_child(user_interface)
	var character = Node.new()
	character.name = "Character"
	user_interface.add_child(character)
	var target = Control.new()
	target.name = "Target"
	character.add_child(target)
	yield(get_tree(), "idle_frame")
	var steve = Steve.instance()
	world.add_child(steve)
	var snake = Snake.instance()
	world.add_child(snake)
	yield(get_tree(), "idle_frame")
	steve.set_physics_process(false)
	snake.set_process(false)
	snake.connect("monster_die", self, "_on_monster_die")
	var steve_health = steve.health
	var player_result = steve.injury(-7, false)
	test.expect(player_result.ok and steve.health == steve_health - 7, "Snake-to-Steve adapter resolves CombatAction damage into Steve Vitals")
	var snake_health = snake.health
	var snake_result = snake.injury(-7, false)
	test.expect(snake_result.ok and snake.health == snake_health - 6 and snake.get_node("HealthBar/HealthBar").value == snake.health, "Steve-to-Snake adapter resolves defense and synchronizes the health bar")
	var money_before = PlayerInventory.money
	var defeat = snake.injury(-10000, false)
	snake.dead()
	test.expect(defeat.ok and defeat.defeated and snake.health == 0, "Snake death is idempotently represented by Vitals")
	test.expect(death_events == 1 and PlayerInventory.money == money_before + snake.money, "Snake death signal presents its reward exactly once")
	_finish(test, world)

func _on_monster_die():
	death_events += 1

func _finish(test, world):
	if world != null:
		world.free()
	for name in ["DataImport", "PlayerInventory", "FileManager", "SkillsFactory", "SkillsProperty", "jsonData", "SaveState", "SceneChange", "FreeNodes", "PlayerStorage", "GameState", "SaveManager", "SceneManager", "ContentRegistry", "EventBus", "AudioManager"]:
		var service = get_tree().get_root().get_node_or_null(name)
		if service != null:
			service.free()
	call_deferred("_finish_after_cleanup", test)

func _finish_after_cleanup(test):
	yield(get_tree(), "idle_frame")
	test.finish(get_tree(), "legacy_combat_scene")
