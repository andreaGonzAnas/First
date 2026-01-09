extends CharacterBody3D

# --- Configuración ---
@export var ui : CanvasLayer

@export var minigame_scene: PackedScene
@export var reward_amount: int = 25

@export var allowed_round: int = 0
@export var dialog_closed: String = "Hairdresser_Closed"
@export var dialog_intro: String = "Hairdresser_Intro"
@export var dialog_already_played: String = "Minigame_AlreadyPlayed"

# --- Variables Internas ---
@onready var interactable: Area3D = $Interactable
var current_instance = null
var game_state
var has_played: bool = false

func _ready():
	interactable.interact = _on_interact
	game_state = get_node_or_null("/root/GameState")

func _on_interact():
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if !dialog or !game_state: return

	if game_state.thisRound != allowed_round:
		dialog.call("ShowDialogueCallable", -1, dialog_closed, self)
		return

	if has_played:
		dialog.call("ShowDialogueCallable", -1, dialog_already_played, self)
		return

	dialog.call("ShowDialogueCallable", -1, dialog_intro, self)

func set_next_dialog(event_name: String):
	if event_name == "Start_Minigame":
		start_minigame()
		
func Start_Minigame():
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if dialog:
		dialog.canvas.visible = false 
	start_minigame()

func start_minigame():
	if current_instance == null and minigame_scene:
		current_instance = minigame_scene.instantiate()
		get_tree().get_root().add_child(current_instance)
		
		# Ocultar HUD normal
		if ui: ui.call("SetHUD_Minigame")
		
		if current_instance.has_signal("minigame_finished"):
			current_instance.minigame_finished.connect(_on_minigame_finished)

		# --- ANALYTICS: INICIO DE MINIJUEGO ---
		var analytics = get_node_or_null("/root/Analytics")
		if analytics:
			# Usamos el nombre del nodo como ID
			analytics.get_completable("Minigame_" + self.name).initialized()
	

func _on_minigame_finished(success_count: int, total_count: int):
	
	has_played = true

	# limpiar
	if current_instance:
		current_instance.queue_free()
		current_instance = null
		if ui: ui.call("SetHUD_Normal")
	
	# porcentaje exito
	var ratio = 0.0
	if total_count > 0:
		ratio = float(success_count) / float(total_count)
	
	# pago
	var final_payment = 0
	var dialog_key = "Minigame_Fail"
	
	if ratio == 1.0: 
		final_payment = reward_amount
		dialog_key = "Minigame_Perfect"
		
	elif ratio > 0.66: 
		final_payment = int(reward_amount * 0.75)
		dialog_key = "Minigame_Good"
		
	elif ratio > 0.33: 
		final_payment = int(reward_amount * 0.40) 
		dialog_key = "Minigame_Regular"
		
	else:
		final_payment = 0 
		dialog_key = "Minigame_Fail"
	
	# Aplicar dinero
	game_state.nMoney += final_payment
	
	game_state.register_job(self.name)

	# Actualizar UI
	if ui: ui.call("UpdateUI")
	
	# --- ANALYTICS: FIN DE MINIJUEGO ---
	var analytics = get_node_or_null("/root/Analytics")
	if analytics and game_state:
		var extra_data = {
			"round_number": game_state.thisRound,
			"clients_happy": success_count,
			"clients_total": total_count
		}
		
		analytics.get_completable("Minigame_" + self.name).completed(true, final_payment, extra_data)

	# Feedback
	var dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	if dialog:
		dialog.call("ForceShowDialogue", dialog_key)

func close_shop_ui():
	if current_instance:
		current_instance.queue_free()
		current_instance = null
		if ui: ui.call("SetHUD_Normal")
