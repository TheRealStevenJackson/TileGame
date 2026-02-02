extends MarginContainer

## Emitted when the card is clicked (played). Passes the card data.
signal card_played(card_data: CardData)

## Assign in inspector or leave null to use res://ResourceIcons.tres.
## ResourceIcons (extends Sprite2D) holds icon refs with region_rect for sprite sheets.
@export var resource_icons: Variant

# This allows you to drag and drop a .tres file into the inspector
@export var data: CardData:
	set(value):
		data = value
		update_ui()

var _icons: Variant

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

	update_ui()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_card_clicked()

func _on_card_clicked() -> void:
	if not data:
		return
	
	# Check if player can play a card
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager and not turn_manager.can_player_play_card():
		print("Cannot play card - already moved this turn")
		return
	
	var pr = get_node_or_null("/root/PlayerResources")
	if pr and pr.has_method("add_resources"):
		pr.add_resources(data.physical_damage_gen, data.money_gen, data.mana_gen)
	
	# Notify TurnManager that player played a card
	if turn_manager and turn_manager.has_method("player_played_card"):
		turn_manager.player_played_card()
	
	# End turn immediately when playing a card (as per requirements)
	if turn_manager and turn_manager.has_method("end_player_turn"):
		turn_manager.end_player_turn()
	
	card_played.emit(data)

func update_ui():
	if not data:
		return
	var vbox: Control = get_node_or_null("PanelContainer/VBoxContainer") if has_node("PanelContainer/VBoxContainer") else get_node_or_null("VBoxContainer") if has_node("VBoxContainer") else get_node_or_null("NinePatchRect/VBoxContainer")
	if not vbox:
		return
	var title_node = get_node_or_null("Title") if has_node("Title") else vbox.get_node_or_null("Title")
	if title_node:
		title_node.text = data.title
	vbox.get_node("Description").text = data.description
	var ill := vbox.get_node_or_null("TextureRect")
	if ill and data.texture_slice:
		ill.texture = data.texture_slice
		ill.texture_filter = Control.TEXTURE_FILTER_NEAREST
	var cost_label := vbox.get_node_or_null("CostLabel")
	if cost_label:
		cost_label.text = str(data.cost)
	var cost_hbox := vbox.get_node_or_null("HBoxContainer2")
	if cost_hbox:
		var cost_node := cost_hbox.get_node_or_null("Cost")
		if cost_node:
			cost_node.text = str(data.cost)
	var gen_container := get_node_or_null("GenContainer") if has_node("GenContainer") else vbox.get_node_or_null("GenContainer") if vbox.has_node("GenContainer") else vbox.get_node_or_null("ResourcesGenerated")
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
		value_label.text = str(value)
