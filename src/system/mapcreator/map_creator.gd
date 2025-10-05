extends SubViewport

const MAP_MAT := preload("res://content/materials/map_creation_mat.tres")

func _ready() -> void:
	await create_tween().tween_interval(0.1).finished
	var copy_nodes := get_tree().get_nodes_in_group("copy-for-map")
	var map := $Map
	for c in copy_nodes:
		var copy := c.duplicate()
		map.add_child(copy)
		copy.owner = self
	recursive_material_swap(map)


func recursive_material_swap(n:Node3D):
	for c in n.get_children():
		if c is MeshInstance3D:
			c.material_override = MAP_MAT
		else:
			recursive_material_swap(c)


func _on_focus_entered() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_focus_exited() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
