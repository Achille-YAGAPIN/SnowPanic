extends Area2D

@export var base_speed: float = 200.0
@export var diagonal_type: int = 1:
	set(value):
		diagonal_type = clamp(value, 1, 3)
		if is_inside_tree():
			setup_ennemi()

@export var rotation_speed: float = 3.0
@export var speed_increase_rate: float = 0.1
@export var max_speed: float = 500.0

const START_POINTS = {
	1: Vector2(360, 500),
	2: Vector2(360, 350),
	3: Vector2(350, 640)
}

var current_speed: float = 0.0
var start_point: Vector2
var end_point: Vector2
var direction: Vector2 = Vector2(-1, -1).normalized()
var is_active: bool = true
var has_collided: bool = false
var signals_connected: bool = false  # Nouvelle variable pour suivre l'état des connexions

func _ready():
	initialize_enemy()
	connect_signals()

func initialize_enemy():
	current_speed = base_speed
	setup_ennemi()
	add_to_group("enemies")

func connect_signals():
	# Vérifier si les signaux sont déjà connectés
	if not signals_connected:
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
			signals_connected = true
		
		var score_timer = get_tree().get_first_node_in_group("score_timer")
		if score_timer and not score_timer.timeout.is_connected(_on_score_timer_timeout):
			score_timer.timeout.connect(_on_score_timer_timeout)

func setup_ennemi():
	if diagonal_type not in START_POINTS:
		return
	
	start_point = START_POINTS[diagonal_type]
	end_point = start_point + direction * 2000
	
	position = start_point
	rotation = direction.angle() + PI / 2
	is_active = true
	has_collided = false
	
	reset_sprite_rotation()

func reset_sprite_rotation():
	if has_node("Sprite2D"):
		$Sprite2D.rotation = 0

func _physics_process(delta):
	if not is_active:
		return
	
	update_position(delta)
	update_sprite_rotation(delta)
	
	if is_out_of_bounds():
		destroy()

func update_position(delta):
	position += direction * current_speed * delta

func update_sprite_rotation(delta):
	if has_node("Sprite2D"):
		$Sprite2D.rotation += rotation_speed * delta

func is_out_of_bounds() -> bool:
	return position.x < -50 or position.y < -50

func destroy():
	if not is_active:
		return
	
	# Déconnecter les signaux avant de détruire
	if signals_connected:
		signals_connected = false
		if body_entered.is_connected(_on_body_entered):
			body_entered.disconnect(_on_body_entered)
	
	is_active = false
	queue_free()

func _on_score_timer_timeout():
	increase_speed()

func increase_speed():
	current_speed = min(current_speed + speed_increase_rate, max_speed)

func _on_body_entered(body: Node2D):
	if not is_active or has_collided:
		return
	
	if is_player(body):
		handle_player_collision(body)

func is_player(body: Node2D) -> bool:
	return body.name == "Player" or body.is_in_group("player")

func handle_player_collision(body: Node2D):
	has_collided = true
	
	if body.has_method("die"):
		body.call_deferred("die")
	
	destroy()
