extends Node

var _player: AudioStreamPlayer      
var _sfx_player: AudioStreamPlayer  

const MAX_VOLUME_DB = -10.0
const MIN_VOLUME_DB = -380.0
const TRANSITION_DURATION = 0.5

var _current_track_path: String = ""

# --- VARIABLE DE MEMORIA ---
var _is_muted_state: bool = false 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Funciona en pausa
	
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.volume_db = MIN_VOLUME_DB
	_player.bus = "Master"
	
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_sfx_player.volume_db = 0.0 
	_sfx_player.bus = "Master"

func play_music(stream_path: String):
	if _current_track_path == stream_path and _player.playing:
		return
	
	_current_track_path = stream_path
	
	# Fade Out (Bajar la anterior)
	if _player.playing:
		var tween_out = create_tween()
		tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 
		tween_out.tween_property(_player, "volume_db", MIN_VOLUME_DB, TRANSITION_DURATION)
		await tween_out.finished
		_player.stop()
	
	# Cargar nueva
	if stream_path != "":
		var stream = load(stream_path)
		if stream:
			_player.stream = stream
			_player.volume_db = MIN_VOLUME_DB # Empezar en silencio
			_player.play()
			
			var target_vol = MAX_VOLUME_DB
			if _is_muted_state:
				target_vol = MIN_VOLUME_DB
			
			var tween_in = create_tween()
			tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween_in.tween_property(_player, "volume_db", target_vol, TRANSITION_DURATION)
		else:
			print("Error Music: " + stream_path)

func play_sfx(stream_path: String):
	if stream_path != "":
		var stream = load(stream_path)
		if stream:
			_sfx_player.stream = stream
			
			# Chequeo de memoria para SFX también
			if _is_muted_state:
				_sfx_player.volume_db = MIN_VOLUME_DB
			else:
				_sfx_player.volume_db = 0.0
				
			_sfx_player.play()
		else:
			print("Error SFX: " + stream_path)

func toggle_mute():
	# Cambiar memoria
	_is_muted_state = !_is_muted_state
	
	# Aplicar cambio
	var target_vol = MAX_VOLUME_DB
	if _is_muted_state:
		target_vol = MIN_VOLUME_DB
		
	_player.volume_db = target_vol
	_sfx_player.volume_db = target_vol

func is_muted() -> bool:
	return _is_muted_state


func stop_music():
	_current_track_path = ""
	
	# Si está sonando, bajar volumen y parar
	if _player.playing:
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Para que funcione aunque el juego esté en pausa
		tween.tween_property(_player, "volume_db", MIN_VOLUME_DB, TRANSITION_DURATION)
		
		await tween.finished
		_player.stop()