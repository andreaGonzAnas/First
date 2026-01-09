extends Control

# ATRIBUTOS
var _canvas_layer: CanvasLayer
var _descrip_label: Label
var _favor_button: Button
var _against_button: Button

@export var _possible_descriptions: Array[String]

func _ready():
	# INICIALIZAR ATRIBUTOS
	_canvas_layer = get_node("CanvasLayer")
	var panel = _canvas_layer.get_node("Panel")
	
	_descrip_label = panel.get_node("DescripPanel/Label")
	_favor_button = panel.get_node("FavorButton")
	_against_button = panel.get_node("AgainstButton")
	
	_canvas_layer.visible = false


func _on_favor_pressed():
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set("aFavorVotacion", int(game_state.get("aFavorVotacion")) + 1)
	
	game_state.set("isNight", true)
	game_state.next_round()
	get_tree().change_scene_to_file("res://Scenes/HouseScene.tscn")


func _on_against_pressed():
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set("enContraVotacion", int(game_state.get("enContraVotacion")) + 1)

	game_state.set("isNight", true)
	game_state.next_round()

	get_tree().change_scene_to_file("res://Scenes/HouseScene.tscn")

func _on_back_pressed():
	_canvas_layer.visible = false

func house_sleep():
	var game_state = get_node_or_null("/root/GameState")

	# Cambiar de escena
	get_tree().change_scene_to_file("res://Scenes/HouseScene.tscn")

func open_menu():
	# Inicializar description label
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		var actual_round = int(game_state.get("thisRound"))
		if actual_round < 5 and actual_round < _possible_descriptions.size():
			_descrip_label.text = _possible_descriptions[actual_round]
	_canvas_layer.visible = true

func close_menu():
	_canvas_layer.visible = false
	
	var parent = get_parent()
	if parent and parent.has_method("close_vote_ui"):
		parent.close_vote_ui()
	else:
		push_error("Votation.gd: No se encontró el padre o el método close_vote_ui")
		queue_free()
