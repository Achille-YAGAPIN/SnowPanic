extends Node

@onready var ennemi_scene = preload("res://scenes/ennemi.tscn")

@export var max_ennemis_per_diagonal: int = 1
@export var spawn_interval: float = 0.5
@export var wave_interval: float = 3.0
@export var wave_size: int = 2
@export var min_distance_between_enemies: float = 150.0
@export var safe_route_guarantee: bool = true

const DIAGONALS = [1, 2, 3]
const START_POSITIONS = {
	1: Vector2(360, 640),
	2: Vector2(360, 431.7),
	3: Vector2(242.8, 640)
}

var current_ennemis: Array = []
var can_spawn: bool = true
var last_spawn_times: Dictionary = {1: 0.0, 2: 0.0, 3: 0.0}
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
	cleanup_all_enemies()

func cleanup_all_enemies():
	for ennemi in current_ennemis:
		if is_instance_valid(ennemi):
			ennemi.queue_free()
	current_ennemis.clear()

func start_wave_spawner():
	while can_spawn:
		cleanup_invalid_enemies()
		spawn_wave()
		await get_tree().create_timer(wave_interval).timeout

func cleanup_invalid_enemies():
	current_ennemis = current_ennemis.filter(func(e): return is_instance_valid(e))

func spawn_wave():
	var enemies_to_spawn = calculate_safe_spawn_count()
	
	for i in range(enemies_to_spawn):
		if not can_spawn:
			break
		
		var diagonal_to_use = get_safe_diagonal_to_spawn()
		if diagonal_to_use != -1:
			spawn_ennemi(diagonal_to_use)
			last_spawn_times[diagonal_to_use] = game_time
		
		await get_tree().create_timer(spawn_interval).timeout

func calculate_safe_spawn_count() -> int:
	var active_diagonals = get_active_diagonals()
	var max_safe_spawns = max(1, active_diagonals.size() - 1)
	
	var available_slots = count_available_slots()
	
	return min(wave_size, max_safe_spawns, available_slots)

func count_available_slots() -> int:
	var count = 0
	for diagonal in DIAGONALS:
		if get_enemies_on_diagonal(diagonal) < max_ennemis_per_diagonal:
			count += 1
	return count

func get_active_diagonals() -> Array:
	return DIAGONALS.filter(
		func(diagonal): return get_enemies_on_diagonal(diagonal) == 0
	)

func get_enemies_on_diagonal(diagonal_type: int) -> int:
	return current_ennemis.filter(
		func(e): return is_instance_valid(e) and e.diagonal_type == diagonal_type
	).size()

func get_safe_diagonal_to_spawn() -> int:
	var available_diagonals = get_available_diagonals()
	
	if safe_route_guarantee and should_block_spawn(available_diagonals):
		return -1
	
	return get_oldest_diagonal(available_diagonals)

func get_available_diagonals() -> Array:
	return DIAGONALS.filter(
		func(diagonal):
			return (get_enemies_on_diagonal(diagonal) < max_ennemis_per_diagonal and
				   game_time - last_spawn_times[diagonal] >= spawn_cooldown and
				   has_sufficient_distance(diagonal))
	)

func should_block_spawn(available_diagonals: Array) -> bool:
	var free_diagonals = get_active_diagonals()
	return free_diagonals.size() <= 1 and available_diagonals.size() > 0

func get_oldest_diagonal(available_diagonals: Array) -> int:
	if available_diagonals.size() == 0:
		return -1
	
	available_diagonals.sort_custom(func(a, b): return last_spawn_times[a] < last_spawn_times[b])
	return available_diagonals[0]

func has_sufficient_distance(diagonal_type: int) -> bool:
	for enemy in current_ennemis:
		if not is_instance_valid(enemy) or enemy.diagonal_type != diagonal_type:
			continue
		
		var spawn_pos = START_POSITIONS[diagonal_type]
		if enemy.position.distance_to(spawn_pos) < min_distance_between_enemies:
			return false
	
	return true

func spawn_ennemi(diagonal_type: int):
	if not can_spawn or get_enemies_on_diagonal(diagonal_type) >= max_ennemis_per_diagonal:
		return
	
	var new_ennemi = ennemi_scene.instantiate()
	new_ennemi.diagonal_type = diagonal_type
	add_child(new_ennemi)
	current_ennemis.append(new_ennemi)
	
	new_ennemi.tree_exited.connect(
		_on_ennemi_destroyed.bind(diagonal_type),
		CONNECT_ONE_SHOT
	)

func _on_ennemi_destroyed(diagonal_type: int):
	if not can_spawn:
		return
	
	cleanup_invalid_enemies()
	await get_tree().create_timer(2.0).timeout
	
	if can_spawn and should_respawn(diagonal_type):
		spawn_ennemi(diagonal_type)

func should_respawn(diagonal_type: int) -> bool:
	return (get_enemies_on_diagonal(diagonal_type) == 0 and
		   game_time - last_spawn_times[diagonal_type] > spawn_cooldown and
		   has_sufficient_distance(diagonal_type) and
		   (get_active_diagonals().size() > 1 or not safe_route_guarantee))
