extends SceneTree

const NpcDefinition = preload("res://actors/NpcDefinition.gd")
const DialogueDefinition = preload("res://actors/DialogueDefinition.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	test.expect(NpcDefinition.new().normalize({"id":"npc.elder","map_id":"map.start","dialogue_id":"dialogue.elder","interaction_radius":48}).id == "npc.elder", "normalizes stable NPC registration")
	var dialogue = {"id":"dialogue.elder","nodes":[{"id":"start","text":"Hello"},{"id":"after","text":"Welcome","requires_flags":["flag.met"]}]}
	test.expect(DialogueDefinition.new().available_nodes(dialogue, []).size() == 1 and DialogueDefinition.new().available_nodes(dialogue, ["flag.met"]).size() == 2, "filters dialogue nodes by world flags")
	test.finish(self, "dialogue_definition")
