extends CharacterBody3D

@onready var interactable: Area3D = $Interactable

@export var current_dialog_event: String

func _ready() -> void:
    # conectar función de interacción
    interactable.interact = _on_interact

func _on_interact() -> void:
    # dialog
    var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
    
    if !dialog:
        print("Error: DialogueManager no encontrado en", name)
        return

    dialog.call("ShowDialogueCallable", -1, current_dialog_event, self)

func set_next_dialog(event_name: String):
    current_dialog_event = event_name
    print(name, " actualizó su diálogo a: ", current_dialog_event)
