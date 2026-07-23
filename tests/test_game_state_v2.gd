extends SceneTree

const StateV2 = preload("res://autoload/GameStateV2.gd")
const ContentRegistry = preload("res://autoload/ContentRegistry.gd")
const PlayerInventory = preload("res://PlayerInventory.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var state = StateV2.new()
	var test = TestProtocol.new()
	var envelope = state.new_envelope()
	envelope.location = {"map_id": "map.level_one", "spawn_id": "spawn.start"}
	var registry = ContentRegistry.new()
	registry.load_content()
	var normalized = state.normalize(envelope)
	test.expect(normalized != null, "normalizes valid v2 envelope")
	test.expect(state.validate_content_compatibility(envelope, "v1-pilot-phase76").ok and state.validate_content_compatibility(envelope, "v2-next").reason == "content_revision_mismatch", "accepts only saves matching the loaded content revision")
	test.expect(state.validate_content_compatibility(envelope, "v1-pilot-phase76", registry).ok, "accepts empty canonical skill state against registry")
	var forged_skill = state.new_envelope()
	forged_skill.skills.known = ["skill.forged"]
	test.expect(state.validate_content_compatibility(forged_skill, "v1-pilot-phase76", registry).reason == "unknown_skill", "rejects persisted skills absent from registry")
	var runtime_inventory = PlayerInventory.new()
	runtime_inventory.known_skills = ["横击剑"]
	runtime_inventory.equipped_skills = ["横击剑"]
	var captured_runtime = state.capture_runtime_skills(envelope, runtime_inventory, registry)
	test.expect(captured_runtime.ok and captured_runtime.state.skills.known == ["skill.basic_slash"], "captures legacy runtime skills into the V2 stable state")
	runtime_inventory.known_skills = []
	runtime_inventory.equipped_skills = []
	test.expect(state.apply_runtime_skills(captured_runtime.state, runtime_inventory, registry).ok and runtime_inventory.equipped_skills == ["横击剑"], "applies V2 stable skills back to runtime legacy arrays")
	runtime_inventory.free()
	test.expect(normalized.section_versions.inventory == 1 and normalized.inventory.version == 1 and normalized.inventory.slots.size() == 50, "creates inventory section v1")
	test.expect(normalized.section_versions.equipment == 2 and normalized.equipment.version == 2 and normalized.equipment.slots.size() == 10, "creates equipment section v2")
	test.expect(normalized.section_versions.skills == 1 and normalized.skills.version == 1 and normalized.skills.known.empty(), "creates canonical skill section v1")
	test.expect(normalized.section_versions.wallet == 1 and normalized.wallet.version == 1 and normalized.wallet.money == 0, "creates wallet section v1")
	test.expect(normalized.section_versions.world == 1 and normalized.world.version == 1, "creates world section v1")
	var parsed = JSON.parse(to_json(normalized))
	test.expect(parsed.error == OK and state.normalize(parsed.result) != null, "v2 envelope round trips through JSON")
	var legacy_player = state.new_envelope()
	legacy_player.player = {"level": 2, "exprience": 3, "max_health": 1100}
	var migrated_player = state.normalize(legacy_player)
	var remigrated_player = state.normalize(migrated_player)
	test.expect(migrated_player.player.version == 1 and migrated_player.player.level == 2 and migrated_player.player.experience == 3, "upgrades player v0 within v2 envelope")
	test.expect(remigrated_player.player.base.max_health == migrated_player.player.base.max_health and remigrated_player.player.derived.max_health == migrated_player.player.derived.max_health, "player migration remains idempotent in v2 envelope")
	var legacy_inventory = state.new_envelope()
	var legacy_versions = legacy_inventory.section_versions.duplicate()
	legacy_versions["inventory"] = 0
	legacy_inventory["section_versions"] = legacy_versions
	legacy_inventory["inventory"] = {}
	var migrated_inventory = state.normalize(legacy_inventory)
	test.expect(migrated_inventory != null and migrated_inventory.section_versions.inventory == 1 and migrated_inventory.inventory.slots.size() == 50, "upgrades empty inventory v0 to v1")
	var unsupported_inventory = state.new_envelope()
	var unsupported_versions = unsupported_inventory.section_versions.duplicate()
	unsupported_versions["inventory"] = 2
	unsupported_inventory["section_versions"] = unsupported_versions
	test.expect(state.normalize(unsupported_inventory) == null, "rejects unsupported inventory section version")
	var unsafe_inventory = state.new_envelope()
	var unsafe_versions = unsafe_inventory.section_versions.duplicate()
	unsafe_versions["inventory"] = 0
	unsafe_inventory["section_versions"] = unsafe_versions
	unsafe_inventory["inventory"] = {"0": ["legacy herb", 1]}
	test.expect(state.normalize(unsafe_inventory) == null, "rejects inventory v0 that lacks a lossless alias migration")
	var legacy_equipment = state.new_envelope()
	var legacy_equipment_versions = legacy_equipment.section_versions.duplicate()
	legacy_equipment_versions["equipment"] = 0
	legacy_equipment["section_versions"] = legacy_equipment_versions
	legacy_equipment["equipment"] = {}
	var migrated_equipment = state.normalize(legacy_equipment)
	test.expect(migrated_equipment != null and migrated_equipment.section_versions.equipment == 2 and migrated_equipment.equipment.slots.size() == 10, "upgrades empty equipment v0 to v2")
	var v1_equipment = state.new_envelope()
	var v1_equipment_versions = v1_equipment.section_versions.duplicate()
	v1_equipment_versions["equipment"] = 1
	v1_equipment["section_versions"] = v1_equipment_versions
	v1_equipment["equipment"] = {"version": 1, "slots": {"Sword": {"instance_id": "item.sword.1", "slot": "Sword", "job": "js", "level": 1, "modifiers": {"basic_damage": 25}}}}
	var migrated_v1_equipment = state.normalize(v1_equipment)
	test.expect(migrated_v1_equipment != null and migrated_v1_equipment.equipment.slots.Sword.enhancement_level == 0, "migrates v1 equipment to a persisted enhancement level")
	var unsupported_equipment = state.new_envelope()
	var unsupported_equipment_versions = unsupported_equipment.section_versions.duplicate()
	unsupported_equipment_versions["equipment"] = 3
	unsupported_equipment["section_versions"] = unsupported_equipment_versions
	test.expect(state.normalize(unsupported_equipment) == null, "rejects unsupported equipment section version")
	var invalid_enhancement = state.new_envelope()
	invalid_enhancement.equipment.slots.Sword = {"instance_id": "item.sword.11", "slot": "Sword", "job": "js", "level": 1, "modifiers": {"basic_damage": 25}, "enhancement_level": 11}
	test.expect(state.normalize(invalid_enhancement) == null, "rejects persisted enhancement beyond plus ten")
	invalid_enhancement.equipment.slots.Sword.enhancement_level = "five"
	test.expect(state.normalize(invalid_enhancement) == null, "rejects non-integer persisted enhancement levels")
	var unsafe_equipment = state.new_envelope()
	var unsafe_equipment_versions = unsafe_equipment.section_versions.duplicate()
	unsafe_equipment_versions["equipment"] = 0
	unsafe_equipment["section_versions"] = unsafe_equipment_versions
	unsafe_equipment["equipment"] = {"Sword": "legacy sword"}
	test.expect(state.normalize(unsafe_equipment) == null, "rejects equipment v0 that lacks a lossless instance migration")
	var legacy_skills = state.new_envelope()
	legacy_skills.section_versions.skills = 0
	legacy_skills.skills = {}
	var migrated_skills = state.normalize(legacy_skills)
	test.expect(migrated_skills != null and migrated_skills.skills.version == 1, "upgrades empty skill v0 to v1")
	var unsafe_skills = state.new_envelope()
	unsafe_skills.section_versions.skills = 0
	unsafe_skills.skills = {"known": ["legacy.basic"]}
	test.expect(state.normalize(unsafe_skills) == null, "rejects non-empty v0 skills without registry migration")
	var invalid_skills = state.new_envelope()
	invalid_skills.skills.equipped = ["skill.willow_return"]
	test.expect(state.normalize(invalid_skills) == null, "rejects equipped skills that are missing from known skills")
	var legacy_wallet = state.new_envelope()
	var legacy_wallet_versions = legacy_wallet.section_versions.duplicate()
	legacy_wallet_versions.erase("wallet")
	legacy_wallet["section_versions"] = legacy_wallet_versions
	legacy_wallet.erase("wallet")
	var migrated_wallet = state.normalize(legacy_wallet)
	test.expect(migrated_wallet != null and migrated_wallet.section_versions.wallet == 1 and migrated_wallet.wallet.money == 0, "upgrades missing wallet v0 to v1")
	var unsupported_wallet = state.new_envelope()
	var unsupported_wallet_versions = unsupported_wallet.section_versions.duplicate()
	unsupported_wallet_versions["wallet"] = 2
	unsupported_wallet["section_versions"] = unsupported_wallet_versions
	test.expect(state.normalize(unsupported_wallet) == null, "rejects unsupported wallet section version")
	var unsafe_wallet = state.new_envelope()
	var unsafe_wallet_versions = unsafe_wallet.section_versions.duplicate()
	unsafe_wallet_versions["wallet"] = 0
	unsafe_wallet["section_versions"] = unsafe_wallet_versions
	unsafe_wallet["wallet"] = {"money": 5}
	test.expect(state.normalize(unsafe_wallet) == null, "rejects wallet v0 that lacks a lossless migration")
	var legacy_world = state.new_envelope()
	legacy_world.section_versions.world = 0
	legacy_world.world = {}
	var migrated_world = state.normalize(legacy_world)
	test.expect(migrated_world != null and migrated_world.world.version == 1, "upgrades empty world v0 to v1")
	var unsafe_world = state.new_envelope()
	unsafe_world.section_versions.world = 0
	unsafe_world.world = {"flags": ["flag.bad"]}
	test.expect(state.normalize(unsafe_world) == null, "rejects non-empty world v0 without lossless migration")
	envelope.erase("location")
	test.expect(state.normalize(envelope) == null, "rejects missing location")
	envelope = state.new_envelope()
	envelope.schema_version = 3
	test.expect(state.normalize(envelope) == null, "rejects unsupported schema")
	registry.free()
	test.finish(self, "game_state_v2")
