extends CanvasLayer

@export var pause_world: bool = false	# flag per bloccare il mondo durante un dialogo

# collegamenti dei nodi della scena
@onready var menu: Control = %MenuRoot
@onready var help: Button = %HelpButton
@onready var quit: Button = %QuitButton
@onready var map_vp: SubViewport = %MapViewport

var open: bool = false	# flag per controllare se il menu è aperto

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# faccio in modo che i bottoni siano selezionabili
	help.focus_mode = Control.FOCUS_ALL
	quit.focus_mode = Control.FOCUS_ALL

	map_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED	# aggiorno la minimappa solo se il menu è aperto

	_set_open(false, false)  # nascondo all'avvio

	# connetto i pulsanti
	help.pressed.connect(_on_help_pressed)
	quit.pressed.connect(_on_quit_pressed)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):	# se si preme il pulsante di "pausa"
		_set_open(!open)	# si chiude il menu
		get_viewport().set_input_as_handled()
		%HelpLabel.visible = false	# nascono il menu di help
		
	elif e.is_action_pressed("accept"):	# se si preme "accept" 
		var f := get_viewport().gui_get_focus_owner()	# si prende il pulsante che si ha in focus
		if f is Button:
			(f as Button).emit_signal("pressed")  # si esegue il pulsante che si ha in focus
			get_viewport().set_input_as_handled()
			return

func _set_open(value: bool, announce: bool = true) -> void:
	open = value	# si imposta lo stato del menu a value

	# pausa globale oppure solo lock movimento
	if pause_world:
		get_tree().paused = open
	elif announce and SignalBus.has_signal("menu_toggled"):
		SignalBus.menu_toggled.emit(open)

	# imposto la visibilità del menu
	menu.visible = open

	# abilito l'aggiornamento della minimappa
	if map_vp:
		map_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if open else SubViewport.UPDATE_DISABLED

	# focus tastiera sul primo bottone
	if open:
		await get_tree().process_frame
		if is_instance_valid(help):
			help.grab_focus()

func is_open() -> bool:
	return open

func _on_help_pressed() -> void:
	%HelpLabel.visible = true	# mostro la label di help

func _on_quit_pressed() -> void:
	get_tree().quit()	# esco dal gioco
