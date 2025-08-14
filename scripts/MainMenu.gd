extends Control

func _ready():
	# Connecter les signaux des boutons (nouvelle syntaxe Godot 4)
	$PlayButton.pressed.connect(_on_PlayButton_pressed)
	
func _on_PlayButton_pressed():
	# Charger et passer à la scène du jeu
	get_tree().change_scene_to_file("res://scenes/main.tscn")
