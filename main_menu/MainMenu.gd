extends Control

func _ready():
	print("started")

var CalibrateScn = load("res://input/joy_calibration/JoyCalibrate.tscn")
var FlightScn = load("res://Flight.tscn")

func _on_BtnCalibrate_pressed():
	get_tree().change_scene_to(CalibrateScn)


func _on_BtnStart_pressed():
	get_tree().change_scene_to(FlightScn)
