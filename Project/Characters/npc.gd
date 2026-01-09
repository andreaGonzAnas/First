extends CharacterBody3D

@onready var interactable: Area3D = $Interactable

@export var npc_id: int
@onready var firstInteract: bool
var current_dialog_event: String = ""


func _ready()->void:
	interactable.interact = _on_interact
	var game_state = get_node_or_null("/root/GameState")
	game_state.deregister_interact_object(str(npc_id))
	if !game_state.has_interacted_object(str(npc_id)):
		print("no está en interactuado")
	firstInteract = true
	
func _on_interact() -> void:
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if !dialog:
		print("Error: DialogueManager no encontrado")
		return


	# Llama al diálogo que esté guardado como "actual"
	dialog.call("ShowDialogueCallable", npc_id, "", self)
	if firstInteract:
		firstInteract = false
		var game_state = get_node_or_null("/root/GameState")
		game_state.register_npc_talk(str(npc_id))

		game_state.changeActivity(1)


func on_round_update(round_index: int) -> void:
	if round_index == 0:
		visible = true
		set_process(true)
		if interactable:
			interactable.monitoring = true
			interactable.monitorable = true
		set_collision_layer_value(1, true)
		set_collision_mask_value(1, true)
		firstInteract = true
	else:

		visible = false
		set_process(false)
		if interactable:
			interactable.monitoring = false
			interactable.monitorable = false
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		
		# Comprobar que se ha visto
		var game_state = get_node_or_null("/root/GameState")
		if !game_state.has_interacted_object(str(npc_id)):
			print("en el update, antes de reiniciar se ha interactuado " )
		if !game_state.has_interacted_object(str(npc_id)):
			game_state.changeActivity(-1)
		firstInteract = true

	


func set_next_dialog(event_name: String):
	if firstInteract:
		firstInteract = false
		

	# Actualiza la variable "actual" 
	current_dialog_event = event_name

	# --- AÑADIDO PARA CINEMÁTICA ---
	if has_meta("cinematic_controller"):
		var controller = get_meta("cinematic_controller")
		if controller.has_method("on_dialog_event"):
			controller.on_dialog_event(event_name)


func get_is_first_interact() -> bool:
	return firstInteract
