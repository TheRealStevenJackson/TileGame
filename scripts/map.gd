extends Node
class_name Map

# 2D tile registry: Dictionary<Vector2, GameTile>
# Key is grid coordinates (x, z), value is the GameTile instance
var tile_registry: Dictionary = {}
var tile_spacing: float = 1.2  # Spacing between tiles

# 2D fog of war registry: Dictionary<Vector2, FogOfWar>
# Key is grid coordinates (x, z), value is the FogOfWar instance
var fog_of_war_registry: Dictionary = {}

func get_tile_at(grid_x: int, grid_z: int) -> GameTile:
	# Get tile at specific grid coordinates
	var grid_key = Vector2(grid_x, grid_z)
	if tile_registry.has(grid_key):
		return tile_registry[grid_key]
	return null

func get_tile_at_position(world_pos: Vector3) -> GameTile:
	# Get tile at world position by converting to grid coordinates
	var grid_x = int(round(world_pos.x / tile_spacing))
	var grid_z = int(round(world_pos.z / tile_spacing))
	return get_tile_at(grid_x, grid_z)

func register_tile(tile: GameTile):
	# Register a tile in the 2D registry using grid coordinates
	# Calculate grid coordinates from world position (position is source of truth)
	var grid_x = int(round(tile.global_position.x / tile_spacing))
	var grid_z = int(round(tile.global_position.z / tile_spacing))
	
	tile.grid_x = grid_x
	tile.grid_z = grid_z
	
	var grid_key = Vector2(grid_x, grid_z)
	tile_registry[grid_key] = tile
	print("Registered tile at grid (", grid_x, ", ", grid_z, ")")

func unregister_tile(tile: GameTile):
	# Unregister a tile from the registry
	var grid_key = Vector2(tile.grid_x, tile.grid_z)
	if tile_registry.has(grid_key) and tile_registry[grid_key] == tile:
		tile_registry.erase(grid_key)
		print("Unregistered tile at grid (", tile.grid_x, ", ", tile.grid_z, ")")

# Fog of War management functions
func get_fog_of_war_at(grid_x: int, grid_z: int) -> FogOfWar:
	# Get fog of war at specific grid coordinates
	var grid_key = Vector2(grid_x, grid_z)
	if fog_of_war_registry.has(grid_key):
		return fog_of_war_registry[grid_key]
	return null

func get_fog_of_war_at_position(world_pos: Vector3) -> FogOfWar:
	# Get fog of war at world position by converting to grid coordinates
	var grid_x = int(round(world_pos.x / tile_spacing))
	var grid_z = int(round(world_pos.z / tile_spacing))
	return get_fog_of_war_at(grid_x, grid_z)

func register_fog_of_war(fog: FogOfWar, grid_x: int, grid_z: int):
	# Register a fog of war tile in the 2D registry using grid coordinates
	var grid_key = Vector2(grid_x, grid_z)
	fog_of_war_registry[grid_key] = fog
	print("Registered fog of war at grid (", grid_x, ", ", grid_z, ")")

func unregister_fog_of_war(grid_x: int, grid_z: int):
	# Unregister a fog of war from the registry
	var grid_key = Vector2(grid_x, grid_z)
	if fog_of_war_registry.has(grid_key):
		fog_of_war_registry.erase(grid_key)
		print("Unregistered fog of war at grid (", grid_x, ", ", grid_z, ")")

func create_fog_of_war_around(grid_x: int, grid_z: int, parent_node: Node):
	# Create fog of war tiles in a ring between 4 and 10 spaces away from the character
	# This creates a donut-shaped area of fog around the character
	var min_radius = 2
	var max_radius = 10
	
	# Iterate through all positions in the square area
	for x in range(grid_x - max_radius, grid_x + max_radius + 1):
		for z in range(grid_z - max_radius, grid_z + max_radius + 1):
			# Calculate distance from character position
			var dx = x - grid_x
			var dz = z - grid_z
			var distance_squared = dx * dx + dz * dz
			var min_dist_squared = min_radius * min_radius
			var max_dist_squared = max_radius * max_radius
			
			# Only create fog if distance is between min_radius and max_radius
			if distance_squared < min_dist_squared or distance_squared > max_dist_squared:
				continue
			
			# Skip if fog already exists at this position
			if get_fog_of_war_at(x, z):
				continue
			
			# Skip if a tile exists at this position (no fog where tiles are)
			if get_tile_at(x, z):
				continue
			
			# Create fog of war instance
			var fog = FogOfWar.new()
			
			# Calculate world position from grid coordinates
			var world_x = x * tile_spacing
			var world_z = z * tile_spacing
			
			# Add to scene tree first (so _ready() can be called)
			parent_node.add_child(fog)
			
			# Set position after adding to scene tree
			fog.global_position = Vector3(world_x, 0, world_z)
			
			# Register in the fog of war registry
			register_fog_of_war(fog, x, z)
			
			print("Created fog of war at grid (", x, ", ", z, ") world pos: ", fog.global_position)
