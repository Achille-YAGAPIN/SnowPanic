extends Control

func _ready():
	$PlayButton.pressed.connect(_on_PlayButton_pressed)
	
func _on_PlayButton_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
