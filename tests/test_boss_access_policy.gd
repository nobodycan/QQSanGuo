extends SceneTree

const BossAccessPolicy = preload("res://actors/BossAccessPolicy.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var policy = BossAccessPolicy.new()
	var definition = {"id":"boss.pilot","map_id":"map.cave","min_level":15,"requires_flags":["story.cave_open"]}
	var world = {"unlocked_maps":["map.cave"],"flags":["story.cave_open"],"defeated_bosses":[]}
	test.expect(policy.can_start(definition, world, 15).ok, "allows an eligible undefeated boss encounter")
	test.expect(policy.can_start(definition, world, 14).reason == "level_locked", "enforces boss minimum level")
	world.defeated_bosses = ["boss.pilot"]
	test.expect(policy.can_start(definition, world, 15).reason == "already_defeated", "prevents duplicate non-repeatable boss fights")
	definition.repeatable = true
	test.expect(policy.can_start(definition, world, 15).ok, "permits explicitly repeatable bosses after defeat")
	test.finish(self, "boss_access_policy")
