extends Area2D

@export var dialogue_key: String	# chiave del dialogo
@export var talking_character: String	# personaggio che sta parlando
@export var trigger_once: bool = true	# imposto il trigger del dialogo

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)	# connetto il trigger

func _on_body_entered(body: Node) -> void:
	if trigger_once and _used:	# se e' gia' stato riprodotto, non lo riproduco
		return
	
	if body.is_in_group("player"):	# se il corpo che e' entrato e' nel "player"
		_used = true
		SignalBus.display_dialog.emit(dialogue_key, talking_character)
		# emetto il segnale per riprodurre il dialogo di chiave "dialogue_key" dal personaggio "talking_character"
