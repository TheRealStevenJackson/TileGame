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
	
	# Create Sprite3D node
	sprite_3d = Sprite3D.new()
	
	# Load the sprite texture
	var texture = load("res://character_sprite.svg")
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

func _process(delta):
	# Optional: Add character movement logic here
	# For now, the sprite will just face the camera automatically
	# If tile changes, update arrows
	if current_tile != previous_tile:
		update_tile_arrows()
	pass