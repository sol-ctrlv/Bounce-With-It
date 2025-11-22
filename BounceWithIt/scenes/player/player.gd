extends CharacterBody2D

# Movimento del giocatore
@export var distance: float = 150.0 	# distanza percorsa dal movimento
@export var bounce_height: float = 75.0	# altezza del salto
@export_range(0,1) var acceleration: float = 0.1	# quanto velocemente accelera 
@export_range(0,1) var deceleration: float = 0.15	# quanto velocemente decelera
@export var jump_force: float = -350.0	# velocita' del rimbalzo
var collided_object: KinematicCollision2D = null	# variabile contenitore per l'oggetto della collisione
var bounce_multiplier: float = 1.0	# moltiplicatore del rimbalzo, si userà 1.0 nel caso non ci sia nessun moltiplicatore nell'oggetto della collisione

# Gestione del codice
var input_dir: float = 0	# usata per memorizzare l'input del giocatore
var input_locked: bool = false	# usata per bloccare l'input quando il menu e' aperto

# Rimbalzo veloce e Wall jump
@onready var _fast_bounce_timer: Timer = $FastBounceTimer	# collego il timer alla variabile
@onready var _wall_dash_timer: Timer = $WallDashTimer	# collego il timer alla variabile
var wall_normal: Vector2	# variabile per memorizzare la normale (direzione) del muro
var consec_wj: float = 1	# usata per diminuire la velocita' di wall jump sullo stesso muro

# Animazioni e suono
@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D	# collego l'animatedSprite alla variabile
@onready var jump: AudioStreamPlayer2D = $AudioStreamPlayer2D	# collego il suono del salto alla variabile
var enable_gravity: bool = false	# usata per attivare la gestione della gravita'


func _physics_process(delta: float) -> void:
	gravity(enable_gravity, delta)	# gestione della gravità
	input_player()	# gestione gli input del giocatore
	move_and_slide()	# gestione del movimento e delle collisioni del giocatore
	update_bounce_multiplier()	# aggiorno il moltiplicatore del rimbalzo in base alla superficie con cui si collide
	bounce()	# gestione dei rimbalzi
	wall_dash()	# gestione del wall dash dal muro


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN	# disabilitp il mouse
	SignalBus.menu_toggled.connect(func(open: bool):	# connetto il segnale del toggle del menu
		input_locked = open)


func gravity(is_enabled: bool, delta: float):	
	# funziona utilizzata per riprodurre l'animazione di spawn
	# non applico la gravita' fintanto che non si conclude l'animazione
	if is_enabled:
		if not is_on_floor():
			velocity += get_gravity() * delta


func _on_animated_sprite_2d_animation_finished() -> void:
	enable_gravity = true


func input_player():
	if input_locked:	# se l'input e' bloccato, mi fermo ed evito di leggere altri input
		velocity.x = move_toward(velocity.x, 0, distance*deceleration)
		return
		
	input_dir = Input.get_axis("left", "right") #left -1, right 1
	if input_dir != 0 and enable_gravity:
		# Mi muovo FROM valore.x, TO direzione * velocità (1 * 300), DELTA (300 * 0.2)
		velocity.x = move_toward(velocity.x, input_dir * distance, distance * acceleration)
		if input_dir == 1:
			animation_player.flip_h = false
		elif input_dir == -1:
			animation_player.flip_h = true
			
	elif input_dir == 0 or input_locked:
		# Questo permette di decelerare facendomi muovere FROM valore.x, TO 0 (fermo), DELTA (300 * 0.1) 
		velocity.x = move_toward(velocity.x, 0, distance * deceleration)


func update_bounce_multiplier():
	bounce_multiplier = 1.0	# rifisso il valore base di 1.0
	# prendo l'ultima collisione del personaggio e se ha una variabile "bounce_multiplier"
	# prendo il suo valore
	var collision: KinematicCollision2D = get_last_slide_collision()
	if collision:
		var collider := collision.get_collider()
		if collider and collider.get("bounce_multiplier") != null:
			bounce_multiplier = collider.get("bounce_multiplier")


func bounce():
	if is_on_floor():	# rimbalzo contro il pavimento
		velocity.y = move_toward(velocity.y, bounce_height, jump_force * bounce_multiplier)
		jump.play()
		# Se il timer (0.3s) non si è fermato, sto rimbalzando avanti e indietro tra due superfici
		# incremento la velocità del rimbalzo
		if _fast_bounce_timer.is_stopped() == false:
			velocity.y *= 2
		
		animation_player.play("bounce_ground")	# riproduco l'animazione
		consec_wj = 1	# resetto il divisore dei rimbalzi consecutivi
		_fast_bounce_timer.start()	# Avvio il timer DOPO che ho fatto il rimbalzo
		
	elif is_on_ceiling():	# rimbalzo contro il soffitto
		velocity.y = move_toward(velocity.y, bounce_height, -jump_force * bounce_multiplier)
		jump.play()
		# Se il timer (0.3s) non si è fermato = sto rimbalzando avanti e indietro tra due superfici
		# incremento la velocità del rimbalzo
		if _fast_bounce_timer.is_stopped() == false:
			velocity.y *= 2
		
		animation_player.play("bounce_ceiling")	# riproduco l'animazione
		consec_wj = 1	# resetto il divisore dei rimbalzi consecutivi
		_fast_bounce_timer.start()	# Avvio il timer DOPO che ho fatto il rimbalzo
		
	elif is_on_wall():	# rimbalzo contro il muro
		wall_normal = get_wall_normal()	# prendo la normale del muro (ossia la sua direzione)
		_wall_dash_timer.start()	# avvio il timer per il wall dash
		
		if wall_normal.x != input_dir:	# se il giocatore si sta muovendo nella stessa direzione del muro
			animation_player.play("bounce_same_wall")
		elif wall_normal.x == input_dir:	# se e' la direzione opposta
			animation_player.play("bounce_wall")
		
		jump.play()
		velocity.y = jump_force * bounce_multiplier / consec_wj
		velocity.x = distance * bounce_multiplier * wall_normal.x
		
		consec_wj += 0.3	# incremento il divisore del rimbalzo consecutivo
		_fast_bounce_timer.start()


func wall_dash():
	if not _wall_dash_timer.is_stopped():	# se il timer non si e' ancora fermato
		input_dir = Input.get_axis("left","right")
		if sign(input_dir) == sign(wall_normal.x):	# se mi sto muovendo lontano dal muro
			animation_player.play("bounce_wall")	#riproduco l'animazionda da un determinato frame
			animation_player.frame = 3
			
			# effettuo il dash
			jump.play()
			velocity.y = jump_force * bounce_multiplier
			velocity.x = distance * bounce_multiplier * 3 * wall_normal.x
			consec_wj = 1	# resetto il divisore
			_wall_dash_timer.stop()	# fermo il timer
