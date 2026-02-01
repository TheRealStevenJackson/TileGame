extends HBoxContainer

# Drag your Card UI scene (.tscn) here
@export var card_scene: PackedScene
# A list where you can drag and drop your .tres card resources (the deck). If empty, cards are loaded from "card data/" folder.
@export var deck_data: Array[CardData] = []
# Number of cards to draw into the hand when the game starts
@export var hand_size: int = 5

const CARD_DATA_PATH := "res://card data/card_%03d.tres"

func _ready():
	# Clear any placeholder cards in the editor
	for child in get_children():
		child.queue_free()

	draw_hand()

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
		add_child(new_card)
		new_card.data = data
