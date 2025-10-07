# Snowmobile.gd (Godot 4.x, GDScript)
extends RigidBody3D

const DRAG_COEFF   := 0.25
const DOWNFORCE_COEFF := 35.0
const TILT_LERP_SPEED := 6.0

var steer_input := 0.0
var throttle_input := 0.0
var brake_input := 0.0
var last_y_pos := 0.0
var camera_spring := 0.0
var is_driving := false
var n := FastNoiseLite.new()
var n_t := 0.0
var shake_amount := 0.0
var is_dead := false


@onready var start = $Start
@onready var idle = $Idle
@onready var go = $Go

@onready var ray: RayCast3D = $RayCast3D
@onready var visual: Node3D = $Visual
@onready var cam_mount: Node3D = $Visual/CamMount
@onready var camera_3d: Camera3D = $Visual/CamMount/Camera3D
@onready var snowmobile: Node3D = $Visual/snowmobile
@onready var fog_exhaust: GPUParticles3D = $Visual/FogExhaust

func _input(event: InputEvent) -> void:
	if is_driving and event.is_action_pressed("check_compass"):
		get_out()


func _physics_process(delta: float) -> void:
	if not is_driving or is_dead:
		if linear_velocity.length() > 0.3:
			linear_velocity *= 0.98
			tilt(delta)
		return
	if global_position.y <= -35.0:
		drown()
		return
	control_sound()
	n_t += delta * (shake_amount+1.0)
	snowmobile.position = Vector3(0.0, n.get_noise_1d(n_t*200.0)*shake_amount*0.02, 0.0)
	fog_exhaust.amount_ratio = clamp(linear_velocity.length()-0.5, 0.0, 15.0)/15.0
	var y_diff := last_y_pos - global_position.y
	last_y_pos = global_position.y
	camera_spring = lerp(camera_spring, (y_diff-camera_3d.position.y) * 0.5, 0.2)
	camera_3d.position.y += camera_spring
	camera_3d.rotation.y = angular_velocity.y*0.1
	camera_3d.rotation.z = angular_velocity.y*0.1
	shake_amount = lerp(shake_amount, throttle_input*3.0, delta*30.0)
	steer_input = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	throttle_input = Input.get_action_strength("move_fwd")
	brake_input = Input.get_action_strength("move_back")
	linear_velocity -= throttle_input*global_basis.z*delta * 20.0
	if linear_velocity.dot(-global_basis.z) > 1.0 and brake_input > 0.0:
		linear_velocity *= 0.98
	elif brake_input > 0.0 and throttle_input <= 0.0:
		linear_velocity -= -brake_input*global_basis.z*delta * 5.0
	if abs(steer_input) > 0.0:
		angular_velocity += global_basis.y * -steer_input * delta * 10.0 * clamp(linear_velocity.length()/10.0, 0.0, 1.0)
	tilt(delta)

func tilt(delta):
	var tilt_speed := TILT_LERP_SPEED
	var up := Vector3.UP
	if ray.get_collider():
		up = ray.get_collision_normal().normalized()
		if up.length_squared() < 0.999:
			up = up.normalized()
	else:
		tilt_speed *= 0.3
		up = Vector3.UP
	
	var body_forward := (-global_transform.basis.z)
	var forward := body_forward.slide(up).normalized()
	if forward.length_squared() < 1e-6:
		forward = Vector3.FORWARD
	var right := forward.cross(up).normalized()
	var target_basis := Basis(
		right,
		up,
		-forward
	).orthonormalized()
	# Smoothly slerp the visual’s rotation toward the target
	var q_from := Quaternion(visual.global_transform.basis)           # or visual.global_transform.basis.get_rotation_quaternion()
	var q_to   := Quaternion(target_basis)                            # or target_basis.get_rotation_quaternion()
	var t      : float = clamp(delta * tilt_speed, 0.0, 1.0)
	var q_new  := q_from.slerp(q_to, t)

	# Keep the visual’s position; only update rotation
	var xform := visual.global_transform
	xform.basis = Basis(q_new).orthonormalized()
	visual.global_transform = xform

func drown():
	if is_dead:
		return
	var damage_tween = create_tween()
	damage_tween.tween_property(%DrownMask, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	damage_tween.tween_property(%DrownLabel, "modulate:a", 1.0, 1.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_delay(2.0)
	damage_tween.tween_callback(respawn).set_delay(5.0)
	is_dead = true

func respawn():
	_G.outside.fade_in()
	await _G.outside.faded_in
	_G.outside.respawn()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var v = state.linear_velocity
	var speed = v.length()
	if speed > 0.01:
		state.apply_central_force(-v.normalized() * speed * speed * DRAG_COEFF)
		state.apply_central_force(-global_transform.basis.y * speed * DOWNFORCE_COEFF)


func _on_interacted() -> void:
	$Start.play()
	_G.found_snowmobile = true
	$Interaction.block = true
	last_y_pos = global_position.y -0.5
	shake_amount = 3.0
	is_driving = true
	camera_3d.current = true
	camera_3d.show()
	_G.player.block = true
	_G.player.position.y += 100.0
	_G.player.hide()
	$Idle.play()
	$Go.play()


func get_out():
	$Idle.stop()
	$Go.stop()
	camera_3d.current = false
	camera_3d.hide()
	$Interaction.block = false
	var found_exit := false
	for e in $Exits.get_children():
		if e.get_overlapping_bodies().is_empty():
			_G.player.global_position = e.global_position
			_G.player.global_rotation.y = global_rotation.y
			found_exit = true
			break
	if not found_exit:
		_G.player.global_position = global_position + Vector3.UP*1.0
	is_driving = false
	fog_exhaust.amount_ratio = 0.0
	_G.player.camera.current = true
	_G.player.block = false
	_G.player.show()

func _on_highlight_stopped() -> void:
	$Visual/snowmobile/Cube_012.material_overlay = null


func _on_highlights_started() -> void:
	$Visual/snowmobile/Cube_012.material_overlay = _G.HIGHLIGHT_MAT

func control_sound():
	var v : float= clamp(linear_velocity.length() / 30.0, 0.0, 1.0)
	$Idle.volume_db = remap(clamp(ease(v, 1.4), 0.0, 0.8), 0.0, 0.8, -10.0, -70.0)
	$Idle.pitch_scale = remap(clamp(ease(v, 1.4), 0.0, 0.8), 0.0, 0.8, 0.8, 1.2)
	$Go.volume_db = remap(clamp(ease(v, 0.5), 0.0, 0.6), 0.0, 0.6, -70.0, -10.0)
	$Go.pitch_scale = remap(clamp(ease(v, 0.5), 0.0, 1.0), 0.0, 1.0, 0.8, 1.2)
