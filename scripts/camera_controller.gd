extends Camera3D

# Rotation speed (radians per second)
@export var rotation_speed: float = 2.0
# Zoom speed (units per scroll)
@export var zoom_speed: float = 5.0
# Minimum and maximum distance from pivot
@export var min_distance: float = 1.0
@export var max_distance: float = 10.0
# Reference to the pivot point (Character)
@export var pivot_path: NodePath
var pivot: Node3D

func _ready():
	# Find the pivot point (Character) if path is set, otherwise search for it
	if pivot_path:
		pivot = get_node(pivot_path) as Node3D
	else:
		# Try to find Character node automatically (sibling in scene)
		var parent = get_parent()
		if parent:
			pivot = parent.get_node_or_null("Character") as Node3D
		# If not found, search the scene tree for Character class
		if not pivot:
			var root = get_tree().root
			pivot = _find_character(root)
	
	# Get the vector towards the pivot and look at it
	if pivot:
		var direction_to_pivot = pivot.global_position - global_position
		look_at(pivot.global_position, Vector3.UP)

func _find_character(node: Node) -> Node3D:
	# Recursively search for Character node
	if node is Character:
		return node as Node3D
	for child in node.get_children():
		var result = _find_character(child)
		if result:
			return result
	return null

func _process(delta):
	if not pivot:
		return
	
	# Get rotation input
	var rotation_direction = 0.0
	
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		rotation_direction = -1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		rotation_direction = 1.0
	
	var pivot_pos = pivot.global_position
	var camera_offset = global_position - pivot_pos
	var needs_update = false
	
	# Rotate camera around pivot point
	if rotation_direction != 0.0:
		# Rotate the offset around the Y-axis (vertical axis)
		var rotation_angle = rotation_direction * rotation_speed * delta
		var rotation_basis = Basis(Vector3.UP, rotation_angle)
		camera_offset = rotation_basis * camera_offset
		needs_update = true
	
	# Move camera towards or away from pivot with W and S
	var zoom_direction = 0.0
	if Input.is_key_pressed(KEY_W):
		zoom_direction = -1.0
	if Input.is_key_pressed(KEY_S):
		zoom_direction = 1.0
	
	if zoom_direction != 0.0:
		var current_distance = camera_offset.length()
		var new_distance = clamp(current_distance + zoom_direction * zoom_speed * delta, min_distance, max_distance)
		
		# Normalize the offset and scale to new distance
		if camera_offset.length() > 0:
			camera_offset = camera_offset.normalized() * new_distance
			needs_update = true
	
	# Update camera position if needed
	if needs_update:
		global_position = pivot_pos + camera_offset
		look_at(pivot_pos, Vector3.UP)
