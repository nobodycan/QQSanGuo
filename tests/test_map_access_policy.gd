extends SceneTree

const MapAccessPolicy = preload("res://actors/MapAccessPolicy.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const WorldState = preload("res://actors/WorldState.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var maps = [{"id": "map.start", "spawns": [{"id": "spawn.a"}]}, {"id": "map.locked", "spawns": [{"id": "spawn.b"}]}]
	var world = WorldState.new().new_state()
	var access = MapAccessPolicy.new()
	test.expect(access.can_enter(maps, world, "map.locked", "spawn.b", "map.start").reason == "locked", "rejects locked maps before scene load")
	world.unlocked_maps.append("map.locked")
	test.expect(access.can_enter(maps, world, "map.locked", "spawn.b", "map.start").ok, "allows unlocked maps with a valid spawn")
	test.expect(access.can_enter(maps, world, "map.locked", "spawn.missing", "map.start").reason == "spawn_missing", "rejects missing target spawns")
	var registry = ContentRegistry.new()
	registry.load_content()
	var registered_world = WorldState.new().new_state()
	registered_world.unlocked_maps.append("map.jianglin")
	test.expect(access.can_enter_registered(registry, registered_world, "map.jianglin", "spawn.entry", "map.level_one").ok, "uses only registry-loaded map definitions")
	registry.free()
	test.finish(self, "map_access_policy")
