extends Camera3D

# Rotation speed (radians per second)
@export var rotation_speed: float = 2.0
# Zoom speed (units per scroll)
@export var zoom_speed: float = 0.5
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

func _find_character(node: Node) -> Node3D:
	# Recursively search for Character node
	if node is Character:
		return node as Node3D
	for child in node.get_children():
		var result = _find_character(child)
		if result:
			return result
	return null

func _input(event):
	# Handle mouse wheel zoom
	if event is InputEventMouseButton and pivot:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(zoom_speed)

func _zoom_camera(zoom_delta: float):
	if not pivot:
		return
	
	var pivot_pos = pivot.global_position
	var camera_offset = global_position - pivot_pos
	var current_distance = camera_offset.length()
	
	# Calculate new distance
	var new_distance = clamp(current_distance + zoom_delta, min_distance, max_distance)
	
	# Normalize the offset and scale to new distance
	if camera_offset.length() > 0:
		camera_offset = camera_offset.normalized() * new_distance
		global_position = pivot_pos + camera_offset
		look_at(pivot_pos, Vector3.UP)

func _process(delta):
	if not pivot:
		return
	
	# Get rotation input
	var rotation_direction = 0.0
	
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		rotation_direction = -1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		rotation_direction = 1.0
	
	# Rotate camera around pivot point
	if rotation_direction != 0.0:
		var pivot_pos = pivot.global_position
		var camera_offset = global_position - pivot_pos
		
		# Rotate the offset around the Y-axis (vertical axis)
		var rotation_angle = rotation_direction * rotation_speed * delta
		var rotation_basis = Basis(Vector3.UP, rotation_angle)
		camera_offset = rotation_basis * camera_offset
		
		# Update camera position
		global_position = pivot_pos + camera_offset
		
		# Make camera look at pivot point
		look_at(pivot_pos, Vector3.UP)
