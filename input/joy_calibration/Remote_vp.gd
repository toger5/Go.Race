tool
extends TextureRect

export var ready = false setget _r

func _r(a):
	_ready()

func _ready():
	print($vp/Remote.get_combined_minimum_size())
	set_texture( $vp.get_texture())
	$vp.size = $vp/Remote.get_combined_minimum_size()