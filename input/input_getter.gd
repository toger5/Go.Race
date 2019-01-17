extends Node
var MOUSE_SENSIBILITY : = 1.0
#var JOY_ACTIONS = ["roll_left", "roll_right", "pitch_down", "pitch_up", "yaw_left", "yaw_right", "trottle_down", "throttle_up"]
enum {ROLL, PITCH, YAW,  THROTTLE}

var mouse_speed : = Vector2()
var use_mouse = false
const RANGE = "range"
const AXIS = "quad_axis"
var calibration = {0 : {AXIS : ROLL, RANGE : [0,0] },
				1 : {AXIS : PITCH, RANGE : [0,0] },
				2 : {AXIS : YAW, RANGE : [0,0]},
				3 : {AXIS : THROTTLE, RANGE : [0,0] }
}
var joystick_id = 0
func _ready():
	load_calibration()
	set_use_mouse(false)
	
	
func save_calibration():
	var file = File.new()
	file.open("user://save_game.dat", File.WRITE)
	file.store_var(calibration)
	file.close()

func load_calibration():
	var file = File.new()
	if OK == file.open("user://save_game.dat", File.READ):
		# TODO write checks for valid data
		var t = file.get_as_text()
		print(t)
		calibration = file.get_var()
		file.close()

func set_axis_ranges(a_r):
	for i in range(4):
		calibration[i][RANGE] = a_r[i]

func set_mapping(joy_axis, quad_axis):
	calibration[joy_axis][AXIS] = quad_axis

func invert(joy_axis):
	calibration[joy_axis][RANGE] = [calibration[joy_axis][RANGE][1], calibration[joy_axis][RANGE][0]]
func is_inverted(joy_axis):
	return calibration[joy_axis][RANGE][0] > calibration[joy_axis][RANGE][1]
func invert_handler(invert, joy_axis):
	if invert != is_inverted(joy_axis):
		invert(joy_axis)
#input mapping
#func add_axis_to_input_map(joy_axis, quad_axis):
#
#	var ev = InputEventJoypadMotion.new()
#	ev.axis = joy_axis
#
#	var index_low = quad_axis * 2
#	var index_high = quad_axis * 2 + 1
#	var ev_low = ev.duplicate()
#	var ev_high = ev.duplicate()
#	ev_low.axis_value = -1.0
#	ev_high.axis_value = 1.0
#	InputMap.action_add_event(JOY_ACTIONS[index_low], ev_low)
#	InputMap.action_add_event(JOY_ACTIONS[index_high], ev_high)
	
##version b
#	for val in [-1.0,1.0]:
#		var e = ev.duplicate()
#		e.axis_value = val
#		InputMap.action_add_event(JOY_ACTIONS[quad_axis * 2 + int((val+1)/2)], e)
	
	
#func clean_input_map():
#	var im = InputMap
#	for a in JOY_ACTIONS:
#		for ev in im.get_action_list(a):
#			if ev is InputEventJoypadMotion:
#				im.action_erase_event(a,ev)

func absmax(a, b) -> float:
	if abs(a) > abs(b):
		return a
	else:
		return b
		
func set_use_mouse(n_use_mouse):
	print("mouse mode update to be: " + str(n_use_mouse))
	if(n_use_mouse && n_use_mouse != use_mouse):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pass
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	use_mouse = n_use_mouse

func _input(e:InputEvent):

	#hanle mouse motion and store it in mouse_speed to use for get_yaw, get_pitch
	var motion_ev : InputEventMouseMotion = e as InputEventMouseMotion
	if motion_ev and use_mouse:
		mouse_speed = motion_ev.relative / 40.0 * MOUSE_SENSIBILITY

func get_calibrated(quad_axis) -> float:
	var axis = calibration[quad_axis][AXIS]
	var axis_range = calibration[quad_axis][RANGE]
	var val = Input.get_joy_axis(joystick_id, axis)
	var offset_val = (val - (axis_range[1] + axis_range[0])/2)
	if (axis_range[1] - axis_range[0]) != 0:
		return 2.0 * offset_val / (axis_range[1] - axis_range[0])
	return 0.0
func get_yaw() -> float:
	
	var j:float = get_calibrated(YAW)
	var m:float = -mouse_speed.x
	
	return absmax(m, j)

func get_pitch() -> float:
	var j:float = get_calibrated(PITCH)
	var m:float = -mouse_speed.y
	return absmax(m, j)

func get_roll() -> float:
	return  get_calibrated(ROLL)

func get_throttle() -> float:
	var j := 1.0/2.0 * (get_calibrated(THROTTLE) + 1.0)
	print("j:", j)
	var b := Input.get_action_strength("trottle_button")
	return absmax(j, b)