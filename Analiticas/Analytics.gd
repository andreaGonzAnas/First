extends Node

# Configuración google forms
const GOOGLE_FORM_URL = "https://docs.google.com/forms/d/e/1FAIpQLSdMFzzauwUmwRvDUhBd-7WQHNRbV6li92NnngfDaADH4o-Ozw/formResponse"
const ENTRY_SESSION = "entry.2125841063" 
const ENTRY_TYPE = "entry.647097484"
const ENTRY_JSON = "entry.1918017563"

const SAVE_PATH = "user://analytics_local.jsonl"
var session_id: String = ""
var user_id: String = "player"

var _timers: Dictionary = {} 
var _http_sender: HTTPRequest

# variables cola
var _request_queue: Array = []
var _is_sending: bool = false  # para ver si el nodo está ocupado

func _ready():
	randomize()
	
	_http_sender = HTTPRequest.new()
	add_child(_http_sender)
	
	# conectar la señal
	_http_sender.request_completed.connect(_on_request_completed)


# login
func check_user_login(input_id: String) -> bool:
	var clean_id = input_id.strip_edges()
	
	# Validamos contra la lista interna (UsersData.gd)
	if clean_id in UsersData.VALID_IDS:
		start_session(clean_id)
		return true
	
	print("Analytics: ID no válido -> ", clean_id)
	return false

func start_session(valid_id: String):
	session_id = valid_id
	print("Analytics: Sesión validada e iniciada (" + session_id + ")")
	
	# lanzar evento
	get_accessible("Game_Application", "app").accessed()


func _trace(verb_id: String, object_id: String, object_type: String, result: Dictionary = {}, extensions: Dictionary = {}):
	
	# si no hay sesion iniciada...
	if session_id == "":
		return
	if session_id == "TESTDEVS":
		return
	
	var time_since_start = Time.get_ticks_msec() / 1000.0
	
	var statement = {
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"game_time": time_since_start,
		"actor": {
			"account": { "name": session_id },
			"name": user_id
		},
		"verb": { "id": verb_id },
		"object": {
			"id": object_id,
			"definition": {
				"type": object_type,
				"extensions": extensions
			}
		}
	}
	
	if not result.is_empty():
		statement["result"] = result

	_save_to_disk(statement)
	_send_to_cloud(statement)

# colas
func _send_to_cloud(data: Dictionary):
	_request_queue.append(data)
	
	_process_queue()

func _process_queue():
	# si ya estamos enviando algo, esperar
	if _is_sending: return
	
	# si la cola está vacía, terminamos
	if _request_queue.is_empty(): return
	
	# iniciar evento
	_is_sending = true
	var data = _request_queue.pop_front()
	
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var session_val = str(data["actor"]["account"]["name"])
	var type_val = str(data["verb"]["id"]).split("/")[-1]
	var json_string = JSON.stringify(data)
	
	var body_data = "%s=%s&%s=%s&%s=%s" % [
		ENTRY_SESSION, session_val.uri_encode(),
		ENTRY_TYPE, type_val.uri_encode(),
		ENTRY_JSON, json_string.uri_encode()
	]
	
	var error = _http_sender.request(GOOGLE_FORM_URL, headers, HTTPClient.METHOD_POST, body_data)
	
	if error != OK:
		print("Analytics Error: No se pudo iniciar la petición HTTP.")
		_is_sending = false # liberar

func _on_request_completed(result, response_code, headers, body):
	# liberar bandera
	_is_sending = false
	
	if response_code != 200:
		print("Analytics Info: Google devolvió código ", response_code)
	
	# mandar mensaje
	_process_queue()

# guardado local
func _save_to_disk(data: Dictionary):
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ_WRITE)
	if not file: file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(data))
		file.close()

# tiempos
func _start_timer(id: String):
	_timers[id] = Time.get_ticks_msec()

func _stop_and_get_duration(id: String) -> float:
	if not _timers.has(id): return 0.0
	var start = _timers[id]
	var end = Time.get_ticks_msec()
	_timers.erase(id)
	return (end - start) / 1000.0

# objetos
func get_alternative(id: String) -> Alternative: return Alternative.new(self, id)
func get_completable(id: String) -> Completable: return Completable.new(self, id)
func get_accessible(id: String, type: String = "screen") -> Accessible: return Accessible.new(self, id, type)
func get_interactable(id: String, type: String = "ui-element") -> Interactable: return Interactable.new(self, id, type)

# clases internas

class Alternative:
	var _t; var _id: String
	func _init(t, id): _t = t; _id = id
	func selected(option: String, extensions: Dictionary = {}):
		_t._trace("http://adlnet.gov/expapi/verbs/chosen", _id, "https://w3id.org/xapi/adl/activity-types/alternative", { "response": option }, extensions)

class Completable:
	var _t; var _id: String
	func _init(t, id): _t = t; _id = id
	func initialized():
		_t._start_timer(_id)
		_t._trace("http://adlnet.gov/expapi/verbs/initialized", _id, "http://adlnet.gov/expapi/activities/interaction")
	func completed(success: bool = true, score: float = 0.0, extensions: Dictionary = {}):
		var duration = _t._stop_and_get_duration(_id)
		
		# resultado
		var result = { 
			"success": success, 
			"score": { "raw": score }, # puntuación y dinero
			"duration": "PT" + str(duration) + "S",
			"extensions": extensions # rondas y demás
		}
		
		result["extensions"]["seconds_taken"] = duration
		
		_t._trace("http://adlnet.gov/expapi/verbs/completed", _id, "http://adlnet.gov/expapi/activities/interaction", result)

class Accessible:
	var _t; var _id: String; var _type: String
	func _init(t, id, type): _t = t; _id = id; _type = type
	func accessed():
		_t._trace("http://activitystrea.ms/schema/1.0/access", _id, "http://activitystrea.ms/schema/1.0/" + _type)

class Interactable:
	var _t; var _id: String; var _type: String
	func _init(t, id, type): _t = t; _id = id; _type = type
	func interacted(extensions: Dictionary = {}):
		_t._trace("http://adlnet.gov/expapi/verbs/interacted", _id, "http://adlnet.gov/expapi/activities/interaction", {}, extensions)
