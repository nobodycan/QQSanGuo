extends SceneTree

const SkillState = preload("res://actors/SkillState.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var skills = SkillState.new()
	var normalized = skills.normalize({"version": 1, "known": ["skill.willow_return", "skill.basic_slash", "skill.basic_slash"], "equipped": ["skill.basic_slash"], "cooldowns": {"skill.basic_slash": 2}})
	test.expect(normalized.known == ["skill.basic_slash", "skill.willow_return"] and normalized.cooldowns["skill.basic_slash"] == 2, "normalizes and sorts canonical skill state")
	test.expect(skills.normalize({"version": 1, "known": ["legacy.basic"], "equipped": [], "cooldowns": {}}).empty(), "rejects non-canonical skill IDs")
	test.expect(skills.normalize({"version": 1, "known": ["skill.basic_slash"], "equipped": ["skill.willow_return"], "cooldowns": {}}).empty(), "rejects equipped skills that are not known")
	test.expect(skills.normalize({"version": 1, "known": ["skill.basic_slash"], "equipped": [], "cooldowns": {"skill.basic_slash": -1}}).empty(), "rejects negative cooldowns")
	test.expect(skills.migrate_v0({}).version == 1 and skills.migrate_v0({"known": []}).empty(), "only empty v0 skill sections migrate losslessly")
	var registry = ContentRegistry.new()
	registry.load_content()
	var migrated = skills.migrate_legacy_registered({"known": ["横击剑", "饮血剑舞"], "equipped": ["饮血剑舞"]}, registry)
	test.expect(migrated.known == ["skill.basic_slash", "skill.blood_sword_dance"] and migrated.equipped == ["skill.blood_sword_dance"], "migrates legacy skill names through validated aliases")
	test.expect(skills.migrate_legacy_registered({"known": ["unknown"], "equipped": []}, registry).empty(), "rejects unresolved legacy skill names")
	test.expect(skills.validate_registered({"version": 1, "known": ["skill.basic_slash"], "equipped": [], "cooldowns": {}}, registry).ok, "accepts canonical skills present in registry")
	test.expect(skills.validate_registered({"version": 1, "known": ["skill.forged"], "equipped": [], "cooldowns": {}}, registry).error == "unknown_skill", "rejects stable-looking skills missing from registry")
	registry.free()
	test.finish(self, "skill_state")
