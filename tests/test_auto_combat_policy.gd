extends SceneTree

const AutoCombatPolicy = preload("res://actors/AutoCombatPolicy.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var policy = AutoCombatPolicy.new()
	var ready = {"map_allows_auto":true,"player_alive":true,"manual_stop":false,"inventory_full":false,"quest_complete":false,"has_reachable_target":true}
	test.expect(policy.decide(ready).ok, "allows safe foreground auto combat")
	var full = ready.duplicate()
	full.inventory_full = true
	var no_target = ready.duplicate()
	no_target.has_reachable_target = false
	var boss = ready.duplicate()
	boss.active_encounter_kind = "boss"
	var transitioning = ready.duplicate()
	transitioning.transitioning = true
	var paused = ready.duplicate()
	paused.pause_or_blocking_ui = true
	test.expect(policy.decide(full).reason == "inventory_full" and policy.decide(no_target).reason == "no_reachable_target" and policy.decide(boss).reason == "boss_or_dungeon" and policy.decide(transitioning).reason == "transition" and policy.decide(paused).reason == "pause_or_blocking_ui", "stops for inventory, targets, encounters, scene transitions, and blocking UI")
	var dead = ready.duplicate()
	dead.player_alive = false
	test.expect(policy.decide(dead).reason == "player_dead", "stops when the player dies")
	test.finish(self, "auto_combat_policy")
