tool
extends Spatial

enum Maps {
	None
	TestOnlyCollider,
	TestRider
}
var map_paths = [
	"",
	"res://maps/Test_only_collider.tscn",
	"res://maps/TestRider/TestRider.tscn"
]
export (Maps) var map setget set_map
func set_map(new_scene):
	for c in get_children():
		remove_child(c)
	map = new_scene
	if new_scene == 0:
		return
	var p_scn = load(map_paths[new_scene])
	add_child(p_scn.instance())