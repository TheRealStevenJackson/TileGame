extends Node3D
class_name Enemy

# Preload required scripts
const Character = preload("res://scripts/character.gd")
const GameTile = preload("res://scripts/game_tile.gd")

# Movement speed
@export var move_speed: float = 2.0

# Reference to the current GameTile the enemy is on
var current_tile: GameTile
var previous_tile: GameTile

# Reference to the sprite
var sprite_3d: Sprite3D

# Enemy stats
@export var health: int = 3
@export var attack_damage: int = 3

# Reference to the player character
var player_character: Character

# Signals
signal enemy_died

func _ready():
	# Find the player character in the scene
	player_character = _find_player_in_scene()
	
	# Create Sprite3D node for enemy
	sprite_3d = Sprite3D.new()
	
	# Load enemy sprite texture (using a different color or sprite)
	var texture = load("res://assets/character_sprite.svg")  # For now, use same sprite but could be different
	if texture:
		sprite_3d.texture = texture
		# Make enemy sprite red to distinguish from player
		sprite_3d.modulate = Color.RED
	else:
		print("Warning: Could not load enemy sprite")
	
	# Set sprite size
	sprite_3d.pixel_size = 0.01
	
	# Set billboard mode
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.centered = true
	
	# Add sprite as child
	add_child(sprite_3d)
	
	# Position sprite slightly above ground
	sprite_3d.position.y = 0.3
	
	# Center on current tile if set
	if current_tile:
		center_on_tile()

func center_on_tile():
	# Center the enemy on its current tile
	if current_tile:
		global_position = current_tile.global_position
		global_position.y = current_tile.global_position.y + 0.1

func move_to_tile(tile: GameTile, duration: float = 0.5):
	# Smoothly animate the enemy to a new tile
	if not tile:
		return
	
	# Update tile references
	previous_tile = current_tile
	current_tile = tile
	
	# Update enemy registry position
	var map = GameMap
	if map and previous_tile:
		map.unregister_enemy(previous_tile.grid_x, previous_tile.grid_z)
		map.register_enemy(self, tile.grid_x, tile.grid_z)
	
	# Calculate target position
	var target_position = tile.global_position
	target_position.y = tile.global_position.y + 0.1
	
	# Create tween for animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_position, duration)
	
	await tween.finished

func take_damage(damage: int):
	health -= damage
	
	# Visual feedback: flash red when taking damage
	if sprite_3d:
		var original_color = sprite_3d.modulate
		sprite_3d.modulate = Color(2.0, 0.5, 0.5, 1.0)  # Bright red flash
		var tween = create_tween()
		tween.tween_property(sprite_3d, "modulate", original_color, 0.3)
	
	if health <= 0:
		# Enemy dies
		emit_signal("enemy_died")
		var map = GameMap
		if map and current_tile:
			map.unregister_enemy(current_tile.grid_x, current_tile.grid_z)
		queue_free()
		# Could add death animation or effects here

func attack_player():
	if not player_character:
		return
	
	# Visual feedback: flash when attacking
	if sprite_3d:
		var original_color = sprite_3d.modulate
		sprite_3d.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Bright white flash
		var tween = create_tween()
		tween.tween_property(sprite_3d, "modulate", original_color, 0.2)
	
	# Deal damage to player
	# Assuming player has a take_damage method - we'll need to add this
	if player_character.has_method("take_damage"):
		player_character.take_damage(attack_damage)
		print("Enemy attacked player for ", attack_damage, " damage")

func perform_turn():
	# Enemy AI logic: follow one tile behind the player
	if not player_character or not current_tile:
		return
	
	var map = GameMap
	if not map:
		return
	
	# Get player's current tile
	var player_tile = player_character.current_tile
	if not player_tile:
		return
	
	# Calculate direction to player
	var dx = player_tile.grid_x - current_tile.grid_x
	var dz = player_tile.grid_z - current_tile.grid_z
	
	# Check if adjacent to player
	var distance_squared = dx * dx + dz * dz
	if distance_squared <= 1.1:  # Adjacent (including diagonally for now)
		# Attack if adjacent
		attack_player()
		return
	
	# Not adjacent, move towards player but try to stay one tile behind
	# Get player's movement direction by checking previous tile
	var player_prev_tile = player_character.previous_tile
	if player_prev_tile and player_prev_tile != current_tile:
		# Check if the target tile is occupied
		if not map.is_tile_occupied(player_prev_tile.grid_x, player_prev_tile.grid_z):
			# Move to where the player was last turn (one tile behind)
			await move_to_tile(player_prev_tile, 0.5)
			return
	
	# Fallback: move directly towards player using better pathfinding
	var best_tile = _find_best_move_towards_player()
	if best_tile:
		await move_to_tile(best_tile, 0.5)

func _find_best_move_towards_player() -> GameTile:
	# Find the best adjacent tile to move towards the player
	# Considers diagonal movement and avoids obstacles
	
	var map = GameMap
	if not map or not player_character or not player_character.current_tile:
		return null
	
	var player_tile = player_character.current_tile
	var current_distance = _get_tile_distance(current_tile, player_tile)
	
	# Check all 8 adjacent tiles (including diagonals)
	var best_tile: GameTile = null
	var best_distance = current_distance
	
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			if dx == 0 and dz == 0:  # Skip current tile
				continue
			
			var check_x = current_tile.grid_x + dx
			var check_z = current_tile.grid_z + dz
			
			# Check if tile exists and is not occupied
			var check_tile = map.get_tile_at(check_x, check_z)
			if check_tile and not map.is_tile_occupied(check_x, check_z):
				# Calculate distance to player from this potential move
				var new_distance = _get_tile_distance(check_tile, player_tile)
				
				# If this move gets us closer to the player, consider it
				if new_distance < best_distance:
					best_distance = new_distance
					best_tile = check_tile
				# If same distance, prefer non-diagonal moves (more natural)
				elif new_distance == best_distance and best_tile and (abs(dx) + abs(dz) == 1):
					best_tile = check_tile
	
	return best_tile

func _get_tile_distance(tile1: GameTile, tile2: GameTile) -> float:
	# Calculate Manhattan distance between two tiles
	if not tile1 or not tile2:
		return 999.0
	
	var dx = abs(tile1.grid_x - tile2.grid_x)
	var dz = abs(tile1.grid_z - tile2.grid_z)
	return dx + dz

func _find_player_in_scene() -> Character:
	# Find the Character node in the scene tree
	var root = get_tree().root
	return _find_player_recursive(root)

func _find_player_recursive(node: Node) -> Character:
	# Recursively search for Character node (player)
	if node is Character:
		return node as Character
	for child in node.get_children():
		var result = _find_player_recursive(child)
		if result:
			return result
	return null

func _exit_tree():
	# Clean up: unregister enemy when removed from scene
	var map = GameMap
	if map and current_tile:
		map.unregister_enemy(current_tile.grid_x, current_tile.grid_z)