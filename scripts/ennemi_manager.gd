# EnemySpawner.gd
extends Node

@onready var ennemi_scene = preload("res://scenes/ennemi.tscn")
@export var max_ennemis: int = 5
@export var spawn_interval: float = 2.0
var current_ennemis = []
var can_spawn: bool = true

func _ready():
	# Connecte le signal du joueur quand il est disponible
	call_deferred("connect_player_signal")
	start_progressive_spawn()

func connect_player_signal():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.game_over.connect(_on_player_died)  # Utilisation du signal game_over
		print("Signal game_over du joueur connecté avec succès")
	else:
		print("Attention : Aucun joueur trouvé dans le groupe 'player'")
func _on_player_died():
	can_spawn = false
	print("Arrêt du spawn des ennemis - Game Over")
	
	# Supprime tous les ennemis existants
	for ennemi in current_ennemis:
		if is_instance_valid(ennemi):
			ennemi.queue_free()
	current_ennemis.clear()

func start_progressive_spawn():
	if not can_spawn:
		return
		
	await get_tree().create_timer(1.0).timeout
	
	for i in range(max_ennemis):
		if not can_spawn:  # Vérifie avant chaque spawn
			break
		spawn_ennemi(i % 5 + 1)
		await get_tree().create_timer(spawn_interval).timeout

func spawn_ennemi(diagonal_type: int):
	if not can_spawn or current_ennemis.size() >= max_ennemis:
		return
		
	var new_ennemi = ennemi_scene.instantiate()
	new_ennemi.diagonal_type = diagonal_type
	add_child(new_ennemi)
	current_ennemis.append(new_ennemi)
	
	# Connexion du signal pour respawn quand l'ennemi est détruit
	new_ennemi.tree_exited.connect(_on_ennemi_destroyed.bind(diagonal_type), CONNECT_ONE_SHOT)
	print("Ennemi spawné : type ", diagonal_type)

func _on_ennemi_destroyed(diagonal_type: int):
	if not can_spawn:
		return
		
	# Nettoie la liste des ennemis invalides
	current_ennemis = current_ennemis.filter(func(e): return is_instance_valid(e))
	
	# Respawn après un délai si le jeu est toujours actif
	var timer = get_tree().create_timer(spawn_interval)
	timer.timeout.connect(
		func():
			if is_inside_tree() and can_spawn:
				spawn_ennemi(diagonal_type),
		CONNECT_ONE_SHOT
	)
