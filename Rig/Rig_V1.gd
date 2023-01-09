extends KinematicBody

var fuel = 100
var fuelcons = 1
export var CurrentState: int
enum ShipState{
		OFF,
		ON,
		DAMAGED,
		DESTROYED
	}

var lookSensitivity = 10
var mouseDelta := Vector2()
var mouse_dir := Vector2()

export var max_speed_forw = 30
export var max_speed_backw = 10
export var acceleration = 0.6
export var pitch_speed = 1.5
export var roll_speed = 2.0
export var yaw_speed = 1.2
export var input_response = 4.0

var velocity = Vector3.ZERO
var forward_speed = 0
var pitch_input = 0
var roll_input = 0
var yaw_input = 0

var camera_lock = true

onready var camera  =$Camera
onready var head = $Camera/head
onready var raycast = $Camera/RayCast
onready var pointerL = $PointerL
onready var pointerR = $PointerR



func _ready():
#	for node in get_tree().get_nodes_in_group("ShipInterface"):
#		node.hide()
	CurrentState = ShipState.OFF
	camera.set_as_toplevel(true)
	camera.global_transform = global_transform
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 


func _process(delta):
	if Input.is_action_just_pressed("Ignition"):
		if CurrentState == ShipState.ON:
			CurrentState = ShipState.OFF
		else:
#			CurrentState = ShipState.ON
#			for node in get_tree().get_nodes_in_group("ShipInterface"):
#				node.show()
			$AnimationPlayer.play("PowerOn")
	if fuel <= 0.05:
		CurrentState = ShipState.OFF
	if CurrentState == ShipState.ON:
		$speed.text = "THRUST: " + String(stepify(forward_speed, 0.1)) + "\nFUEL: " + String(stepify(fuel, 0.1)) + "%"
	$MeshInstance/X_display.text = String(abs(stepify(rad2deg(rotation.x), 0.1)))
	$MeshInstance/Y_display.text = String(abs(stepify(rad2deg(rotation.y), 0.1)))
	$MeshInstance/Z_display.text = String(abs(stepify(rad2deg(rotation.z), 0.1)))
	if Input.is_action_pressed("unlock_camera") or CurrentState == ShipState.OFF:
		camera_lock = true
		camera.global_transform = global_transform
#		camera.rotation = lerp(camera.rotation, rotation, 0.01)
		head.rotation_degrees.x -= mouseDelta.y * lookSensitivity * delta
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -89, 89)
		head.rotation_degrees.y -= mouseDelta.x * lookSensitivity * delta
	elif CurrentState != ShipState.OFF:
		camera_lock = false
#		camera.global_transform.origin = global_transform.origin
		camera.global_transform = global_transform
		camera.rotation.x = lerp_angle(camera.rotation.x, rotation.x, 10 * delta)
		camera.rotation.y = lerp_angle(camera.rotation.y, rotation.y, 10 * delta)
		camera.rotation.z = lerp_angle(camera.rotation.z, rotation.z, 10 * delta)
		head.rotation = lerp(head.rotation, Vector3(0, deg2rad(0), 0), 10 * delta)
	mouseDelta = Vector2()
	
	#gun pointing
	var point = raycast.get_collision_point()
	if point:
		pointerL.look_at(point, transform.basis.y)
		pointerR.look_at(point, transform.basis.y)


func _physics_process(delta):
	match CurrentState:
		ShipState.OFF:
#			for node in get_tree().get_nodes_in_group("ShipInterface"):
#				node.hide()
			$"no power".show()
			if $AnimationPlayer.current_animation != "PowerOn":
				$AnimationPlayer.play("NO POWER")
			forward_speed = lerp(forward_speed, 0, acceleration * delta)
		ShipState.ON:
			get_input(delta)
			$"no power".hide()
	camera.rotation = lerp(camera.rotation, rotation, 0.01)
	head.transform.origin.x = lerp (head.transform.origin.x, 0.0, 2 * delta)
	
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.z, roll_input * roll_speed * delta)
	transform.basis = transform.basis.orthonormalized()
	velocity = -transform.basis.z * forward_speed
# warning-ignore:return_value_discarded
	move_and_collide(velocity * delta)


 
func get_input(delta):
	#thust
	if Input.is_action_pressed("thrust forw"):
		forward_speed = lerp(forward_speed, max_speed_forw, acceleration * delta)
		fuel = lerp(fuel, 0, abs(forward_speed/10000*fuelcons)*delta)
	if Input.is_action_pressed("thrust backw"):
		forward_speed = lerp(forward_speed, -max_speed_backw, acceleration * delta)
		fuel = lerp(fuel, 0, abs(forward_speed/10000*fuelcons)*delta)
	else:
		forward_speed = lerp(forward_speed, 0, acceleration * delta)
	#rotation
	mouse_dir = (mouseDelta * input_response * delta)
#	pitch_input = lerp(pitch_input, Input.get_axis("pitch down", "pitch up"), input_response * delta) 
#	yaw_input = lerp(yaw_input, Input.get_axis( "yaw right", "yaw left"), input_response * delta)
	roll_input = lerp(roll_input, Input.get_axis("roll right", "roll left"), input_response * delta)
	if !camera_lock:
		pitch_input = clamp(lerp(pitch_input, -mouse_dir.y , input_response * delta), -pitch_speed, pitch_speed)
		yaw_input = clamp(lerp(yaw_input, -mouse_dir.x, input_response * delta), -yaw_speed, yaw_speed)
	else:
		pitch_input = lerp(pitch_input, 0, input_response * delta)
		yaw_input = lerp(yaw_input, 0, input_response * delta)
	
	
	

func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative


