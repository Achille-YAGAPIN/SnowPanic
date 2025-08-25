extends Node2D

@onready var game_over_sprite = $GameOverSprite
@onready var restart_button = $UserInterface/RestartButton

func _ready():
	$Player.game_over.connect(_on_game_over)
	game_over_sprite.hide()
	restart_button.hide()
	$AudioStreamPlayer.play()
	restart_button.pressed.connect(_on_restart_pressed)

func _on_game_over():
	game_over_sprite.show()
	restart_button.show()
	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
