extends KinematicBody

#camera control
var lookSensitivity = 10
var mouseDelta := Vector2()
var mouse_dir := Vector2()
var camera_lock = true
#ship control
enum ShipState {OFF,ON, STARTUP, SHUTDOWN}
export(ShipState) var CurrentState
#ship steering params
var acceleration = 0.6
var max_speed_forw = 30
var max_speed_backw = 10
var pitch_speed = 1.5
var roll_speed = 2.0
var yaw_speed = 1.2
var input_response = 4.0
#ship params
var fuel = 100
var fuelcons = 1
#changing vars
var velocity = Vector3.ZERO
var speed = 0
var pitch_input = 0
var roll_input = 0
var yaw_input = 0
#references
onready var camera  = $Camera
onready var head = $Camera/head
onready var raycast = $Camera/RayCast
onready var pointerL = $PointerL
onready var pointerR = $PointerR
onready var compass = $Compass
onready var compassMat = $"Compass/3D Compass".get_surface_material(0)

export var compassTarget: NodePath


func _ready():
	CurrentState = ShipState.OFF 
	camera.set_as_toplevel(true)
	camera.global_transform = global_transform
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 


func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative



func _process(delta):
	animation_control()
	mission_compass()
	camera_control(delta)
	if Input.is_action_just_pressed("Ignition"):
		if CurrentState == ShipState.ON: #power down
			CurrentState = ShipState.SHUTDOWN
		elif CurrentState == ShipState.OFF:
			CurrentState = ShipState.STARTUP
	if fuel <= 0.05:
		CurrentState = ShipState.SHUTDOWN
	if CurrentState == ShipState.ON:
		display_info()
	
	#gun pointing
	var point = raycast.get_collision_point()
	if point:
		pointerL.look_at(point, transform.basis.y)
		pointerR.look_at(point, transform.basis.y)


func _physics_process(delta):
	match CurrentState:
		ShipState.OFF:
			speed = lerp(speed, 0, acceleration * delta)
		ShipState.ON:
			get_input(delta)
	#ship rotation
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.z, roll_input * roll_speed * delta)
	transform.basis = transform.basis.orthonormalized()
	#ship thrust
	velocity = -transform.basis.z * speed
	# warning-ignore:return_value_discarded
	move_and_collide(velocity * delta)


func get_input(delta):
	#thust
	if Input.is_action_pressed("thrust forw"):
		speed = lerp(speed, max_speed_forw, acceleration * delta)
		fuel = lerp(fuel, 0, abs(speed/10000*fuelcons)*delta)
	if Input.is_action_pressed("thrust backw"):
		speed = lerp(speed, -max_speed_backw, acceleration * delta)
		fuel = lerp(fuel, 0, abs(speed/10000*fuelcons)*delta)
	else:
		speed = lerp(speed, 0, acceleration * delta)
	#rotation
	mouse_dir = (mouseDelta * input_response * delta)
#	pitch_input = lerp(pitch_input, Input.get_axis("pitch down", "pitch up"), input_response * delta) 
#	yaw_input = lerp(yaw_input, Input.get_axis( "yaw right", "yaw left"), input_response * delta)
	roll_input = lerp(roll_input, Input.get_axis("roll right", "roll left"), input_response * delta)
	#mouse control
	if !camera_lock:
		pitch_input = clamp(lerp(pitch_input, -mouse_dir.y , input_response * delta), -pitch_speed, pitch_speed)
		yaw_input = clamp(lerp(yaw_input, -mouse_dir.x, input_response * delta), -yaw_speed, yaw_speed)
	else:
		pitch_input = lerp(pitch_input, 0, input_response * delta)
		yaw_input = lerp(yaw_input, 0, input_response * delta)


func display_info():
	$ShipInterface/MainDisplay.text = "THRUST: " + String(stepify(speed, 0.1)) + "\nFUEL: " + String(stepify(fuel, 0.1)) + "%"
	$ShipInterface/X_display.text = String(abs(stepify(rad2deg(rotation.x), 0.1)))
	$ShipInterface/Y_display.text = String(abs(stepify(rad2deg(rotation.y), 0.1)))
	$ShipInterface/Z_display.text = String(abs(stepify(rad2deg(rotation.z), 0.1)))


func camera_control(delta):
	if Input.is_action_pressed("unlock_camera") or CurrentState == ShipState.OFF: #unlock camera
		camera_lock = true
		camera.global_transform = global_transform
		head.rotation_degrees.x -= mouseDelta.y * lookSensitivity * delta
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -89, 89)
		head.rotation_degrees.y -= mouseDelta.x * lookSensitivity * delta
	elif CurrentState != ShipState.OFF: #lock camera
		camera_lock = false
		camera.global_transform = global_transform
		camera.rotation.x = lerp_angle(camera.rotation.x, rotation.x, 10 * delta)
		camera.rotation.y = lerp_angle(camera.rotation.y, rotation.y, 10 * delta)
		camera.rotation.z = lerp_angle(camera.rotation.z, rotation.z, 10 * delta)
		head.rotation = lerp(head.rotation, Vector3(0, deg2rad(0), 0), 10 * delta)
	mouseDelta = Vector2() #stops camera movement without input
	head.transform.origin.x = lerp (head.transform.origin.x, 0.0, 2 * delta) #smooth transition from freelook


func animation_control():
	match CurrentState:
		ShipState.OFF:
			if $AnimationPlayer.current_animation != "PowerUp":
				$AnimationPlayer.play("NO POWER")
				compassMat.albedo_color = Color(1, 0, 0, 0.75)
		ShipState.STARTUP:
			$AnimationPlayer.play("PowerUp")
		ShipState.ON:
			compassMat.albedo_color = Color(0, 1, 0.5, 0.75)
		ShipState.SHUTDOWN:
			$AnimationPlayer.play("ShutDown")

func mission_compass():
	compass.look_at(get_node(compassTarget).transform.origin, transform.basis.y)
