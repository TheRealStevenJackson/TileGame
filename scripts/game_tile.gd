extends Node3D
class_name GameTile

# Reference to the Map instance that manages the tile registry
var map: Map

# Grid coordinates for this tile
var grid_x: int = 0
var grid_z: int = 0

# Interactive item system
enum ItemType {
	NONE,
	KEY,
	CARD,
	SHOPKEEPER,
	BOSS_DOOR
}

var interactive_item: ItemType = ItemType.NONE
var item_sprite: Sprite3D
var item_label: Label3D

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

# Track hover state for each arrow
var right_arrow_hovered: bool = false
var left_arrow_hovered: bool = false
var back_arrow_hovered: bool = false
var front_arrow_hovered: bool = false

func _ready():
	# Get the Map singleton instance
	map = GameMap
	if not map:
		print("Warning: Map singleton not found")
	
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
	
	# Enable/disable input areas based on arrow visibility
	# This ensures clicks only work when arrows are visible
	if right_arrow_area:
		right_arrow_area.input_ray_pickable = visible
	if left_arrow_area:
		left_arrow_area.input_ray_pickable = visible
	if back_arrow_area:
		back_arrow_area.input_ray_pickable = visible
	if front_arrow_area:
		front_arrow_area.input_ray_pickable = visible

func setup_arrow_click_area(arrow: Sprite3D, direction: String):
	# Create an Area3D for click detection
	var area = Area3D.new()
	area.name = direction + "_arrow_area"
	
	# Enable input ray picking - CRITICAL for input_event to work
	area.input_ray_pickable = true
	
	# Create a collision shape (box shape to match arrow size)
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	# Make the collision shape larger and thicker for easier clicking
	# Arrow sprite is rotated -90 degrees on X axis, so it's flat in X-Z plane
	box_shape.size = Vector3(0.5, 0.5, 0.1)  # Larger and thicker for better click detection
	collision_shape.shape = box_shape
	area.add_child(collision_shape)
	
	# Position and rotate the area to match the arrow
	area.position = arrow.position
	area.rotation_degrees = arrow.rotation_degrees
	
	# Connect input event signal for clicks
	area.input_event.connect(_on_arrow_clicked.bind(direction))
	
	# Connect mouse hover signals for color change
	# Note: These work on Area3D when input_ray_pickable is true
	area.mouse_entered.connect(_on_arrow_mouse_entered.bind(direction))
	area.mouse_exited.connect(_on_arrow_mouse_exited.bind(direction))
	
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
	
	# Ensure the area is always ready for input (even when arrow is hidden)
	area.visible = true  # Area should always be visible for input detection

func _on_arrow_clicked(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int, direction: String):
	# Only handle mouse button clicks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Verify the arrow is visible before processing click
		var arrow_visible = false
		match direction:
			"right":
				arrow_visible = right_arrow and right_arrow.visible
			"left":
				arrow_visible = left_arrow and left_arrow.visible
			"back":
				arrow_visible = back_arrow and back_arrow.visible
			"front":
				arrow_visible = front_arrow and front_arrow.visible
		
		if arrow_visible:
			print("Arrow clicked: ", direction)  # Debug output
			on_arrow_click(direction)
		else:
			print("Arrow click ignored - arrow not visible: ", direction)

func _on_arrow_mouse_entered(direction: String):
	# Change arrow color to pink when mouse hovers over it
	_set_arrow_hovered(direction, true)

func _on_arrow_mouse_exited(direction: String):
	# Change arrow color back to white when mouse leaves
	_set_arrow_hovered(direction, false)

func _set_arrow_hovered(direction: String, hovered: bool):
	# Update hover state and arrow color
	var arrow: Sprite3D = null
	match direction:
		"right":
			arrow = right_arrow
			right_arrow_hovered = hovered
		"left":
			arrow = left_arrow
			left_arrow_hovered = hovered
		"back":
			arrow = back_arrow
			back_arrow_hovered = hovered
		"front":
			arrow = front_arrow
			front_arrow_hovered = hovered
	
	if arrow and arrow.visible:
		if hovered:
			arrow.modulate = Color.PINK
		else:
			arrow.modulate = Color.WHITE

func on_arrow_click(direction: String):
	# Check if player can move
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager and not turn_manager.can_player_move():
		print("Cannot move - not player's turn or already moved")
		return
	
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
	if not map:
		print("Error: Map instance not found")
		return
	
	var existing_tile = map.get_tile_at(new_grid_x, new_grid_z)
	if existing_tile:
		# Check if the tile is occupied by an enemy
		if map.is_tile_occupied(new_grid_x, new_grid_z):
			print("Cannot move to occupied tile at grid position (", new_grid_x, ", ", new_grid_z, ")")
			return
		
		print("Tile already exists at grid position (", new_grid_x, ", ", new_grid_z, ") - not creating duplicate")
		# Move character to existing tile instead of creating a new one
		var character = _find_character_in_scene()
		if character:
			character.move_to_tile(existing_tile, 0.5)
		return  # Exit early - don't create a new tile
	
	# No tile exists at this position, so create a new one
	# Calculate new tile position based on grid coordinates
	var new_tile_position = Vector3(
		new_grid_x * map.tile_spacing,
		global_position.y,  # Keep same Y level
		new_grid_z * map.tile_spacing
	)
	
	# Create new GameTile instance
	var new_tile = GameTile.new()
	new_tile.map = GameMap  # Set map reference to singleton so new tile can register itself
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
	# Register this tile in the Map's 2D registry
	if map:
		map.register_tile(self)
	else:
		print("Warning: Cannot register tile - Map instance not found")

func unregister_tile():
	# Unregister this tile from the Map's registry
	if map:
		map.unregister_tile(self)
	else:
		print("Warning: Cannot unregister tile - Map instance not found")

func set_interactive_item(item_type: ItemType):
	# Set an interactive item on this tile
	interactive_item = item_type
	
	# Create visual representation
	if item_type != ItemType.NONE:
		_create_item_visual()
	else:
		_remove_item_visual()

func _create_item_visual():
	# Create visual representation for the item
	if item_sprite:
		item_sprite.queue_free()
	if item_label:
		item_label.queue_free()
	
	# Create sprite for the item
	item_sprite = Sprite3D.new()
	add_child(item_sprite)
	
	# Set sprite properties based on item type
	match interactive_item:
		ItemType.KEY:
			item_sprite.texture = load("res://assets/character_sprite.svg")  # Placeholder
			item_sprite.modulate = Color.GOLD
		ItemType.CARD:
			item_sprite.texture = load("res://assets/character_sprite.svg")  # Placeholder
			item_sprite.modulate = Color.BLUE
		ItemType.SHOPKEEPER:
			item_sprite.texture = load("res://assets/character_sprite.svg")  # Placeholder
			item_sprite.modulate = Color.GREEN
		ItemType.BOSS_DOOR:
			item_sprite.texture = load("res://assets/character_sprite.svg")  # Placeholder
			item_sprite.modulate = Color.PURPLE
	
	item_sprite.pixel_size = 0.005
	item_sprite.position = Vector3(0, 0.2, 0)  # Float above tile
	item_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Create label for item type
	item_label = Label3D.new()
	add_child(item_label)
	
	match interactive_item:
		ItemType.KEY:
			item_label.text = "KEY"
		ItemType.CARD:
			item_label.text = "CARD"
		ItemType.SHOPKEEPER:
			item_label.text = "SHOP"
		ItemType.BOSS_DOOR:
			item_label.text = "BOSS DOOR"
	
	item_label.font_size = 32
	item_label.position = Vector3(0, 0.4, 0)
	item_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _remove_item_visual():
	# Remove visual representation
	if item_sprite:
		item_sprite.queue_free()
		item_sprite = null
	if item_label:
		item_label.queue_free()
		item_label = null

func interact_with_item():
	# Handle interaction when player moves onto this tile
	match interactive_item:
		ItemType.KEY:
			_collect_key()
		ItemType.CARD:
			_collect_card()
		ItemType.SHOPKEEPER:
			_open_shop()
		ItemType.BOSS_DOOR:
			_try_open_boss_door()

func _collect_key():
	print("Player found a key!")
	var player_resources = get_node_or_null("/root/PlayerResources")
	if player_resources:
		player_resources.keys += 1
		player_resources.resources_changed.emit()
		print("Keys collected: ", player_resources.keys)
	
	# Remove the item
	set_interactive_item(ItemType.NONE)

func _collect_card():
	print("Player found a card!")
	# Draw an additional card
	var card_hand = _find_card_hand()
	if card_hand and card_hand.has_method("draw_additional_cards"):
		card_hand.draw_additional_cards(1)
		print("Drew 1 additional card")
	
	# Remove the item
	set_interactive_item(ItemType.NONE)

func _open_shop():
	print("Player encountered shopkeeper!")
	# Open the shop UI
	var ui = _find_ui()
	if ui and ui.has_method("_show_shop"):
		ui._show_shop()
	
	# Remove the shopkeeper after interaction
	set_interactive_item(ItemType.NONE)

func _try_open_boss_door():
	var player_resources = get_node_or_null("/root/PlayerResources")
	if player_resources and player_resources.keys > 0:
		player_resources.keys -= 1
		player_resources.resources_changed.emit()
		print("Player used a key to open the boss door!")
		set_interactive_item(ItemType.NONE)
	else:
		print("Boss door is locked! Need a key to open it.")

func _find_card_hand():
	# Find the card hand container
	var root = get_tree().root
	return _find_card_hand_recursive(root)

func _find_card_hand_recursive(node: Node):
	# Recursively search for Card_Hand_Container
	if node.get_script() and node.get_script().resource_path.ends_with("Card_Hand_Container.gd"):
		return node
	for child in node.get_children():
		var result = _find_card_hand_recursive(child)
		if result:
			return result
	return null

func _find_ui():
	# Find the UI script
	var root = get_tree().root
	return _find_ui_recursive(root)

func _find_ui_recursive(node: Node):
	# Recursively search for node_3d_ui script
	if node.get_script() and node.get_script().resource_path.ends_with("node_3d_ui.gd"):
		return node
	for child in node.get_children():
		var result = _find_ui_recursive(child)
		if result:
			return result
	return null

func _exit_tree():
	# Clean up: unregister tile when removed from scene
	unregister_tile()

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
