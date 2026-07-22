extends SceneTree

const CombatAction = preload("res://actors/CombatAction.gd")
const EffectState = preload("res://actors/EffectState.gd")
const SpawnerScope = preload("res://actors/SpawnerScope.gd")
const TargetRegistry = preload("res://actors/TargetRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

const TICKS = 15 * 60 * 60
const ENCOUNTER_TICKS = 900

func _init():
	var test = TestProtocol.new()
	var combat = CombatAction.new()
	var effects_model = EffectState.new()
	var scope = SpawnerScope.new()
	var registry = TargetRegistry.new()
	var player = {"id": "player.soak", "faction": "player"}
	var effects = []
	var target_misses = 0
	var rewards = 0
	var duplicate_rewards = 0
	for tick in range(TICKS):
		var encounter = int(tick / ENCOUNTER_TICKS)
		var enemy_id = "enemy.soak." + str(encounter)
		if tick % ENCOUNTER_TICKS == 0:
			scope.spawn(enemy_id)
			registry = TargetRegistry.new()
			registry.register_target(enemy_id, TargetRegistry.FACTION_ENEMY, Vector2(8, 0))
		var target = registry.select_nearest(player.id, player.faction, Vector2.ZERO)
		if target.empty():
			target_misses += 1
		if tick % ENCOUNTER_TICKS == 0 and not target.empty():
			var defender = combat.vitals.new_state(10, 0)
			var action = {
				"id": "soak." + str(tick),
				"attacker": player,
				"defender": {"id": target.id, "faction": target.faction},
				"damage": {"base_damage": 10, "defense": 0}
			}
			var result = combat.resolve(action, defender)
			if result.ok and result.defeated:
				var defeat = scope.defeat(target.id, "defeat." + str(encounter))
				if defeat.ok:
					rewards += 1
				else:
					duplicate_rewards += 1
				var duplicate = scope.defeat(target.id, "defeat." + str(encounter))
				if not duplicate.ok and duplicate.error == "unknown_actor":
					duplicate_rewards += 1
				effects = effects_model.apply(effects, {"id": "burn", "remaining_ticks": 2, "max_stacks": 1, "power": 1})
		var tick_result = effects_model.tick(effects)
		effects = tick_result.effects
	test.expect(target_misses == 0, "15-minute soak keeps a target for every simulated tick")
	test.expect(effects.empty(), "temporary effects expire without becoming permanent")
	test.expect(rewards == 60, "each encounter grants exactly one reward")
	test.expect(duplicate_rewards == 60, "each duplicate defeat is rejected without a second reward")
	test.finish(self, "combat_soak")
