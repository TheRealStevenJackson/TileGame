extends Node3D
## Adds card hand and resource display to the viewport root so they draw on top of the 3D view.
## Attach this script to the root Node3D of your scene.

# Preload enemy script
const Enemy = preload("res://scripts/enemy.gd")

var turn_label: Label
var attack_buttons_container: VBoxContainer
var move_counter_label: Label
var health_label: Label
var damage_flash_rect: ColorRect
var shop_panel: PanelContainer
var card_hand_container: HBoxContainer

func _ready() -> void:
	call_deferred("_setup_ui")

func _setup_ui() -> void:
	var root := get_tree().root
	if not root:
		return
	# CanvasLayer at viewport root, high layer so it draws on top
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 100
	ui_layer.follow_viewport_enabled = false
	root.add_child(ui_layer)
	# Full-rect container so child Controls get viewport size for layout
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.set_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(overlay)
	# Card hand (CanvasLayer with HBoxContainer inside)
	var card_hand_scene := load("res://scenes/CardHand.tscn") as PackedScene
	if card_hand_scene:
		var card_hand := card_hand_scene.instantiate()
		overlay.add_child(card_hand)
		# Store reference to the HBoxContainer
		var hbox = card_hand.get_node_or_null("HBoxContainer")
		if hbox:
			card_hand_container = hbox
	# Resource display (CanvasLayer with Panel inside)
	var resource_display_scene := load("res://ResourceDisplay.tscn") as PackedScene
	if resource_display_scene:
		var resource_display := resource_display_scene.instantiate()
		overlay.add_child(resource_display)
	
	# Add damage flash effect (invisible by default)
	damage_flash_rect = ColorRect.new()
	damage_flash_rect.color = Color(1.0, 0.0, 0.0, 0.0)  # Transparent red
	damage_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(damage_flash_rect)
	
	# Add shop panel (hidden by default)
	shop_panel = PanelContainer.new()
	shop_panel.set_anchors_preset(Control.PRESET_CENTER)
	shop_panel.size = Vector2(400, 300)
	shop_panel.position = Vector2(-200, -150)
	shop_panel.visible = false
	
	var shop_vbox = VBoxContainer.new()
	shop_vbox.add_theme_constant_override("separation", 10)
	shop_panel.add_child(shop_vbox)
	
	var shop_title = Label.new()
	shop_title.text = "Shop - Rare Cards"
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_vbox.add_child(shop_title)
	
	# Add some shop items
	var item1_button = Button.new()
	item1_button.text = "Power Card - 50💰 (Increases damage)"
	item1_button.custom_minimum_size = Vector2(350, 40)
	item1_button.pressed.connect(_buy_power_card)
	shop_vbox.add_child(item1_button)
	
	var item2_button = Button.new()
	item2_button.text = "Health Card - 30💰 (Restores 5 HP)"
	item2_button.custom_minimum_size = Vector2(350, 40)
	item2_button.pressed.connect(_buy_health_card)
	shop_vbox.add_child(item2_button)
	
	var close_button = Button.new()
	close_button.text = "Close Shop"
	close_button.custom_minimum_size = Vector2(350, 40)
	close_button.pressed.connect(_close_shop)
	shop_vbox.add_child(close_button)
	
	overlay.add_child(shop_panel)
	
	# Add End Turn button
	_add_end_turn_button(overlay)
	
	print("Node3D UI: card hand, resource display, and end turn button added to viewport root")

func _add_end_turn_button(parent: Control) -> void:
	var button := Button.new()
	button.text = "End Turn"
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_END
	button.custom_minimum_size = Vector2(120, 40)
	
	# Position in bottom right corner
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = -130
	button.offset_top = -50
	button.offset_right = -10
	button.offset_bottom = -10
	
	button.pressed.connect(_on_end_turn_pressed)
	parent.add_child(button)
	
	# Add turn indicator label
	turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.text = "Player Turn"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	turn_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	turn_label.custom_minimum_size = Vector2(200, 40)
	
	# Position above the end turn button
	turn_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	turn_label.offset_left = -210
	turn_label.offset_top = -100
	turn_label.offset_right = -10
	turn_label.offset_bottom = -60
	
	parent.add_child(turn_label)
	
	# Add move counter label
	move_counter_label = Label.new()
	move_counter_label.name = "MoveCounterLabel"
	move_counter_label.text = "Moves until cards: 5/5"
	move_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	move_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_counter_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	move_counter_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	move_counter_label.custom_minimum_size = Vector2(200, 40)
	
	# Position below the turn label with more spacing
	move_counter_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	move_counter_label.offset_left = -220
	move_counter_label.offset_top = -125
	move_counter_label.offset_right = -10
	move_counter_label.offset_bottom = -85
	
	parent.add_child(move_counter_label)
	
	# Add health label
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "Health: 20/20"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	health_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	health_label.custom_minimum_size = Vector2(200, 40)
	
	# Position below the move counter with spacing
	health_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	health_label.offset_left = -220
	health_label.offset_top = -165
	health_label.offset_right = -10
	health_label.offset_bottom = -125
	
	parent.add_child(health_label)
	
	attack_buttons_container = VBoxContainer.new()
	attack_buttons_container.name = "AttackButtons"
	attack_buttons_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	attack_buttons_container.size_flags_vertical = Control.SIZE_SHRINK_END
	
	# Position to the left of the end turn button
	attack_buttons_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	attack_buttons_container.offset_left = -280
	attack_buttons_container.offset_top = -200
	attack_buttons_container.offset_right = -140
	attack_buttons_container.offset_bottom = -10
	
	parent.add_child(attack_buttons_container)
	
	# Connect to turn manager signals
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager:
		turn_manager.player_turn_started.connect(_on_player_turn_started)
		turn_manager.enemy_turn_started.connect(_on_enemy_turn_started)
		turn_manager.adjacent_enemies_changed.connect(_on_adjacent_enemies_changed)
		turn_manager.move_counter_changed.connect(_on_move_counter_changed)
	
	# Connect to character health signal
	var character = _find_character()
	if character and character.has_signal("health_changed"):
		character.health_changed.connect(_on_player_health_changed)
		# Initialize health display
		_on_player_health_changed(character.health, character.max_health)

func _on_end_turn_pressed() -> void:
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager and turn_manager.has_method("end_player_turn"):
		turn_manager.end_player_turn()

func _on_player_turn_started() -> void:
	if turn_label:
		turn_label.text = "Player Turn"

func _on_enemy_turn_started() -> void:
	if turn_label:
		turn_label.text = "Enemy Turn"

func _on_adjacent_enemies_changed(enemies: Array) -> void:
	# Clear existing attack buttons
	for child in attack_buttons_container.get_children():
		child.queue_free()
	
	# Get player's available damage
	var player_resources = get_node_or_null("/root/PlayerResources")
	var available_damage = 0
	if player_resources:
		available_damage = player_resources.physical_damage
	
	# Create attack buttons for each adjacent enemy
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if enemy and is_instance_valid(enemy):
			var attack_button = Button.new()
			attack_button.text = "Attack (%d dmg → %d HP)" % [available_damage, enemy.health]
			attack_button.custom_minimum_size = Vector2(200, 50)
			
			# Style the button to be red and outlined
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = Color(0.8, 0.2, 0.2, 0.8)  # Red background
			style_normal.border_color = Color(1.0, 0.0, 0.0, 1.0)  # Red border
			style_normal.border_width_bottom = 2
			style_normal.border_width_top = 2
			style_normal.border_width_left = 2
			style_normal.border_width_right = 2
			style_normal.corner_radius_bottom_left = 4
			style_normal.corner_radius_bottom_right = 4
			style_normal.corner_radius_top_left = 4
			style_normal.corner_radius_top_right = 4
			
			var style_hover = style_normal.duplicate()
			style_hover.bg_color = Color(1.0, 0.3, 0.3, 0.9)  # Lighter red on hover
			
			var style_pressed = style_normal.duplicate()
			style_pressed.bg_color = Color(0.6, 0.1, 0.1, 0.9)  # Darker red when pressed
			
			attack_button.add_theme_stylebox_override("normal", style_normal)
			attack_button.add_theme_stylebox_override("hover", style_hover)
			attack_button.add_theme_stylebox_override("pressed", style_pressed)
			attack_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))  # White text
			
			attack_button.pressed.connect(_on_attack_enemy_pressed.bind(enemy))
			attack_buttons_container.add_child(attack_button)

func _on_move_counter_changed(current: int, max_value: int) -> void:
	if move_counter_label:
		move_counter_label.text = "Moves until cards: %d/%d" % [current, max_value]

func _on_attack_enemy_pressed(enemy: Enemy) -> void:
	var turn_manager = get_node_or_null("/root/TurnManager")
	if turn_manager and turn_manager.has_method("attack_enemy"):
		# Use all available physical damage for the attack
		var player_resources = get_node_or_null("/root/PlayerResources")
		if player_resources:
			var damage = player_resources.physical_damage
			if damage > 0:
				turn_manager.attack_enemy(enemy, damage)
				_flash_attack_effect()  # Visual feedback for attacking
			else:
				print("No physical damage available to attack")

func _find_character() -> Character:
	# Find the Character node in the scene tree
	var root = get_tree().root
	return _find_character_recursive(root)

func _find_character_recursive(node: Node) -> Character:
	# Recursively search for Character node
	if node is Character:
		return node as Character
	
	for child in node.get_children():
		var result = _find_character_recursive(child)
		if result:
			return result
	
	return null

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_label:
		health_label.text = "Health: %d/%d" % [current_health, max_health]
	
	# Flash red if health decreased
	if current_health < max_health:
		_flash_damage_effect()

func _flash_damage_effect() -> void:
	# Flash red when taking damage
	if damage_flash_rect:
		var tween = create_tween()
		damage_flash_rect.color = Color(1.0, 0.0, 0.0, 0.3)  # Red flash
		tween.tween_property(damage_flash_rect, "color", Color(1.0, 0.0, 0.0, 0.0), 0.5)  # Fade out

func _flash_attack_effect() -> void:
	# Flash white when attacking
	if damage_flash_rect:
		var tween = create_tween()
		damage_flash_rect.color = Color(1.0, 1.0, 1.0, 0.2)  # White flash
		tween.tween_property(damage_flash_rect, "color", Color(1.0, 1.0, 1.0, 0.0), 0.3)  # Fade out

func _show_shop() -> void:
	if shop_panel:
		shop_panel.visible = true

func _close_shop() -> void:
	if shop_panel:
		shop_panel.visible = false

func _buy_power_card() -> void:
	var player_resources = get_node_or_null("/root/PlayerResources")
	if player_resources and player_resources.money >= 50:
		player_resources.money -= 50
		player_resources.physical_damage += 2
		player_resources.resources_changed.emit()
		print("Bought Power Card! Damage increased by 2.")
	else:
		print("Not enough money for Power Card!")

func _buy_health_card() -> void:
	var player_resources = get_node_or_null("/root/PlayerResources")
	var character = _find_character()
	if player_resources and player_resources.money >= 30 and character:
		player_resources.money -= 30
		character.health = min(character.health + 5, character.max_health)
		character.emit_signal("health_changed", character.health, character.max_health)
		player_resources.resources_changed.emit()
		print("Bought Health Card! Restored 5 HP.")
	else:
		print("Not enough money for Health Card!")
