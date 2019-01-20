extends Panel
signal activated(axis)
signal disable()
func _ready():
	pass

var sb_enabled = load("res://input/joy_calibration/axis_enabled_sbox.tres")
var sb_disabled = load("res://input/joy_calibration/axis_disabled_sbox.tres")

enum {NO_AXIS, VERTICAL, HORIZONTAL}

var active_axis = NO_AXIS
var current_pos = Vector2(0,0)
func get_axis_by_id(axis:int)->Panel:
	var axis_panel : Panel = null
	if axis == HORIZONTAL:
		axis_panel = $Hori
	elif axis == VERTICAL:
		axis_panel = $Vert
	return axis_panel

func set_X(x):
	current_pos.x = x
	update_nod_pos()

func set_Y(y):
	current_pos.y = y
	update_nod_pos()

func update_nod_pos():
	#print("curpos: ", current_pos)
	var pos = rect_size/2 + current_pos * (rect_size.x/2 - $Nod.rect_size.x / 2)
	var offset = $Nod.rect_size / 2
	$Nod.rect_position = Vector2(pos.x, rect_size.y - pos.y) - offset
#not used atm
func enable_additional_axis(axis):
	emit_signal("activated", axis)
	get_axis_by_id(axis).add_stylebox_override("panel", sb_enabled)

func disable_all():
	for a in [VERTICAL, HORIZONTAL]:
		get_axis_by_id(a).add_stylebox_override("panel", sb_disabled)
	emit_signal("disable")

func enable_exclusiv_axis(axis:int):
	disable_all()
	active_axis = axis
	enable_additional_axis(axis)

func _on_Hori_gui_input(e):
	if e is InputEventMouseButton and e.pressed:
		enable_exclusiv_axis(HORIZONTAL)


func _on_Vert_gui_input(e):
	if e is InputEventMouseButton and e.pressed:
		enable_exclusiv_axis(VERTICAL)


func _on_Stick_bg_gui_input(e):
	if e is InputEventMouseButton and e.pressed:
		disable_all()
