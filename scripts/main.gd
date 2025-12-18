extends Node2D

@onready var player: Node = $Player
@onready var game_over_sprite: Node2D = $GameOverSprite
@onready var restart_button: TextureButton = $UserInterface/RestartButton
@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	initialize_ui()
	connect_signals()
	start_music()
	
func initialize_ui() -> void:
	game_over_sprite.hide()
	restart_button.hide()

func connect_signals() -> void:
	player.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)

func start_music() -> void:
	music_player.play()
	
func _on_game_over() -> void:
	show_game_over()
	pause_game()

func show_game_over() -> void:
	game_over_sprite.show()
	restart_button.show()

func pause_game() -> void:
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false
	
func _on_restart_pressed() -> void:
	resume_game()
	restart_scene()

func restart_scene() -> void:
	get_tree().reload_current_scene()
