extends Control


func _ready():
	pass


func _on_Button_pressed():
	var result = SaveState.save_game()
	if result.get("ok", false):
		print("save")
	else:
		print(result.get("error", "unknown_save_error"))


func _on_Button2_pressed():
	var result = SaveState.load_game()
	if result.get("ok", false):
		print("load")
	else:
		print(result.get("error", "unknown_load_error"))


func _on_Button3_pressed():
	self.visible = false
	pass # Replace with function body.


func _on_Button4_pressed():
	$CenterContainer/Button4/AcceptDialog.popup_centered()
	pass # Replace with function body.


func _on_AcceptDialog_confirmed():
#	SceneChange.goto_scene("res://Login.tscn", self)
	get_tree().change_scene("res://Login.tscn")
	pass # Replace with function body.


func _on_AcceptDialog_mouse_entered():
	print("Mouse be absorbd in there")
	pass # Replace with function body.
