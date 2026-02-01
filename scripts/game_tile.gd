extends Node3D
class_name GameTile

# References to the arrow sprites
var right_arrow: Sprite3D
var left_arrow: Sprite3D
var back_arrow: Sprite3D
var front_arrow: Sprite3D

func _ready():
	# Create a flat cube mesh
	var mesh_instance = MeshInstance3D.new()
	var array_mesh = ArrayMesh.new()
	
	# Define flat cube dimensions (width, depth, height)
	var width = 1.0
	var depth = 1.0
	var height = 0.1  # Very flat
	
	# Create vertices for a flat cube
	var vertices = PackedVector3Array([
		# Bottom face
		Vector3(-width/2, -height/2, -depth/2),  # 0
		Vector3(width/2, -height/2, -depth/2),   # 1
		Vector3(width/2, -height/2, depth/2),    # 2
		Vector3(-width/2, -height/2, depth/2),  # 3
		# Top face
		Vector3(-width/2, height/2, -depth/2),  # 4
		Vector3(width/2, height/2, -depth/2),   # 5
		Vector3(width/2, height/2, depth/2),    # 6
		Vector3(-width/2, height/2, depth/2),  # 7
	])
	
	# Define indices for all 6 faces
	var indices = PackedInt32Array([
		# Bottom face
		0, 2, 1,
		0, 3, 2,
		# Top face
		4, 5, 6,
		4, 6, 7,
		# Front face
		0, 1, 5,
		0, 5, 4,
		# Back face
		2, 3, 7,
		2, 7, 6,
		# Left face
		3, 0, 4,
		3, 4, 7,
		# Right face
		1, 2, 6,
		1, 6, 5,
	])
	
	# Create arrays for the mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Create normals for proper lighting
	var normals = PackedVector3Array()
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var normal = Vector3.ZERO
		# Calculate normal based on which face the vertex belongs to
		if abs(vertex.y + height/2) < 0.01:  # Bottom face
			normal = Vector3(0, -1, 0)
		elif abs(vertex.y - height/2) < 0.01:  # Top face
			normal = Vector3(0, 1, 0)
		elif abs(vertex.x + width/2) < 0.01:  # Left face
			normal = Vector3(-1, 0, 0)
		elif abs(vertex.x - width/2) < 0.01:  # Right face
			normal = Vector3(1, 0, 0)
		elif abs(vertex.z + depth/2) < 0.01:  # Front face
			normal = Vector3(0, 0, -1)
		else:  # Back face
			normal = Vector3(0, 0, 1)
		normals.append(normal)
	
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	# Add the mesh data
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Set the mesh and add to scene
	mesh_instance.mesh = array_mesh
	add_child(mesh_instance)
	
	# Create 3D arrows pointing out from each side
	create_side_arrows(width, depth, height)

func create_side_arrows(width: float, depth: float, height: float):
	# Load arrow texture
	var arrow_texture = load("res://assets/arrow_sprite.svg")
	if not arrow_texture:
		print("Warning: Could not load arrow_sprite.svg")
		return
	
	# Arrow size
	var arrow_size = 0.3
	var arrow_height = height / 2 + 0.01  # Position at tile surface level
	
	# Right arrow (pointing in +X direction) - flat in X-Z plane
	right_arrow = Sprite3D.new()
	right_arrow.texture = arrow_texture
	right_arrow.pixel_size = 0.01
	right_arrow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	right_arrow.centered = true
	right_arrow.position = Vector3(width/2 + 0.1, arrow_height, 0)
	right_arrow.rotation_degrees = Vector3(-90, 0, 0)  # Flat, pointing right
	right_arrow.visible = false  # Initially hidden
	add_child(right_arrow)
	
	# Left arrow (pointing in -X direction) - flat in X-Z plane
	left_arrow = Sprite3D.new()
	left_arrow.texture = arrow_texture
	left_arrow.pixel_size = 0.01
	left_arrow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	left_arrow.centered = true
	left_arrow.position = Vector3(-width/2 - 0.1, arrow_height, 0)
	left_arrow.rotation_degrees = Vector3(-90, 180, 0)  # Flat, pointing left
	left_arrow.visible = false  # Initially hidden
	add_child(left_arrow)
	
	# Back arrow (pointing in +Z direction) - flat in X-Z plane
	back_arrow = Sprite3D.new()
	back_arrow.texture = arrow_texture
	back_arrow.pixel_size = 0.01
	back_arrow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	back_arrow.centered = true
	back_arrow.position = Vector3(0, arrow_height, depth/2 + 0.1)
	back_arrow.rotation_degrees = Vector3(-90, -90, 0)  # Flat, pointing back
	back_arrow.visible = false  # Initially hidden
	add_child(back_arrow)
	
	# Front arrow (pointing in -Z direction) - flat in X-Z plane
	front_arrow = Sprite3D.new()
	front_arrow.texture = arrow_texture
	front_arrow.pixel_size = 0.01
	front_arrow.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	front_arrow.centered = true
	front_arrow.position = Vector3(0, arrow_height, -depth/2 - 0.1)
	front_arrow.rotation_degrees = Vector3(-90, 90, 0)  # Flat, pointing front
	front_arrow.visible = false  # Initially hidden
	add_child(front_arrow)

func set_arrows_visible(visible: bool):
	# Show or hide all arrows based on whether character is on this tile
	if right_arrow:
		right_arrow.visible = visible
	if left_arrow:
		left_arrow.visible = visible
	if back_arrow:
		back_arrow.visible = visible
	if front_arrow:
		front_arrow.visible = visible
