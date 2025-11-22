extends RigidBody2D

var speed: float = 0	# velocita' che cambierò in seguito
var original_dir: Vector2 = Vector2.LEFT  # lo sprite neutro guarda a sinistra
var dir: Vector2 = Vector2.ZERO	# direzione del proiettile


func _ready() -> void:
	$AnimatedSprite2D.play("default")	# imposto l'animazione
	
	# abilito le collisioni
	contact_monitor = true
	max_contacts_reported = 5
	dir = original_dir.rotated(global_rotation).normalized()	# imposto la rotazione in base alla direzione che guarda
	

func _physics_process(_delta: float) -> void:
	linear_velocity = speed * dir	# imposto la velocità del proiettile
	if not $AnimatedSprite2D.is_playing():	# se l'animazione si è conclusa
		queue_free()	# lo rimuovo dalla scena

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):	# se collide con un corpo che non è nel gruppo "player"
		speed = speed / 10	# rallento il proiettile
		$AnimatedSprite2D.play("destroy")	# riproduco l'animazione di distruzione
