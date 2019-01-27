extends RigidBody


export var power = 6.0
export var rate = 4.2
export var air_resistance = 0.001
var power_curve : Curve = load("res://quadcopter/power_curve.tres")
onready var sound : AudioStreamPlayer = $AudioStreamPlayer as AudioStreamPlayer
func _ready():
	sound.stream.loop_mode = AudioStreamSample.LOOP_PING_PONG
	sound.playing = true
	connect("body_entered",self,"_body_entered")
	connect("body_exited",self,"_body_exit")
	input_getter.set_use_mouse(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass
var sound_pitch = 0.0
func _process(delta):
	var sp = sound.pitch_scale
	if abs(sound_pitch - sound.pitch_scale) > 0.07:
		sp += sign(sound_pitch - sound.pitch_scale) * 0.07
	else:
#		print("fast")
		sound.pitch_scale = sound_pitch
	if sound_pitch < 1:
		sound.volume_db = -20 * (1-sound_pitch)
	else:
		sound.volume_db = 0
	sound.pitch_scale = max(0.01, sp)
#	print(sound.pitch_scale)
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
var coll = false
func _body_entered(c):
	print("is colliding")
	coll = true
func _body_exit(c):
	if get_colliding_bodies().size() == 0:
		coll = false
	print("exit left: " + str(get_colliding_bodies().size()))
func _integrate_forces(ph):
	var joy_throttle := input_getter.get_throttle()
	if joy_throttle < 0.0:
		joy_throttle = 0.0
	var joy_roll := input_getter.get_roll()
	var joy_pitch := input_getter.get_pitch()
	var joy_yaw := input_getter.get_yaw()
	
	#apply prop impulse
	
	var motor_force = lv(Vector3(0,power_curve.interpolate(joy_throttle)*power + 0.1,0))
	var roll_pow = 0.6

#	if abs(ph.angular_velocity.z) < abs(joy_roll*rate):
#		ph.add_torque(lv( Vector3(0 ,0, -joy_roll*roll_pow)))
#	if abs(ph.angular_velocity.z) > abs(joy_roll*rate):
#		ph.add_torque(lv( Vector3(0 ,0, -sign(ph.angular_velocity.z)*roll_pow)))
#
#	if abs(ph.angular_velocity.y) < abs(joy_yaw*rate):
#		ph.add_torque( lv(Vector3(0 ,-joy_yaw*roll_pow, 0)))
#	if abs(ph.angular_velocity.y) > abs(joy_yaw*rate):
#		ph.add_torque(lv( Vector3(0 ,-sign(ph.angular_velocity.y)*roll_pow, 0)))
#
#	if abs(ph.angular_velocity.x) < abs(joy_pitch*rate):
#		ph.add_torque( lv(Vector3(-joy_pitch*roll_pow ,0, 0)))
#	if abs(ph.angular_velocity.x) > abs(joy_pitch*rate):
#		ph.add_torque(lv( Vector3(-sign(ph.angular_velocity.x)*roll_pow ,0, 0)))
	ph.angular_velocity = lv(Vector3(0 ,0,-joy_roll*rate))
	ph.angular_velocity += lv(Vector3(-joy_pitch*rate ,0,0))
	ph.angular_velocity += lv(Vector3(0,-joy_yaw*rate,0))
	var air_force = -linear_velocity.normalized() * linear_velocity.length_squared() * air_resistance
	ph.add_central_force(motor_force + air_force)
	sound_pitch = 0.3+motor_force.length()*2/power + air_force.length()/2/power

