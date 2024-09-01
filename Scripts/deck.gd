extends Node2D

@export var card_textures : Array[Texture2D]

var window_size : Vector2 = Vector2(1200, 800)
var card_scene = preload("res://Scenes/card.tscn")
var last_clicked = 1

signal update_score
signal collected_all

func _ready() -> void:
	for texture in card_textures:
		var card = card_scene.instantiate()
		card.card_image = texture
		card.position.x = randf_range(100, window_size.x - 50)
		card.position.y = randf_range(50, window_size.y - 50)
		card.rotation_degrees = randf_range(-180, 180)
		add_child(card)
		card.connect("picked_up", _on_card_picked_up)
	last_clicked = Time.get_ticks_msec()
		
func _on_card_picked_up():
	var score = calculate_score()
	last_clicked = Time.get_ticks_msec()
	update_score.emit(score)
	
	print("children: ", get_child_count())
	if get_child_count() == 1:
		collected_all.emit()

func calculate_score() -> int:
	var elapsed_msec : int = Time.get_ticks_msec() - last_clicked
	if elapsed_msec < 600:
		elapsed_msec = 600
	var elapsed_sec : float = elapsed_msec/1000.0
	var inversed : float = 1.0/elapsed_sec
	var score : float = inversed * 100
	return round(score)
