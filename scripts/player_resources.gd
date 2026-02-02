extends Node
## Autoload: tracks Physical Damage, Money, and Mana. Cards add to these when played.
## Connect to resources_changed to update UI.

signal resources_changed

var physical_damage: int = 0
var money: int = 0
var mana: int = 0
var keys: int = 0

func add_resources(pd: int, m: int, mn: int) -> void:
	physical_damage += pd
	money += m
	mana += mn
	resources_changed.emit()

func reset() -> void:
	physical_damage = 0
	money = 0
	mana = 0
	resources_changed.emit()
