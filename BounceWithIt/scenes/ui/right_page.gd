extends Control

@export_file("*.json") var thoughts_file: String	# path al file json

@onready var display: RichTextLabel = %DisplayMessage
@onready var thought_lbl: Label     = %Thoughts

var thoughts: Dictionary = {}	# dizionario dei pensieri
var flat: Array[Dictionary] = []	# ogni item: {"key": String, "page": int, "text": String}
var cursor: int = 0	# cursore delle pagine

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	display.focus_mode = Control.FOCUS_ALL	# imposto il focus
	display.autowrap_mode = TextServer.AUTOWRAP_WORD	
	display.get_v_scroll_bar().visible = false	# rendo invisibile la scrollbar
	thought_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD	

	SignalBus.menu_toggled.connect(_on_menu_toggled)	# collego il toggle del menu
	thoughts = _load_json(thoughts_file)	# salvo il file json
	Journal.updated.connect(_rebuild)	# connetto il rebuil e lo rebuildo
	_rebuild()

func _rebuild() -> void:
	# prova a ricordare quale chiave e pagina stavo guardando
	var old_key := ""
	var old_page := 0
	if flat.size() > 0:
		old_key = str(flat[cursor].get("key",""))
		old_page = int(flat[cursor].get("page",0))

	# ricostruisco la lista, per ogni chiave tutte le sue pagine
	flat.clear()
	for key in Journal.seen_order:
		var pages: Array = Journal.pages_by_key.get(key, [])
		for i in pages.size():
			flat.append({
				"key": key,
				"page": i,
				"text": str(pages[i]).strip_edges()
			})

	# riposiziono il cursore
	if flat.size() == 0:
		cursor = 0
		_show_current()
		return
	var found := false
	for i in flat.size():
		var d: Dictionary = flat[i]
		if str(d.get("key","")) == old_key and int(d.get("page",0)) == old_page:
			cursor = i
			found = true
			break
	if not found:
		cursor = clampi(cursor, 0, flat.size() - 1)

	_show_current()

func _show_current() -> void:
	if flat.size() == 0:
		display.text = ""
		thought_lbl.text = ""
		return

	var d: Dictionary = flat[cursor]
	display.bbcode_enabled = false
	display.text = str(d.get("text",""))

	var k: String = str(d.get("key",""))
	thought_lbl.text = str(thoughts.get(k, ""))


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if get_viewport().gui_get_focus_owner() != display:
		return

	if e.is_action_pressed("accept"):	# se premo "accept", muovo il cursore in avanti di uno
		_step(+1)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("back"):	# se premo "back", muovo il cursore indietro di uno
		_step(-1)
		get_viewport().set_input_as_handled()


func _step(delta: int) -> void:
	if flat.size() == 0:
		return
	cursor = (cursor + delta) % flat.size()
	if cursor < 0:
		cursor += flat.size()
	_show_current()


func _on_menu_toggled(open: bool) -> void:
	if open:
		var key := Journal.last_key()	# vado all'ultima chiave
		if key.is_empty() or flat.is_empty():
			return
		for i in flat.size():
			var d: Dictionary = flat[i]	# salvo il dizionario
			if str(d.get("key","")) == key and int(d.get("page",0)) == 0:
				cursor = i
				_show_current()
				await get_tree().process_frame
				display.grab_focus()     # prendo subito il focus della text box
				return


func _load_json(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
		
	var txt := FileAccess.get_file_as_string(path)
	var data : Variant = JSON.parse_string(txt)
	
	return data if data is Dictionary else {}
