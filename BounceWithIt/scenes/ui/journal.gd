extends Node
signal updated

var seen_order: Array[String] = []	# ordine di visualizzazione delle chiavi
var pages_by_key: Dictionary = {}	# pagine del dizionario 

func add_page(key: String, page: String) -> void:	# passo chiave e pagina
	var text: Array = pages_by_key.get(key, [])	# prendo il testo della chiave (vedendo se c'è l'ho già nel dizionario)
	if text.is_empty():	# se non c'è
		seen_order.append(key)	# aggiungo la chiave all'array di chiavi
	text.append(page)	# inserisco la pagina passata come parametro
	pages_by_key[key] = text	# salvo la pagina alla chiave
	updated.emit()	# faccio l'update

func last_key() -> String:
	return "" if seen_order.is_empty() else seen_order.back()	# invio l'ultima chiave nell'array
