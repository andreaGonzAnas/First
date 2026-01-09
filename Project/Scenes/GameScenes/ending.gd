extends Control

# --- CONFIGURACIÓN ---
@export_enum("good", "bad") var ending_type: String = "good"
@export var main_menu_scene: String = "res://Menus/MainMenu.tscn" 

func _ready():
	var video_player = $VideoStreamPlayer
	MusicManager.stop_music()
	if(MusicManager.is_muted()):
		video_player.volume_db = -80.0
	else:
		video_player.volume_db = -30.0
	# Aseguramos que la señal esté conectada
	if not video_player.finished.is_connected(_on_VideoStreamPlayer_finished):
		video_player.finished.connect(_on_VideoStreamPlayer_finished)
	
	video_player.play()

	var endname = ""
	var is_success = false
	
	if ending_type == "good":
		endname = "Final_Bueno"
		is_success = true
	else:
		endname = "Final_Malo"
		is_success = false

	# --- ANALÍTICAS ---
	var final_data = {
		"ending_name": endname,
		"final_moral": GameState.moral,
		"final_activity": GameState.activity
	}
	
	Analytics.get_completable("Game_Session").completed(is_success, 0, final_data)

func _on_VideoStreamPlayer_finished():
	# ACTUALIZAR GAMESTATE
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.end_reached = ending_type
	else:
		print("Error: No se encuentra GameState para guardar el final.")

	# VOLVER AL MENÚ
	get_tree().change_scene_to_file(main_menu_scene)
