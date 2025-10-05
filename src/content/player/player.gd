extends CharacterBody3D

@export var is_inside := false

@export var max_speed := 5.0
@export var max_speed_sprinting := 9.0
@export var acceleration := 20.0
@export var decceleration := 10.0
@export var mouse_sensitivity := 3.0
@export var mouse_movement_reduction := 0.001
@export var cam_vertical_limit := PI*0.48
@export var cam_default_fov := 75.0

var fall_damage := 0.0
var is_sprinting := false
var block := false
var last_global_position : Vector3
var on_ground_for := 0.0
var health := 20.0
var is_dead := false
var damage_tween : Tween
var damage_tween_cam : Tween

@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var interactor: RayCast3D = $Head/Camera3D/Interactor
@onready var camera: Camera3D = $Head/Camera3D
@onready var damage: TextureRect = %Damage

var last_interactor : Node
var step_distance := 0.0

func _ready() -> void:
	_G.player = self
	camera_3d.fov = cam_default_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_inside:
		$Items/Compass.queue_free()
		$Snow.hide()
		$Fog.hide()
		$Head/Camera3D/PostProcessInside.show()
	else:
		$Snow.show()
		$Fog.show()
		$Head/Camera3D/PostProcessOutside.show()

func _physics_process(delta: float) -> void:
	if block:
		return
	
	check_kill()
	slowly_heal(delta)
	check_interactor()
	control_movement(delta)
	control_camera(delta)
	move_and_slide()
	check_falldamage(delta)
	stepper()
	last_global_position = global_position

func stepper():
	if is_on_floor():
		step_distance += global_position.distance_to(last_global_position)
		if step_distance > 1.3:
			if is_inside:
				pass
			else:
				$StepSnow.play()
			step_distance = 0.0

func slowly_heal(delta):
	if is_dead:
		return
	if health <= 0.0:
		die()
		return
	health = clamp(delta+health, 0.0, 20.0)
	damage.modulate.a = remap(health, 0.0, 20.0, 1.0, 0.0)

func check_kill():
	if global_position.y <= -70.0:
		drown()

func drown():
	if is_dead:
		return
	if damage_tween:
		damage_tween.kill()
	damage_tween = create_tween()
	damage_tween.tween_property(%DrownMask, "modulate:a", 1.0, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	damage_tween.tween_property(%DrownLabel, "modulate:a", 1.0, 1.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_delay(2.0)
	damage_tween.tween_callback(respawn).set_delay(5.0)
	block = true
	is_dead = true

func die():
	if is_dead:
		return
	damage.modulate.a = 1.0
	if damage_tween:
		damage_tween.kill()
	damage_tween = create_tween()
	damage_tween.tween_property(%Hit, "modulate:a", 0.7, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	if damage_tween_cam:
		damage_tween_cam.kill()
	damage_tween_cam = create_tween().set_parallel()
	damage_tween_cam.tween_property(camera, "rotation:z", 0.5, 1.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	damage_tween_cam.tween_property(camera, "position:y", -0.7, 1.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	damage_tween_cam.tween_property(%DeathLabel, "modulate:a", 1.0, 1.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_delay(2.0)
	damage_tween_cam.tween_callback(respawn).set_delay(5.0)
	block = true
	is_dead = true

func respawn():
	_G.outside.fade_in()
	await _G.outside.faded_in
	_G.outside.respawn()

func _input(event) -> void:
	if block:
		return
	if event is InputEventMouseMotion:
		var mouse_offset: Vector2 = event.relative * mouse_movement_reduction * mouse_sensitivity
		rotate_body(mouse_offset.x)
		control_head(mouse_offset.y)

func check_interactor():
	var c := interactor.get_collider()
	if c != null:
		last_interactor = c
		last_interactor.start_highlight()
		if Input.is_action_just_pressed("interact"):
			last_interactor.try_interact()
	elif last_interactor != null:
		last_interactor.stop_highlight()
		last_interactor = null
		

func control_movement(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor() and on_ground_for > 0.1:
		velocity.y += 4.0
		
	#is_sprinting = Input.is_action_pressed("sprint")
	is_sprinting = false
	var input_vector := Input.get_vector("move_left", "move_right", "move_back", "move_fwd")
	var current_max_speed := max_speed if not is_sprinting else max_speed_sprinting
	if input_vector.length() > 0.1:
		var forward_back := global_transform.basis.z*-input_vector.y
		var strafe := global_transform.basis.x*input_vector.x
		var total_movement := (strafe + forward_back).limit_length(1.0)
		velocity = velocity+(total_movement*delta*acceleration)
		if Vector3(velocity.x, 0.0, velocity.z).length() > current_max_speed:
			var max_calc := Vector3(velocity.x, 0.0, velocity.z).limit_length(current_max_speed)
			max_calc.y = velocity.y
			velocity = velocity.move_toward(max_calc, min(delta*60.0, 1.0))
	else:
		velocity = velocity.move_toward(Vector3(0.0, velocity.y, 0.0), delta*decceleration)
	if not is_on_floor():
		velocity += get_gravity() * delta

func check_falldamage(delta):
	if is_dead:
		return
	if not is_on_floor():
		fall_damage += last_global_position.y - global_position.y
		on_ground_for = 0.0
	else:
		on_ground_for = min(on_ground_for+delta, 0.5)
		if on_ground_for > 0.1:
			if fall_damage > 4.0:
				if damage_tween_cam:
					damage_tween_cam.kill()
				damage_tween_cam = create_tween()
				damage_tween_cam.tween_property(camera, "rotation:z", randf_range(0.1, 0.2)+fall_damage*0.05, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
				damage_tween_cam.tween_property(camera, "rotation:z", 0.0, 0.4+fall_damage*0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				if damage_tween:
					damage_tween.kill()
				damage_tween = create_tween()
				damage_tween.tween_property(%Hit, "modulate:a", remap(fall_damage, 4.0, 20.0, 0.2, 1.0), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
				damage_tween.tween_property(%Hit, "modulate:a", 0.0, 0.4+fall_damage*0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				health -= fall_damage
				if health <= 0.0:
					die()
			fall_damage = 0.0

func rotate_body(offset:float):
	rotation.y -= offset

func control_camera(delta:float):
	var movement_speed: Vector2 = Vector2(velocity.x, velocity.y)
	var target_fov := cam_default_fov if not is_sprinting else cam_default_fov + (15.0*(movement_speed.length()/max_speed_sprinting))
	camera_3d.fov = lerp(camera_3d.fov, target_fov, delta*3.0)

func control_head(offset:float):
	head.rotation.x = clamp(head.rotation.x-offset, -cam_vertical_limit, cam_vertical_limit)
