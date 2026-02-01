extends MarginContainer

## Assign in inspector or leave null to use res://ResourceIcons.tres
@export var resource_icons: ResourceIcons

# This allows you to drag and drop a .tres file into the inspector
@export var data: CardData:
	set(value):
		data = value
		if is_inside_tree():
			update_ui()

var _icons: ResourceIcons

func _ready():
	_icons = resource_icons
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
	if gen_container and _icons:
		_set_gen_row(gen_container.get_node_or_null("PhysicalDamageRow"), data.physical_damage_gen, _icons.icon_physical_damage)
		_set_gen_row(gen_container.get_node_or_null("MoneyRow"), data.money_gen, _icons.icon_money)
		_set_gen_row(gen_container.get_node_or_null("ManaRow"), data.mana_gen, _icons.icon_mana)
	else:
		var gen_label := vbox.get_node_or_null("GenLabel")
		if gen_label:
			var parts: Array[String] = []
			if data.physical_damage_gen > 0:
				parts.append("+%d Physical Damage" % data.physical_damage_gen)
			if data.money_gen > 0:
				parts.append("+%d Money" % data.money_gen)
			if data.mana_gen > 0:
				parts.append("+%d Mana" % data.mana_gen)
			gen_label.text = ", ".join(parts) if parts.size() > 0 else ""

func _set_gen_row(row: Control, value: int, icon: Variant) -> void:
	if not row:
		return
	row.visible = value > 0
	if value <= 0:
		return
	var tex: Texture2D = null
	if icon is Texture2D:
		tex = icon
	elif icon is Sprite2D and icon.texture:
		tex = icon.texture
	var icon_node := row.get_node_or_null("Icon")
	if icon_node and tex:
		if icon_node is TextureRect:
			icon_node.texture = tex
		elif icon_node is Sprite2D:
			icon_node.texture = tex
	var value_label := row.get_node_or_null("Value")
	if value_label:
		value_label.text = "+%d" % value
