extends Panel

@onready var background_texture = $Background

func set_background(texture: Texture2D):
	if background_texture and texture:
		background_texture.texture = texture
