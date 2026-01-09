extends Node

# --- ESTADO GLOBAL ---
var end_reached: String = "none"

var can_interact: bool = true
var ignore_next_interact: bool = false
var can_move: bool = true
var _last_interaction_time: int = 0

var nMoney: int = 10
var nPopulation: int = 60
var thisRound: int = 0
var isNight: bool = false

var baseOpinionFavor: int = 22
var baseOpinionContra: int = 26

var baseVotacionFavor: int = 24
var baseVotacionContra: int = 16

var baseVotacionFavorAnt: int = 24
var baseVotacionContraAnt: int = 16

var aFavorOpinion: int = 22
var enContraOpinion: int = 26

var cambioRonda: float = 1

var empujarPos: int = 0
var empujarNeg: int = 0

var moral: int = 0
var activity: int = 0

var last_accesory : Texture2D = null

# --- LISTA DE OBJETOS SIN INTERACTUAR ---
var activity_list: Array = []

# --- LISTA DE OBJETOS INTERACTUADOS ---
var interacted_activity_list: Array = []

# --- LISTA ÚNICA DE ENTIDADES ---
var entity_list: Array = []

# --- LISTA DE COMPRAS ---
var bought_items_list: Array[String] = []

var extraOpinion: int = 0
var margenVotacion: int = 0

var aFavorVotacion: int = 24
var enContraVotacion: int = 16

# --- BLOQUE DE MISIONES ---
signal mission_updated

# Variables de progreso
var visited_buildings_history: Dictionary = {} 
var talked_npcs_round: Dictionary = {}         
var tried_to_buy_cert: bool = false            
var visited_urn: bool = false # Para el día 1

var jobs_done_round: Array = []

# Configuración
const TOTAL_BUILDINGS_TO_EXPLORE = 6
var total_npcs_active = 4
var objetos_visitados_en_ronda: Array = []

# Funciones de registro (Llamadas por los objetos)
func register_npc_talk(npc_id: String):
	if not talked_npcs_round.has(npc_id):
		talked_npcs_round[npc_id] = true
		emit_signal("mission_updated")

func register_urn_visit():
	if not visited_urn:
		visited_urn = true
		emit_signal("mission_updated")

func set_tried_to_buy():
	if not tried_to_buy_cert:
		tried_to_buy_cert = true
		emit_signal("mission_updated")

func get_visited_buildings_count() -> int:
	return visited_buildings_history.size()



# --- DETECCIÓN AUTOMÁTICA DE ENTIDADES ---
func load_entities_from_scene():
	var scene_root = get_tree().get_current_scene()
	if !scene_root:
		push_error("No se encontró la escena actual al cargar entidades.")
		return

	entity_list.clear()

	# Buscar recursivamente en toda la escena
	_scan_entities(scene_root)
 

# --- ESCANEO RECURSIVO ---
func _scan_entities(node: Node):
	for child in node.get_children():
		if !child:
			continue

		if child.has_method("on_round_update"):
			entity_list.append(child)

		if child.get_child_count() > 0:
			_scan_entities(child)

# Registra un item como "comprado"
func register_bought_item(item_id: String):
	if not bought_items_list.has(item_id):
		bought_items_list.append(item_id)

# Comprueba si un item ya se ha comprado
func has_bought_item(item_id: String) -> bool:
	return bought_items_list.has(item_id)

# Registra un objeto como "interactuado"
func register_interact_object(obj_name: String) -> void:
	if not visited_buildings_history.has(obj_name):
		visited_buildings_history[obj_name] = true
		emit_signal("mission_updated")

# Comprueba si un objeto se ha interactuado con él
func has_interacted_object(object_id: String) -> bool:
	return object_id in objetos_visitados_en_ronda

func deregister_interact_object(object_id: String):
	if interacted_activity_list.has(object_id):
		interacted_activity_list.erase(object_id)
	

# --- AVANZAR RONDA ---
func next_round():
	load_entities_from_scene()
	thisRound += 1
	nMoney += 10
	# ---RESETEO DE MISIONES---
	match thisRound:
		1: total_npcs_active = 4 # Día 2
		2: total_npcs_active = 4 # Día 3
		3: total_npcs_active = 3 # Día 4
		4: total_npcs_active = 2 # Día 5
		_: total_npcs_active = 4
	talked_npcs_round.clear()
	tried_to_buy_cert = false
	emit_signal("mission_updated")
	if(thisRound == 1):
		baseVotacionFavorAnt = aFavorVotacion
		baseVotacionContraAnt = enContraVotacion
		nPopulation = 57
		baseOpinionFavor = 26
		aFavorOpinion = 26
		baseVotacionFavor = 26
		baseOpinionContra = 19
		enContraOpinion = 19
		baseVotacionContra = 17
		cambioRonda = 1.75
		extraOpinion = 0
		margenVotacion = 7
		aFavorVotacion = baseVotacionFavor
		enContraVotacion = baseVotacionContra
	elif(thisRound == 2):
		baseVotacionFavorAnt = aFavorVotacion
		baseVotacionContraAnt = enContraVotacion
		nPopulation = 43
		baseOpinionFavor = 14
		aFavorOpinion = 14
		baseVotacionFavor = 14
		baseOpinionContra = 9
		enContraOpinion = 9
		baseVotacionContra = 9
		cambioRonda = 0.5
		extraOpinion = 0
		margenVotacion = 3
		aFavorVotacion = baseVotacionFavor
		enContraVotacion = baseVotacionContra
	elif(thisRound == 3):
		baseVotacionFavorAnt = aFavorVotacion
		baseVotacionContraAnt = enContraVotacion
		nPopulation = 38
		baseOpinionFavor = 12
		aFavorOpinion = 12
		baseVotacionFavor = 12
		baseOpinionContra = 19
		enContraOpinion = 19
		baseVotacionContra = 0
		cambioRonda = 0.5
		extraOpinion = 0
		margenVotacion = 2
		aFavorVotacion = baseVotacionFavor
		enContraVotacion = baseVotacionContra
		
	elif(thisRound == 4):
		baseVotacionFavorAnt = aFavorVotacion
		baseVotacionContraAnt = enContraVotacion
		extraOpinion = 0
	
	update_all_entities(thisRound)
	update_population_opinion()

	var ui_node = get_tree().current_scene.get_node_or_null("TrialScene/UI")
	if ui_node:
		ui_node.call("UpdateOpinionBar")
	else:
		print("no se encontró UI")

# --- ACTUALIZAR TODAS LAS ENTIDADES ---
func update_all_entities(current_round: int):
	for entity in entity_list:
		if entity and entity.has_method("on_round_update"):
			entity.on_round_update(current_round)


func update_population_opinion():
	#recalcular opinion
	aFavorOpinion = baseOpinionFavor
	enContraOpinion = baseOpinionContra
	aFavorVotacion = baseVotacionFavor
	enContraVotacion = baseVotacionContra
	if extraOpinion > 0:
		# sumar en contra, restar en neutral
		enContraOpinion += extraOpinion * 2

		# votaciones
		if extraOpinion == 1:
			enContraVotacion += (margenVotacion/2)
		else:
			enContraVotacion += margenVotacion
	elif extraOpinion < 0:
		# sumar a favor, restar en neutral
		aFavorOpinion += abs(extraOpinion) * 2

		# votaciones
		if extraOpinion == 1:
			aFavorVotacion += (margenVotacion/2)
		else:
			aFavorVotacion += margenVotacion

	# Recalcular votación
	var ui_node = get_tree().current_scene.get_node_or_null("TrialScene/UI")
	if ui_node:
		ui_node.call("UpdateOpinionBar")
	else:
		print("no se encontró UI")


# --- RESETEO ---
func reset_game_state():
	can_interact = true
	ignore_next_interact = false
	can_move = true

	nMoney = 10
	nPopulation = 60
	thisRound = 0
	isNight = false

	baseOpinionFavor = 22
	baseOpinionContra = 26

	baseVotacionFavor = 24
	baseVotacionContra = 16

	baseVotacionFavorAnt = 24
	baseVotacionContraAnt = 16

	aFavorOpinion = 22
	enContraOpinion = 26
	cambioRonda = 1

	empujarPos = 0
	empujarNeg = 0

	moral = 0
	activity = 0

	last_accesory = null

	# --- LISTA DE OBJETOS SIN INTERACTUAR ---
	activity_list = []

	# --- LISTA DE OBJETOS INTERACTUADOS ---
	interacted_activity_list = []

	# --- LISTA ÚNICA DE ENTIDADES ---
	entity_list = []

	# --- LISTA DE COMPRAS ---
	bought_items_list = []

func changeMoral(change_amount : int):
	var newmoral = change_amount + moral
	moral = newmoral

func changeActivity(change_amount : int):
	var newactivity = change_amount + activity
	activity = newactivity


func register_job(building_name: String):
	if not jobs_done_round.has(building_name):
		jobs_done_round.append(building_name)
		emit_signal("mission_updated")
