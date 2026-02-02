@tool
extends EditorScript

const CARD_DATA_DIR := "res://card data"
const SPRITE_DIR := "res://sprites/items"

func _run() -> void:
	var sprite_files := []
	var dir := DirAccess.open(SPRITE_DIR)
	if not dir:
		push_error("Could not open sprite dir")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			sprite_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# Sort the sprite files by X then Y
	sprite_files.sort_custom(func(a, b):
		var a_match = a.get_slice("_", 1).split("_")
		var b_match = b.get_slice("_", 1).split("_")
		var a_x = int(a_match[0])
		var a_y = int(a_match[1])
		var b_x = int(b_match[0])
		var b_y = int(b_match[1])
		if a_x != b_x:
			return a_x < b_x
		return a_y < b_y
	)
	
	# Define categories and their sprite ranges
	var categories = {
		"weapon": {"start": 0, "end": 69, "keywords": ["knife", "sword", "knuckle", "pipe", "punch", "threat", "buster", "cut", "gut", "brawl", "kick"]},
		"money": {"start": 70, "end": 139, "keywords": ["lint", "fee", "haggle", "tip", "loot", "credit", "cash", "scrounge", "finder"]},
		"tech": {"start": 140, "end": 209, "keywords": ["battery", "core", "circuit", "hotwire", "rig", "siphon", "scrap", "emergency", "short", "jury"]},
		"action": {"start": 210, "end": 279, "keywords": ["sweep", "parts", "route", "trade", "spare", "run", "triple", "bunker"]},
		"other": {"start": 280, "end": 307, "keywords": []}
	}
	
	var count := 0
	for i in range(1, 101):
		var card_path := "%s/card_%03d.tres" % [CARD_DATA_DIR, i]
		if not ResourceLoader.exists(card_path):
			continue
		var card_data: CardData = load(card_path)
		if not card_data:
			continue
		
		# Determine category
		var category = "other"
		var title_lower = card_data.title.to_lower()
		for cat in categories:
			for keyword in categories[cat]["keywords"]:
				if keyword in title_lower:
					category = cat
					break
			if category != "other":
				break
		
		# Pick sprite index
		var cat_data = categories[category]
		var num_sprites = cat_data["end"] - cat_data["start"] + 1
		var sprite_index = cat_data["start"] + (card_data.title.hash() % num_sprites)
		if sprite_index >= sprite_files.size():
			sprite_index = sprite_files.size() - 1
		
		var sprite_path := "%s/%s" % [SPRITE_DIR, sprite_files[sprite_index]]
		var texture: Texture2D = load(sprite_path)
		if texture:
			card_data.texture_slice = texture
			var err := ResourceSaver.save(card_data, card_path)
			if err == OK:
				print("Assigned %s (%s) to card %d: %s" % [sprite_path, category, i, card_data.title])
			else:
				push_error("Failed to save card %d" % i)
		count += 1
	print("Assigned %d textures" % count)
