extends Node

@onready var ennemi_scene = preload("res://scenes/ennemi.tscn")
@export var max_ennemis_per_diagonal: int = 1
@export var spawn_interval: float = 0.5
@export var wave_interval: float = 3.0
@export var wave_size: int = 2
@export var min_distance_between_enemies: float = 150.0
@export var safe_route_guarantee: bool = true

var current_ennemis = []
var can_spawn: bool = true
var last_spawn_times = {1: 0.0, 2: 0.0, 3: 0.0}
var spawn_cooldown: float = 2.0
var game_time: float = 0.0

func _ready():
	connect_player_signal()
	start_wave_spawner()

func _process(delta):
	game_time += delta

func connect_player_signal():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.game_over.connect(_on_player_died)

func _on_player_died():
	can_spawn = false
	
	for ennemi in current_ennemis:
		if is_instance_valid(ennemi):
			ennemi.queue_free()
	current_ennemis.clear()

func start_wave_spawner():
	while can_spawn:
		current_ennemis = current_ennemis.filter(func(e): return is_instance_valid(e))
		
		var enemies_to_spawn = calculate_safe_spawn_count()
		
		for i in range(enemies_to_spawn):
			if not can_spawn:
				break
			
			var diagonal_to_use = get_safe_diagonal_to_spawn()
			if diagonal_to_use != -1:
				spawn_ennemi(diagonal_to_use)
				last_spawn_times[diagonal_to_use] = game_time
			
			await get_tree().create_timer(spawn_interval).timeout
		
		await get_tree().create_timer(wave_interval).timeout

func calculate_safe_spawn_count() -> int:
	var active_diagonals = get_active_diagonals()
	var max_safe_spawns = max(1, active_diagonals.size() - 1)
	
	var available_slots = 0
	for diagonal in [1, 2, 3]:
		if get_enemies_on_diagonal(diagonal) < max_ennemis_per_diagonal:
			available_slots += 1
	
	return min(wave_size, max_safe_spawns, available_slots)

func get_active_diagonals() -> Array:
	var active = []
	for diagonal in [1, 2, 3]:
		if get_enemies_on_diagonal(diagonal) == 0:
			active.append(diagonal)
	return active

func get_enemies_on_diagonal(diagonal_type: int) -> int:
	return current_ennemis.filter(
		func(e): return is_instance_valid(e) and e.diagonal_type == diagonal_type
	).size()

func get_safe_diagonal_to_spawn() -> int:
	var available_diagonals = []
	
	for diagonal in [1, 2, 3]:
		if get_enemies_on_diagonal(diagonal) >= max_ennemis_per_diagonal:
			continue
		
		if game_time - last_spawn_times[diagonal] < spawn_cooldown:
			continue
		
		if not has_sufficient_distance(diagonal):
			continue
		
		available_diagonals.append(diagonal)
	
	if safe_route_guarantee:
		var free_diagonals = get_active_diagonals()
		if free_diagonals.size() <= 1 and available_diagonals.size() > 0:
			return -1
	
	if available_diagonals.size() == 0:
		return -1
	
	available_diagonals.sort_custom(func(a, b): return last_spawn_times[a] < last_spawn_times[b])
	return available_diagonals[0]

func has_sufficient_distance(diagonal_type: int) -> bool:
	for enemy in current_ennemis:
		if not is_instance_valid(enemy):
			continue
		
		if enemy.diagonal_type == diagonal_type:
			var start_positions = {
				1: Vector2(360, 640),
				2: Vector2(360, 431.7),
				3: Vector2(242.8, 640)
			}
			
			var spawn_pos = start_positions[diagonal_type]
			var distance = enemy.position.distance_to(spawn_pos)
			
			if distance < min_distance_between_enemies:
				return false
	
	return true

func spawn_ennemi(diagonal_type: int):
	if not can_spawn:
		return
	
	if get_enemies_on_diagonal(diagonal_type) >= max_ennemis_per_diagonal:
		return
	
	var new_ennemi = ennemi_scene.instantiate()
	new_ennemi.diagonal_type = diagonal_type
	add_child(new_ennemi)
	current_ennemis.append(new_ennemi)
	
	new_ennemi.tree_exited.connect(_on_ennemi_destroyed.bind(diagonal_type), CONNECT_ONE_SHOT)

func _on_ennemi_destroyed(diagonal_type: int):
	if not can_spawn:
		return
	
	current_ennemis = current_ennemis.filter(func(e): return is_instance_valid(e))
	
	await get_tree().create_timer(2.0).timeout
	
	if can_spawn and get_enemies_on_diagonal(diagonal_type) == 0:
		if game_time - last_spawn_times[diagonal_type] > spawn_cooldown:
			if has_sufficient_distance(diagonal_type):
				var active_diagonals = get_active_diagonals()
				if active_diagonals.size() > 1 or not safe_route_guarantee:
					spawn_ennemi(diagonal_type)
