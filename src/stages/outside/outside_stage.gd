extends Node3D

@export var override_respawn := false

const win_text := "Your run took %s minutes.

You died %s times."

signal faded_in

func _enter_tree() -> void:
	_G.outside = self

func _ready() -> void:
	if not override_respawn:
		respawn()
	else:
		_G.respawns = 1
		%BlackFade.modulate.a = 0.0

func game_over():
	_G.player.block = true
	var t := create_tween().set_parallel()
	t.tween_property(%WinFade, "modulate:a", 1.0, 3.0)
	t.tween_property(%WinLabel1, "modulate:a", 1.0, 2.0).set_delay(1.0+4.0)
	t.tween_property(%WinLabel1, "modulate:a", 0.0, 1.0).set_delay(8.0+4.0)
	t.tween_property(%WinLabel2, "modulate:a", 1.0, 2.0).set_delay(10.0+4.0)
	t.tween_property(%WinLabel2, "modulate:a", 0.0, 1.0).set_delay(17.0+4.0)
	%WinLabel3.text = win_text % [_G.timer, _G.respawns-1]
	t.tween_property(%WinLabel3, "modulate:a", 1.0, 2.0).set_delay(19.0+4.0)
	

func _physics_process(_delta: float) -> void:
	var height := get_viewport().get_camera_3d().global_position.y
	get_tree().call_group("snow", "set_amount_ratio", clamp(remap(height, -50.0, 80.0, 0.3, 1.0), 0.2, 1.0))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("respawn"):
		respawn()

func respawn():
	_G.respawns += 1
	get_tree().get_first_node_in_group("player").queue_free()
	var spawn_points := get_tree().get_nodes_in_group("spawn-point")
	var spawn_point :Node3D = spawn_points.pick_random()
	var player := preload("res://content/player/player.tscn").instantiate()
	player.position = spawn_point.global_position
	player.rotation.y = spawn_point.global_rotation.y
	add_child(player)
	if _G.found_snowmobile:
		get_tree().get_first_node_in_group("snowmobile").queue_free()
		var snowmobile := preload("res://content/snowmobile/snowmobile.tscn").instantiate()
		snowmobile.position = spawn_point.global_position + spawn_point.global_basis.x*2.0 - spawn_point.global_basis.z*1.3
		snowmobile.rotation.y = spawn_point.global_rotation.y
		add_child(snowmobile)
	if _G.respawns == 1:
		play_intro()
	else:
		var t := create_tween()
		t.tween_property(%BlackFade, "modulate:a", 0.0, 2.0).set_delay(0.2)

func play_intro():
	var t := create_tween().set_parallel()
	t.tween_property(%IntroLabel1, "modulate:a", 1.0, 2.0).set_delay(1.0)
	t.tween_property(%IntroLabel1, "modulate:a", 0.0, 1.0).set_delay(8.0)
	t.tween_property(%IntroLabel2, "modulate:a", 1.0, 2.0).set_delay(10.0)
	t.tween_property(%IntroLabel2, "modulate:a", 0.0, 1.0).set_delay(17.0)
	t.tween_property(%IntroLabel3, "modulate:a", 1.0, 2.0).set_delay(19.0)
	t.tween_property(%IntroLabel3, "modulate:a", 0.0, 1.0).set_delay(27.0)
	t.tween_property(%BlackFade, "modulate:a", 0.0, 3.0).set_delay(24)


func fade_in(duration:= 1.5):
	var t := create_tween()
	t.tween_property(%BlackFade, "modulate:a", 1.0, duration)
	t.tween_callback(func(): faded_in.emit())
	
