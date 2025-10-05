extends Control

var game_started := false


func _ready() -> void:
	%WhiteFade.show()
	var t := create_tween()
	t.tween_property(%WhiteFade, "modulate:a", 0.0, 2.0)

func _on_button_pioneer_pressed() -> void:
	if game_started:
		return
	game_started = true
	$VBoxContainer/HBoxContainer/ButtonPioneer.modulate.a = 0.0
	$VBoxContainer/HBoxContainer/ButtonSupervisor.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(%WhiteFade, "modulate:a", 1.0, 1.0)
	t.tween_callback(change_to_pioneer)

func change_to_pioneer():
	get_tree().change_scene_to_file("res://stages/outside/outside_stage.tscn")

func _on_button_supervisor_pressed() -> void:
	if game_started:
		return
	game_started = true
	$VBoxContainer/HBoxContainer/ButtonPioneer.modulate.a = 0.0
	$VBoxContainer/HBoxContainer/ButtonSupervisor.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(%BlackFade, "modulate:a", 1.0, 1.0)
	t.tween_callback(change_to_supervisor)

func change_to_supervisor():
	RenderingServer.set_default_clear_color(Color.BLACK)
	get_tree().change_scene_to_file("res://stages/home/home_stage.tscn")
