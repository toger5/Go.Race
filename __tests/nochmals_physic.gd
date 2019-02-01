extends RigidBody

export (NodePath) var motor_front_left
export (NodePath) var motor_front_right
export (NodePath) var motor_back_left
export (NodePath) var motor_back_right
var motor_power = 120
onready var debug = $"../debug"
var pos = Vector3()
# Called when the node enters the scene tree for the first time.
var motors = []
var pidroll = PidController.new(5.0, 0.5, 0.5)
var pidpitch = PidController.new(5.0, 0.5, 0.5)
var max_throttle_power = 0.8
func _ready():
	pos = translation
	motors = [get_node(motor_front_left),get_node(motor_front_right),get_node(motor_back_right),get_node(motor_back_left)]
func l_to_g(v : Vector3) -> Vector3:
	return transform.basis.xform(v)
func g_to_l(v : Vector3) -> Vector3:
	return transform.basis.xform_inv(v)
func _integrate_forces(ph):
	var input_roll = input_getter.get_roll()
	var input_pitch =  input_getter.get_pitch()
	var input_yaw =  input_getter.get_yaw()
	var input_power = input_getter.get_throttle()
	input_power = input_power * 0.9 + 0.1 # Props are always spinning a little...
		
		
		
	print("angvel ", ph.angular_velocity)
	var cur_rot_speed = ph.transform.basis.xform_inv(ph.angular_velocity)
	var cal_rate = 10
	var target_rot_speed = Vector3(input_pitch*cal_rate, input_yaw*cal_rate, input_roll*cal_rate)
#	print("target ", target_rot_speed)
	var error =  target_rot_speed - cur_rot_speed
#	print("error ",error)
#	var error_f_b = pids[PITCH].iter(error.x)
	var error_f_b = pidpitch.iter(error.x)
#	var error_yaw = pids[YAW].iter(error.y)
	var error_l_r = pidroll.iter(error.z)
#		print("error_f_b ", error_f_b)
#	print("error_l_r ", error_l_r)
#		print("error_yaw ", error_yaw)
	
	#(left,top,front)
	#front left(1,0,1), front right(-1,0,1), back right(-1,0,-1), back left(1,0,-1)
	var motor_handle_forces = [ error_l_r-error_f_b,  -error_l_r-error_f_b, -error_l_r+error_f_b,  error_l_r+error_f_b]
	var motor_pos = [Vector3(),Vector3(),Vector3(),Vector3()]
	for j in [0,1,2,3]:
		var current_motor_force =  0
		var i = j
		print("ip ",input_power)
		motor_pos[i] = motors[i].translation
		current_motor_force += min(motor_handle_forces[i] + input_power * motor_power*max_throttle_power, motor_power)
		current_motor_force = max(0, current_motor_force)
		print (current_motor_force)
		if j == 0:
			pass
#			print("basis ",transform.basis.y)
#			print(l_to_g(Vector3(0,1,0)))
#			print(gv(motor_pos[i]))
		ph.add_force(transform.basis.y * current_motor_force, l_to_g(motor_pos[i]))
#	ph.add_central_force(Vector3(0,9.81,0))
	translation = pos
	debug.translation = l_to_g(motor_pos[0]) + translation#pos + transform.basis.y * 1
	#ph.add_torque(Vector3(0,error_yaw,0))
#		print(motor_forces)
	#print("cur_force ", motor_forces)
#		print("motor pos", motor_pos)
#		var glob_m_pos = []
#		for i in motor_pos:
#			glob_m_pos.append(gv(i))
#		print("glob pos", glob_m_pos)
	#current_air_force = -ph.linear_velocity.normalized() * ph.linear_velocity.length_squared() * cal_air_resistance
	#ph.add_central_force(current_air_force)