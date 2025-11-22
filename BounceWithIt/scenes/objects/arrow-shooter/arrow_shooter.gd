extends RigidBody2D

@onready var arrow = preload("res://scenes/objects/arrow-shooter/projectile.tscn")	# precarico la scena del proiettile
@onready var muzzle: Marker2D = $Muzzle	# collego il mirino ad una variabile
@onready var cooldown: Timer = $Cooldown	# collego il timer ad una variabile
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D	# collego l'audio ad una variabile
@export var var_time: float = 2.0	# esporto il tempo tra un colpo e l'altro cosi' da renderlo facilmente modificabile per ogni istanza
@export var proj_speed: float = 120.0	# esporto il la velocite' del colpo cosi' da renderlo facilmente modificabile per ogni istanza

func _ready() -> void:
	$AnimatedSprite2D.play("idle")	# riproduco "idle"
	freeze = true	# non applico la gravita'
	cooldown.autostart = true	# modifico il timer
	cooldown.wait_time = var_time


func _on_cooldown_timeout() -> void:
	$AnimatedSprite2D.play("shoot")	# quando scade il timer, riproduco l'animazione


func _on_animated_sprite_2d_animation_finished() -> void:
	# alla fine dell'animazione sparo il colpo, riproduco il suono e ritorno in idle
	shoot()
	audio.play()
	$AnimatedSprite2D.play("idle")

func shoot() -> void:
	var temp_arrow = arrow.instantiate()	# istanzio un colpo
	temp_arrow.global_transform = muzzle.global_transform	# li do la posizione del mirino
	temp_arrow.speed = proj_speed	# li do la velocità impostata
	get_tree().current_scene.add_child(temp_arrow)	# la aggiungo alla scena
