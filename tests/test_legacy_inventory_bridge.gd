extends SceneTree

const LegacyInventoryBridge = preload("res://actors/LegacyInventoryBridge.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var bridge = LegacyInventoryBridge.new()
	var aliases = {"legacy herb": "item.herb", "legacy sword": "item.sword"}
	test.expect(bridge.add_legacy("new herb", 12, 10), "adds a legacy pickup through a canonical command")
	var added = bridge.project_legacy()
	test.expect(added[0] == ["new herb", 10] and added[1] == ["new herb", 2], "canonical pickup projects deterministic legacy stacks")
	test.expect(not bridge.take(0).empty() and bridge.place(4, "new herb", 10, 10), "takes and places a stack through canonical commands")
	test.expect(bridge.adjust(4, -3) and bridge.project_legacy()[4] == ["new herb", 7], "adjusts a canonical stack quantity")
	test.expect(bridge.adjust(4, -7) and not bridge.project_legacy().has(4), "removes a stack after final canonical consumption")
	bridge = LegacyInventoryBridge.new()
	test.expect(bridge.import_legacy({"0": ["legacy herb", 7], "4": ["legacy sword", 1]}, aliases), "imports legacy slots through explicit aliases")
	test.expect(bridge.move(4, 1), "moves canonical legacy inventory slot")
	test.expect(bridge.split(0, 3, 2), "splits canonical legacy stack")
	var projected = bridge.project_legacy()
	test.expect(projected[0] == ["legacy herb", 5] and projected[1] == ["legacy sword", 1] and projected[3] == ["legacy herb", 2], "projects canonical commands back to legacy UI shape")
	var round_trip = bridge.export_state()
	test.expect(bridge.import_legacy(projected, aliases) and to_json(bridge.export_state()) == to_json(round_trip), "legacy projection round trips through the command bridge")
	test.expect(not bridge.import_legacy({"0": ["unknown", 1]}, aliases), "rejects legacy entries without stable aliases")
	test.finish(self, "legacy_inventory_bridge")
