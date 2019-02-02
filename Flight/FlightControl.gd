extends Control

export (NodePath) var quad_path
# Called when the node enters the scene tree for the first time.
onready var quad : QuadCopter = get_node(quad_path)

func _process(delta):
	update_speed_label()
func update_speed_label():
	$VBox/SpeedLabel.text = "speed: "+ str(round(quad.get_speed() * 100 * 3.6)/100)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
