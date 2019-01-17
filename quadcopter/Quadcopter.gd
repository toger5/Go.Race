extends RigidBody

# class member variables go here, for example:
var power = 2
var rate = 2

func _ready():
	input_getter.set_use_mouse(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass
func _input(e):
	#Toggle mouse use mouse (esc -> use mouse = false, click -> use_mouse = true)
	var mouse_button_ev : = e as InputEventMouseButton
	if mouse_button_ev and not input_getter.use_mouse:
		input_getter.set_use_mouse(true)
	if e.is_action("ui_cancel"):
		if e.pressed:
			input_getter.set_use_mouse(false)
func lv(v):
	return transform.basis.xform(v)

func _physics_process(delta):
	var joy_throttle := input_getter.get_throttle()
	if joy_throttle < 0.0:
		joy_throttle = 0.0
	var joy_roll := input_getter.get_roll()
	var joy_pitch := input_getter.get_pitch()
	var joy_yaw := input_getter.get_yaw()
	
	angular_velocity = Vector3()
	apply_impulse(Vector3(),lv(Vector3(0,joy_throttle*power,0)))
	angular_velocity = lv(Vector3(0 ,0,-joy_roll*rate))
	angular_velocity = angular_velocity + lv(Vector3(-joy_pitch*rate ,0,0))
	angular_velocity = angular_velocity + lv(Vector3(0,-joy_yaw*rate,0))

