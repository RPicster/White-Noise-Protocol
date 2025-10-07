extends Node3D

@onready var compass_needle: Node3D = $Visual/compass_needle
@onready var compass_aim: Node3D = $Visual/compass_aim

@onready var invisible_needle: Marker3D = $InvisibleNeedle
@onready var invisible_aim: Marker3D = $InvisibleAim

@onready var visual: Node3D = $Visual

var needle_spring := 0.0
var last_target_needle_position := 0.0
var movement := 0.0
var delay := 0.0
var is_active := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("check_compass"):
		_G.player.finish_tutorial()
		is_active = !is_active

func _physics_process(delta: float) -> void:
	var target_needle_rotation = -invisible_needle.global_rotation.y
	movement = angle_difference(target_needle_rotation, last_target_needle_position)
	last_target_needle_position = target_needle_rotation
	
	invisible_aim.rotation.y = lerp_angle(invisible_aim.rotation.y, target_needle_rotation, delta*2.0)
	compass_aim.rotation.y = snapped(invisible_aim.rotation.y, PI*0.01)
	
	var err := angle_difference(compass_needle.rotation.y, target_needle_rotation)
	needle_spring = lerp(needle_spring, err*0.5, 0.05)
	compass_needle.rotation.y += needle_spring
	visual.visible = visual.position.y > 0.2
	visual.position.y = lerp(visual.position.y, 0.0 if not is_active else 0.4, delta*5.0)
	visual.position.z = lerp(visual.position.z, 0.4 if not is_active else 0.0, delta*5.0)
	visual.scale = lerp(visual.scale, Vector3.ONE*0.1 if not is_active else Vector3.ONE, delta*5.0)
	visual.rotation.x = lerp_angle(visual.rotation.x, 0.1 if not is_active else 0.4, delta*5.0)
