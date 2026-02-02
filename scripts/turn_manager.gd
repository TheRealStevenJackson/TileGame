extends Node

# Turn states
enum TurnState {
	PLAYER_TURN,
	ENEMY_TURN,
	WAITING
}

# Current turn state
var current_state: TurnState = TurnState.PLAYER_TURN

# Track if player has moved this turn
var player_has_moved: bool = false

# Track if player has played a card this turn
var player_has_played_card: bool = false

# Number of extra enemy turns (when player plays a card)
var extra_enemy_turns: int = 0

# Move counter for card draws
var moves_until_card_draw: int = 5
const MOVES_PER_CARD_DRAW = 5
const CARDS_PER_DRAW = 5

# Adjacent enemies available for attack
var adjacent_enemies: Array = []

# Signals
signal player_turn_started
signal enemy_turn_started
signal turn_ended
signal adjacent_enemies_changed(enemies: Array)
signal move_counter_changed(current: int, max: int)

func _ready():
	# Start the game with player turn
	start_player_turn()
	
	# Place random interactive items on the map
	var map = GameMap
	if map and map.has_method("place_random_items"):
		map.place_random_items()

func start_player_turn():
	current_state = TurnState.PLAYER_TURN
	player_has_moved = false
	player_has_played_card = false
	update_adjacent_enemies()
	emit_signal("player_turn_started")
	print("Player turn started")

func update_adjacent_enemies():
	# Update the list of adjacent enemies
	var character = _find_character_in_scene()
	if character and character.current_tile:
		var map = get_node_or_null("/root/GameMap")
		if map:
			adjacent_enemies = map.get_adjacent_enemies(character.current_tile.grid_x, character.current_tile.grid_z)
			emit_signal("adjacent_enemies_changed", adjacent_enemies)

func can_attack_enemy(enemy: Enemy) -> bool:
	# Check if player can attack a specific enemy
	return current_state == TurnState.PLAYER_TURN and adjacent_enemies.has(enemy)

func attack_enemy(enemy: Enemy, damage: int):
	# Attack an enemy with specified damage
	if not can_attack_enemy(enemy):
		print("Cannot attack enemy - not adjacent or not player's turn")
		return
	
	# Calculate actual damage to deal (don't waste damage beyond what's needed)
	var actual_damage = min(damage, enemy.health)
	
	# Spend only the actual damage from player resources
	var player_resources = get_node_or_null("/root/PlayerResources")
	if player_resources and player_resources.physical_damage >= actual_damage:
		player_resources.physical_damage -= actual_damage
		player_resources.resources_changed.emit()
		
		# Deal damage to enemy
		enemy.take_damage(actual_damage)
		
		# Visual feedback for player attacking
		var character = _find_character()
		if character and character.has_method("_flash_attack_effect"):
			character._flash_attack_effect()
		
		print("Player attacked enemy for ", actual_damage, " damage (", damage - actual_damage, " damage wasted)")
		
		# Update adjacent enemies in case enemy died
		update_adjacent_enemies()
	else:
		print("Not enough physical damage to attack")

func _on_enemy_died():
	# Called when an enemy dies - update adjacent enemies
	update_adjacent_enemies()

func draw_cards():
	# Draw 5 more cards
	# Find the card hand by searching the scene tree
	var card_hand = _find_card_hand()
	if card_hand and card_hand.has_method("draw_additional_cards"):
		card_hand.draw_additional_cards(CARDS_PER_DRAW)
		print("Drew ", CARDS_PER_DRAW, " additional cards")
	else:
		print("Could not find card hand to draw cards")

func _find_card_hand() -> HBoxContainer:
	# Search for the card hand HBoxContainer in the scene
	var root = get_tree().root
	return _find_card_hand_recursive(root)

func _find_card_hand_recursive(node: Node) -> HBoxContainer:
	# Recursively search for HBoxContainer with Card_Hand_Container script
	if node is HBoxContainer and node.get_script() and node.get_script().resource_path.ends_with("Card_Hand_Container.gd"):
		return node as HBoxContainer
	
	for child in node.get_children():
		var result = _find_card_hand_recursive(child)
		if result:
			return result
	
	return null

func _find_character_in_scene() -> Character:
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

func start_enemy_turn():
	current_state = TurnState.ENEMY_TURN
	emit_signal("enemy_turn_started")
	print("Enemy turn started")

func end_player_turn():
	if current_state != TurnState.PLAYER_TURN:
		return
	
	current_state = TurnState.WAITING
	
	# If player played a card, give enemies an extra turn
	if player_has_played_card:
		extra_enemy_turns += 1
		print("Player played a card - enemies get an extra turn")
	
	# Start enemy turn
	start_enemy_turn()
	
	# Perform enemy turns
	await perform_enemy_turns()
	
	# If there are extra enemy turns, do them
	while extra_enemy_turns > 0:
		extra_enemy_turns -= 1
		print("Extra enemy turn")
		await perform_enemy_turns()
	
	# Start next player turn
	start_player_turn()

func player_moved():
	if current_state == TurnState.PLAYER_TURN:
		player_has_moved = true
		update_adjacent_enemies()
		
		# Decrement move counter
		moves_until_card_draw -= 1
		emit_signal("move_counter_changed", moves_until_card_draw, MOVES_PER_CARD_DRAW)
		
		# Check if it's time to draw cards
		if moves_until_card_draw <= 0:
			draw_cards()
			moves_until_card_draw = MOVES_PER_CARD_DRAW
			emit_signal("move_counter_changed", moves_until_card_draw, MOVES_PER_CARD_DRAW)
		
		# Player can still play a card after moving, or end turn
		print("Player moved")

func player_played_card():
	if current_state == TurnState.PLAYER_TURN:
		player_has_played_card = true
		# Could end turn immediately or allow more actions
		print("Player played a card")

func can_player_move() -> bool:
	return current_state == TurnState.PLAYER_TURN and not player_has_moved and not player_has_played_card

func can_player_play_card() -> bool:
	return current_state == TurnState.PLAYER_TURN and not player_has_moved

func perform_enemy_turns():
	# Get the map singleton
	var map = GameMap
	if map:
		await map.perform_enemy_turns()
	
	emit_signal("turn_ended")

func _find_character() -> Character:
	# Find the Character node in the scene tree
	var root = get_tree().root
	return _find_character_recursive(root)
