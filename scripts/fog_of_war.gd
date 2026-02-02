extends Node3D
class_name FogOfWar

# Reference to the cloud sprite
var cloud_sprite: Sprite3D

# Track if fog is currently fading
var is_fading: bool = false

# Initial visibility state (set before adding to scene tree)
var initial_visible: bool = true

# Height offset above the character
# Character is at tile.y + 0.1 (base) + 0.3 (sprite) = 0.4 total
# Position fog just above that, at around 0.5-0.6 units above tile
@export var height_offset: float = 0.5

func _ready():
	# Create Sprite3D node for the cloud
	cloud_sprite = Sprite3D.new()
	
	# Load the cloud sprite texture
	var texture = load("res://assets/cloud_sprite.svg")
	if texture:
		cloud_sprite.texture = texture
	else:
		print("Warning: Could not load cloud_sprite.svg")
	
	# Set sprite size - make fog larger to cover the tile area
	# Fog should be larger than character sprite to cover the tile
	cloud_sprite.pixel_size = 0.01  # Larger than character (0.01) to cover tile area
	
	# Set billboard mode to always face the camera
	cloud_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Center the sprite (pivot point)
	cloud_sprite.centered = true
	
	# Add sprite as child
	add_child(cloud_sprite)
	
	# Position cloud sprite just above character height
	# Character height is approximately 0.4 units from tile surface
	# Position fog at height_offset (default 0.5) above tile surface
	cloud_sprite.position.y = height_offset
	
	# Set initial visibility and opacity based on initial_visible property
	cloud_sprite.visible = initial_visible
	cloud_sprite.modulate = Color.WHITE  # Initialize to full opacity
	
	#print("Fog of war created at position: ", global_position, " sprite at y: ", cloud_sprite.position.y)

func fade_out(duration: float = 0.5):
	# Animate the fog of war becoming invisible
	if not cloud_sprite or is_fading or not cloud_sprite.visible:
		return
	
	# Mark as fading to prevent multiple fade animations
	is_fading = true
	
	# Create a tween to fade out the sprite
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate the modulate alpha from current alpha to 0.0
	var start_alpha = cloud_sprite.modulate.a
	tween.tween_property(cloud_sprite, "modulate:a", 0.0, duration)
	
	# After fade completes, hide the sprite
	await tween.finished
	cloud_sprite.visible = false
	is_fading = false

func fade_in(duration: float = 0.5):
	# Animate the fog of war becoming visible
	if not cloud_sprite or is_fading:
		return
	
	# Mark as fading to prevent multiple fade animations
	is_fading = true
	
	# Make sprite visible if it's not already
	if not cloud_sprite.visible:
		cloud_sprite.visible = true
		cloud_sprite.modulate.a = 0.0  # Start from invisible
	
	# Create a tween to fade in the sprite
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate the modulate alpha from current alpha to 1.0
	tween.tween_property(cloud_sprite, "modulate:a", 1.0, duration)
	
	# After fade completes, reset fading flag
	await tween.finished
	is_fading = false
