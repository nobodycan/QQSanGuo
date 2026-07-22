extends SceneTree

const AudioManagerScript = preload("res://autoload/AudioManager.gd")
const TestProtocol = preload("res://tests/TestProtocol.gd")

func _init():
	var manager = AudioManagerScript.new()
	manager.settings_path = "user://test_audio_settings.cfg"
	var directory = Directory.new()
	if directory.file_exists(manager.settings_path): directory.remove(manager.settings_path)
	var test = TestProtocol.new()
	test.expect(manager.load_settings().volume_db == 0.0, "missing settings use default volume")
	test.expect(manager.save_settings(-8.5).ok, "writes audio settings")
	test.expect(manager.load_settings().volume_db == -8.5, "reloads saved volume")
	if directory.file_exists(manager.settings_path): directory.remove(manager.settings_path)
	test.finish(self, "audio_settings")
