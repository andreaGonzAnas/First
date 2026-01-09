extends CharacterBody3D
@export var final_cutscene_scene: String = "res://Scenes/GoodFinalCinematic.tscn"

# Referencias
@onready var interactable = $Interactable
var game_state

func _ready():
	game_state = get_node_or_null("/root/GameState")
	if interactable:
		interactable.interact = _on_interact

func _on_interact():
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if dialog:
		# Si el jugador hace clic, es porque NO saltó el evento automático
		# así que mostramos el diálogo corto donde se van.
		dialog.call("ShowDialogueCallable", -1, "Npc2.5", self)

func set_next_dialog(event_name: String):
	# Final Bueno
	if event_name == "Npc1.5.1":
		await get_tree().create_timer(0.5).timeout
		await transition()
		get_tree().change_scene_to_file(final_cutscene_scene)
		
	# se queda
	elif event_name == "Npc1.5.2":
		_disappear()

	# Final Malo
	elif event_name == "Npc2.5":
		_disappear()

func _disappear():
	var sprite1 = get_node_or_null("Sprite3D")
	var sprite2 = get_node_or_null("Sprite3D2")
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if sprite1:
		tween.tween_property(sprite1, "modulate:a", 0.0, 1.0)
	
	if sprite2:
		tween.tween_property(sprite2, "modulate:a", 0.0, 1.0)
		
	await tween.finished
	
	# Eliminar el NPC de la escena
	queue_free()


func transition():
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen:
		transition_screen.call("transition")
		await transition_screen.on_transition_finished
