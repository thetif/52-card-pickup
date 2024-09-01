extends Node2D

@onready var game_timer : Timer = $GameTimer
@onready var score_label : Label = $HUD/ScoreLabel
@onready var time_label: Label = $HUD/TimeLabel

var score : int = 0

func _ready() -> void:
	game_timer.start() # 5 minute timer
	update_score_label()
	
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
	update_score_label()
	print("final score: ", score)
	game_timer.stop()
	get_tree().quit()
	
func _on_game_timer_timeout() -> void:
	print("timeout score: ", score)
