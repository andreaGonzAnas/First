extends CanvasLayer

# --- ATRIBUTOS ---
var _pause_panel: Panel

# Botones y Barras
var _main_menu_button: Button
var _resume_button: Button
var _favor_bar: Panel
var _contra_bar: Panel
var _opinion_bar: Control

var _population_panel: Panel
var _money_panel: Panel

var original_money_x: float = 0.0
var original_money_y: float = 0.0

var mission_panel : Panel
var main_mission: Label
var explore_mission: Label
var talk_mission: Label


#BOTON DE MUTE AUDIO
var mute_button: TextureButton

func _ready():
	# Inicializar paneles
	_pause_panel = get_node("PausePanel")
	_opinion_bar = get_node("OpinionBar")
	_favor_bar = _opinion_bar.get_node("RedBar")
	_contra_bar = _opinion_bar.get_node("GreenBar")
	
	_population_panel = get_node("nPoblacion")
	_money_panel = get_node("nDinero")
	
	# Inicializar botones
	_main_menu_button = _pause_panel.get_node("VBoxContainer").get_node("MainMenuButton")
	_resume_button = _pause_panel.get_node("VBoxContainer").get_node("ResumeButton")
	mute_button = _pause_panel.get_node("MuteButton")
	
	#Inicializar misiones
	mission_panel = get_node("MissionPanel")
	main_mission = mission_panel.get_node("MainMissionLabel")
	explore_mission = mission_panel.get_node("ExploreLabel")
	talk_mission = mission_panel.get_node("TalkLabel")

	# --- CONEXIÓN DE MISIONES ---
	var game_state = get_node_or_null("/root/GameState")
	if game_state.has_signal("mission_updated"):
		game_state.mission_updated.connect(update_missions)
		update_missions()

	_main_menu_button.pressed.connect(OnMainMenuButton)
	_resume_button.pressed.connect(OnResumeButton)
	mute_button.pressed.connect(OnMuteButton)
	
	# Visibilidad inicial
	_pause_panel.visible = false
	
	# Comprobar estado del audio y actualizar el icono
	var audio = get_node_or_null("/root/MusicManager")
	if audio:
		if audio.is_muted():
			mute_button.texture_normal = load("res://Assets/Finales/muted.png")
		else:
			mute_button.texture_normal = load("res://Assets/Finales/unmuted.png")

	UpdateUI()
	UpdateOpinionBar()

func _input(event):
	if event.is_action_pressed("Pause"):
		OnPauseButton()

# --- MÉTODOS PÚBLICOS ---
func OnPauseButton():
	get_tree().paused = true
	_pause_panel.visible = true

func OnMainMenuButton():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/MainMenu.tscn")

func OnResumeButton():
	_pause_panel.visible = false
	get_tree().paused = false

func OnMuteButton():
	var audio = get_node("/root/MusicManager")
	if audio:
		audio.toggle_mute()
		if audio.is_muted():
			mute_button.texture_normal = load("res://Assets/Finales/muted.png")
		else:
			mute_button.texture_normal = load("res://Assets/Finales/unmuted.png")

# --- ACTUALIZACIÓN DE UI ---
func UpdateUI():
	var game_state = get_node("/root/GameState")
	
	# Actualizar población
	var n_popu = get_node("nPoblacion").get_node("Label")
	if game_state:
		n_popu.text = str(game_state.get("nPopulation"))
	
	# Actualizar dinero
	var n_money = get_node("nDinero").get_node("Label")
	if game_state:
		n_money.text = str(game_state.get("nMoney"))
		

func UpdateOpinionBar():
	var game_state = get_node("/root/GameState")
	if not game_state: return
	
	var a_favor = int(game_state.get("aFavorOpinion"))
	var en_contra = int(game_state.get("enContraOpinion"))
	var n_popu = int(game_state.get("nPopulation"))
	
	# Evitar división por cero
	if n_popu == 0: return 
	
	# Calcular porcentajes
	var favor_percent = float(a_favor) / n_popu
	var contra_percent = float(en_contra) / n_popu
	
	var bar_width = _opinion_bar.size.x
	
	# Barra izquierda (a favor / RedBar)
	_favor_bar.size = Vector2(bar_width * favor_percent, _favor_bar.size.y)
	_favor_bar.position = Vector2(0 + 25, _favor_bar.position.y)
	
	# Barra derecha (en contra / GreenBar)
	_contra_bar.size = Vector2(bar_width * contra_percent, _contra_bar.size.y)
	_contra_bar.position = Vector2(bar_width - _contra_bar.size.x + 5, _contra_bar.position.y)

# --- MODOS DE HUD ---
func SetHUD_Normal():
	if _population_panel: _population_panel.visible = true
	if _money_panel: _money_panel.visible = true
	if _opinion_bar: _opinion_bar.visible = true
	if mission_panel: mission_panel.visible = true

func SetHUD_Shop():
	if _population_panel: _population_panel.visible = false
	if _opinion_bar: _opinion_bar.visible = false
	if _money_panel: _money_panel.visible = true
	if mission_panel: mission_panel.visible = false

func SetHUD_Minigame():
	if _population_panel: _population_panel.visible = false
	if _money_panel: _money_panel.visible = false
	if _opinion_bar: _opinion_bar.visible = false
	if mission_panel: mission_panel.visible = false




func update_missions():
	var gs = get_node_or_null("/root/GameState")
	if not gs: return

	var round_idx = gs.thisRound
	
	# --- EVALUAR ESTADO ---
	var npc_done = gs.talked_npcs_round.size() >= gs.total_npcs_active
	var explore_done = gs.get_visited_buildings_count() >= gs.TOTAL_BUILDINGS_TO_EXPLORE
	
	# trabajo
	var work_mode_active = (round_idx == 4 and gs.tried_to_buy_cert)
	
	# Comprobamos si el trabajo está TERMINADO (Bar + Peluquería hechos)
	var work_done = false
	if work_mode_active:
		work_done =	gs.jobs_done_round.size() >= 2
	
	# --- 2. LISTA DE SECUNDARIAS ---
	var active_texts = []
	
	# A) Misión de Hablar (Siempre visible si falta)
	if not npc_done:
		active_texts.append("• Habla con la gente")
	
	# B) Misión de Explorar / Trabajar (Una sustituye a la otra)
	if work_mode_active:
		# Si se activó el trabajo, este REEMPLAZA a la exploración
		if not work_done:
			active_texts.append("• Trabaja para ganar dinero")
	else:
		# Si aún no se ha activado el trabajo, mostramos explorar normal
		if not explore_done:
			active_texts.append("• Explora la plaza")

	# --- 3. MOSTRAR EN PANTALLA ---
	if talk_mission: talk_mission.text = ""; talk_mission.visible = false
	if explore_mission: explore_mission.text = ""; explore_mission.visible = false
	
	# Asignamos ordenadamente
	if active_texts.size() > 0 and talk_mission:
		talk_mission.text = active_texts[0]
		talk_mission.visible = true
		
	if active_texts.size() > 1 and explore_mission:
		explore_mission.text = active_texts[1]
		explore_mission.visible = true

	# --- 4. MISIÓN PRINCIPAL ---
	var main_text = ""
	match round_idx:
		0: main_text = "• Vuelve a casa" if gs.visited_urn else "• Ve a la urna de votación"
		1, 2, 3: main_text = "• Decide si votar o volver a casa"
		4: 
			# LÓGICA FINAL DÍA 5:
			# Si la lista de secundarias está vacía, significa que has hecho todo
			# (Hablar + Trabajar/Explorar)
			if active_texts.size() == 0:
				main_text = "• No hay nada más que hacer"
			else:
				main_text = "• Compra el certificado"

	if main_mission: main_mission.text = main_text

	# Visibilidad del panel
	if mission_panel:
		mission_panel.visible = (main_text != "" or active_texts.size() > 0)

func _get_common_sub_missions(gs) -> String:
	var text = ""
	
	if gs.talked_npcs_round.size() < gs.total_npcs_active:
		text += "Habla con la gente del pueblo\n"
	
	# Usamos el contador del historial que creamos en GameState
	if gs.get_visited_buildings_count() < gs.TOTAL_BUILDINGS_TO_EXPLORE:
		text += "Explora la plaza\n"
		
	return text
