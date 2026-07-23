extends SceneTree

const DialoguePresenter = preload("res://actors/DialoguePresenter.gd")
const InteractionSession = preload("res://actors/InteractionSession.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var test = TestProtocol.new()
	var definition = {"id":"dialogue.elder","nodes":[{"id":"start","text":"Hello"},{"id":"after","text":"Welcome","requires_flags":["flag.met"]}]}
	var view = DialoguePresenter.new().present(definition, ["flag.met"])
	test.expect(view.ok and view.lines.size() == 2 and view.lines[0].text == "Hello", "presents only available dialogue lines")
	var session = InteractionSession.new()
	test.expect(session.open("npc.elder") and session.close("npc.elder") and session.open("npc.merchant"), "closing a dialogue releases the interaction lock")
	test.finish(self, "dialogue_presenter")
