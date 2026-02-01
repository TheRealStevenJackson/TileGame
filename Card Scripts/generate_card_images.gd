@tool
extends EditorScript
## Run from the editor: File → Run (Ctrl+Shift+X).
## Generates a unique placeholder image for each card in "card data/"
## and assigns it to the card's image property.

const CARD_DATA_DIR := "res://card data"
const OUTPUT_DIR := "res://generated_card_images"
const IMAGE_SIZE := Vector2i(256, 256)
const BORDER_PX := 8

func _run() -> void:
	var dir := DirAccess.open("res://")
	if not dir:
		push_error("Could not open res://")
		return
	if not dir.dir_exists(OUTPUT_DIR.trim_prefix("res://")):
		var err := DirAccess.make_dir_absolute(OUTPUT_DIR)
		if err != OK:
			push_error("Could not create %s: %s" % [OUTPUT_DIR, error_string(err)])
			return
		print("Created folder: ", OUTPUT_DIR)

	var count := 0
	for i in range(1, 101):
		var path := "%s/card_%03d.tres" % [CARD_DATA_DIR, i]
		if not ResourceLoader.exists(path):
			continue
		var card_data: CardData = load(path) as CardData
		if not card_data:
			continue
		var img := _generate_card_image(i, card_data)
		if not img:
			continue
		var out_path := "%s/card_%03d.png" % [OUTPUT_DIR, i]
		var abs_path := ProjectSettings.globalize_path(out_path)
		var err := img.save_png(abs_path)
		if err != OK:
			push_error("Failed to save %s: %s" % [out_path, error_string(err)])
			continue
		card_data.image = load(out_path) as Texture2D
		err = ResourceSaver.save(card_data, path)
		if err != OK:
			push_error("Failed to save card %s: %s" % [path, error_string(err)])
			continue
		count += 1
	print("Generated %d card images and updated card data." % count)

func _generate_card_image(card_index: int, card_data: CardData) -> Image:
	var img := Image.create(IMAGE_SIZE.x, IMAGE_SIZE.y, false, Image.FORMAT_RGBA8)
	if not img:
		return null
	# Distinct hue per card, moderate saturation and value
	var hue := (card_index - 1) / 99.0 * 0.85
	var base := Color.from_hsv(hue, 0.45, 0.35)
	var border := Color.from_hsv(hue, 0.5, 0.2)
	var inner := Rect2i(BORDER_PX, BORDER_PX, IMAGE_SIZE.x - BORDER_PX * 2, IMAGE_SIZE.y - BORDER_PX * 2)
	img.fill(border)
	img.fill_rect(inner, base)
	return img
