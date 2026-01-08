extends CharacterBody3D

# --- Variables del Diálogo ---
@onready var interactable: Area3D = $Interactable
@onready var firstInteract: bool = true

@export var ui: CanvasLayer
# --- Variables de la UI de la Tienda ---
@export var shop_ui_scene: PackedScene 
@export var shop_background_image: Texture2D 
var shop_instance = null

# --- Datos de Items por Ronda ---
@export var round_items: Array[ShopItemData] = []

# --- Variables de Referencia ---
var game_state = null
var dialog = null
var player = null

func _ready():
	interactable.interact = _on_interact
	
	# Obtener referencias clave una sola vez
	game_state = get_node_or_null("/root/GameState")
	dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")
	player = get_parent().get_node_or_null("Player")

	if !game_state: print("Error: shop.gd no pudo encontrar GameState")
	if !dialog: print("Error: shop.gd no pudo encontrar DialogueManager")
	if !player: print("Error: shop.gd no pudo encontrar Player")
	if(game_state.last_accesory != null):
		if player.has_method("set_player_sprite"):
			player.call("set_player_sprite", game_state.last_accesory)


	
func _on_interact():
	if !game_state or !dialog: return
	var current_round = game_state.thisRound

	# Comprobar si hay item para la ronda
	if current_round < 0 or current_round >= round_items.size():
		var initial_pos: Vector3 = global_position
		global_position = Vector3(100, -40, 0)
		dialog.call("ShowDialogueCallable", -1, "Shop_SoldOut", self)
		global_position = initial_pos
		return

	var item_data: ShopItemData = round_items[current_round]
	var item_id = item_data.item_id
	var dialog_to_show = ""

	# Comprueba en GameState si el item ya se ha comprado
	if game_state.has_bought_item(item_id):
		# Si ya lo tiene, muestra el diálogo de "post-compra"
		dialog_to_show = "Shop_Exit"
	else:
		# Si no lo tiene, muestra el diálogo de compra inicial
		if game_state.get("thisRound") == 4:
			dialog_to_show = "ShopFinal"
		else:
			dialog_to_show = "Shop"

	# Instanciar la UI
	if shop_instance == null and shop_ui_scene:
		shop_instance = shop_ui_scene.instantiate()
		get_tree().get_root().add_child(shop_instance)
		if ui: ui.call("SetHUD_Shop")

		if shop_instance.has_method("set_background"):
			shop_instance.set_background(shop_background_image)
			shop_instance.set_price_in_shop(item_data.cost)
			shop_instance.set_item_in_shop(item_data.itemInShop)
	
	# Llamar al diálogo
	var initial_pos: Vector3 = global_position
	global_position = Vector3(100, -40, 0)
	dialog.call("ShowDialogueCallable", -1, dialog_to_show, self)
	global_position = initial_pos

# --- LÓGICA DE COMPRA ---
func Shop_AttemptPurchase():
	_attempt_purchase(game_state.thisRound)

func _attempt_purchase(round_index: int):
	if !game_state or !dialog or !player:
		return
	
	if round_index < 0 or round_index >= round_items.size():
		return
	
	var item_data: ShopItemData = round_items[round_index]
	var item_id = item_data.item_id
	var item_cost = item_data.cost
	var item_texture = item_data.texture
	
	# Comprobar dinero
	if game_state.nMoney >= item_cost:
		game_state.nMoney -= item_cost
		
		if ui:
			ui.call("UpdateUI")
		
		if player.has_method("set_player_sprite"):
			player.call("set_player_sprite", item_texture)
		
		# --- Registra la compra ---
		game_state.register_bought_item(item_id)
		game_state.last_accesory = item_texture
		
		# --- ANALYTICS: COMPRA ---
		var analytics = get_node_or_null("/root/Analytics")
		if analytics:
			# Registramos una interacción de tipo "purchase"
			analytics.get_interactable("Shop_" + item_id, "market-item").interacted({
				"cost": item_cost,
				"round_number": game_state.thisRound,
				"money_left": game_state.nMoney
			})
		if game_state.thisRound == 4:
			game_state.set_tried_to_buy()
		dialog.call("ForceShowDialogue", "Shop_Success")
	else:
		# No hay dinero suficiente
		if game_state.thisRound == 4:
			game_state.set_tried_to_buy()
			dialog.call("ForceShowDialogue", "Shop_FailFinal")
		else:
			dialog.call("ForceShowDialogue", "Shop_Fail")

func close_shop_ui():
	if shop_instance:
		shop_instance.queue_free()
		shop_instance = null
		if ui: ui.call("SetHUD_Normal")

func on_round_update(round_index: int):
	pass


func Shop_DeclinePurchase():
	# Si es ultimo dia y dices que no, activar misión de trabajar
	if game_state and game_state.thisRound == 4:
		game_state.set_tried_to_buy()
	
		dialog.call("ForceShowDialogue", "Shop_ExitFinal")
