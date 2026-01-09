extends CharacterBody3D

# --- Variables de Interacción ---
@onready var interactable: Area3D = $Interactable
var current_dialog_event: String = ""

# --- Variables de UI ---
@export var vote_ui_scene: PackedScene
var vote_instance = null

func _ready():
	interactable.interact = _on_interact
	
func _on_interact():
	var game_state = get_node_or_null("/root/GameState")
	
	if game_state.thisRound == 0:
		# Registrar visita a la urna en el primer día
		game_state.call("register_urn_visit")

		
	# Iniciar diálogo
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if dialog:
		var act_dialog = "VotePlaceRound" + str(game_state.get("thisRound") + 1)
		print("Iniciando diálogo en VotingPlace:", act_dialog)
		dialog.call("ShowDialogueCallable", -1, act_dialog, self)

# --- CALLBACK DEL DIÁLOGO ---
func set_next_dialog(event_name: String):
	# Si el diálogo termina con éxito, abrimos la votación
	if event_name == "Votation.Success":
		open_vote_ui()

# --- GESTIÓN DE LA UI ---
func open_vote_ui():
	if vote_instance == null and vote_ui_scene:
		vote_instance = vote_ui_scene.instantiate()
		add_child(vote_instance)
		print("UI de votación abierta.")
		
		if vote_instance.has_method("open_menu"):
			vote_instance.call("open_menu")

func close_vote_ui():
	# Esta función se llama si sales del menú SIN votar (con el botón Back)
	if vote_instance:
		vote_instance.queue_free()
		vote_instance = null
	
	# Devolver el control al jugador
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set("can_move", true)
		game_state.set("can_interact", true)

func on_round_update(round_index: int):
	pass