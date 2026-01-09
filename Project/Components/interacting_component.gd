extends Node3D

@onready var interact_lable: Label3D = $InteractLable

var currentInteractions := []
var canInteract := true
var interact_cooldown: float = 0.0

func _input(event: InputEvent) -> void:
	# Si hay cooldown activo, ignoramos cualquier input
	if interact_cooldown > 0:
		return
	
	# Input de interacción normal
	if event.is_action_pressed("Interact") and canInteract and GameState.can_interact:
		if currentInteractions:
			currentInteractions[0].interact.call()

func _process(delta: float) -> void:
	# Reducir el cooldown automáticamente cada frame
	if interact_cooldown > 0:
		interact_cooldown -= delta

	# Lógica visual
	if currentInteractions and canInteract and GameState.can_interact:
		currentInteractions.sort_custom(_sort_by_distance)
		if currentInteractions[0].is_interactable:
			interact_lable.text = currentInteractions[0].interact_name
			interact_lable.show()
	else:
		interact_lable.hide()

func _sort_by_distance(area1, area2):
	var area1_dist = global_position.distance_to(area1.global_position)
	var area2_dist = global_position.distance_to(area2.global_position)
	return area1_dist < area2_dist

func _on_interact_range_area_entered(area: Area3D) -> void:
	currentInteractions.push_back(area)

func _on_interact_range_area_exited(area: Area3D) -> void:
	currentInteractions.erase(area)

# --- FUNCIONES PARA SEÑALES ---
func _on_dialogue_started():
	canInteract = false
	GameState.can_move = false
	interact_lable.hide()

func _on_dialogue_finished():
	canInteract = true
	GameState.can_move = true
	
	# Activamos el cooldown
	interact_cooldown = 0.2
