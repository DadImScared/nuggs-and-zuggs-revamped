extends VBoxContainer

signal card_selected(sauce: BaseSauceResource)
@export var sauce_data: BaseSauceResource

@onready var icon_texture = $Icon
@onready var name_label = $Name
@onready var description_label = $Description
@onready var choose_button = $Choose

func _ready() -> void:
	#choose_button.pressed.connect(_on_sauce_selected)
	update_visuals()

func _on_sauce_selected():
	pass
	##print("sauce selectedd in card")
	#card_selected.emit(sauce_data)

func update_visuals(p_sauce_data = null):
	if p_sauce_data:
		sauce_data = p_sauce_data
	name_label.text = sauce_data.sauce_name
	description_label.text = sauce_data.description
	icon_texture.modulate = sauce_data.sauce_color
