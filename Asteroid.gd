extends RigidBody

var maxhp
var hp


func _ready():
	maxhp = round(rand_range(50, 100))
	hp = maxhp

func recieve_damage(dmg):
	hp -= dmg
	if hp <= 0:
		queue_free()
