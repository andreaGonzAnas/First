extends Node3D

# --- Variables de la UI de la Escena ---
@export var id: int = 0
@onready var firstInteract: bool = true
var living_room_instance = null
var dialog = null


func _ready():
	dialog = get_parent().get_node_or_null("PruebaDialogo/DialogueManager")

	if !dialog: print("Error: shop.gd no pudo encontrar DialogueManager")


func _on_interact():
	if !dialog: return

	var dialog_to_show = ""

func _start_Dialogue():
	dialog.call("ShowDialogueCallable", id, "", self)

func set_next_dialog(event_name: String):
	pass

func close_shop_ui():
	var parent = get_parent()
	if parent.has_method("EndSceneAsync"):
		parent.EndSceneAsync()

	
func close_house_ui():
	var parent_scene = get_parent()
	
	if parent_scene.has_method("end_scene_async"):
		parent_scene.end_scene_async()
	else:
		print("Error: HouseScene no tiene el método 'end_scene_async'")
