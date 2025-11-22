extends CanvasLayer

@export_file("*.json") var scene_text_file: String	# path del file al json

var scene_text: Dictionary = {}	# testo della scena
var selected_text: Array = []	# testo selezionato
var in_progress: bool = false	# flag per indicare se è in progresso
var portrait_end: String = ".png"	# estensione dello sprite
var portrait_cache: Dictionary = {}	# # cache dei nomi degli sprite (memorizzo i nomi già incontrati così posso caricarli velocemente)
var current_key: String = ""	# chiave corrente

@export var typewriter_time: float = 0.3  # secondi per andare da 0 a 1
var typing: bool = false	# flag se sta scrivendo
var tween: Tween	# gestione animazione

@onready var background: Control = $PanelContainer/HSplitContainer
@onready var text_label: Label = $PanelContainer/HSplitContainer/NinePatchRect/TextLabel
@onready var portrait: TextureRect = $PanelContainer/HSplitContainer/IconBackground/SpeakerSprite
@onready var portrait_dir: String = "res://assets/talking-sprites/"
@onready var accept_icon = preload("res://assets/tres/accept_key.tres")

func _ready() -> void:
	background.visible = false	# lo rendo invisibile
	scene_text = _load_scene_text()	# carico il file json
	SignalBus.display_dialog.connect(on_display_dialog)	# collego il display_dialog

func _load_scene_text() -> Dictionary:
	if scene_text_file.is_empty():
		push_error("scene_text_file non impostato")
		return {}
	
	if not FileAccess.file_exists(scene_text_file):
		push_error("File non trovato: %s" % scene_text_file)
		return {}
	
	var text: String = FileAccess.get_file_as_string(scene_text_file)	# accedo il file come stringa
	var data: Variant = JSON.parse_string(text)	# riformatto la stringa da json
	
	if data is Dictionary:
		return data as Dictionary
	
	push_error("JSON non valido in %s" % scene_text_file)
	return {}


func on_display_dialog(text_key: String, character: String) -> void:	# quando mostro il dialogo, passo la chiave e il personaggio
	_set_portrait_by_name(character)	# imposto lo sprite del personaggio
	current_key = text_key	# mi salvo la chiave
	
	var text: Variant = scene_text.get(text_key, null)	# salvo il testo rispettivo alla chiave
	if text is Array:
		selected_text = (text as Array).duplicate()	# duplico il testo
		in_progress = true	# imposto il flag
		background.visible = true	# lo rendo visibile
		get_tree().paused = true	# metto in pausa la scena
		_show_text()	# mostro il testo
	else:
		push_warning("Chiave '%s' non trovata nel JSON." % text_key)

func _set_portrait_by_name(name: String) -> void:
	if name.is_empty():	# se è vuoto, esco
		return
	if portrait_cache.has(name):	# se il nome è quello nella cache
		portrait.texture = portrait_cache[name]	# carico lo sprite della cache
		return
	
	var path := portrait_dir.rstrip("/") + "/" + name + portrait_end	# creo il path al file
	if FileAccess.file_exists(path):
		var tex := load(path) as Texture2D	# carico la texture 
		if tex:
			portrait.texture = tex	# la imposto come texture
			portrait_cache[name] = tex	# la salvo nella cache dei nomi
	else:
		push_warning("Portrait non trovato: %s" % path)


func _show_text() -> void:
	var text: String = str(selected_text.pop_front())	# prendo il testo nella prima riga
	Journal.add_page(current_key, text)	# lo aggiungo alla pagina
	_run_typewriter(text)	# lo animo come typewriter


func _run_typewriter(text: String) -> void:
	if is_instance_valid(tween):	# se c'è già un altro tween, lo elimino e deistanzio
		tween.kill()
		tween = null
	
	typing = true
	text_label.visible_ratio = 0.0
	text_label.text = text	# imposto il testo passato come paramestro

	# cancella tween precedente (se esiste)
	if tween and tween.is_valid():
		tween.kill()

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
	text_label.text = ""	# reimposto la il testo della casella
	background.visible = false	# lo rendo invisibile
	in_progress = false	# cambio il flag
	get_tree().paused = false	# riesumo l'albero

func _unhandled_input(event: InputEvent) -> void:
	if not in_progress:
		return
	
	if event.is_action_pressed("accept"):	# se premo "accept" vado alla prossima linea
		if typing:
			return
		_next_line()
		get_viewport().set_input_as_handled()
