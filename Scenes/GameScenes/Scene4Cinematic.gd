extends Node3D

# --- REFERENCIAS ---
@export_group("Actores Cinemática")
@export var penelope_npc: CharacterBody3D
@export var oliver_npc: CharacterBody3D
@export var albert_npc: CharacterBody3D
var camera_3d: Camera3D 

@export_group("NPCs Gameplay (Final)")
@export var npc3: CharacterBody3D
@export var npc4: CharacterBody3D
@export var npc5: CharacterBody3D

@export_group("Posiciones")
@export var marker_start: Marker3D 
@export var marker_vote: Marker3D 

@export_group("Interfaz (HUD)")
@export var ui: CanvasLayer

# --- FRAMES ---
@export var walking_frames: Array[Texture2D] = [] 
@export var penelope_idle_frame: Texture2D 

var dialogue_manager
var is_walking = false 

func _ready():
	await get_tree().process_frame
	dialogue_manager = get_node_or_null("TrialScene/PruebaDialogo/DialogueManager")
	
	camera_3d = get_viewport().get_camera_3d()
	if not camera_3d:
		return

	if penelope_npc:
		penelope_npc.set_script(load("res://Characters/npc.gd"))
		penelope_npc.set_meta("cinematic_controller", self)
	
	# Ocultar NPCs finales al inicio
	if npc3: npc3.visible = false
	if npc4: npc4.visible = false
	if npc5: npc5.visible = false
	
	MusicManager.play_music("res://Assets/Musica/dia4.wav")
	
	start_cinematic()

func start_cinematic():
	_disable_camera_controller()
	if ui: ui.SetHUD_Minigame()
	
	if marker_start:
		penelope_npc.global_position = marker_start.global_position
		oliver_npc.global_position = marker_start.global_position + Vector3(2, 0, 0)
		
		if penelope_npc and penelope_idle_frame:
			var sprite = penelope_npc.get_node_or_null("Sprite3D")
			if sprite:
				sprite.texture = penelope_idle_frame
		
		var conversation_offset = Vector3(0, 80, 150) 
		camera_3d.global_position = marker_start.global_position + conversation_offset
		
		var look_target = (penelope_npc.global_position + oliver_npc.global_position) / 2
		camera_3d.look_at(look_target)
	
	_trigger_dialog("Npc1.4")

func _disable_camera_controller():
	if not camera_3d: return
	camera_3d.top_level = true 
	camera_3d.set_process(false)
	camera_3d.set_physics_process(false)
	
	var parent = camera_3d.get_parent()
	if parent:
		parent.set_process(false)
		parent.set_physics_process(false)
		var grandparent = parent.get_parent()
		if grandparent:
			grandparent.set_process(false)
			grandparent.set_physics_process(false)

func on_dialog_event(event_name: String):
	match event_name:
		"Cinematic_Walk":
			_sequence_walk_up()
		"Cinematic_Punch":
			_sequence_punch()
		"Cinematic_WakeUp": 
			_sequence_aftermath()
		"Cinematic_End":
			_sequence_finish()

# --- CAMINAR ---
func _sequence_walk_up():
	var duration = 4.0
	
	is_walking = true
	_play_walk_anim(penelope_npc)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(penelope_npc, "global_position", marker_vote.global_position, duration)
	
	var final_offset = Vector3(0, 40, 70)
	var cam_final_pos = marker_vote.global_position + final_offset
	
	tween.tween_property(camera_3d, "global_position", cam_final_pos, duration)
	tween.tween_property(camera_3d, "rotation_degrees:x", -25.0, duration) 
	
	await tween.finished
	is_walking = false 
	await get_tree().process_frame 
	
	if penelope_idle_frame:
		var sprite = penelope_npc.get_node_or_null("Sprite3D")
		if sprite: sprite.texture = penelope_idle_frame
	
	_trigger_dialog("Npc2.4")

func _play_walk_anim(npc):
	var sprite = npc.get_node_or_null("Sprite3D") 
	if not sprite or walking_frames.is_empty(): return
	var frame_idx = 0
	var frame_speed = 0.15 
	while is_walking:
		sprite.texture = walking_frames[frame_idx]
		frame_idx = (frame_idx + 1) % walking_frames.size()
		await get_tree().create_timer(frame_speed).timeout

# --- EL GOLPE ---
func _sequence_punch():
	MusicManager.play_sfx("res://Assets/sfx/golpe.wav")
	# OCULTAR HUD JUEGO
	if ui: ui.SetHUD_Minigame()
	
	var transition = get_node_or_null("/root/TransitionScreen")
	if transition:
		# EFECTO DE FLASH
		var rect = transition.get_node("ColorRect")
		rect.color = Color.WHITE
		rect.modulate.a = 1.0
		await get_tree().create_timer(0.05).timeout
		rect.color = Color.BLACK
		
		# --- SACUDIDA DE LA CAPA (CANVAS LAYER) ---
		var shake_tween = create_tween()
		var original_offset = transition.offset
		var shake_force = 20.0
		
		for i in range(15):
			var random_offset = Vector2(
				randf_range(-shake_force, shake_force),
				randf_range(-shake_force, shake_force)
			)
			shake_tween.tween_property(transition, "offset", original_offset + random_offset, 0.02)
		
		# Devolver la capa a su sitio (0,0)
		shake_tween.tween_property(transition, "offset", original_offset, 0.02)

	await get_tree().create_timer(1.0).timeout
	
	if oliver_npc:
		oliver_npc.global_position = penelope_npc.global_position + Vector3(2, 0, 0)

	_trigger_dialog("Npc2.4.1")

# --- RESTAURACIÓN Y FADE IN ---
func _sequence_aftermath():
	ui.SetHUD_Normal()
	# INTERCAMBIO DE NPCS
	if penelope_npc: penelope_npc.queue_free()
	if oliver_npc: oliver_npc.queue_free()
	if albert_npc: albert_npc.queue_free()
	
	if npc3: npc3.visible = true
	if npc4: npc4.visible = true
	if npc5: npc5.visible = true
	
	# RESETEO DE CÁMARA
	if camera_3d:
		camera_3d.top_level = false # Volver a ser hijo del Player
		camera_3d.position = Vector3(-220,0,0) 
		camera_3d.rotation = Vector3.ZERO
		
		# Reactivar scripts del controlador
		camera_3d.set_process(true)
		camera_3d.set_physics_process(true)
		var parent = camera_3d.get_parent()
		if parent:
			parent.set_process(true)
			parent.set_physics_process(true)
			var grandparent = parent.get_parent()
			if grandparent:
				grandparent.set_process(true)
				grandparent.set_physics_process(true)
				grandparent.set_process_input(true)

	# FADE IN
	var transition = get_node_or_null("/root/TransitionScreen")
	if transition:
		var tween = create_tween()
		tween.tween_property(transition.get_node("ColorRect"), "modulate:a", 0.0, 2.0)
		await tween.finished
	
	# FINALIZAR CINEMÁTICA
	_sequence_finish()


# --- FIN DEL JUEGO ---
func _sequence_finish():
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set("can_interact", true)
		game_state.set("can_move", true)
		game_state.set("ignore_next_interact", false)

func _trigger_dialog(key: String):
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.set("can_interact", true) 
		
	if dialogue_manager:
		dialogue_manager.call("ShowDialogueCallable", -1, key, penelope_npc)
