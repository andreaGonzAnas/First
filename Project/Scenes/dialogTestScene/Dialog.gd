extends Control

const FONT_REGULAR = preload("res://Assets/Fonts/lucidagrande.ttf")
const FONT_ITALIC = preload("res://Assets/Fonts/lucidagrande-italic.otf")

# --- GAME STATE ---
var game_state: Node

# --- JSONS ---
var json_data: Dictionary
var json_file_path: String

# --- CAJA NPCS ---
@export var npc_s_rect: Panel
@export var npc_label_text: Label
@export var npc_portrait_rect: TextureRect
@export var npc_name_label: Label

# --- CAJA CLOVER ---
@export var clover_rect: Panel
@export var label_text: Label
@export var clover_rect_portrait: TextureRect
@export var clover_rect_name_label: Label

# BOTONES OPCIONES
@export var options_rect: ColorRect
@export var response_buttons: Array[Button]

# --- VARIABLES DE ESTADO ---
var name_of_the_event: String
var actual_line: int
var dialog_array: Array
var is_dialogue_showing: bool = false
var is_waiting_for_response: bool = false
var is_end_of_dialogue: bool = false
var response_next_event: Array = []
var visible_option_count: int = 0

# Manejo de opciones
var selected_option_index: int = 0
var last_input_was_mouse: bool = false

# Manejo de UI dialogo
var current_npc: Node3D
var current_portrait_texture: Texture2D = null
var current_npc_name: String = ""
var current_clover_portrait_texture: Texture2D = null
var current_clover_name: String = ""
var canvas: CanvasLayer

func _ready():
	game_state = get_node_or_null("/root/GameState")

	var locale = TranslationServer.get_locale()
	if locale.begins_with("es"): 
		json_file_path = "res://JsonDialog/text.json"
	else:
		json_file_path = "res://JsonDialog/en.json"

	json_data = load_dialogue(json_file_path)

	if response_buttons.size() >= 3:
		response_next_event.resize(3)
		for i in range(response_buttons.size()):
			var btn = response_buttons[i]
			btn.pressed.connect(func():
				last_input_was_mouse = true
				selected_option_index = i
				_on_response_button_pressed(response_next_event[i])
			)
			btn.mouse_entered.connect(func():
				last_input_was_mouse = true
				selected_option_index = i
				update_option_selection()
			)
	else:
		push_error("Error: Los botones de respuesta no están asignados en el Inspector.")

	canvas = get_node("CanvasLayer")
	canvas.visible = false
	hide_options()

# --- INPUT GENERAL ---
func _input(event):
	if event.is_action_pressed("Interact"):
		
		if is_end_of_dialogue:
			var last_line_data = dialog_array[dialog_array.size() - 1] as Dictionary

			# next
			if last_line_data.has("next"):
				var next_event_name = str(last_line_data["next"])
				
				# Si está en el JSON, es otro diálogo
				if json_data.has(next_event_name):
					is_end_of_dialogue = false
					is_dialogue_showing = false
					show_dialogue(next_event_name)
					return 
				else:
					# Cerramos la UI
					canvas.visible = false
					is_end_of_dialogue = false
					is_dialogue_showing = false
					
					# Avisamos al NPC
					if current_npc and current_npc.has_method("set_next_dialog"):
						current_npc.set_next_dialog(next_event_name)
					else:
						push_error("Dialog: El NPC no tiene método set_next_dialog para: " + next_event_name)
					
					return
			
			is_end_of_dialogue = false
			is_dialogue_showing = false

			var next_event = json_data[name_of_the_event] as Dictionary
			var options_array: Array = []
			
			if next_event.has("options"):
				options_array = next_event["options"]
			
			if options_array != null and options_array.size() > 0:
				show_options(options_array)
			else: 
				# FIN DEL DIÁLOGO
				var analytics = get_node_or_null("/root/Analytics")
				if analytics:
					analytics.get_completable(name_of_the_event).completed()

				canvas.visible = false
				get_viewport().set_input_as_handled()

				if game_state:
					game_state.set("can_interact", true)
					game_state.set("can_move", true)
					game_state.set("ignore_next_interact", true)

				if current_npc:
					if current_npc.has_method("close_shop_ui"):
						current_npc.call("close_shop_ui")
					if current_npc.has_method("close_house_ui"):
						current_npc.call("close_house_ui")
					if current_npc.has_method("set_next_dialog"):
						current_npc.call("set_next_dialog", name_of_the_event)
		else:
			show_next_dialogue()
			

func ShowDialogueCallable(id: int, building_event: String, npc_node: Node3D):
	if game_state:
		# Comprueba si ya hay un diálogo
		if game_state.get("can_interact") == false && id != 0:
			return
		game_state.set("can_interact", false)
		game_state.set("can_move", false)

	current_npc = npc_node
	if id != -1:
		var new_pos = get_screen_position_from_world(npc_node.global_position)
		npc_s_rect.position = new_pos + Vector2(-npc_s_rect.size.x / 2.3, -300)
	
		if npc_portrait_rect:
			npc_portrait_rect.position = Vector2(npc_portrait_rect.position.x, npc_portrait_rect.position.y)
	
	else:
		#cinematica final
		if current_npc.name == "NPC2" :
			var viewport_width = get_viewport().get_visible_rect().size.x
			var viewport_height = get_viewport().get_visible_rect().size.y
			npc_s_rect.position = Vector2(viewport_width / 2.5, viewport_height / 3)
			npc_portrait_rect.position = Vector2(npc_portrait_rect.position.x, npc_portrait_rect.position.y)
		#cinematica penny dia 4
		elif current_npc.name == "PENNY":
			var viewport_width = get_viewport().get_visible_rect().size.x
			var viewport_height = get_viewport().get_visible_rect().size.y
			npc_s_rect.position = Vector2(viewport_width / 2.75, viewport_height / 5.5)
			npc_portrait_rect.position = Vector2(npc_portrait_rect.position.x, npc_portrait_rect.position.y)
		#es la tienda 
		else:
			var viewport_width = get_viewport().get_visible_rect().size.x
			var viewport_height = get_viewport().get_visible_rect().size.y
			npc_s_rect.position = Vector2(viewport_width / 5, viewport_height / 12)
			npc_portrait_rect.position = Vector2(npc_portrait_rect.position.x, npc_portrait_rect.position.y)

	var event_name = ""

	if id == -1: 
		show_dialogue(building_event)
	else:
		var is_first = bool(current_npc.get("firstInteract"))
		if is_first:
			var round_num = int(game_state.get("thisRound")) + 1
			event_name = "Npc" + str(id) + "." + str(round_num)
			show_dialogue(event_name)
		else:
			var round_num = int(game_state.get("thisRound")) + 1
			event_name = "Npc" + str(id) + "." + str(round_num) + ".Repetir"
			show_dialogue(event_name)

func ForceShowDialogue(event_name: String):
	if current_npc == null:
		push_error("ForceShowDialogue: No hay 'currentNpc' para mostrar el diálogo.")
		return
	
	hide_options()
	npc_label_text.text = ""
	show_dialogue(event_name)

func get_screen_position_from_world(world_pos: Vector3) -> Vector2:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	var screen_pos = camera.unproject_position(world_pos)
	return screen_pos

func show_dialogue(event_name: String):
	if current_npc != null and current_npc.has_method(event_name):
		current_npc.call(event_name)
		return

	if is_dialogue_showing: return
	
	if json_data == null:
		json_data = load_dialogue(json_file_path)

	if not json_data.has(event_name):
		# cinematica
		if current_npc and current_npc.has_method("set_next_dialog"):
			current_npc.set_next_dialog(event_name)
			canvas.visible = false
			is_dialogue_showing = false
			return
		
		push_error("showDialogue: Evento '" + event_name + "' no encontrado en JSON ni como método en el NPC.")
		return

	var dialogue_event = json_data[event_name] as Dictionary
	is_dialogue_showing = true
	is_end_of_dialogue = false
	is_waiting_for_response = false
	actual_line = 0
	name_of_the_event = event_name

	var analytics = get_node_or_null("/root/Analytics")
	if analytics:
		analytics.get_completable(name_of_the_event).initialized()

	dialog_array = dialogue_event["dialogs"]
	canvas.visible = true
	show_next_dialogue()

func show_next_dialogue():
	if not is_dialogue_showing: return

	if dialog_array.size() == 0:
		is_end_of_dialogue = true
		return

	var line_data = dialog_array[actual_line] as Dictionary
	MusicManager.play_sfx("res://Assets/sfx/click_avanzar_dialogo.wav")
	if str(line_data["author"]) == "npc":
		npc_s_rect.visible = true
		clover_rect.visible = false

		if line_data.has("text"):
			npc_label_text.text = str(line_data["text"])
			var anim_player = npc_s_rect.get_node("AnimationPlayer")
			anim_player.play("showText")

		if npc_portrait_rect:
			if line_data.has("portrait"):
				var image_path = str(line_data["portrait"])
				var new_texture = load(image_path)
				if new_texture:
					current_portrait_texture = new_texture
				else:
					push_error("No se pudo cargar el retrato: " + image_path)

			if current_portrait_texture:
				npc_portrait_rect.texture = current_portrait_texture
				npc_portrait_rect.visible = true

		if npc_name_label:
			if line_data.has("name"):
				current_npc_name = str(line_data["name"])
			if not current_npc_name.is_empty():
				npc_name_label.text = current_npc_name

	else: # Clover
		npc_s_rect.visible = false
		clover_rect.visible = true

		var text_to_display = ""
		if line_data.has("quadrant_thought"):
			var quadrant_data = line_data["quadrant_thought"] as Dictionary
			text_to_display = get_quadrant_thought(quadrant_data)
		elif line_data.has("text"):
			text_to_display = str(line_data["text"])
		
		if not text_to_display.is_empty():
			var final_text = text_to_display
			
			if label_text.label_settings:
				if final_text.begins_with("*") and final_text.ends_with("*"):
					label_text.label_settings.font = FONT_ITALIC
					final_text = final_text.trim_prefix("*").trim_suffix("*")
				else:
					label_text.label_settings.font = FONT_REGULAR
			else:
				if final_text.begins_with("*") and final_text.ends_with("*"):
					label_text.add_theme_font_override("font", FONT_ITALIC)
					final_text = final_text.trim_prefix("*").trim_suffix("*")
				else:
					label_text.add_theme_font_override("font", FONT_REGULAR)
			
			label_text.text = final_text
			clover_rect.get_node("AnimationPlayer").play("showText")

		if clover_rect_portrait:
			if line_data.has("portrait"):
				var image_path = str(line_data["portrait"])
				var new_texture = load(image_path)
				if new_texture:
					current_clover_portrait_texture = new_texture
				else:
					push_error("No se pudo cargar el retrato: " + image_path)

			if current_clover_portrait_texture:
				clover_rect_portrait.texture = current_clover_portrait_texture
				clover_rect_portrait.visible = true

		if clover_rect_name_label:
			if line_data.has("name"):
				current_clover_name = str(line_data["name"])
			if not current_clover_name.is_empty():
				clover_rect_name_label.text = current_clover_name

	is_end_of_dialogue = actual_line >= dialog_array.size() - 1
	if not is_end_of_dialogue:
		actual_line += 1

func show_options(options_array: Array):
	is_waiting_for_response = true
	hide_options()
	options_rect.visible = true
	clover_rect.visible = false

	visible_option_count = options_array.size()

	for i in range(options_array.size()):
		if i >= response_buttons.size(): break
		var option = options_array[i] as Dictionary

		response_buttons[i].text = str(option["response"])
		response_buttons[i].visible = true

		var gain_val = 0
		if option.has("gain"):
			gain_val = int(option["gain"])

		response_next_event[i] = {
			"nextEvent": str(option["next"]),
			"answerToDisplay": str(option["response"]),
			"gain": gain_val
		}

	selected_option_index = 0
	last_input_was_mouse = false
	update_option_selection()

func _on_response_button_pressed(response: Dictionary):
	is_waiting_for_response = false
	hide_options()
	npc_label_text.text = ""

	var choice_text = str(response["answerToDisplay"])
	var gain_val = response["gain"]
	var analytics_data = {}

	if response["gain"] == 0:
		game_state.call("changeActivity", -1)
		analytics_data["stat_change"] = "activity -1"
	else:
		var gain = response["gain"]
		if gain == 1 or gain == -1:
			game_state.call("changeMoral", gain)
			analytics_data["stat_change"] = "moral " + str(gain_val)

			var a = game_state.get("extraOpinion")
			game_state.set("extraOpinion", a + gain) # suma o resta 1 dependiendo de la eleccion

			game_state.call("update_population_opinion")

	var analytics = get_node_or_null("/root/Analytics")
	if analytics:
		analytics.get_alternative(name_of_the_event).selected(choice_text, analytics_data)

	await show_dialogue(response["nextEvent"])

func hide_options():
	for button in response_buttons:
		if button: button.visible = false
	options_rect.visible = false

func load_dialogue(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: " + file_path)
		return {}

	var json_text = file.get_as_text()
	file.close()
	
	var parsed_result = JSON.parse_string(json_text)
	if parsed_result is Dictionary:
		return parsed_result
	return {}

func update_option_selection():
	if response_buttons.is_empty():
		return
	selected_option_index = clamp(selected_option_index, 0, response_buttons.size() - 1)
	for i in range(response_buttons.size()):
		if response_buttons[i] == null: continue
		if not last_input_was_mouse and i == selected_option_index and response_buttons[i].visible:
			response_buttons[i].grab_focus()
		else:
			response_buttons[i].release_focus()

func get_quadrant_thought(quadrant_data: Dictionary) -> String:
	var moral = int(game_state.get("moral"))
	var activity = int(game_state.get("activity"))
	
	var key: String
	if activity > 0:
		key = "pos_act_pos_mor" if moral > 0 else "pos_act_neg_mor"
	else: 
		key = "neg_act_pos_mor" if moral > 0 else "neg_act_neg_mor"

	if quadrant_data.has(key):
		return str(quadrant_data[key])
	else:
		push_error("GetQuadrantThought: Clave '" + key + "' no encontrada en JSON!")
		return "Error: Falta diálogo para este cuadrante."
