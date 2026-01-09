extends Panel

@onready var background_texture = $Background
@onready var item_in_shop = $Item
@export var label_price: Label 

# para cambiar imagen
func set_background(texture: Texture2D):
	if background_texture and texture:
		background_texture.texture = texture

func set_item_in_shop(texture: Texture2D):
	if item_in_shop and texture:
		item_in_shop.texture = texture

func set_price_in_shop(price: int):
	label_price.text = str(price)
