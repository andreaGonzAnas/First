extends CharacterBody3D

# --- Variables de Interacción ---
@onready var interactable: Area3D = $Interactable
@onready var firstInteract: bool = true
@export var current_dialog_event: String

# --- Variables de UI ---
@export var house_ui_scene: PackedScene 
@export var house_background_image: Texture2D 
var house_instance = null

func _ready():
	interactable.interact = _on_interact
	
func _on_interact():
	# Iniciar el diálogo
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if dialog:
		dialog.call("ShowDialogueCallable", -1, current_dialog_event, self)

# dormir
func House_AttemptSleep():
	#Primero, decir que es de noche
	var game_state = get_node_or_null("/root/GameState")

	if game_state.get("thisRound") >= 4:
		await transition()
		get_tree().change_scene_to_file("res://Scenes/GameScenes/BadFinalCinematic.tscn")
		return

	if game_state:
		game_state.set("isNight", true)
		game_state.next_round()

	# Cambiar de escena
	get_tree().change_scene_to_file("res://Scenes/HouseScene.tscn")


# --- LÓGICA DE CIERRE ---
func set_next_dialog(event_name: String):
	# Siempre reseteamos al diálogo inicial para la próxima vez
	current_dialog_event = "HomeRound1"
	
	# Si el diálogo ha terminado, cerramos la UI
	if event_name == "HomeRound.Success":
		House_AttemptSleep()

func close_house_ui():
	if house_instance:
		house_instance.queue_free()
		house_instance = null

func on_round_update(_round_index: int):
	pass

func transition():
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen:
		transition_screen.call("transition")
		await transition_screen.on_transition_finished
