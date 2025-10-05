extends Node3D

@export var station_id := 1

var is_open := false

@onready var radarmast_console_cap: MeshInstance3D = $radar/RadarmastConsoleCap

func _ready() -> void:
	$radar/RadarmastTop/Label3D.text = "Station %s" % station_id
	$ScreenViewport/RadarScreen.set_station_id(station_id)
	$ScreenViewport/RadarScreen.disable_screen()
	$ScreenViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	

func _on_door_highlights_started() -> void:
	radarmast_console_cap.material_overlay = _G.HIGHLIGHT_MAT

func _on_door_highlight_stopped() -> void:
	radarmast_console_cap.material_overlay = null

func _on_door_interacted() -> void:
	if is_open:
		return
	var t := create_tween()
	t.tween_property(radarmast_console_cap, "rotation_degrees:x", 90.0, 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	is_open = true
	$DoorInteraction.block = true
	$LeverInteraction.block = false

func _on_lever_highlights_started() -> void:
	$radar/RadarmastLever.material_overlay = _G.HIGHLIGHT_MAT

func _on_lever_highlight_stopped() -> void:
	$radar/RadarmastLever.material_overlay = null

func _on_lever_interacted() -> void:
	$Beep.play()
	$ExtendStatiopn.play()
	$LeverInteraction.block = true
	var t := create_tween()
	t.tween_property($radar/RadarmastLever, "rotation_degrees:x", -180.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	t.tween_property($radar/RadarmastTop, "position:y", 0.0, 12.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	t.set_parallel().tween_property($radar/RadarmastTop/RadarmastTop2, "position:y", 4.0, 12.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	$radar/Radarmast_On.show()
	$radar/RadarmastTop/RadarmastTop2/Radarmast_On_2.show()
	$radar/Radarmast_Off.hide()
	$radar/RadarmastTop/RadarmastTop2/Radarmast_Off_2.hide()
	$ScreenViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	$ScreenViewport/RadarScreen.enable_screen()
