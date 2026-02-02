extends Control
## Shows current Physical Damage, Money, and Mana in the upper right.
## Expects child nodes: PDValue, MoneyValue, ManaValue (Labels).

@onready var pd_label: Label = get_node_or_null("HBox/PDRow/PDValue")
@onready var money_label: Label = get_node_or_null("HBox/MoneyRow/MoneyValue")
@onready var mana_label: Label = get_node_or_null("HBox/ManaRow/ManaValue")
@onready var keys_label: Label = get_node_or_null("HBox/KeysRow/KeysValue")

func _ready() -> void:
	_update_labels()
	var pr = get_node_or_null("/root/PlayerResources")
	if pr and pr.has_signal("resources_changed"):
		pr.resources_changed.connect(_update_labels)

func _update_labels() -> void:
	var pr = get_node_or_null("/root/PlayerResources")
	if not pr:
		return
	if pd_label:
		pd_label.text = str(pr.physical_damage)
	if money_label:
		money_label.text = str(pr.money)
	if mana_label:
		mana_label.text = str(pr.mana)
	if keys_label:
		keys_label.text = str(pr.keys)
