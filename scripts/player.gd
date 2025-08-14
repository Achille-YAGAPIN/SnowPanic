extends CharacterBody2D

signal game_over

@export var step_distance: float = 75.0
@export var max_steps: int = 1
var current_index: int = 0
var is_alive: bool = true
var base_position: Vector2  # Position d'origine

func _ready():
	add_to_group("player")
	base_position = position  # Sauvegarde la position initiale
	
func _physics_process(_delta):
	if not is_alive:
		return
	if Input.is_action_just_pressed("ui_right") and current_index < max_steps:
		move(1)
	elif Input.is_action_just_pressed("ui_left") and current_index > -max_steps:
		move(-1)

func move(direction: int):
	if not is_alive:
		return
	current_index += direction
	update_position()

func update_position():
	position = base_position + Vector2(
		current_index * step_distance,
		-current_index * step_distance
	)

func die():
	if not is_alive:
		return
		
	is_alive = false
	print("Le joueur est mort - Game Over!")
	emit_signal("game_over")
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(queue_free)
