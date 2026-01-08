extends Node3D

func _ready():
	var game_state = get_node_or_null("/root/GameState")
	
	var round_num = int(game_state.get("thisRound"))
	
	var name_round = "Scene" + str(round_num)
	
	get_tree().change_scene_to_file("res://Scenes/GameScenes/" + name_round + ".tscn")
	print("ROUND ACTUAL: " + str(round_num))