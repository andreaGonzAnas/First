extends CharacterBody3D

@onready var interactable: Area3D = $Interactable
@onready var firstInteract: bool

@export var current_dialog_event: String
@export var build_name: String


func _ready()->void:
	interactable.interact = _on_interact
	firstInteract = true
func _on_interact() -> void:
	
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if !dialog:
		print("Error: DialogueManager no encontrado")
		return

	dialog.call("ShowDialogueCallable", -1, current_dialog_event, self)

	if firstInteract:
		#--- PRIMERA VEZ ---
		firstInteract = false
		
		var game_state = get_node_or_null("/root/GameState")
		
		if !game_state.has_interacted_object(build_name):
			game_state.register_interact_object(build_name)
			game_state.changeActivity(1)
			var analytics = get_node_or_null("/root/Analytics")
			if analytics:
				analytics.get_interactable("Fountain").interacted({
				"stat_change": "activity +1",
				"current_activity": game_state.get("activity")
			})
		
func set_next_dialog(event_name: String):
	if firstInteract:
		firstInteract = false
	current_dialog_event = event_name

			
func on_round_update(round_index: int) -> void:
	if round_index > 0:
		# Comprobar que se ha visto
		var game_state = get_node_or_null("/root/GameState")
		if !game_state.visited_buildings_history.has(build_name):
			game_state.changeActivity(-1)
	elif round_index == 0:
		firstInteract = true
