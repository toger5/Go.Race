extends RigidBody


export var one_motor_power = 1.0
export var rate = 1
export var air_resistance = 0.001
onready var sound : AudioStreamPlayer = $AudioStreamPlayer as AudioStreamPlayer


export (NodePath) var motor_front_left 
export (NodePath) var motor_front_right
export (NodePath) var motor_back_left
export (NodePath) var motor_back_right
onready var motors = [$motor_front_left, $motor_front_right, $motor_back_right, $motor_back_left]
var physics : QuadPhysics = QuadPhysicsPID.new(self, rate, air_resistance, one_motor_power,0.1,0.00,0.0)#QuadPhysicsLinear.new(self, rate, air_resistance, one_motor_power)

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
	physics.update_input(input_getter.get_roll(), input_getter.get_pitch(), input_getter.get_yaw(), input_getter.get_throttle())
	physics.apply_forces(ph)
	sound_pitch = 0.3+physics.current_motor_force*2 / physics.motor_power*4 + physics.current_air_force.length()/2/physics.motor_power*4
	#apply prop impulse
	
#	var roll_pow = 0.6

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

class QuadPhysics:
	
	var power_curve : Curve = load("res://quadcopter/power_curve.tres")
	
	var cal_air_resistance
	var cal_rate
	var input_target_vector
	var input_power
	var input_roll
	var input_pitch
	var input_yaw
	var quad_body : RigidBody
	var motor_power
	var current_motor_force : float
	var current_air_force : Vector3
	func _init(quad : RigidBody, rate : float, air : float, power : float):
		print("init QuadPhysics")
		quad_body = quad
		cal_rate = rate
		cal_air_resistance = air
		motor_power = power
		
	func update_input(roll, pitch, yaw, power):
		input_roll = roll
		input_pitch = pitch
		input_yaw = yaw
		input_power = power_curve.interpolate(max(input_getter.get_throttle(), 0)) 
		input_power = input_power * 0.9 + 0.1 # Props are always spinning a little...
		
	func apply_forces(ph : PhysicsDirectBodyState):
		print("forces not applyed in QuadPhysics, override apply_forces")

	func l_to_g(v : Vector3) -> Vector3:
		return transform.basis.xform(v)
	func g_to_l(v : Vector3) -> Vector3:
		return transform.basis.xform_inv(v)

class QuadPhysicsLinear extends QuadPhysics:
	func _init(quad : RigidBody, rate : float, air : float, power : float).(quad,rate,air,power):
		pass

	func apply_forces(ph : PhysicsDirectBodyState):
		ph.angular_velocity = lv(Vector3(0 ,0,-input_roll*cal_rate))
		ph.angular_velocity += lv(Vector3(-input_pitch*cal_rate ,0,0))
		ph.angular_velocity += lv(Vector3(0,-input_yaw*cal_rate,0))
		current_air_force = -ph.linear_velocity.normalized() * ph.linear_velocity.length_squared() * cal_air_resistance
		current_motor_force = (motor_power*4) * input_power
		ph.add_central_force(current_motor_force * quad_body.transform.basis.y + current_air_force)
		
class QuadPhysicsPID extends QuadPhysics:
	var pids = []
	#TODO need to make checks, if the quad body actually has those properties...
	enum {ROLL = 0, PITCH = 1, YAW = 2}
	func _init(quad : RigidBody, rate : float, air : float, power : float, P : float, I : float, D : float).(quad,rate,air,power):
#		for i in range(3):
#			pids.append(PidController.new(P, I, D))
		pids.append(PidController.new(0.2, 0.01, 0.001)) #Roll
		pids.append(PidController.new(0.1, 0.01, 0.001)) #pitch
		pids.append(PidController.new(0.001, 0.001, 0.1)) #yaw

		
	func apply_forces(ph : PhysicsDirectBodyState):
		print("angvel ", ph.angular_velocity)
		var cur_rot_speed = ph.transform.basis.xform_inv(ph.angular_velocity)
		var target_rot_speed = Vector3(input_pitch*cal_rate, input_yaw*cal_rate, -input_roll*cal_rate)
		print("target ", target_rot_speed)
		var error =  target_rot_speed - cur_rot_speed
		print("error ",error)
		var error_f_b = pids[PITCH].iter(error.x)
		var error_yaw = pids[YAW].iter(error.y)
		var error_l_r =- pids[ROLL].iter(error.z)
#		print("error_f_b ", error_f_b)
		print("error_l_r ", error_l_r)
#		print("error_yaw ", error_yaw)
		
		#(left,top,front)
		#front left(1,0,1), front right(-1,0,1), back right(-1,0,-1), back left(1,0,-1)
		var motor_handle_forces = [ -error_l_r - error_f_b ,  error_l_r - error_f_b , error_l_r + error_f_b , -error_l_r + error_f_b ]
		var motor_forces = [0,0,0,0]
		var motor_pos = [Vector3(),Vector3(),Vector3(),Vector3()]
		current_motor_force =  0
		for j in [0,1,2,3]:
			var i = j
			motor_pos[i] = quad_body.motors[i].translation
			motor_forces[i] = min(motor_handle_forces[i] + input_power * motor_power, motor_power)
			current_motor_force += motor_forces[i]
			
			ph.add_force(g_to_l(Vector3(0,1,0)) * motor_forces[i], l_to_g(motor_pos[i]))
		ph.add_torque(Vector3(0,error_yaw,0))
#		print(motor_forces)
		#print("cur_force ", motor_forces)
#		print("motor pos", motor_pos)
#		var glob_m_pos = []
#		for i in motor_pos:
#			glob_m_pos.append(gv(i))
#		print("glob pos", glob_m_pos)
		#current_air_force = -ph.linear_velocity.normalized() * ph.linear_velocity.length_squared() * cal_air_resistance
		#ph.add_central_force(current_air_force)