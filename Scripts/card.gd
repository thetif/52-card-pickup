extends Area2D

@export var card_image : Texture2D 
@onready var sprite : Sprite2D = $Sprite2D

signal picked_up


func _ready() -> void:
	sprite.texture = card_image

func _on_input_event(_viewport:Node, event:InputEvent, _shape_idx:int) -> void:
	if event is InputEventMouseButton && \
	event.button_index == MOUSE_BUTTON_LEFT && \
	event.pressed:
		queue_free()
		picked_up.emit()
