extends Control

# SEÑAL PARA EL EDIFICIO
signal minigame_finished(success_count: int, total_count: int)

# --- CONFIGURACIÓN ---
@export var customer_scene: PackedScene 
@export var min_spawn_time: float = 2.0 
@export var max_spawn_time: float = 5.0 

# Referencias
@onready var seats_container = $Seats # El nodo que contiene los Marker2D
@onready var spawn_timer = $SpawnTimer
@onready var tool_cursor = $CanvasLayer/ToolCursor
@onready var score_label = $CanvasLayer/Label # Reutilizamos tu label para puntos

# --- VARIABLES ---
var total_game_time: float = 30.0
var score: int = 0
var clients_served_count: int = 0
var total_customers_spawned: int = 0
var game_active: bool = false
var active_customers: Array = []
var available_seats: Array = []

# ESTADO DE LA MANO
var current_held_item: String = "" 

func _ready():
	randomize()
	# Recoger los marcadores de sillas
	if seats_container:
		available_seats = seats_container.get_children()
	
	# Configurar cursor
	tool_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tool_cursor.visible = false
	
	# Configurar Timer
	spawn_timer.one_shot = true
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	StartGame()

func _process(_delta):
	# actualizar tiempo
	total_game_time -= _delta
	if total_game_time <= 0:
			EndGame()

	if game_active:
		# cursor
		if current_held_item != "":
			tool_cursor.visible = true
			tool_cursor.global_position = get_global_mouse_position() - (tool_cursor.size / 2)
		else:
			tool_cursor.visible = false

func StartGame():
	score = 0
	game_active = true
	current_held_item = ""
	
	# Limpiar clientes anteriores
	get_tree().call_group("Customers", "queue_free")
	active_customers.clear()
	
	UpdateScoreUI()
	_spawn_customer()
	_start_next_spawn()

func EndGame():
	game_active = false
	spawn_timer.stop()
	print("Juego terminado. Puntos: ", score)
	tool_cursor.visible = false
	current_held_item = ""
	# El edificio multiplicará esto por el dinero
	emit_signal("minigame_finished", clients_served_count, total_customers_spawned)

# spawnear clientes
func _spawn_customer():
	if not game_active: return
	if customer_scene == null: return
	
	# Buscar silla libre
	var free_seats = []
	for i in range(available_seats.size()):
		var occupied = false
		for c in active_customers:
			if is_instance_valid(c) and c.get_meta("seat_index") == i:
				occupied = true
				break
		if not occupied:
			free_seats.append(i)
	
	# Si hay sitio, crear cliente
	if free_seats.size() > 0:
		var seat_idx = free_seats.pick_random()
		var customer = customer_scene.instantiate()
		
		# Añadirlo al nodo Seats o al Main, pero NO al CanvasLayer
		add_child(customer) 
		customer.global_position = available_seats[seat_idx].global_position
		customer.set_meta("seat_index", seat_idx)
		customer.add_to_group("Customers")
		
		# Bebida aleatoria
		var drinks = ["agua", "zumo", "cafe"]
		customer.SetupCustomer(drinks.pick_random())
		total_customers_spawned += 1
		
		# Conectar señales
		customer.customer_clicked.connect(_on_customer_clicked)
		customer.client_left.connect(_on_client_left.bind(customer))
		
		active_customers.append(customer)

func _start_next_spawn():
	if not game_active: return
	var time = randf_range(min_spawn_time, max_spawn_time)
	spawn_timer.start(time)

func _on_spawn_timer_timeout():
	_spawn_customer()
	_start_next_spawn()

# interacción
func _on_water_pressed(): _equip_drink("agua", "res://Assets/Finales/agua_icon.png")
func _on_juice_pressed(): _equip_drink("zumo", "res://Assets/Finales/zumo_icon.png")
func _on_soda_pressed():  _equip_drink("cafe", "res://Assets/Finales/cafe_icon.png")

func _equip_drink(drink_name: String, icon_path: String):
	if not game_active: return
	current_held_item = drink_name
	var tex = load(icon_path)
	if tex:
		tool_cursor.texture = tex

# en cliente...
func _on_customer_clicked(customer_node):
	if not game_active: return
	
	if current_held_item == "":
		return
	
	# Intentar servir
	var success = customer_node.TryServe(current_held_item)
	
	if success:
		# bebida correcta
		score += 10
		clients_served_count += 1
		current_held_item = "" 
		tool_cursor.visible = false
	else:
		# bebida incorrecta
		score -= 5
	
	UpdateScoreUI()

func _on_client_left(penalty, customer_ref):
	if penalty > 0:
		score -= penalty
	
	if customer_ref in active_customers:
		active_customers.erase(customer_ref)
	
	UpdateScoreUI()

func UpdateScoreUI():
	score_label.text = "Puntos: " + str(score)
