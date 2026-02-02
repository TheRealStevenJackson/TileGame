extends HBoxContainer

# Drag your Card_Template scene (.tscn) here
@export var card_scene: PackedScene
# A list where you can drag and drop your .tres card resources (the deck). If empty, cards are loaded from "card data/" folder.
@export var deck_data: Array[CardData] = []
# Number of cards to draw into the hand when the game starts
@export var hand_size: int = 5

const CARD_DATA_PATH := "res://card data/card_%03d.tres"

func _ready() -> void:
	# Clear any placeholder cards in the editor
	for child in get_children():
		child.queue_free()
	# Defer so layout is ready when under a 3D viewport
	call_deferred("draw_hand")

func _get_deck() -> Array[CardData]:
	if not deck_data.is_empty():
		return deck_data
	# Fallback: load cards from card data folder
	var loaded: Array[CardData] = []
	for i in range(1, 101):
		var path := CARD_DATA_PATH % i
		if ResourceLoader.exists(path):
			var res = load(path) as CardData
			if res:
				loaded.append(res)
	return loaded

func draw_hand():
	var deck := _get_deck()
	if deck.is_empty():
		push_warning("CardHand: No deck_data assigned and no cards found in res://card data/")
		return
	if not card_scene:
		push_warning("CardHand: No card_scene assigned.")
		return

	# Build a shuffled list and draw up to hand_size cards
	deck = deck.duplicate()
	deck.shuffle()

	var to_draw := mini(hand_size, deck.size())
	for i in range(to_draw):
		var data: CardData = deck[i]
		var new_card = card_scene.instantiate()
		# CardLoader with .data may be on root (Card_Template) or on child MarginContainer (Card_Template)
		var card_ui := _get_card_ui_node(new_card)
		if card_ui:
			card_ui.data = data
		# HBoxContainer only lays out Control children; if root is Node2D, add the Control (card_ui) instead
		var to_add: Node = new_card
		if not (new_card is Control) and card_ui is Control:
			new_card.remove_child(card_ui)
			new_card.queue_free()
			to_add = card_ui
		add_child(to_add)
		to_add.size_flags_horizontal = 0
		if card_ui and card_ui.has_signal("card_played"):
			card_ui.card_played.connect(_on_card_played.bind(to_add))

func _get_card_ui_node(card_instance: Node) -> Node:
	# Card_Template root is Node2D, child is MarginContainer
	if "data" in card_instance:
		return card_instance
	var margin := card_instance.get_node_or_null("MarginContainer")
	if margin and "data" in margin:
		return margin
	for child in card_instance.get_children():
		if "data" in child:
			return child
	return null

func _on_card_played(_card_data: CardData, card_node: Node) -> void:
	if is_instance_valid(card_node) and card_node.get_parent() == self:
		remove_child(card_node)
		card_node.queue_free()

func draw_additional_cards(count: int):
	# Draw additional cards to the existing hand
	var deck := _get_deck()
	if deck.is_empty():
		push_warning("CardHand: No deck_data assigned and no cards found in res://card data/")
		return
	if not card_scene:
		push_warning("CardHand: No card_scene assigned.")
		return

	# Build a shuffled list and draw up to count cards
	deck = deck.duplicate()
	deck.shuffle()

	var to_draw := mini(count, deck.size())
	for i in range(to_draw):
		var data: CardData = deck[i]
		var new_card = card_scene.instantiate()
		# CardLoader with .data may be on root (Card_Template) or on child MarginContainer (Card_Template)
		var card_ui := _get_card_ui_node(new_card)
		if card_ui:
			card_ui.data = data
		# HBoxContainer only lays out Control children; if root is Node2D, add the Control (card_ui) instead
		var to_add: Node = new_card
		if not (new_card is Control) and card_ui is Control:
			new_card.remove_child(card_ui)
			new_card.queue_free()
			to_add = card_ui
		add_child(to_add)
		to_add.size_flags_horizontal = 0
		if card_ui and card_ui.has_signal("card_played"):
			card_ui.card_played.connect(_on_card_played.bind(to_add))
