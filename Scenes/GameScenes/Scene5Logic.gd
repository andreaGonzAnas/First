extends Node3D

@export var viktor_npc: Node3D 
@export var good_ending_marker: Marker3D 

func _ready():
	await get_tree().process_frame

	MusicManager.play_music("res://Assets/Musica/dia5.wav")
	check_auto_start_event()

func check_auto_start_event():
	var game_state = get_node_or_null("/root/GameState")
	var dialog_manager = get_child(0).get_node_or_null("PruebaDialogo/DialogueManager")
	
	if not game_state or not dialog_manager or not viktor_npc:
		print("Error: Faltan referencias en Scene5Logic")
		return

	# --- CONDICIÓN DEL FINAL BUENO ---
	var moral = int(game_state.get("moral"))
	var activity = int(game_state.get("activity"))
	
	if moral >= 10 and activity > 0:
		# --- LÓGICA DE POSICIONAMIENTO ---
		if good_ending_marker:
			viktor_npc.global_position = good_ending_marker.global_position
			viktor_npc.global_rotation = good_ending_marker.global_rotation
		else:
			print("Advertencia: No has asignado el 'good_ending_marker' en el Inspector.")

		# Forzamos el inicio del diálogo del final bueno
		dialog_manager.call("ShowDialogueCallable", -1, "Npc1.5", viktor_npc)
	else:
		print("Condiciones no cumplidas. Los NPCs se quedan en su sitio original.")
