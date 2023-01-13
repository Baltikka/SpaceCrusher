extends Spatial

var overheat = false

onready var ship = get_parent()
onready var display = $Label3D

func _process(_delta):
	$Label3D/OmniLight.light_energy = ship.heat/100.0
	if ship.heat == 0:
		overheat = false
	if ship.heat < 10:
		display.text = " "
		if !overheat:
			display.modulate = Color(0, 1, 0, 1)
	elif ship.heat >= 10 and ship.heat < 20:
		display.text = "I"
		if !overheat:
			display.modulate = Color(0, 1, 0, 1)
	elif ship.heat >= 20 and ship.heat < 30:
		display.text = "II"
		if !overheat:
			display.modulate = Color(0, 1, 0, 1)
	elif ship.heat >= 30 and ship.heat < 40:
		display.text = "III"
		if !overheat:
			display.modulate = Color(0, 1, 0, 1)
	elif ship.heat >= 40 and ship.heat < 50:
		display.text = "IIII"
		if !overheat:
			display.modulate = Color(1, 1, 0, 1)
	elif ship.heat >= 50 and ship.heat < 60:
		display.text = "IIIII"
		if !overheat:
			display.modulate = Color(1, 1, 0, 1)
	elif ship.heat >= 60 and ship.heat < 70:
		display.text = "IIIIII"
		if !overheat:
			display.modulate = Color(1, 1, 0, 1)
	elif ship.heat >= 70 and ship.heat < 80:
		if !overheat:
			display.text = "IIIIIII"
			display.modulate = Color(1, 1, 0, 1)
	elif ship.heat >= 80 and ship.heat < 90:
		if !overheat:
			display.text = "IIIIIIII"
		display.modulate = Color(1, 0, 0, 1)
	elif ship.heat >= 90 and ship.heat < 99:
		if !overheat:
			display.text = "IIIIIIIII"
		display.modulate = Color(1, 0, 0, 1)
	elif ship.heat == 100:
		overheat = true
		display.text = "OVERHEAT"
		display.modulate = Color(1, 0, 0, 1)
