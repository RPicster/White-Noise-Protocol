extends Node

const HIGHLIGHT_MAT := preload("res://content/materials/interaction_overlay_mat.tres")

var STATION_CODES := {
	1 : 523567,
	2 : 912568,
	3 : 756218,
	4 : 512932
}

var station_state := {
	1: false,
	2: false,
	3: false,
	4: false,
}

var log_entries := {
	1: {"title" : "30.11.1978",
		"entry" : "We just arrived. The last shift left and I feel like I will have a great time with my collegue!\n\nAs soon as the network stations are online we will be so much quicker."},
	2: {"title" : "18.12.1978",
		"entry" : "Today was the best weather we saw in quite a while!\n\nWe used the opportunity and mapped out the surroundings more.\nThe network is a bit shaky tho."},
	3: {"title" : "13.8.1979",
		"entry" : "These cursed network stations are offline again!\n\nI swear, one day I am going to go out and fix them myself!\nI feel like this monkey has two left hands!"},
}

var respawns := 0
var timer := 0
var outside : Node3D
var player : Node3D
var fullscreen := false
var found_snowmobile := false

func _ready() -> void:
	var t := Timer.new()
	add_child(t)
	t.one_shot = false
	t.wait_time = 60.0
	t.timeout.connect(increase_time)
	t.start()

func increase_time():
	timer += 1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		if not fullscreen:
			fullscreen = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			fullscreen = false
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func stations_online() -> bool:
	var is_online := true
	for s in station_state.values():
		if not s:
			is_online = false
			break
	return is_online

func get_online_station_count() -> int:
	var online_stations := 0
	for s in station_state.values():
		if s:
			online_stations += 1
	return online_stations
