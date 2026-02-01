@tool
extends Node

@export var source_sheet: Texture2D
@export var sprite_size: Vector2i = Vector2i(16, 16)
@export var output_folder: String = "res://sprites/items/"
@export var run_slicer: bool = false:
	set(val):
		if val and source_sheet:
			_slice_sheet()

func _slice_sheet():
	# Ensure the directory exists
	if not DirAccess.dir_exists_absolute(output_folder):
		DirAccess.make_dir_recursive_absolute(output_folder)
	
	var columns = source_sheet.get_width() / sprite_size.x
	var rows = source_sheet.get_height() / sprite_size.y
	
	for y in range(rows):
		for x in range(columns):
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = source_sheet
			atlas_tex.region = Rect2(x * sprite_size.x, y * sprite_size.y, sprite_size.x, sprite_size.y)
			
			var file_name = "sprite_%d_%d.tres" % [x, y]
			var path = output_folder + file_name
			ResourceSaver.save(atlas_tex, path)
			
	print("Slicing complete! Check: ", output_folder)
