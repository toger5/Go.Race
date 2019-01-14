extends HBoxContainer
signal selected()
var selected_quad_axis = -1

func deselect_all():
	$StickL.disable_all()
	$StickR.disable_all()
func _ready():
	deselect_all()
	selected_quad_axis = -1

func _on_StickR_activated(axis):
	deselect_all()
	if(axis == $StickR.HORIZONTAL):
		selected_quad_axis = input_getter.PITCH
	if(axis == $StickR.VERTICAL):
		selected_quad_axis = input_getter.ROLL
	emit_signal("selected")

func _on_StickL_activated(axis):
	deselect_all()
	if(axis == $StickR.HORIZONTAL):
		selected_quad_axis = input_getter.YAW
	if(axis == $StickR.VERTICAL):
		selected_quad_axis = input_getter.THROTTLE
	emit_signal("selected")


func update_with_current():
	$StickR.set_X(input_getter.get_roll())
	$StickR.set_Y(input_getter.get_pitch())
	$StickL.set_X(input_getter.get_yaw())
	print(input_getter.get_throttle())
	$StickL.set_Y(input_getter.get_throttle() * 2.0 - 1.0)

func _on_disable():
	selected_quad_axis = -1


