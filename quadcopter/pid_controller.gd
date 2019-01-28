class_name PidController
extends Node

var Kp
var Ki
var Kd
var _derivator
var _integrator
#var Integrator_max
#var Integrator_min

func _init(P, I, D):
	Kp=P
	Ki=I
	Kd=D
	
func iter(error):
	var P_value = Kp * error
	var D_value
	if _derivator == null:
		# only runs on first iteration
		D_value = Kd * error
	else:
		# the _derivator is a helper to derive the error. It stores the error of the last iteration.
		# error - _derivator is the change of error "the angular velocity of the quad"
		D_value = Kd * ( error - _derivator)
	_derivator = error
	
	if _integrator == null:
		# only runs on first iteration
		_integrator = error
	else:
		_integrator = _integrator + error

	#if _integrator > Integrator_max:
	#	_integrator = Integrator_max
	#elif _integrator < Integrator_min:
	#	_integrator = Integrator_min

	var I_value = _integrator * Ki

	var out = P_value + I_value + D_value

	return out

func reset():
	_integrator=0
	_derivator=0