extends KinematicBody

var lookSensitivity = 10
var mouseDelta : Vector2 = Vector2()

var vel : Vector3
var max_vel = 12
var rot_vel : Vector3
var yaw_vel : Vector3
var pitch_vel : Vector3
var roll_vel : Vector3

var thrust_const : float = 1
var yaw_const : float = 1.2
var pitch_const : float = 1.5
var roll_const : float = 2.0

var max_thrust_forw : float = 50000
var max_thrust_backw : float = 50
var min_thrust_forw : float = 50
var min_thrust : float = 0.1
var min_rot_vel : float = 0.05
var max_yaw : float = 1.5
var max_pitch : float = 2.0
var max_roll : float = 2.0

var thrust_forw : bool
var thrust_backw : bool
var yaw_left : bool
var yaw_right : bool
var pitch_up : bool
var pitch_down : bool
var roll_left : bool
var roll_right : bool
var shoot : bool
var shoot_extended : bool

var boost : bool




var collision : KinematicCollision
var life = 100

onready var camera  =$Camera
onready var head = $Camera/Camera

func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative


# Called when the node enters the scene tree for the first time.
func _ready():
	camera.set_as_toplevel(true)
	camera.global_transform = global_transform
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  
	

func _process(delta):
	$speed.text = "THRUST: " + String(abs(stepify(vel.x, 0.1)))
	$MeshInstance/X_display.text = String(abs(stepify(rotation.x, 0.1)))
	$MeshInstance/Y_display.text = String(abs(stepify(rotation.y, 0.1)))
	$MeshInstance/Z_display.text = String(abs(stepify(rotation.z, 0.1)))
	if Input.is_action_pressed("unlock_camera"):
		camera.global_transform = global_transform
#		camera.rotation = lerp(camera.rotation, rotation, 0.01)
		head.rotation_degrees.x -= mouseDelta.y * lookSensitivity * delta
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -89, 89)
		head.rotation_degrees.y -= mouseDelta.x * lookSensitivity * delta
	else:
#		camera.global_transform.origin = global_transform.origin
		camera.global_transform = global_transform
#		camera.rotation.x = lerp_angle(camera.rotation.x, rotation.x, 10 * delta)
#		camera.rotation.y = lerp_angle(camera.rotation.y, rotation.y, 10 * delta)
#		camera.rotation.z = lerp_angle(camera.rotation.z, rotation.z, 10 * delta)
		head.rotation = lerp(head.rotation, Vector3(0, deg2rad(90), 0), 10 * delta)
	mouseDelta = Vector2()


func _physics_process(delta):
	#camera control
	#camera.global_transform = lerp(camera.global_transform, global_transform, 0.5 * delta)
	camera.rotation = lerp(camera.rotation, rotation, 0.01)
	
	
	#movement inputs
	thrust_forw = true if Input.is_action_pressed("thrust forw") else false
	thrust_backw = true if Input.is_action_pressed("thrust backw") else false
	yaw_left = true if Input.is_action_pressed("yaw left") else false
	yaw_right = true if Input.is_action_pressed("yaw right") else false
	pitch_up = true if Input.is_action_pressed("pitch up") else false
	pitch_down = true if Input.is_action_pressed("pitch down") else false
	roll_left = true if Input.is_action_pressed("roll left") else false
	roll_right = true if Input.is_action_pressed("roll right") else false
	#shoot inputs
	shoot = true if Input.is_action_just_pressed("shoot") else false
	shoot_extended = true if Input.is_action_pressed("shoot") else false
	#custom_inputs
	boost = true if Input.is_action_pressed("boost") else false
	
	#thrust
	var thrust_dot = vel.dot(Vector3(-1, 0, 0))
	if thrust_forw or thrust_backw:
		if thrust_forw:
			if thrust_dot < 0:
				if !boost:
					vel += Vector3(-1, 0, 0) * thrust_const * 2.5 * delta * 10
				else:
					vel += Vector3(-1, 0, 0) * thrust_const * 2.5 * delta * 100
			elif thrust_dot < max_thrust_forw:
				if !boost:
					vel += Vector3(-1, 0, 0) * thrust_const * delta
				else:
					vel += Vector3(-1, 0, 0) * thrust_const * delta * 100
		if thrust_backw:
			if thrust_dot > 0:
				vel += Vector3(1, 0, 0) * thrust_const * 2.5 * delta
			elif thrust_dot > -max_thrust_backw:
				vel += Vector3(1, 0, 0) * thrust_const * delta
	else:
		if thrust_dot >= min_thrust_forw:
			pass
		elif thrust_dot > min_thrust and thrust_dot < min_thrust_forw:
			vel += Vector3(1, 0, 0) * thrust_const * 1.5 * delta
		elif thrust_dot < -min_thrust:
			vel += Vector3(-1, 0, 0) * thrust_const * 1.5 * delta
		else:
			vel.x = 0
	
	#yaw
	var yaw_dot = yaw_vel.dot(Vector3(0, 1, 0))
	if yaw_left or yaw_right:
		if yaw_left:
			if yaw_dot < 0:
				yaw_vel += Vector3(0, 1, 0) * 2 * yaw_const * delta
			if yaw_dot < max_yaw:
				yaw_vel += Vector3(0, 1, 0) * yaw_const * delta
		if yaw_right:
			if yaw_dot > 0:
				yaw_vel += Vector3(0, -1, 0) * yaw_const * 2 * delta
			elif yaw_dot > -max_yaw:
				yaw_vel += Vector3(0, -1, 0) * yaw_const * delta
	else:
		if yaw_dot > min_rot_vel:
			yaw_vel -= Vector3(0, 1, 0) * yaw_const * 1.5 * delta
		elif yaw_dot < -min_rot_vel:
			yaw_vel -= Vector3(0, -1, 0) * yaw_const * 1.5 * delta
		else:
			yaw_vel = Vector3()
			vel.z = 0
	
	#pitch
	var pitch_dot = pitch_vel.dot(Vector3(0, 0, -1))
	if pitch_up or pitch_down:
		if pitch_up:
			if pitch_dot < 0:
				pitch_vel += Vector3(0, 0, -1) * pitch_const * 3 * delta
			elif pitch_dot < max_pitch:
				pitch_vel += Vector3(0, 0, -1) * pitch_const * delta
		if pitch_down:
			if pitch_dot > 0:
				pitch_vel += Vector3(0, 0, 1) * pitch_const * 3 * delta
			elif pitch_dot > -max_pitch:
				pitch_vel += Vector3(0, 0, 1) * pitch_const * delta
	else:
		if pitch_dot > min_rot_vel:
			pitch_vel -= Vector3(0, 0, -1) * pitch_const * 1.5 * delta
		elif pitch_dot < -min_rot_vel:
			pitch_vel -= Vector3(0, 0, 1) * pitch_const * 1.5 * delta
		else:
			pitch_vel = Vector3()
			vel.y = 0
	
	#roll
	var roll_dot = roll_vel.dot(Vector3(1, 0, 0))
	if roll_left or roll_right:
		if roll_left:
			if roll_dot < 0:
				roll_vel += Vector3(1, 0, 0) * roll_const * 2 * delta
			elif roll_dot < max_roll:
				roll_vel += Vector3(1, 0, 0) * roll_const * delta
		if roll_right:
			if roll_dot > 0:
				roll_vel += Vector3(-1, 0, 0) * roll_const * 2 * delta
			elif roll_dot > -max_roll:
				roll_vel += Vector3(-1, 0, 0) * roll_const * delta
	else:
		if roll_dot > min_rot_vel:
			roll_vel -= Vector3(1, 0, 0) * roll_const * 1.5 * delta
		elif roll_dot < -min_rot_vel:
			roll_vel -= Vector3(-1, 0, 0) * roll_const * 1.5 * delta
		else:
			roll_vel = Vector3()
	
	#apply movements
	rot_vel = yaw_vel + pitch_vel + roll_vel
	vel += rot_vel.cross(vel) * delta * delta
	if !boost:
		if vel.x < -12 or vel.x > 12:
			vel.x = lerp(vel.x, 12, delta)
		else:
			vel.x = clamp(vel.x, -12, 12)
		head.fov = lerp(head.fov, 90, 2 * delta)
		head.transform.origin.x = lerp (head.transform.origin.x, 0.615, 2 * delta)
		$Blur.hide()
	else:
		$Blur.show()
		vel.x = clamp(vel.x, -1200, 1200)
		head.fov = lerp(head.fov, 140, 0.5 * delta)
		head.transform.origin.x = lerp (head.transform.origin.x, 0.065, 0.5 * delta)
	collision = move_and_collide(transform.basis.xform(vel) * delta)
	if rot_vel.length() != 0:
		rotate(transform.basis.xform(rot_vel.normalized()), rot_vel.length() * delta)
	
	
#	$model/Steering.rotation.z = pitch_vel.z * 0.3
#	$model/Steering.rotation.y = yaw_vel.y * 0.35
#	$model/Steering.rotation.x = roll_vel.x * 0.2
	
