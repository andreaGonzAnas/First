extends Button

# referencia npc
@onready var npc_padre = get_parent().get_parent()

func _process(_delta):
	if npc_padre:
		# obtener posición central del NPC en pantalla
		var posicion_pantalla = npc_padre.get_global_transform_with_canvas().origin
		
		# buscar el sprite para saber cuánto mide
		var sprite = npc_padre.get_node_or_null("BodySprite")
		
		if sprite and sprite.texture:
			# tamaño real sprite
			var sprite_size = sprite.texture.get_size() * sprite.scale
			var esquina_arriba_izq = posicion_pantalla - (sprite_size / 2)
			
			# asignar posicion
			global_position = esquina_arriba_izq
		else:
			global_position = posicion_pantalla + Vector2(-50, -100)