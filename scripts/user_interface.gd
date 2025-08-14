extends Control

var score = 0

func _ready():
	update_score()
	connect_player_signal()

func update_score():
	$ScoreLabel.text = "Score: " + str(score)

func _on_score_timer_timeout() -> void:
	score += 100  # Incrémenter le score
	update_score()

func connect_player_signal():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.game_over.connect(_on_game_over)
		print("Signal game_over connecté avec succès")
	else:
		print("Attention : Aucun joueur trouvé")
		# On essaie à nouveau après un court délai au cas où le joueur n'est pas encore chargé
		await get_tree().create_timer(0.1).timeout
		connect_player_signal()

func _on_game_over():
	# Affiche le score final dans la console
	print("Game Over! Score final: ", score)
	
	# Optionnel : Arrêter le timer de score si nécessaire
	$ScoreTimer.stop()
	
	# Optionnel : Afficher un message à l'écran
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER\nScore final: " + str(score)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 - 50)
	add_child(game_over_label)
