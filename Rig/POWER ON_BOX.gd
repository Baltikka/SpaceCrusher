extends Area

onready var anim = $AnimationPlayer

var on = false

func interact():
	var ON = get_parent().ShipState.ON
	var OFF = get_parent().ShipState.OFF
	var state = get_parent().CurrentState
	match state:
		ON:
			state = get_parent().shutdown()
			anim.play("shutdown")
		OFF:
			state = get_parent().startup()
			anim.play("startup")
