extends Control

signal minigame_finished(success_count: int, total_count: int)

# --- REFERENCIAS DE NODOS ---
@onready var canvas_layer = $CanvasLayer 
@onready var instruction_label = $CanvasLayer/Label
@onready var client_label = $CanvasLayer/ClienteLabel
@onready var tool_cursor = $CanvasLayer/ToolCursor
@onready var client_zone = $CanvasLayer/ClientZone
@onready var video_player = $CanvasLayer/VideoStreamPlayer
@onready var client_background = $CanvasLayer/TextureRect
@onready var stars_container = $CanvasLayer/StarsContainer 

# --- RECURSOS: IMÁGENES DE FONDO ---
var bg_simple_start = preload("res://Assets/Finales/HairMini1.png") 
var bg_full_start = preload("res://Assets/Finales/HairMini2.png")   
var bg_full_washed = preload("res://Assets/Finales/HairMini3.png")  
var bg_full_cut = preload("res://Assets/Finales/HairMini4.png")     
var bg_finished = preload("res://Assets/Finales/HairMini.png")      

# --- RECURSOS: VIDEOS ---
var video_cut_dry = preload("res://Assets/Videos/cut1.ogv") 
var video_cut_wet = preload("res://Assets/Videos/cut2.ogv") 
var video_wash = preload("res://Assets/Videos/wash.ogv")    
var video_dry = preload("res://Assets/Videos/dry.ogv")      

# --- CONSTANTES ---
const TOOL_SCISSORS = "tijeras"
const TOOL_SHAMPOO = "champu"
const TOOL_DRYER = "secador"
const TOOL_SCISSORS_WET = "tijeras_mojado" 
const MAX_ROUNDS = 3

# --- VARIABLES DE ESTADO ---
var rounds_played = 0
var rounds_won = 0
var is_working = false
var current_tool_selected: String = ""
var order_sequence: Array = []
var current_step_index: int = 0

func _ready():
	tool_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.visible = false
	
	if stars_container:
		stars_container.visible = false
		# Centrar el pivote de las estrellas
		for star in stars_container.get_children():
			if star is TextureRect:
				star.pivot_offset = star.size / 2
	
	start_new_round()

func _process(_delta):
	if current_tool_selected != "":
		tool_cursor.global_position = get_global_mouse_position() - (tool_cursor.size / 2)

# --- GESTIÓN DE RONDAS ---
func start_new_round():
	if rounds_played >= MAX_ROUNDS:
		minigame_finished.emit(rounds_won, MAX_ROUNDS)
		return

	rounds_played += 1
	current_step_index = 0
	current_tool_selected = ""
	tool_cursor.visible = false
	
	is_working = false
	client_zone.mouse_filter = Control.MOUSE_FILTER_STOP

	client_background.modulate.a = 1.0
	instruction_label.modulate.a = 1.0
	client_label.modulate.a = 1.0

	if randf() > 0.5:
		order_sequence = [TOOL_SCISSORS]
		client_label.text = "Cliente " + str(rounds_played) + "/" + str(MAX_ROUNDS)
		instruction_label.text = "¡Solo las puntas!"
		client_background.texture = bg_simple_start 
	else:
		order_sequence = [TOOL_SHAMPOO, TOOL_SCISSORS_WET, TOOL_DRYER]
		client_label.text = "Cliente " + str(rounds_played) + "/" + str(MAX_ROUNDS)
		instruction_label.text = "¡Completo! (Lavar, Cortar, Secar)"
		client_background.texture = bg_full_start

# --- SELECCIÓN DE HERRAMIENTAS ---
func _on_cut_pressed(): select_tool(TOOL_SCISSORS, "res://Assets/Finales/tijeras_icon.png")
func _on_wash_pressed(): select_tool(TOOL_SHAMPOO, "res://Assets/Finales/jabon_icon.png")
func _on_dry_pressed(): select_tool(TOOL_DRYER, "res://Assets/Finales/secador_icon.png")

func select_tool(tool_name: String, icon_path: String):
	if is_working: return 
	current_tool_selected = tool_name
	var tex = load(icon_path)
	if tex:
		tool_cursor.texture = tex
		tool_cursor.visible = true

# --- INTERACCIÓN ---
func _on_client_zone_pressed():
	if is_working: return
	if current_tool_selected == "": return

	var step_needed = order_sequence[current_step_index]
	var is_correct = false
	
	if current_tool_selected == step_needed:
		is_correct = true
	elif step_needed == TOOL_SCISSORS_WET and current_tool_selected == TOOL_SCISSORS:
		is_correct = true
	
	if is_correct:
		perform_action_video(step_needed) 
	else:
		fail_round()

# --- VIDEO ---
func perform_action_video(tool_type_needed: String):
	is_working = true
	client_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	instruction_label.text = "Utilizando herramienta..."
	
	current_tool_selected = ""
	tool_cursor.visible = false
	
	var stream_to_play = null
	match tool_type_needed:
		TOOL_SCISSORS: stream_to_play = video_cut_dry
		TOOL_SCISSORS_WET: stream_to_play = video_cut_wet
		TOOL_SHAMPOO: stream_to_play = video_wash
		TOOL_DRYER: stream_to_play = video_dry

	if stream_to_play:
		video_player.stream = stream_to_play
		video_player.visible = true
		video_player.play()
		await video_player.finished 
		video_player.visible = false
	else:
		await get_tree().create_timer(1.0).timeout
	
	complete_step(tool_type_needed)

# --- COMPLETAR PASO ---
func complete_step(tool_just_used: String):
	current_step_index += 1
	
	# actualizar fondo primero
	match tool_just_used:
		TOOL_SHAMPOO: client_background.texture = bg_full_washed 
		TOOL_SCISSORS_WET: client_background.texture = bg_full_cut    
		TOOL_SCISSORS: client_background.texture = bg_finished    
		TOOL_DRYER: client_background.texture = bg_finished    

	# cliente terminado...
	if current_step_index >= order_sequence.size():
		rounds_won += 1
		instruction_label.text = "¡Cliente satisfecho!"
		client_background.texture = bg_finished # Asegurar fondo final
		
		# Bloquear interaccion
		client_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		is_working = true
		
		if stars_container:
			await play_star_animation()
		else:
			await get_tree().create_timer(1.0).timeout
			
		start_new_round()
		
	else:
		# --- CASO INTERMEDIO: NO HAY ESTRELLAS ---
		is_working = false
		client_zone.mouse_filter = Control.MOUSE_FILTER_STOP 
		
		var next_tool = order_sequence[current_step_index]
		var display_text = next_tool.replace("_mojado", "")
		instruction_label.text = "¡Bien! Siguiente paso: " + display_text.to_upper()

# --- ANIMAR ESTRELLAS ---
func play_star_animation():
	stars_container.visible = true
	
	for star in stars_container.get_children():
		star.visible = false
		star.scale = Vector2(0.1, 0.1)
		star.rotation_degrees = -180
	
	for star in stars_container.get_children():
		star.visible = true
		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "scale", Vector2(1, 1), 0.4)
		tween.tween_property(star, "rotation_degrees", 0.0, 0.4)
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.5).timeout
	stars_container.visible = false

# --- ERROR ---
func fail_round():
	is_working = true
	client_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instruction_label.text = "¡Ay! ¡Te has equivocado!"
	client_zone.modulate = Color(1, 0, 0)
	
	var original_offset = canvas_layer.offset
	var shake_tween = create_tween()
	var shake_intensity = 15.0
	var shake_duration = 0.05
	
	for i in range(10):
		var random_x = randf_range(-shake_intensity, shake_intensity)
		var random_y = randf_range(-shake_intensity, shake_intensity)
		shake_tween.tween_property(canvas_layer, "offset", original_offset + Vector2(random_x, random_y), shake_duration)
	
	shake_tween.tween_property(canvas_layer, "offset", original_offset, shake_duration)
	
	await shake_tween.finished
	await get_tree().create_timer(0.5).timeout 
	
	client_zone.modulate = Color(1, 1, 1)
	start_new_round()
