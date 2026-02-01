extends Node3D
class_name GameTile

# Static 2D tile registry: Dictionary<Vector2, GameTile>
# Key is grid coordinates (x, z), value is the GameTile instance
static var tile_registry: Dictionary = {}
static var tile_spacing: float = 1.2  # Spacing between tiles

# Grid coordinates for this tile
var grid_x: int = 0
var grid_z: int = 0

# References to the arrow sprites
var right_arrow: Sprite3D
var left_arrow: Sprite3D
var back_arrow: Sprite3D
var front_arrow: Sprite3D

# References to arrow click areas
var right_arrow_area: Area3D
var left_arrow_area: Area3D
var back_arrow_area: Area3D
var front_arrow_area: Area3D

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
	
	# Register this tile in the 2D registry
	register_tile()

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
	setup_arrow_click_area(right_arrow, "right")
	
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
	setup_arrow_click_area(left_arrow, "left")
	
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
	setup_arrow_click_area(back_arrow, "back")
	
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
	setup_arrow_click_area(front_arrow, "front")

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

func setup_arrow_click_area(arrow: Sprite3D, direction: String):
	# Create an Area3D for click detection
	var area = Area3D.new()
	area.name = direction + "_arrow_area"
	
	# Create a collision shape (box shape to match arrow size)
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.3, 0.3, 0.01)  # Match arrow sprite size
	collision_shape.shape = box_shape
	area.add_child(collision_shape)
	
	# Position the area at the arrow's position
	area.position = arrow.position
	
	# Connect input event signal
	area.input_event.connect(_on_arrow_clicked.bind(direction))
	
	# Add to scene
	add_child(area)
	
	# Store reference based on direction
	match direction:
		"right":
			right_arrow_area = area
		"left":
			left_arrow_area = area
		"back":
			back_arrow_area = area
		"front":
			front_arrow_area = area
	
	# Area3D is always ready for input events (monitoring/monitorable don't affect input_event)

func _on_arrow_clicked(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int, direction: String):
	# Only handle mouse button clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		on_arrow_click(direction)

func on_arrow_click(direction: String):
	# Calculate grid coordinates for the new tile
	var new_grid_x = grid_x
	var new_grid_z = grid_z
	
	match direction:
		"right":
			new_grid_x += 1  # +X direction
		"left":
			new_grid_x -= 1  # -X direction
		"back":
			new_grid_z += 1  # +Z direction
		"front":
			new_grid_z -= 1  # -Z direction
	
	# Check if a tile already exists at this grid position
	var grid_key = Vector2(new_grid_x, new_grid_z)
	if tile_registry.has(grid_key):
		print("Tile already exists at grid position (", new_grid_x, ", ", new_grid_z, ") - not creating duplicate")
		# Move character to existing tile instead of creating a new one
		var existing_tile = tile_registry[grid_key]
		var character = _find_character_in_scene()
		if character:
			character.move_to_tile(existing_tile, 0.5)
		return  # Exit early - don't create a new tile
	
	# No tile exists at this position, so create a new one
	# Calculate new tile position based on grid coordinates
	var new_tile_position = Vector3(
		new_grid_x * tile_spacing,
		global_position.y,  # Keep same Y level
		new_grid_z * tile_spacing
	)
	
	# Create new GameTile instance
	var new_tile = GameTile.new()
	new_tile.grid_x = new_grid_x
	new_tile.grid_z = new_grid_z
	new_tile.global_position = new_tile_position
	
	# Add to scene tree (add as sibling to this tile)
	var parent = get_parent()
	if parent:
		parent.add_child(new_tile)
	else:
		# Fallback: add to scene root
		get_tree().root.add_child(new_tile)
	
	print("Spawned new tile at grid (", new_grid_x, ", ", new_grid_z, ") position ", new_tile_position, " in direction ", direction)
	
	# Move the character to the new tile with smooth animation
	var character = _find_character_in_scene()
	if character:
		character.move_to_tile(new_tile, 0.5)  # 0.5 second animation

func register_tile():
	# Register this tile in the 2D registry using grid coordinates
	# Calculate grid coordinates from world position (position is source of truth)
	grid_x = int(round(global_position.x / tile_spacing))
	grid_z = int(round(global_position.z / tile_spacing))
	
	var grid_key = Vector2(grid_x, grid_z)
	tile_registry[grid_key] = self
	print("Registered tile at grid (", grid_x, ", ", grid_z, ")")

func unregister_tile():
	# Unregister this tile from the registry
	var grid_key = Vector2(grid_x, grid_z)
	if tile_registry.has(grid_key) and tile_registry[grid_key] == self:
		tile_registry.erase(grid_key)
		print("Unregistered tile at grid (", grid_x, ", ", grid_z, ")")

func _exit_tree():
	# Clean up: unregister tile when removed from scene
	unregister_tile()

static func get_tile_at(grid_x: int, grid_z: int) -> GameTile:
	# Get tile at specific grid coordinates
	var grid_key = Vector2(grid_x, grid_z)
	if tile_registry.has(grid_key):
		return tile_registry[grid_key]
	return null

static func get_tile_at_position(world_pos: Vector3) -> GameTile:
	# Get tile at world position by converting to grid coordinates
	var grid_x = int(round(world_pos.x / tile_spacing))
	var grid_z = int(round(world_pos.z / tile_spacing))
	return get_tile_at(grid_x, grid_z)

func _find_character_in_scene() -> Character:
	# Find the Character node in the scene tree
	var root = get_tree().root
	return _find_character_recursive(root)

func _find_character_recursive(node: Node) -> Character:
	# Recursively search for Character node
	if node is Character:
		return node as Character
	for child in node.get_children():
		var result = _find_character_recursive(child)
		if result:
			return result
	return null
