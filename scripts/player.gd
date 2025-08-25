extends CharacterBody2D

signal game_over

@export var step_distance: float = 75.0
@export var max_steps: int = 1
@export var swipe_angle_tolerance: float = 30.0

var current_index: int = 0
var is_alive: bool = true
var base_position: Vector2
var touch_start_position: Vector2

const MIN_SWIPE_DISTANCE: int = 50

func _ready():
	add_to_group("player")
	base_position = position

func _physics_process(_delta):
	if not is_alive: return
	
	if Input.is_action_just_pressed("ui_right") and current_index < max_steps:
		move(1)
	elif Input.is_action_just_pressed("ui_left") and current_index > -max_steps:
		move(-1)

func _input(event):
	if not is_alive: return
	if not event is InputEventScreenTouch: return
	
	if event.pressed:
		touch_start_position = event.position
	else:
		handle_swipe(event.position)

func handle_swipe(end_position: Vector2):
	var swipe_vector = end_position - touch_start_position
	
	if swipe_vector.length() <= MIN_SWIPE_DISTANCE: return
	
	var swipe_angle = rad_to_deg(swipe_vector.angle())
	
	if is_swipe_diagonal_up_right(swipe_angle) and current_index < max_steps:
		move(1)
	elif is_swipe_diagonal_down_left(swipe_angle) and current_index > -max_steps:
		move(-1)

func is_swipe_diagonal_up_right(angle: float) -> bool:
	return abs(angle + 45) <= swipe_angle_tolerance

func is_swipe_diagonal_down_left(angle: float) -> bool:
	return abs(angle - 135) <= swipe_angle_tolerance

func move(direction: int):
	current_index += direction
	update_position()

func update_position():
	position = base_position + Vector2(
		current_index * step_distance,
		-current_index * step_distance
	)

func die():
	if not is_alive: return
	
	is_alive = false
	game_over.emit()
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
