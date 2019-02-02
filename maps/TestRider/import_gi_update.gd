tool
extends EditorScenePostImport
func post_import(scene):
	print("pist import")
	check_children(scene)
	for c in node.get_children():
		check_children(c)
func check_children(node):
	if node is MeshInstance:
		print("made ", node.name, " use bake lights")
		node.use_in_baked_light = true
	return
	for c in node.get_children():
		check_children(c)