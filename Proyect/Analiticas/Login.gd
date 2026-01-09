extends Control

@onready var line_edit = $VBoxContainer/CanvasLayer/InputID
@onready var login_button = $VBoxContainer/CanvasLayer/BtnEnter
@onready var status_label = $VBoxContainer/CanvasLayer/ErrorLabel

var game_scene_path = "res://Menus/MainMenu.tscn"

func _ready():
	login_button.pressed.connect(_on_login_button_pressed)
	login_button.disabled = false
	status_label.text = "Introduce tu ID."
	status_label.modulate = Color.WHITE
	line_edit.grab_focus()

func _on_login_button_pressed():
	var input_text = line_edit.text
	if input_text.is_empty():
		status_label.text = "Por favor, escribe algo."
		status_label.modulate = Color.RED
		return

	var is_valid = Analytics.check_user_login(input_text)
	
	if is_valid:
		status_label.text = "Accediendo..."
		status_label.modulate = Color.GREEN
		login_button.disabled = true
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file(game_scene_path)
	else:
		status_label.text = "ID incorrecto. Inténtalo de nuevo."
		status_label.modulate = Color.RED
		line_edit.grab_focus()