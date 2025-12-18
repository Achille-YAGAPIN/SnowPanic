extends CharacterBody2D

signal game_over

@export var step_distance: float = 75.0
@export var max_steps: int = 1
@export var swipe_angle_tolerance: float = 30.0

const MIN_SWIPE_DISTANCE: int = 50

var current_index: int = 0
var is_alive: bool = true
var base_position: Vector2
var touch_start_position: Vector2

func _ready() -> void:
	add_to_group("player")
	base_position = position

func _physics_process(_delta: float) -> void:
	if not is_alive:
		return
	
	handle_keyboard_input()

func _input(event: InputEvent) -> void:
	if not is_alive:
		return
	
	handle_touch_input(event)

func handle_keyboard_input() -> void:
	if Input.is_action_just_pressed("ui_right"):
		try_move(1)
	elif Input.is_action_just_pressed("ui_left"):
		try_move(-1)

func handle_touch_input(event: InputEvent) -> void:
	if event is not InputEventScreenTouch:
		return
	
	if event.pressed:
		touch_start_position = event.position
	else:
		handle_swipe(event.position)

func handle_swipe(end_position: Vector2) -> void:
	var swipe_vector := end_position - touch_start_position
	
	if swipe_vector.length() < MIN_SWIPE_DISTANCE:
		return
	
	var angle := rad_to_deg(swipe_vector.angle())
	
	if is_swipe_up_right(angle):
		try_move(1)
	elif is_swipe_down_left(angle):
		try_move(-1)

func is_swipe_up_right(angle: float) -> bool:
	return abs(angle + 45.0) <= swipe_angle_tolerance

func is_swipe_down_left(angle: float) -> bool:
	return abs(angle - 135.0) <= swipe_angle_tolerance
func try_move(direction: int) -> void:
	if not can_move(direction):
		return
	
	current_index += direction
	update_position()

func can_move(direction: int) -> bool:
	var next_index := current_index + direction
	return next_index >= -max_steps and next_index <= max_steps

func update_position() -> void:
	position = base_position + Vector2(
		current_index * step_distance,
		-current_index * step_distance
	)

func die() -> void:
	if not is_alive:
		return
	
	is_alive = false
	game_over.emit()
	play_death_animation()

func play_death_animation() -> void:
	var tween := create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
