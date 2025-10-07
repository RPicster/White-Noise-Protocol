extends Node3D

var using_computer := false
@export var override_intro := false

func _ready():
	if override_intro:
		%BlackFade.modulate.a = 0.0
		return
	$Player.block = true
	var t := create_tween().set_parallel()
	t.tween_property(%IntroLabel1, "modulate:a", 1.0, 2.0).set_delay(1.0)
	t.tween_property(%IntroLabel1, "modulate:a", 0.0, 1.0).set_delay(6.0)
	t.tween_property(%IntroLabel2, "modulate:a", 1.0, 2.0).set_delay(8.0)
	t.tween_property(%IntroLabel2, "modulate:a", 0.0, 1.0).set_delay(13.0)
	t.tween_property(%IntroLabel3, "modulate:a", 1.0, 2.0).set_delay(15.0)
	t.tween_property(%IntroLabel3, "modulate:a", 0.0, 1.0).set_delay(23.0)
	t.tween_property(%BlackFade, "modulate:a", 0.0, 3.0).set_delay(20)
	t.tween_callback(func(): $Player.block = false).set_delay(20)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and using_computer:
		stop_using_computer()
	if using_computer:
		$ScreenViewport/ComputerScreen.input(event)

func _on_computer_highlights_started() -> void:
	$station/Keyboard.material_overlay = _G.HIGHLIGHT_MAT


func _on_computer_highlight_stopped() -> void:
	$station/Keyboard.material_overlay = null


func _on_computer_interacted() -> void:
	if using_computer:
		return
	using_computer = true
	$Player.block = true
	var c_cam := $ComputerCamera
	var c_cam_t := $ComputerCameraPosition
	var original_position: Vector3 = c_cam_t.global_position
	var original_rotation: Vector3 = c_cam_t.global_rotation
	var original_fov: float = 33.4
	c_cam.global_position = get_viewport().get_camera_3d().global_position
	c_cam.global_rotation = get_viewport().get_camera_3d().global_rotation
	c_cam.fov = get_viewport().get_camera_3d().fov
	c_cam.current = true
	var t := create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(c_cam, "global_position", original_position, 0.5)
	t.tween_property(c_cam, "global_rotation", original_rotation, 0.5)
	t.tween_property(c_cam, "fov", original_fov, 0.5)
	t.tween_callback($ScreenViewport/ComputerScreen.start_computer).set_delay(0.7)

func stop_using_computer():
	if not using_computer:
		return
	$ScreenViewport/ComputerScreen.exit_computer()
	var c_cam := $ComputerCamera
	var v_cam: Camera3D = $Player.camera
	var original_position: Vector3 = v_cam.global_position
	var original_rotation: Vector3 = v_cam.global_rotation
	var original_fov: float = v_cam.fov
	var t := create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.tween_property(c_cam, "global_position", original_position, 0.3)
	t.tween_property(c_cam, "global_rotation", original_rotation, 0.3)
	t.tween_property(c_cam, "fov", original_fov, 0.3)
	t.tween_callback(stopped_using_computer.bind(v_cam)).set_delay(0.3)

func stopped_using_computer(cam:Camera3D):
	using_computer = false
	$Player.block = false
	cam.current = true


func _on_computer_exit_request() -> void:
	stop_using_computer()


func _on_computer_screen_beep() -> void:
	$Beep.play()
