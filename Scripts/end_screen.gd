extends Control

# Use this game API key if you want to test with a functioning leaderboard
# "987dbd0b9e5eb3749072acc47a210996eea9feb0"
var game_API_key = "dev_9e750f1f20134d8eac2b024855449471"
var development_mode = false
var leaderboard_key = "52-card-pickup"
var session_token = ""
var score = 0

# HTTP Request node can only handle one call per node
var auth_http = HTTPRequest.new()
var leaderboard_http = HTTPRequest.new()
var submit_score_http = HTTPRequest.new()
var set_name_http = HTTPRequest.new()
var get_name_http = HTTPRequest.new()

signal restart_game

@onready var play_button = $PlayButton

@onready var final_header = $FinalScore/Header
@onready var final_score = $FinalScore/Score

@onready var leaderboard = $Leaderboard/Board
@onready var name_text_edit = $Leaderboard/ChangePlayerNameText
@onready var save_name_button = $Leaderboard/SavePlayerNameButton

func _ready():
	_authentication_request()
	leaderboard.visible = false

func _authentication_request():
	# Check if a player session exists
	var player_session_exists = false
	var player_identifier : String
	var file = FileAccess.open("user://LootLocker.data", FileAccess.READ)
	if file != null:
		player_identifier = file.get_as_text()
		#print("player ID="+player_identifier)
		file.close()
 
	if player_identifier != null and player_identifier.length() > 1:
		#print("player session exists, id="+player_identifier)
		player_session_exists = true
	if(player_identifier.length() > 1):
		player_session_exists = true
		
	## Convert data to json string:
	var data = { "game_key": game_API_key, "game_version": "0.0.0.1", "development_mode": development_mode }
	
	# If a player session already exists, send with the player identifier
	if(player_session_exists == true):
		data = { "game_key": game_API_key, "player_identifier":player_identifier, "game_version": "0.0.0.1", "development_mode": development_mode }
	
	# Add 'Content-Type' header:
	var headers = ["Content-Type: application/json"]
	
	# Create a HTTPRequest node for authentication
	auth_http = HTTPRequest.new()
	add_child(auth_http)
	auth_http.request_completed.connect(_on_authentication_request_completed)
	# Send request
	auth_http.request("https://api.lootlocker.io/game/v2/session/guest", headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	# Print what we're sending, for debugging purposes:
	#print(data)

func _on_authentication_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	
	# Save the player_identifier to file
	var file = FileAccess.open("user://LootLocker.data", FileAccess.WRITE)
	file.store_string(json.get_data().player_identifier)
	file.close()
	
	# Save session_token to memory
	session_token = json.get_data().session_token
	
	# Print server response
	#print(json.get_data())
	
	# Clear node
	auth_http.queue_free()
	# Get leaderboards
	_get_leaderboards()

func _get_leaderboards():
	#print("Getting leaderboards")
	
	var url = "https://api.lootlocker.io/game/leaderboards/"+leaderboard_key+"/list?count=10"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	# Create a request node for getting the highscore
	leaderboard_http = HTTPRequest.new()
	add_child(leaderboard_http)
	leaderboard_http.request_completed.connect(_on_leaderboard_request_completed)
	
	# Send request
	leaderboard_http.request(url, headers, HTTPClient.METHOD_GET, "")

func _on_leaderboard_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	
	# Print data
	#print(json.get_data())
	
	# Formatting as a leaderboard
	var leaderboardFormatted = ""
	if json.get_data().items != null:
		for n in json.get_data().items.size():
			var player = str(json.get_data().items[n].player.name) if json.get_data().items[n].player.name != "" else str(json.get_data().items[n].player.id)
			
			leaderboardFormatted += str(json.get_data().items[n].rank)+str(". ")
			leaderboardFormatted += player+str(" - ")
			leaderboardFormatted += str(json.get_data().items[n].score)+str("\n")
		# Print the formatted leaderboard to the console
		leaderboard.text = leaderboardFormatted
		leaderboard.visible = true
		#print(leaderboardFormatted)
	
	# Clear node
	leaderboard_http.queue_free()

func _upload_score(score: int):
	var data = { "score": str(score) }
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	submit_score_http = HTTPRequest.new()
	add_child(submit_score_http)
	submit_score_http.request_completed.connect(_on_upload_score_request_completed)
	# Send request
	submit_score_http.request("https://api.lootlocker.io/game/leaderboards/"+leaderboard_key+"/submit", headers, HTTPClient.METHOD_POST, JSON.stringify(data))
	# Print what we're sending, for debugging purposes:
	#print(data)

func _on_upload_score_request_completed(result, response_code, headers, body) :
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	
	# Print data
	#print(json.get_data())
	
	# Clear node
	submit_score_http.queue_free()
	
	_get_leaderboards()

func _change_player_name(player_name):
	#print("Changing player name")
	
	var data = { "name": str(player_name) }
	var url =  "https://api.lootlocker.io/game/player/name"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	# Create a request node for getting the highscore
	set_name_http = HTTPRequest.new()
	add_child(set_name_http)
	set_name_http.request_completed.connect(_on_player_set_name_request_completed)
	# Send request
	set_name_http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(data))
	
func _on_player_set_name_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	
	# Print data
	#print(json.get_data())
	set_name_http.queue_free()
	
	_get_leaderboards()

func _get_player_name():
	#print("Getting player name")
	var url = "https://api.lootlocker.io/game/player/name"
	var headers = ["Content-Type: application/json", "x-session-token:"+session_token]
	
	# Create a request node for getting the highscore
	get_name_http = HTTPRequest.new()
	add_child(get_name_http)
	get_name_http.request_completed.connect(_on_player_get_name_request_completed)
	# Send request
	get_name_http.request(url, headers, HTTPClient.METHOD_GET, "")

func _on_player_get_name_request_completed(result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	
	# Print data
	#print(json.get_data())
	# Print player name
	#print(json.get_data().name)

func _on_save_button_pressed() -> void:
	save_name_button.disabled = true
	var name = name_text_edit.text
	_change_player_name(name)
	name_text_edit.text = ""

func _on_name_changed() -> void:
	save_name_button.disabled = false

func _on_main_game_over(win : bool, score: int) -> void:
	if win == true:
		final_header.text = "You Win!"
	else:
		final_header.text = "Better Luck Next Time"
		
	final_score.text = "Score: " + str(score)
	_upload_score(score)


func _on_play_button_pressed() -> void:
	restart_game.emit()
