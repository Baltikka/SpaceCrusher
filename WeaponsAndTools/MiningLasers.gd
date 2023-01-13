extends Spatial

var base_damage = 0.5

var distance_to_target = 0.0
var target_exists = false
var obtained_target
var lasers_active = false
var overheat = false


onready var ship = get_parent().get_parent()
onready var hit_effect = $CPUParticles
onready var hit_light = $CPUParticles/OmniLight
var Lasers = []


func _ready():
	hit_effect.emitting = false
	Lasers.append($Laser)
	Lasers.append($Laser2)
	for laser in Lasers:
		laser.scale.z = 0
	#laser.transform.basis.get_scale().z = 0
	ship.connect("raycastTarget", self, "_on_Target_Obtained")
	ship.connect("LMB", self, "_laser_Activation")



func _on_Target_Obtained(target, position, _distance, locked):
	if locked:
		distance_to_target = $Laser.global_transform.origin.distance_to(position)
		hit_effect.global_transform.origin = position
		target_exists = true
		obtained_target = target
	else:
		distance_to_target = 100.0
		target_exists = false
		obtained_target = null
	for laser in Lasers:
		laser.look_at(position, transform.basis.y)
	if lasers_active and ship.heat < 100 and !overheat:
		for laser in Lasers:
			laser.scale.z = distance_to_target
			if locked:
				hit_light.show()
				hit_effect.emitting = true
			else:
				hit_light.hide()
				hit_effect.emitting = false
	else:
		hit_light.hide()
		hit_effect.emitting = false
		for laser in Lasers:
			laser.scale.z = 0
	


func _laser_Activation(active):
	lasers_active = active


func _on_Timer_timeout():
	if lasers_active and !overheat:
		ship.heat += 1
		ship.heat = min(100, ship.heat)
		if ship.heat == 100:
			overheat = true
		if obtained_target:
			if obtained_target.is_in_group("Mineable") or obtained_target.is_in_group("Enemy"):
				obtained_target.recieve_damage(base_damage + ship.heat/100)
	else:
		ship.heat -= 1
		ship.heat = max(0, ship.heat)
		if ship.heat == 0:
			overheat = false
