extends CharacterBody3D

@onready var interactable: Area3D = $Interactable
@onready var firstInteract: bool = true

func _ready()->void:
	interactable.interact = _on_interact
	
func _on_interact() -> void:
	
	if firstInteract:
		firstInteract = false  # Evita repetir la interacción inicial

		var player = get_node_or_null("/root/TrialScene/Player")
		if player:
			player.call("change_activity",1)
			

		
		var dialog = get_parent().get_node("PruebaDialogo/DialogueManager")
		if dialog:
			dialog.call("ShowDialogueCallable", "PruebaEvento1", position)
