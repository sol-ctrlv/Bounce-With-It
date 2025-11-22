extends Node

signal display_dialog(key: String, character: String)	# creo il segnale per visualizzare il dialogo
signal menu_toggled(open: bool)	# creo il segnale per mostrare il menu di pausa


func show(key: String) -> void:
	display_dialog.emit(key)
