extends Node2D

@onready var deck = $Deck
@onready var game_timer : Timer = $GameTimer
@onready var lava_timer : Timer = $LavaTimer
@onready var hud : CanvasLayer = $HUD
@onready var score_label : Label = $HUD/ScoreLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var end_screen : Control = $EndScreen 
@onready var instructions : Control = $Instructions

var lava_scene = preload("res://Scenes/lava.tscn")
var window_size : Vector2 = Vector2(1200, 800)

signal game_over

var score : int = 0

func _ready() -> void:
	update_score_label()
	hud.visible = true
	end_screen.visible = false
	
func _physics_process(delta: float) -> void:
	update_time_label()

func time_left_in_game():
	var time_left: float = game_timer.time_left
	var minutes = floor(time_left / 60)
	var seconds = int(time_left) % 60
	return [minutes, seconds]

func update_time_label():
	time_label.text = "Time: %02d:%02d" % time_left_in_game()

func update_score_label():
	score_label.text = "Score: " + str(score)

func _on_deck_update_score(points:int) -> void:
	score += points
	update_score_label()
	print("score: ", score)

func _on_deck_collected_all() -> void:
	score += game_timer.time_left
	game_timer.stop()
	end_game(true)
	
func _on_game_timer_timeout() -> void:
	end_game(false)
	
func end_game(win : bool) -> void:
	game_over.emit(win, score)
	deck.queue_free()
	hud.visible = false
	end_screen.visible = true

func _on_end_screen_restart_game() -> void:
	get_tree().reload_current_scene()

func _on_play_pressed() -> void:
	instructions.visible = false
	game_timer.start()
	lava_timer.start()

func _on_lava_timer_timeout() -> void:
	var lava = lava_scene.instantiate()
	lava.position.x = randf_range(50, window_size.x - 50)
	lava.position.y = randf_range(100, window_size.y - 50)
	add_child(lava)
