extends KinematicBody

var speed = 7
const ACCEL_DEFAULT = 3
const ACCEL_BOOST = 10
onready var accel = ACCEL_DEFAULT
#var gravity = 9.8
#var jump = 5

var cam_accel = 40
var mouse_sense = 0.1
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#get mouse input for camera rotation
	if event is InputEventMouseMotion:
#		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		rotate_x(deg2rad(-event.relative.y * mouse_sense))
		if (rotation.x > deg2rad(90) or rotation.x < deg2rad(-90)):
			rotate_y(deg2rad(event.relative.x * mouse_sense))
		else:
			rotate_y(deg2rad(-event.relative.x * mouse_sense))
#		rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _process(_delta):
		print(rad2deg(rotation.x))
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
#	if Engine.get_frames_per_second() > Engine.iterations_per_second:
#		camera.set_as_toplevel(true)
#		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
#		camera.rotation.y = rotation.y
#		camera.rotation.x = head.rotation.x
#	else:
		camera.set_as_toplevel(false)
		camera.global_transform = global_transform
		
func _physics_process(delta):
	#get keyboard input
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var v_rot = global_transform.basis.get_euler().x
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var v_input = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	var z_rotator = Input.get_action_strength("tilt_left") - Input.get_action_strength("tilt_right")
	rotate_z(deg2rad(z_rotator * 1))
	direction = Vector3(h_input, v_input, f_input).rotated(global_transform.basis.y, h_rot).rotated(global_transform.basis.x, v_rot).normalized()
	
#	#jumping and gravity
#	if is_on_floor():
#		snap = -get_floor_normal()
#		accel = ACCEL_DEFAULT
#		gravity_vec = Vector3.ZERO
#	else:
#		snap = Vector3.DOWN
#		accel = ACCEL_AIR
#		gravity_vec += Vector3.DOWN * gravity * delta
#
#	if Input.is_action_just_pressed("jump") and is_on_floor():
#		snap = Vector3.ZERO
#		gravity_vec = Vector3.UP * jump
	
	#make it move
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	movement = velocity + gravity_vec
	
# warning-ignore:return_value_discarded
	move_and_slide(movement, global_transform.basis.y)
	
	
	
