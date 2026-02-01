extends Node3D
class_name Character

# Movement speed
@export var move_speed: float = 3.0

# Reference to the current GameTile the character is on
@export var current_tile_path: NodePath
var current_tile: GameTile
var previous_tile: GameTile  # Track previous tile to hide its arrows

# Reference to the sprite
var sprite_3d: Sprite3D

func _ready():
	# Resolve current_tile from NodePath
	if current_tile_path:
		current_tile = get_node(current_tile_path) as GameTile
	
	# If tile not found, automatically find the only GameTile in the scene
	if not current_tile:
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child is GameTile:
					current_tile = child
					break
	
	# Create Sprite3D node
	sprite_3d = Sprite3D.new()
	
	# Load the sprite texture
	var texture = load("res://assets/character_sprite.svg")
	if texture:
		sprite_3d.texture = texture
	else:
		print("Warning: Could not load character_sprite.svg")
	
	# Set sprite size (adjust to match your game scale)
	sprite_3d.pixel_size = 0.01  # Adjust this value to scale the sprite
	
	# Set billboard mode to always face the camera
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Center the sprite (pivot point)
	sprite_3d.centered = true
	
	# Add sprite as child
	add_child(sprite_3d)
	
	# Position sprite slightly above ground (adjust as needed)
	sprite_3d.position.y = 0.3
	
	# Center character on its current tile
	center_on_tile()
	
	# Create fog of war surrounding the character's starting position
	create_surrounding_fog_of_war()

func center_on_tile():
	# Center the character on the tile it references
	if current_tile:
		global_position = current_tile.global_position
		# Position slightly above the tile surface
		global_position.y = current_tile.global_position.y + 0.1
		# Update arrow visibility
		update_tile_arrows()

func update_tile_arrows():
	# Hide arrows on previous tile
	if previous_tile:
		previous_tile.set_arrows_visible(false)
	
	# Show arrows on current tile
	if current_tile:
		current_tile.set_arrows_visible(true)
	
	# Update previous tile reference
	previous_tile = current_tile

func move_to_tile(tile: GameTile, duration: float = 0.5):
	# Smoothly animate the character to a new tile
	if not tile:
		return
	
	# Update tile references
	previous_tile = current_tile
	current_tile = tile
	
	# Calculate target position (center of tile, slightly above)
	var target_position = tile.global_position
	target_position.y = tile.global_position.y + 0.1
	
	# Get the Map singleton to find nearby fog of war
	var map = GameMap
	if map:
		# Calculate grid coordinates of the new tile position
		var grid_x = int(round(tile.global_position.x / map.tile_spacing))
		var grid_z = int(round(tile.global_position.z / map.tile_spacing))
		
		# Find all fog of war within min_radius of 2
		var min_radius = 1.9
		var fade_in_radius = 3.9
		var fog_to_fade_out = []
		var fog_to_fade_in = []
		
		# Iterate through all fog of war in the registry
		for grid_key in map.fog_of_war_registry:
			var fog = map.fog_of_war_registry[grid_key]
			if not fog or not is_instance_valid(fog):
				continue
			
			# Calculate distance from character's new position
			var fog_grid_x = int(grid_key.x)
			var fog_grid_z = int(grid_key.y)
			var dx = fog_grid_x - grid_x
			var dz = fog_grid_z - grid_z
			var distance_squared = dx * dx + dz * dz
			var min_dist_squared = min_radius * min_radius
			var fade_in_dist_squared = fade_in_radius * fade_in_radius
			
			# If fog is within min_radius, add it to the fade out list
			if distance_squared <= min_dist_squared:
				fog_to_fade_out.append(fog)
			# If fog is at radius 3 or more, add it to the fade in list
			elif distance_squared >= fade_in_dist_squared:
				fog_to_fade_in.append(fog)
		
		# Animate all nearby fog of war fading out
		for fog in fog_to_fade_out:
			if is_instance_valid(fog):
				fog.fade_out(duration)
		
		# Animate all distant fog of war fading in
		for fog in fog_to_fade_in:
			if is_instance_valid(fog):
				fog.fade_in(duration)
	
	# Create a tween for smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_position, duration)
	
	# Update arrow visibility after movement completes
	await tween.finished
	update_tile_arrows()

func create_surrounding_fog_of_war():
	# Create fog of war tiles surrounding the character's current position
	if not current_tile:
		return
	
	# Get the Map singleton
	var map = GameMap
	if not map:
		print("Warning: Cannot create fog of war - Map singleton not found")
		return
	
	# Calculate grid coordinates from the tile's world position
	# This is more reliable than using grid_x/grid_z which might not be set yet
	var grid_x = int(round(current_tile.global_position.x / map.tile_spacing))
	var grid_z = int(round(current_tile.global_position.z / map.tile_spacing))
	
	# Get FogOfWarContainer node to add fog of war as children
	# This keeps the scene organized
	var parent = get_parent()
	var fog_container = parent.get_node_or_null("FogOfWarContainer") if parent else null
	if not fog_container:
		# Fallback to parent if container doesn't exist
		fog_container = parent if parent else get_tree().root
	
	# Create fog of war around the character
	map.create_fog_of_war_around(grid_x, grid_z, fog_container)

func _process(delta):
	# Optional: Add character movement logic here
	# For now, the sprite will just face the camera automatically
	# If tile changes, update arrows
	if current_tile != previous_tile:
		update_tile_arrows()
	pass