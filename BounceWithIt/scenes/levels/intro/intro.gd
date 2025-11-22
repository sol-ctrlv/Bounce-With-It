extends CanvasLayer

@export_file("*.json") var scene_text_file: String	# path per il json con il testo

var scene_text: Dictionary = {}	# testo della scena
var selected_text: Array = []	# testo selezionato
var in_progress: bool = false	# flag per indicare se il testo è in progresso

@export var typewriter_time: float = 0.5  # secondi per far apparire la frase
var typing: bool = false	# flag per indicare se sta scrivendo
var tween: Tween	# usato per gestire l'animazione

@onready var background: Control = $PanelContainer/HSplitContainer	# collegamento al background
@onready var text_label: Label = $PanelContainer/HSplitContainer/NinePatchRect/TextLabel	# collegamento alla casella di testo

func _enter_tree() -> void:
	SignalBus.display_dialog.connect(on_display_dialog)	# connetto il segnale per mostrare il dialogo


func _ready() -> void:
	scene_text = _load_scene_text()	# carico il file del testo
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.display_dialog.emit("Intro", "gary")	# mostro il dialogo del testo con chiave "Intro" parlato da "gary"


func _load_scene_text() -> Dictionary:	# carico il file e lo memorizzo come dizionario
	if scene_text_file.is_empty():
		push_error("scene_text_file non impostato")
		return {}
	
	if not FileAccess.file_exists(scene_text_file):
		push_error("File non trovato: %s" % scene_text_file)
		return {}
	
	var text: String = FileAccess.get_file_as_string(scene_text_file)
	var data: Variant = JSON.parse_string(text)
	
	if data is Dictionary:
		return data as Dictionary
	
	push_error("JSON non valido in %s" % scene_text_file)
	return {}


func on_display_dialog(text_key: String, _character: String) -> void:
	var text: Variant = scene_text.get(text_key, null)	# memorizzo il testo in corrispondenza della chiave "text_key"
	if text is Array:
		selected_text = (text as Array).duplicate()	# duplico il testo
		in_progress = true	# attivo il flag
		_show_text()	# inizio a mostrare il testo
	else:
		push_warning("Chiave '%s' non trovata nel JSON." % text_key)


func _show_text() -> void:
	_run_typewriter(str(selected_text.pop_front()))	# rimuovo il primo elemento dell'array e lo mostro con l'effetto typewriter


func _run_typewriter(text: String) -> void:
	if is_instance_valid(tween):	# se c'è già un altro tween, lo elimino e deistanzio
		tween.kill()
		tween = null
	
	typing = true
	text_label.visible_ratio = 0.0
	text_label.text = text	# imposto il testo passato come paramestro
	
	tween = get_tree().create_tween()	# creo l'animazione
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # continua anche se metti in pausa il gioco
	tween.tween_property(text_label, "visible_ratio", 1.0, max(typewriter_time, 0.001))	# incremento il rateo di visibilità di 0.001 fino al 1.0
	tween.finished.connect(func ():
		typing = false
	)	# quando finisco, chiudo il flag


func _next_line() -> void:
	if selected_text.is_empty():
		_finish()	# se non c'è testo, concludo
	else:
		_show_text()	# altrimenti continuo a fare il pop


func _finish() -> void:
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/levels/first_level/first_level.tscn")	# avvio il primo livello


func _input(event: InputEvent) -> void:
	if not in_progress:
		return
		
	if event.is_action_pressed("accept"):	# se premo "accept" vado alla prossima linea
		if typing:
			return
		_next_line()
