extends Control

var score = 0

func _ready():
	update_score()
	connect_player_signal()
	
	# Ajouter le timer au groupe pour qu'il soit accessible
	$ScoreTimer.add_to_group("score_timer")

func update_score():
	$ScoreLabel.text = str(score)

func _on_score_timer_timeout() -> void:
	score += 10
	update_score()

func connect_player_signal():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.game_over.connect(_on_game_over)

func _on_game_over():
	$ScoreTimer.stop()
	
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER\nScore final: " + str(score)
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 - 50)
	add_child(game_over_label)
