extends Node

const CombatUiStub = preload("res://tests/fixtures/CombatUiStub.gd")
const Steve = preload("res://Character/Steve.tscn")
const Snake = preload("res://Enemy/Snake.tscn")
const PlayerIntent = preload("res://actors/PlayerIntent.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

const SOAK_TICKS = 15 * 60 * 60
const ENCOUNTER_TICKS = 900

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
	var second_snake = Snake.instance()
	world.add_child(second_snake)
	yield(get_tree(), "idle_frame")
	steve.set_physics_process(false)
	snake.set_process(false)
	second_snake.set_process(false)
	var manual_intent = PlayerIntent.new()
	manual_intent.source = PlayerIntent.SOURCE_MANUAL
	var automation_intent = PlayerIntent.new()
	automation_intent.source = PlayerIntent.SOURCE_AUTOMATION
	var manual_result = steve.execute_combat_skill(snake, "legacy.basic", manual_intent)
	var automation_result = steve.execute_combat_skill(second_snake, "legacy.active", automation_intent)
	test.expect(manual_result.ok and manual_result.source == PlayerIntent.SOURCE_MANUAL and snake.health == manual_result.vitals.health, "manual Steve skill uses CombatDriver and synchronizes the real Snake")
	test.expect(automation_result.ok and automation_result.source == PlayerIntent.SOURCE_AUTOMATION and second_snake.health == automation_result.vitals.health and automation_result.damage > manual_result.damage, "automation Steve skill uses the same driver with the active skill")
	var scene_soak_failures = 0
	var scene_soak_actions = 0
	for tick in range(SOAK_TICKS):
		if tick % ENCOUNTER_TICKS == 0:
			_reset_snake(snake)
			_reset_snake(second_snake)
			steve.vitals_state.magic = steve.vitals_state.max_magic
			steve.magic = steve.vitals_state.magic
			var soak_manual = steve.execute_combat_skill(snake, "legacy.basic", manual_intent)
			var soak_automation = steve.execute_combat_skill(second_snake, "legacy.active", automation_intent)
			scene_soak_actions += 2
			if not soak_manual.ok or not soak_automation.ok or snake.health != soak_manual.vitals.health or second_snake.health != soak_automation.vitals.health:
				scene_soak_failures += 1
	test.expect(scene_soak_actions == 120 and scene_soak_failures == 0, "15-minute simulated scene soak keeps both migrated combat adapters synchronized")
	var steve_health = steve.health
	var player_result = steve.injury(-7, false)
	test.expect(player_result.ok and steve.health == steve_health - 7, "Snake-to-Steve adapter resolves CombatAction damage into Steve Vitals")
	var magic_before_heal = steve.magic
	steve._on_self_heal_timeout()
	test.expect(steve.health == steve_health - 3 and steve.magic == magic_before_heal + 2, "Steve self-heal restores Vitals health and magic without the legacy setter")
	var snake_health = snake.health
	var snake_result = snake.injury(-7, false)
	test.expect(snake_result.ok and snake.health == snake_health - 6 and snake.get_node("HealthBar/HealthBar").value == snake.health, "Steve-to-Snake adapter resolves defense and synchronizes the health bar")
	snake.money = 7
	snake.exprience = 0
	var money_before_reward = PlayerInventory.money
	var defeat = snake.injury(-10000, false)
	snake.dead()
	snake.dead()
	test.expect(defeat.ok and defeat.defeated and snake.health == 0 and PlayerInventory.money == money_before_reward + snake.money, "repeated real Snake death presents its reward exactly once after Vitals defeat")
	_finish(test, world)

func _reset_snake(snake):
	snake.vitals_state = snake.vitals_model.new_state(snake.max_health, 0)
	snake.health = snake.vitals_state.health
	snake.get_node("HealthBar/HealthBar").value = snake.health

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
