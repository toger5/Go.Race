extends HBoxContainer
signal inverted(is_inverted)
signal select


func _on_Inverted_toggled(active):
	emit_signal("inverted", active)

func show_map_tools(inverted):
	$Button.visible = true
	$Button.text = tr("UNKNOWN")
	$Inverted.visible = true
	$Inverted.pressed = inverted