extends CharacterBody3D

@export var is_inside := false

@export var max_speed := 3.0
@export var max_speed_sprinting := 5.0
@export var acceleration := 20.0
@export var decceleration := 10.0
@export var mouse_sensitivity := 3.0
@export var mouse_movement_reduction := 0.001
@export var cam_vertical_limit := PI*0.48
@export var cam_default_fov := 75.0

var is_sprinting := false
var block := false

@onready var head: Node3D = $Head
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var interactor: RayCast3D = $Head/Camera3D/Interactor
@onready var camera: Camera3D = $Head/Camera3D

var last_interactor : Node

func _ready() -> void:
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
	check_interactor()
	control_movement(delta)
	control_camera(delta)
	move_and_slide()

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
	is_sprinting = Input.is_action_pressed("sprint")
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
		velocity += get_gravity()

func rotate_body(offset:float):
	rotation.y -= offset

func control_camera(delta:float):
	var movement_speed: Vector2 = Vector2(velocity.x, velocity.y)
	var target_fov := cam_default_fov if not is_sprinting else cam_default_fov + (15.0*(movement_speed.length()/max_speed_sprinting))
	camera_3d.fov = lerp(camera_3d.fov, target_fov, delta*3.0)

func control_head(offset:float):
	head.rotation.x = clamp(head.rotation.x-offset, -cam_vertical_limit, cam_vertical_limit)
