extends KinematicBody

var vel : Vector3
var rot_vel : Vector3
var yaw_vel : Vector3
var pitch_vel : Vector3
var roll_vel : Vector3

var thrust_const : float = 20
var yaw_const : float = 1.2
var pitch_const : float = 1.5
var roll_const : float = 2.0

var max_thrust_forw : float = 200
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

var camera_switch : bool
var crr_camera : int = 1
onready var tween = $Tween

var laser_scene = preload("res://Laser 2.tscn")
onready var laser_pos = [$L1, $R1, $M1, $L2, $R2, $M1]
var laser_num = 0
var laser_continuous : bool = false
var time_since_laser : float = 0
var laser_interval : float = 0.1

var collision : KinematicCollision
var life = 100

onready var life_bar_size = $"Health Bar".scale.z
var enemy_count : int


#spawns and initializes laser
func spawn_laser():
	var laser_instance = laser_scene.instance()
	get_parent().add_child(laser_instance)
	laser_instance.transform = transform
	laser_instance.transform.origin = to_global(laser_pos[laser_num].transform.origin)
	laser_instance.vel = Vector3(vel.x, 0, 0)
	laser_num = laser_num + 1 if laser_num + 1 < laser_pos.size() else 0

#damge and death
func damage(value):
	life -= value
	$"Health Bar".scale.z = life_bar_size * life / 100
	if life <= 0:
		var explosion = preload("res://Explsion.tscn")
		var explosion_instance = explosion.instance()
		get_parent().add_child(explosion_instance)
		explosion_instance.transform.origin = transform.origin
		print(explosion_instance.transform.origin)
		get_tree().call_group("enemy", "player_dead")
		queue_free()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func _physics_process(delta):
	#camera control
	camera_switch = true if Input.is_action_just_pressed("camera") else false
	var vel_ratio = -vel.x/max_thrust_forw
	var cam_1_trans = $"Camera 1".translation.linear_interpolate($"Camera 1".translation - Vector3(0.3, 0, 0), vel_ratio)
	var cam_2_trans = $"Camera 2".translation.linear_interpolate($"Camera 2".translation - Vector3(5, 1, 0), vel_ratio)
	var cam_3_trans = $"Camera 3".translation.linear_interpolate($"Camera 3".translation - Vector3(10, 0, 0), vel_ratio)
	var cam_1_fov = $"Camera 1".fov * (1 - vel_ratio) + ($"Camera 1".fov + 10) * vel_ratio
	var cam_2_fov = $"Camera 2".fov * (1 - vel_ratio) + ($"Camera 2".fov + 20) * vel_ratio
	var cam_3_fov = $"Camera 3".fov * (1 - vel_ratio) + ($"Camera 3".fov + 35) * vel_ratio
	if camera_switch:
		crr_camera += 1
		if crr_camera > 3:
			crr_camera = 1
		if crr_camera == 1:
			tween.interpolate_property($"Camera Main", "translation", cam_3_trans, cam_1_trans, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property($"Camera Main", "rotation", $"Camera 3".rotation, $"Camera 1".rotation, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property($"Camera Main", "fov", cam_3_fov, cam_1_fov, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.start()
		if crr_camera == 2:
			tween.interpolate_property($"Camera Main", "translation", cam_1_trans, cam_2_trans, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property($"Camera Main", "rotation", $"Camera 1".rotation, $"Camera 2".rotation, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property($"Camera Main", "fov", cam_1_fov, cam_2_fov, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.start()
		if crr_camera == 3:
			tween.interpolate_property($"Camera Main", "translation", cam_2_trans, cam_3_trans, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property($"Camera Main", "rotation", $"Camera 2".rotation, $"Camera 3".rotation, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property($"Camera Main", "fov", cam_2_fov, cam_3_fov, 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.start()
	if crr_camera == 1:
		$"Camera Main".translation = cam_1_trans
		$"Camera Main".fov = cam_1_fov
	if crr_camera == 2:
		$"Camera Main".translation = cam_2_trans
		$"Camera Main".fov = cam_2_fov
	if crr_camera == 3:
		$"Camera Main".translation = cam_3_trans
		$"Camera Main".fov = cam_3_fov
	
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
	
	#thrust
	var thrust_dot = vel.dot(Vector3(-1, 0, 0))
	if thrust_forw or thrust_backw:
		if thrust_forw:
			if thrust_dot < 0:
				vel += Vector3(-1, 0, 0) * thrust_const * 2.5 * delta
			elif thrust_dot < max_thrust_forw:
				vel += Vector3(-1, 0, 0) * thrust_const * delta
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
	collision = move_and_collide(transform.basis.xform(vel) * delta)
	if rot_vel.length() != 0:
		rotate(transform.basis.xform(rot_vel.normalized()), rot_vel.length() * delta)
	
	"""
	#collision
	if collision:
		if collision.collider.is_in_group("obstacle"):
			damage(100)
	"""
	
	$model/Steering.rotation.z = pitch_vel.z * 0.3
	$model/Steering.rotation.y = yaw_vel.y * 0.35
	$model/Steering.rotation.x = roll_vel.x * 0.2
	
	#shoot
	if shoot_extended:
		if shoot:
			spawn_laser()
		else:
			if laser_continuous:
				time_since_laser += delta
				if time_since_laser >= laser_interval:
					time_since_laser = false
					spawn_laser()
			else:
				time_since_laser = 0
				laser_continuous = true
	else:
		laser_continuous = false
	
	#count enemy
	enemy_count = get_tree().get_nodes_in_group("enemy").size()
	while enemy_count < $"Enemy Count".get_child_count():
		var removed = $"Enemy Count".get_child($"Enemy Count".get_child_count() - 1)
		removed.hide()
		$"Enemy Count".remove_child(removed)
		print($"Enemy Count".get_child_count())
