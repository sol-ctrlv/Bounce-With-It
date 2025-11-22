extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/intro/intro.tscn")	# se preme "start", faccio partire l'intro


func _on_exit_pressed() -> void:
	get_tree().quit()	# se preme "exit", esco dal gioco
