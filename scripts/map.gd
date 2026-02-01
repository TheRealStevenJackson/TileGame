extends Node
class_name Map

# 2D tile registry: Dictionary<Vector2, GameTile>
# Key is grid coordinates (x, z), value is the GameTile instance
var tile_registry: Dictionary = {}
var tile_spacing: float = 1.2  # Spacing between tiles

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
