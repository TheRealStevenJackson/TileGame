extends MarginContainer

## Assign in inspector or leave null to use res://ResourceIcons.tres.
## ResourceIcons (extends Sprite2D) holds icon refs with region_rect for sprite sheets.
@export var resource_icons: Variant

# This allows you to drag and drop a .tres file into the inspector
@export var data: CardData:
	set(value):
		data = value
		if is_inside_tree():
			update_ui()

var _icons: Variant

func _ready():
	update_ui()

func update_ui():
	if not data:
		return
	var vbox: Control = get_node_or_null("PanelContainer/VBoxContainer") if has_node("PanelContainer/VBoxContainer") else get_node_or_null("VBoxContainer")
	if not vbox:
		return
	vbox.get_node("Title").text = data.title
	vbox.get_node("Description").text = data.description
	var ill := vbox.get_node_or_null("TextureRect")
	if ill and data.image:
		ill.texture = data.image
	var cost_label := vbox.get_node_or_null("CostLabel")
	if cost_label:
		cost_label.text = str(data.cost)
	var cost_hbox := vbox.get_node_or_null("HBoxContainer2")
	if cost_hbox:
		var cost_node := cost_hbox.get_node_or_null("Cost")
		if cost_node:
			cost_node.text = str(data.cost)
	var gen_container := vbox.get_node_or_null("GenContainer")
	if gen_container:
		var icon_pd = _icons.icon_physical_damage if _icons else null
		var icon_money = _icons.icon_money if _icons else null
		var icon_mana = _icons.icon_mana if _icons else null
		_set_gen_row(gen_container.get_node_or_null("PhysicalDamageRow"), data.physical_damage_gen, icon_pd)
		_set_gen_row(gen_container.get_node_or_null("MoneyRow"), data.money_gen, icon_money)
		_set_gen_row(gen_container.get_node_or_null("ManaRow"), data.mana_gen, icon_mana)

func _set_gen_row(row: Control, value: int, icon: Variant) -> void:
	if not row:
		return
	row.visible = value > 0
	if value <= 0:
		return
	var icon_node := row.get_node_or_null("Icon")
	if not icon_node:
		icon_node = row.get_node_or_null("Sprite2D")
	if icon_node:
		if icon is Texture2D:
			if icon_node is TextureRect:
				icon_node.texture = icon
			elif icon_node is Sprite2D:
				icon_node.texture = icon
		elif icon is Sprite2D and icon.texture:
			# Use Sprite2D so we keep region_rect for sprite sheets
			if icon_node is TextureRect:
				icon_node.texture = icon.texture
			elif icon_node is Sprite2D:
				icon_node.texture = icon.texture
				icon_node.region_enabled = icon.region_enabled
				icon_node.region_rect = icon.region_rect
	var value_label := row.get_node_or_null("Value")
	if value_label:
		value_label.text = "+%d" % value
