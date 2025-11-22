extends AnimatableBody2D

func _process(_delta: float) -> void:
	if !$AnimatedSprite2D.is_playing():	# se non sto riproducendo nessuna animazione
		$AnimatedSprite2D.play("idle")	# riproduco l'idle

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		$AnimatedSprite2D.play("hit")	# riproduco l'animazione di "hit" se si viene colpiti dal giocatore
