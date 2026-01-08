extends Node2D
class_name BarCustomer

# SEÑALES
signal customer_clicked(node)
signal client_left(penalty)
signal client_served(gain) # Agregada señal served que usa el juego principal

# REFERENCIAS
@onready var body_sprite = $BodySprite
@onready var order_icon = $Bubble/Icon

# CAMBIO: Ahora buscamos el nodo "Button"
@onready var click_button = $CanvasLayer/Button 

# VARIABLES
var wanted_drink: String = ""
var total_time: float = 10.0
var current_time: float = 0.0
var is_active: bool = false
var original_pos: Vector2

func _ready():
	set_process(false)
	if body_sprite: original_pos = body_sprite.position
	
	# CONEXIÓN DE SEÑAL
	if click_button:
		# Desconectar si ya estaba conectado para evitar duplicados
		if click_button.pressed.is_connected(_on_button_pressed):
			click_button.pressed.disconnect(_on_button_pressed)
		
		click_button.pressed.connect(_on_button_pressed)
	else:
		print("ERROR: No se encuentra el nodo 'Button' en cliente.tscn")

func SetupCustomer(drink_name: String):
	wanted_drink = drink_name
	
	# Cargar icono
	var path = "res://Assets/Finales/" + drink_name + "_icon.png"
	var tex = load(path)
	if tex and order_icon:
		order_icon.texture = tex
	
	current_time = total_time
	is_active = true
	set_process(true)

func _process(delta):
	if not is_active: return
	
	current_time -= delta
	var ratio = current_time / total_time
	
	# Feedback visual
	if ratio < 0.3:
		body_sprite.modulate = Color(1, ratio * 3, ratio * 3) # Rojo
	
	if ratio < 0.15:
		body_sprite.position = original_pos + Vector2(randf_range(-2, 2), randf_range(-2, 2))
	else:
		body_sprite.position = original_pos

	if current_time <= 0:
		_leave(true)

# FUNCIÓN QUE RECIBE EL CLICK DEL BOTÓN
func _on_button_pressed():
	if is_active:
		print("Cliente clickado: ", wanted_drink)
		emit_signal("customer_clicked", self)

func TryServe(drink_given: String) -> bool:
	if not is_active: return false
	
	if drink_given == wanted_drink:
		_leave(false) # Se va feliz
		return true
	else:
		# Feedback error
		var tween = create_tween()
		tween.tween_property(body_sprite, "scale", Vector2(1.2, 0.8), 0.1)
		tween.tween_property(body_sprite, "scale", Vector2(1, 1), 0.1)
		return false

func _leave(angry: bool):
	is_active = false
	if click_button: 
		click_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var penalty = 10 if angry else 0
	
	# Emitir la señal correcta dependiendo del resultado
	if angry:
		emit_signal("client_left", penalty)
	else:
		emit_signal("client_served", 10) # Puntos por servir bien
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)