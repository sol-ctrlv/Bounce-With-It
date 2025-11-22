extends CharacterBody2D

@export var speed: float = 120.0	# velocita'
@export var offset: int = 250	# distanza percorsa a sinsitra e destra
@export var dir: float = -1	# direzione da cui partire
@export var horizontal: bool = true	# se muoversi orizzontalemente (se falso, si muove in verticale)
var left: float = 0.0	# limite sinistro
var right: float = 0.0	# limite destro


func _ready() -> void:
	if horizontal:	# calcolo i limiti sinistri e destri (che sia in orizzontale o verticale)
		left = global_position.x - offset
		right = global_position.x + offset
	else:
		left = global_position.y - offset
		right = global_position.y + offset
	
func _physics_process(_delta: float) -> void:
	if !$AnimatedSprite2D.is_playing():
		$AnimatedSprite2D.play("idle")	# riproduco l'idle se non c'è nessuna animazione
		
	if horizontal:
		# muovi su X, Y costante
		velocity.x = speed * dir
		velocity.y = 0.0
		move_and_slide()

		if dir > 0 and global_position.x >= right:
			global_position.x = right
			dir = -1
		elif dir < 0 and global_position.x <= left:
			global_position.x = left
			dir = 1
	else:
		# muovi su Y, X costante
		velocity.y = speed * dir
		velocity.x = 0.0
		move_and_slide()

		if dir > 0 and global_position.y >= right:
			global_position.y = right
			dir = -1
		elif dir < 0 and global_position.y <= left:
			global_position.y = left
			dir = 1


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$AnimatedSprite2D.play("hit")
