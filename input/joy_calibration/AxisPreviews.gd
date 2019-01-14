extends VBoxContainer
signal selected()
var joysticks = Input.get_connected_joypads()
var active_joy_index = -1
var JoyAxisBar = load("res://input/joy_calibration/JoyAxisBar.tscn")
var selected_joy_axis = -1
func _ready():
	for c in get_children():
		remove_child(c)

	for i in range(4):
		var axis_bar = JoyAxisBar.instance()
		axis_bar.name = "bar"
		axis_bar.connect("inverted", input_getter, "invert_handler", [i])
		axis_bar.get_node("Button").connect("pressed", self, "select_handler", [i])
		add_child(axis_bar)
		
		var lbl = axis_bar.get_node("Button")
		lbl.text = tr("UNKNOWN") #Input.get_joy_axis_string(i)
	
	for j in joysticks:
		if active_joy_index == -1:
			active_joy_index = j
		var l: Label = Label.new()
		l.text = Input.get_joy_name(j)
		print(l.text)
		add_child(l)

func select_handler(index):
	if selected_joy_axis != -1:
		get_child(selected_joy_axis).get_node("Button").pressed = false
	if selected_joy_axis == index:
		selected_joy_axis = -1
	else:
		selected_joy_axis = index
		emit_signal("selected")
func deselect_all():
	if selected_joy_axis != -1:
		get_child(selected_joy_axis).get_node("Button").pressed = false
func show_inverted():
	for i in range(4):
		var c = get_child(i)
		if c is HBoxContainer:
			c.show_map_tools(input_getter.is_inverted(i))