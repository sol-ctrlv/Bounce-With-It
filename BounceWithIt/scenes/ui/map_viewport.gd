extends SubViewport

var player: CharacterBody2D 	# identifico il giocatore
@onready var camera: Camera2D = $Camera2D	 # collego la camera

func _ready() -> void:
	world_2d = get_tree().root.world_2d	# salvo il mondo come quello della scena attuale
	player = get_tree().get_first_node_in_group("player")	# salvo il giocatore


func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.position = player.position	# imposto la posizione della camera a quella del giocatore
