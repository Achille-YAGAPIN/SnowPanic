extends Node2D

@onready var game_over_sprite = $GameOverSprite

func _ready():
	# Connecter le signal (exemple avec le Player)
	$Player.game_over.connect(_on_game_over)
	game_over_sprite.hide()  # Cacher au départ

func _on_game_over():
	print("Signal game_over reçu !")
	game_over_sprite.show()

	get_tree().paused = true
