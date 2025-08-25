extends Area2D

@export var base_speed: float = 200.0  # Renommé pour plus de clarté
@export var diagonal_type: int = 1:
	set(value):
		var clamped_value = clamp(value, 1, 3)
		if diagonal_type != clamped_value:
			diagonal_type = clamped_value
			if is_inside_tree():
				setup_ennemi()

@export var rotation_speed: float = 3.0
@export var speed_increase_rate: float = 0.1  # Augmentation de vitesse par seconde
@export var max_speed: float = 500.0  # Vitesse maximale

var current_speed: float = 0.0
# Points de départ modifiés selon vos spécifications
var start_points = {
	1: Vector2(360, 500),
	2: Vector2(360, 350),
	3: Vector2(350, 640)
}

var start_point: Vector2
var end_point: Vector2
var direction: Vector2 = Vector2(-1, -1).normalized()  # Direction diagonale normalisée
var is_active: bool = true
var has_collided: bool = false

func _ready():
	current_speed = base_speed
	setup_ennemi()
	add_to_group("enemies")
	
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	body_entered.connect(_on_body_entered)
	
	# Se connecter au timer de score pour mettre à jour la vitesse
	var score_timer = get_tree().get_first_node_in_group("score_timer")
	if score_timer:
		score_timer.timeout.connect(_on_score_timer_timeout)

func setup_ennemi():
	if diagonal_type not in start_points:
		return
		
	start_point = start_points[diagonal_type]
	
	# Calculer un point de fin basé sur la direction (pour la détection de sortie d'écran)
	# On prend un point très éloigné dans la direction pour s'assurer qu'il sorte de l'écran
	end_point = start_point + direction * 2000
	
	position = start_point
	rotation = direction.angle() + PI / 2
	is_active = true
	has_collided = false
	
	if has_node("Sprite2D"):
		$Sprite2D.rotation = 0

func _physics_process(delta):
	if not is_active:
		return
	
	position += direction * current_speed * delta
	
	if has_node("Sprite2D"):
		$Sprite2D.rotation += rotation_speed * delta
	
	if is_past_end_point():
		handle_destruction()

# Fonction appelée à chaque tick du timer de score
func _on_score_timer_timeout():
	# Augmenter la vitesse progressivement
	current_speed = min(current_speed + speed_increase_rate, max_speed)
	print("Vitesse ennemis augmentée: ", current_speed)  # Debug, à retirer

func is_past_end_point() -> bool:
	# Vérifier si l'ennemi est sorti de l'écran
	var viewport_rect = get_viewport_rect()
	
	# Pour une direction diagonale (-1, -1), on vérifie si l'ennemi est sorti par le haut ou la gauche
	if position.x < -50 or position.y < -50:
		return true
	
	return false

func handle_destruction():
	if not is_active:
		return
		
	is_active = false
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if not is_active or has_collided:
		return
		
	if body.name == "Player" or body.is_in_group("player"):
		has_collided = true
		
		if body.has_method("die"):
			body.call_deferred("die")
		
		handle_destruction()
