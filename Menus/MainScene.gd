extends Node3D

# --- Versión con @onready var (más fácil) ---
# Asegúrate de que los nombres coinciden con tu escena
@onready var player = $Player
@onready var dialogue_manager_node = $PruebaDialogo
@onready var interacting_component = $Player/InteractingComponent

func _ready():
	# Conectar Señal de Diálogo -> al Script del Jugador
	dialogue_manager_node.DialogueStarted.connect(player._on_dialogue_started)
	dialogue_manager_node.DialogueFinished.connect(player._on_dialogue_finished)
	
	# Conectar Señal de Diálogo -> al Script de Interacción
	dialogue_manager_node.DialogueStarted.connect(interacting_component._on_dialogue_started)
	dialogue_manager_node.DialogueFinished.connect(interacting_component._on_dialogue_finished)
