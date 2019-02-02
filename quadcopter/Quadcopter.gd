class_name QuadCopter
extends RigidBody


export var MOTOR_POWER = 0.7
export var RATE = 5.7
export var AIR_RESISTANCE = 0.0015


export (NodePath) var motor_front_left 
export (NodePath) var motor_front_right
export (NodePath) var motor_back_left
export (NodePath) var motor_back_right

onready var motors = [$motor_front_left, $motor_front_right, $motor_back_right, $motor_back_left]
var motor_rpms = [0,0,0,0]
const IDLE_RPM = 600
const MAX_RPM = 1800
var physics : QuadPhysics = QuadPhysicsPID.new(self, RATE, AIR_RESISTANCE, MOTOR_POWER,0.1,0.00,0.0)#QuadPhysicsLinear.new(self, rate, air_resistance, one_motor_power)
var pos
func _ready():
	for sp in $Sounds.get_children():
		var stream_player = sp as AudioStreamPlayer
		if !stream_player:
			continue
		stream_player.stream.loop_mode = AudioStreamSample.LOOP_PING_PONG
		stream_player.playing = true

	connect("body_entered",self,"_body_entered")
	connect("body_exited",self,"_body_exit")
	input_getter.set_use_mouse(true)
	# Called every time the node is added to the scene.
	# Initialization here
	pass
func get_speed():
	return linear_velocity.length()
func _process(delta):
	var i = 0
	for sp in $Sounds.get_children():
		var stream_player = sp as AudioStreamPlayer
		stream_player.volume_db = -100
		if !stream_player or i > 1:
			continue
		var MAX_PITCH = 1.4
		var MAX_PITCH_STEP = 0.07
		var target_pitch = lerp(0.07, MAX_PITCH, motor_rpms[i] / MAX_RPM)
		var current_pitch = stream_player.pitch_scale
		if abs(target_pitch - current_pitch) > MAX_PITCH_STEP:
			current_pitch += MAX_PITCH_STEP * sign(target_pitch - current_pitch)
		else:
			current_pitch = target_pitch
		if target_pitch < 1:
			var db = linear2db(lerp(0.4,0.6,target_pitch/MAX_PITCH))
			print("db: ",db)
			stream_player.volume_db = db
		else:
			stream_player.volume_db = 0
		stream_player.pitch_scale = max(0.01, current_pitch)
		i += 1

func _input(e):
	#Toggle mouse use mouse (esc -> use mouse = false, click -> use_mouse = true)
	var mouse_button_ev : = e as InputEventMouseButton
	if mouse_button_ev and not input_getter.use_mouse:
		input_getter.set_use_mouse(true)
	if e.is_action("ui_cancel"):
		if e.pressed:
			input_getter.set_use_mouse(false)

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
#		input_power = input_power * 0.9 + 0.1 # Props are always spinning a little...
		
	func apply_forces(ph : PhysicsDirectBodyState):
		print("forces not applyed in QuadPhysics, override apply_forces")

	func l_to_g(v : Vector3) -> Vector3:
		return quad_body.transform.basis.xform(v)
	func g_to_l(v : Vector3) -> Vector3:
		return quad_body.transform.basis.xform_inv(v)

class QuadPhysicsLinear extends QuadPhysics:
	func _init(quad : RigidBody, rate : float, air : float, power : float).(quad,rate,air,power):
		pass

	func apply_forces(ph : PhysicsDirectBodyState):
		ph.angular_velocity = l_to_g(Vector3(0 ,0,-input_roll*cal_rate))
		ph.angular_velocity += l_to_g(Vector3(-input_pitch*cal_rate ,0,0))
		ph.angular_velocity += l_to_g(Vector3(0,-input_yaw*cal_rate,0))
		current_air_force = -ph.linear_velocity.normalized() * ph.linear_velocity.length_squared() * cal_air_resistance
		current_motor_force = (motor_power*4) * input_power
		ph.add_central_force(current_motor_force * quad_body.transform.basis.y + current_air_force)
		
class QuadPhysicsPID extends QuadPhysics:
	var pids = []
	var max_throttle_power = 0.8 #TODO maybe move this to QuadPhysics
	#TODO need to make checks, if the quad body actually has those properties...
	enum {ROLL = 0, PITCH = 1, YAW = 2}
	func _init(quad : RigidBody, rate : float, air : float, power : float, P : float, I : float, D : float).(quad,rate,air,power):
		pids.append(PidController.new(0.03, 0.002, 0.001)) #Roll
		pids.append(PidController.new(0.03, 0.002, 0.001)) #pitch
		pids.append(PidController.new(0.2, 0.01, 0.001)) #yaw

		
	func apply_forces(ph : PhysicsDirectBodyState):
		var cur_rot_speed = g_to_l(ph.angular_velocity)
		var target_rot_speed = Vector3(input_pitch*cal_rate, -input_yaw*cal_rate, input_roll*cal_rate)
		var error =  target_rot_speed - cur_rot_speed

		var error_f_b = pids[PITCH].iter(error.x)
		var error_yaw = pids[YAW].iter(error.y)
		var error_l_r = pids[ROLL].iter(error.z)

		var motor_handle_forces = [ error_l_r - error_f_b ,  -error_l_r - error_f_b ,- error_l_r + error_f_b , error_l_r + error_f_b ]
		
		current_motor_force = 0
		for i in [0,1,2,3]:
			var motor_pos = quad_body.motors[i].translation
			var motor_force = min(motor_handle_forces[i] + input_power * (motor_power * max_throttle_power), motor_power)
#			current_motor_force += motor_force
			ph.add_force(quad_body.transform.basis.y * motor_force, l_to_g(motor_pos))
			quad_body.motor_rpms[i] = min(quad_body.MAX_RPM, max(quad_body.IDLE_RPM, motor_force/motor_power * quad_body.MAX_RPM + current_air_force.length()/motor_power/2 * quad_body.MAX_RPM))
		ph.add_torque(quad_body.transform.basis.y * sign(error_yaw)*min(abs(error_yaw), 0.1))
		current_air_force = -ph.linear_velocity * ph.linear_velocity.length() * cal_air_resistance
		ph.add_central_force(current_air_force)
