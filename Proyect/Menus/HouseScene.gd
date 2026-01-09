extends Node3D

# REFERENCIAS
var _parent_npc: Node3D

@export var canvas: CanvasLayer

@export var morning_background: Texture2D
@export var night_background: Texture2D

@export var morning_frames: Array[Texture2D]
@export var morning_delays: Array[float]

@export var night_frames: Array[Texture2D]
@export var night_delays: Array[float]

@export var morning_sfx: Array[AudioStream]
@export var night_sfx: Array[AudioStream]
@export var day_5_sfx: Array[AudioStream]

# Cinemática especial para ronda 5
@export var round5_frames: Array[Texture2D]
@export var round5_delays: Array[float]

@export var barras: Node2D
@export var barra_favor: ColorRect
@export var barra_contra: ColorRect

@export var numeros: Node2D
@export var label_favor: Label
@export var label_contra: Label

# Señal personalizada
signal scene_ended

func _ready():
	_parent_npc = get_node("Parents")
	
	# CallDeferred en GDScript
	call_deferred("start_scene_async")

	barras.visible = false
	numeros.visible = false

func start_scene_async():
	# Mostrar transición al iniciar
	await transition()
	
	var game_state = get_node_or_null("/root/GameState")
	var is_night = false

	#Musica 
	if game_state:
		is_night = game_state.get("isNight")
		
		if is_night:
			# Música de Noche
			MusicManager.play_music("res://Assets/Musica/casa_noche.wav")
		else:
			# Música de Día
			MusicManager.play_music("res://Assets/Musica/casa_dia.wav")

	# Determinar ronda actual
	var current_round = 0
	if game_state:
		var val = game_state.get("thisRound")
		if val != null:
			current_round = int(val)
	
	# Setear fondo
	if canvas:
		canvas.visible = true
		var texture_to_use: Texture2D
		
		if game_state:
			var val = game_state.get("isNight")
			if val != null:
				is_night = bool(val)
		
		if is_night:
			texture_to_use = night_background
		else:
			texture_to_use = morning_background
		
		var panel = canvas.get_node("Panel")
		if panel:
			panel.texture = texture_to_use
		
		if not is_night:
			if current_round == 4:
				await play_round5_cinematic(panel)
				_parent_npc.call("_start_Dialogue")
			else:
				await play_morning_animation(panel)
				_parent_npc.call("_start_Dialogue")
		else:
			await play_night_animation(panel)
			await get_tree().create_timer(3.0).timeout
			if game_state:
				game_state.set("isNight", false)
			get_tree().reload_current_scene()


func end_scene_async():
	if canvas:
		canvas.visible = false
	
	await transition()
	get_tree().change_scene_to_file("res://Scenes/SceneManager.tscn")

func transition():
	var transition_screen = get_node_or_null("/root/TransitionScreen")
	if transition_screen:
		transition_screen.call("transition")
		# Esperar a la señal 'on_transition_finished' del nodo TransitionScreen
		await transition_screen.on_transition_finished

func play_morning_animation(panel: TextureRect):
	if not panel or morning_frames.size() == 0:
		return
	
	for i in range(morning_frames.size()):
		panel.texture = morning_frames[i]
		if i < morning_sfx.size() and morning_sfx[i] != null:
			MusicManager.play_sfx(morning_sfx[i].resource_path)
		var delay = 0.5
		if morning_delays.size() > i:
			delay = morning_delays[i]
			
		await get_tree().create_timer(delay).timeout

func play_night_animation(panel: TextureRect):
	if not panel or night_frames.size() == 0:
		return
		
	for i in range(night_frames.size()):
		panel.texture = night_frames[i]
		if i < night_sfx.size() and night_sfx[i] != null:
			MusicManager.play_sfx(night_sfx[i].resource_path)
		if i == 10:
			barras.visible = true
			await night_panels(panel)
			
		var delay = 0.5
		if night_delays.size() > i:
			delay = night_delays[i]
			
		await get_tree().create_timer(delay).timeout

func play_round5_cinematic(panel: TextureRect):
	if not panel or round5_frames.size() == 0:
		return
	
	# Mostrar animación especial de ronda 5
	for i in range(round5_frames.size()):
		panel.texture = round5_frames[i]
		if i < day_5_sfx.size() and day_5_sfx[i] != null:
			MusicManager.play_sfx(day_5_sfx[i].resource_path)
		var delay = 0.5
		if round5_delays.size() > i:
			delay = round5_delays[i]
			
		await get_tree().create_timer(delay).timeout

	# Después de la animación, iniciar diálogo
	_parent_npc.call("_start_Dialogue")

func night_panels(_panel: TextureRect):
	var step_visual := 15.0        # píxeles que suben por escalón
	var max_bar_height := 200.0    # altura máxima para la barra más grande
	var frame_delay := 0.2         # segundos por escalón

	# Base de las barras
	var base_favor := barra_favor.position.y + barra_favor.size.y
	var base_contra := barra_contra.position.y + barra_contra.size.y

	# Reset inicial
	barra_favor.size.y = 0
	barra_contra.size.y = 0

	var current_left := 0.0
	var current_right := 0.0

	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return

	var target_left = float(game_state.get("baseVotacionFavorAnt"))
	var target_right = float(game_state.get("baseVotacionContraAnt"))

	await get_tree().create_timer(1.0).timeout

	# Mientras alguna barra no haya llegado al valor máximo
	while current_left < target_left or current_right < target_right:
		MusicManager.play_sfx("res://Assets/sfx/pitido_noche.wav")
		# Incrementamos valores si no han llegado al máximo
		if current_left < target_left:
			current_left = min(current_left + 2, target_left)
			
			var height_favor = barra_favor.size.y + step_visual
			height_favor = min(height_favor, max_bar_height)
			
			barra_favor.size.y = height_favor
			barra_favor.position.y = base_favor - height_favor
		
		if current_right < target_right:
			current_right = min(current_right + 2, target_right)
			
			var height_contra = barra_contra.size.y + step_visual
			height_contra = min(height_contra, max_bar_height)
			
			barra_contra.size.y = height_contra
			barra_contra.position.y = base_contra - height_contra

		# Esperamos un frame
		await get_tree().create_timer(0.7).timeout

	barras.visible = false

	await get_tree().create_timer(3.0).timeout
	# Que salgan los numeros
	label_favor.text = str(game_state.get("baseVotacionFavorAnt"))
	label_contra.text = str(game_state.get("baseVotacionContraAnt"))
	MusicManager.play_sfx("res://Assets/sfx/pitido_noche.wav")

	numeros.visible = true
	await get_tree().create_timer(3.0).timeout
	numeros.visible = false
	await get_tree().create_timer(1.0).timeout
