extends Node

# ATRIBUTOS
# Paneles
var _main_menu_panel: Panel
var _options_panel: Panel
var _blocker: ColorRect

# Referencia al fondo
@onready var _background_rect: TextureRect = $CanvasLayer/MainMenuPanel/TextureRect

# Botones
var _start_button: Button
var _options_button: Button
var _exit_button: Button
var _back_button: Button
var _spanish_button: Button
var _english_button: Button

var _mute_button: TextureButton

# Variable de estado del menú opciones (solo para lógica visual)
var _is_options_menu_open: bool = false

func _ready():
	MusicManager.play_music("res://Assets/Musica/menu.wav")
	
	# Inicializar paneles
	_main_menu_panel = get_node("CanvasLayer/MainMenuPanel")
	_options_panel = get_node("CanvasLayer/OptionsMenuPanel")
	_blocker = get_node("CanvasLayer/blocker")
	
	# Inicializar botones
	_start_button = _main_menu_panel.get_node("VBoxContainer/Start")
	_options_button = _main_menu_panel.get_node("VBoxContainer/Config")
	_exit_button = _main_menu_panel.get_node("VBoxContainer/Exit")
	
	_back_button = _options_panel.get_node("Back")
	_spanish_button = _options_panel.get_node("Spanish")
	_english_button = _options_panel.get_node("English")
	
	_mute_button = _options_panel.get_node("MuteButton")

	# --- BLOQUEO DE TECLADO ---
	# Establecemos el modo de foco a NONE para que solo reaccionen al ratón
	# y las flechas/espacio no hagan nada.
	_start_button.focus_mode = Control.FOCUS_NONE
	_options_button.focus_mode = Control.FOCUS_NONE
	_exit_button.focus_mode = Control.FOCUS_NONE
	_back_button.focus_mode = Control.FOCUS_NONE
	_spanish_button.focus_mode = Control.FOCUS_NONE
	_english_button.focus_mode = Control.FOCUS_NONE
	_mute_button.focus_mode = Control.FOCUS_NONE

	# Conexión de señales
	_start_button.pressed.connect(_on_start_button)
	_options_button.pressed.connect(_on_options_button)
	_exit_button.pressed.connect(_on_exit_button)
	
	_back_button.pressed.connect(_on_back_button)
	_spanish_button.pressed.connect(_on_spanish_button)
	_english_button.pressed.connect(_on_english_button)
	_mute_button.pressed.connect(_on_mute_button)
	
	# Visibilidad paneles inicial
	_main_menu_panel.visible = true
	_options_panel.visible = false
	_blocker.visible = false

	# --- LÓGICA DE CAMBIO DE FONDO SEGÚN EL FINAL ---
	_update_background_based_on_ending()

	# Configuración de audio inicial
	var audio = get_node_or_null("/root/MusicManager")
	if audio:
		if audio.is_muted():
			_mute_button.texture_normal = load("res://Assets/Finales/muted.png")
		else:
			_mute_button.texture_normal = load("res://Assets/Finales/unmuted.png")

	# Resetear estado del juego
	var GameState = get_node_or_null("/root/GameState")
	if GameState:
		GameState.reset_game_state()

func _update_background_based_on_ending():
	var game_state = get_node_or_null("/root/GameState")
	var texture_path = "res://Assets/Finales/FondilloMenuSerios1.png" # Por defecto (none)
	
	if game_state:
		match game_state.end_reached:
			"good":
				texture_path = "res://Assets/Finales/FondilloMenuSerios2.png"
			"bad":
				texture_path = "res://Assets/Finales/FondilloMenuSerios3.png"
			"none", _:
				texture_path = "res://Assets/Finales/FondilloMenuSerios1.png"
	
	var tex = load(texture_path)
	if tex and _background_rect:
		_background_rect.texture = tex
	else:
		print("Error: No se pudo cargar el fondo: ", texture_path)

# --- FUNCIONES DE BOTONES ---

func _on_start_button():
	if not get_tree():
		push_error("GetTree() es null")
		return
		
	get_tree().change_scene_to_file("res://Scenes/HouseScene.tscn")

func _on_options_button():
	_options_panel.visible = true
	_is_options_menu_open = true
	_blocker.visible = true

func _on_exit_button():
	get_tree().quit()

func _on_back_button():
	_main_menu_panel.visible = true
	_options_panel.visible = false
	_is_options_menu_open = false
	_blocker.visible = false

func _on_spanish_button():
	TranslationServer.set_locale("es")

func _on_english_button():
	TranslationServer.set_locale("en")

func _on_mute_button():
	var audio = get_node("/root/MusicManager")
	if audio:
		audio.toggle_mute()
		if audio.is_muted():
			_mute_button.texture_normal = load("res://Assets/Finales/muted.png")
		else:
			_mute_button.texture_normal = load("res://Assets/Finales/unmuted.png")
