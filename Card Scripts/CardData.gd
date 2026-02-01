extends Resource
class_name CardData

enum ResourceType {
	PHYSICAL_DAMAGE,
	MONEY,
	MANA
}

@export var title: String = ""
@export_multiline var description: String = ""
@export var image: Texture2D
@export var cost: int = 0
@export var physical_damage_gen: int = 0
@export var money_gen: int = 0
@export var mana_gen: int = 0
