extends Control

var axis_range = []
enum{AXIS_RANGE_STATE, MAPPING_STATE}
var current_state = AXIS_RANGE_STATE
func _ready():
	$VBox/NextButton.text = tr("DONE")
	$VBox/Instruction.text = tr("CALIBRATE_RANGE")
	for i in range(4):
		axis_range.append([0.0,0.0])

func _input(ev):
	if ev is InputEventJoypadMotion:
		var jv : = ev as InputEventJoypadMotion
		var axis = jv.axis
		var val = jv.axis_value
		if axis <= 3:
			if current_state == AXIS_RANGE_STATE:
				if axis_range[axis][0] > val:
					axis_range[axis][0] = val
				elif axis_range[axis][1] < val:
					axis_range[axis][1] = val
				print("axis: ", axis, " min: ",axis_range[axis][0], " max: ", axis_range[axis][1])
	
			var calibrated_val = (val - (axis_range[axis][1] + axis_range[axis][0])/2)
			if (axis_range[axis][1] - axis_range[axis][0]) != 0:
				calibrated_val = 2*calibrated_val / (axis_range[axis][1] - axis_range[axis][0])
			$VBox/HBox/AxisPreviews.get_child(axis).get_node("ProgressBar").value = calibrated_val
			$VBox/HBox/Remote.update_with_current()

func _on_axis_selected():
	var joy_axis = $VBox/HBox/Remote.selected_quad_axis
	var quad_axis =  $VBox/HBox/AxisPreviews.selected_joy_axis
	if joy_axis != -1 and quad_axis != -1:
		input_getter.set_mapping(joy_axis, quad_axis)
		$VBox/HBox/Remote.deselect_all()
		$VBox/HBox/AxisPreviews.deselect_all()
func _on_NextButton_pressed():
	if current_state == AXIS_RANGE_STATE:
		$VBox/NextButton.text = tr("FINISH")
		current_state = MAPPING_STATE
		$VBox/HBox/AxisPreviews.show_inverted()
		input_getter.set_axis_ranges(axis_range)
	elif current_state == MAPPING_STATE:
		get_tree().change_scene("res://main_menu/MainMenu.tscn")
