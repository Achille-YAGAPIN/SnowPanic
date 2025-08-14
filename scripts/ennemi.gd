extends Area2D

@export var speed: float = 200.0
@export var diagonal_type: int = 1:
	set(value):
		diagonal_type = clamp(value, 1, 3)
		if is_inside_tree(): # S'assurer que le node est prêt
			setup_ennemi()
@export var respawn_delay: float = 1.0

var diagonals = {
	1: [Vector2(360, 640), Vector2(0, 0)],   # Bas gauche
	2: [Vector2(360, 431.7), Vector2(117.2, 0)], # Haut droite
	3: [Vector2(242.8, 640), Vector2(0, 208.3)],      # Droite horizontale (ajouté)
}

var start_point: Vector2
var end_point: Vector2
var direction: Vector2
var is_active: bool = true

func _ready():
	setup_ennemi()
	print("Enemy created (diagonal ", diagonal_type, ")")
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)

func setup_ennemi():
	start_point = diagonals[diagonal_type][0]
	end_point = diagonals[diagonal_type][1]
	direction = (end_point - start_point).normalized()
	position = start_point
	rotation = direction.angle() + PI / 2
	is_active = true

func _physics_process(delta):
	if not is_active:
		return
		
	position += direction * speed * delta

	if is_past_end_point():
		handle_destruction()

func is_past_end_point() -> bool:
	var threshold = 5.0  # Petite marge pour éviter les problèmes de précision
	
	if direction.x > 0 and position.x > end_point.x - threshold:
		return true
	elif direction.x < 0 and position.x < end_point.x + threshold:
		return true
	if direction.y > 0 and position.y > end_point.y - threshold:
		return true
	elif direction.y < 0 and position.y < end_point.y + threshold:
		return true
	return false

func handle_destruction():
	is_active = false
	var parent = get_parent()
	if parent != null and parent.has_method("spawn_ennemi"):
		parent.call_deferred("spawn_ennemi", diagonal_type)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
		
	if body.name == "Player" or body.is_in_group("player"):
		# Appeler la fonction die() du joueur
		if body.has_method("die"):
			body.call_deferred("die")
		print("Le joueur a été touché par l'ennemi !")
		handle_destruction()
