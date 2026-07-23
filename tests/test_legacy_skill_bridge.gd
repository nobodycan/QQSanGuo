extends SceneTree

const LegacySkillBridge = preload("res://actors/LegacySkillBridge.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var registry = ContentRegistry.new()
	registry.load_content()
	var bridge = LegacySkillBridge.new()
	test.expect(bridge.import_legacy(["横击剑", "饮血剑舞"], ["饮血剑舞"], registry), "imports legacy runtime skill arrays through registry")
	test.expect(bridge.export_canonical().known == ["skill.basic_slash", "skill.blood_sword_dance"], "exports canonical skill state for V2 persistence")
	test.expect(bridge.project_legacy(registry).equipped == ["饮血剑舞"], "projects canonical state back to legacy UI names")
	test.expect(not bridge.import_legacy(["unknown"], [], registry), "rejects unresolved runtime skill names")
	registry.free()
	test.finish(self, "legacy_skill_bridge")
