# Scenes/UI/level_up.gd
extends Control

signal sauce_selected(sauce_data: BaseSauceResource)

const SAUCE_CARD = preload("res://Scenes/UI/sauce_card.tscn")
@onready var sauce_selection = %SauceSelection

func _ready() -> void:
	generate_cards()

func generate_cards():
	# UPDATED: Use static SauceDatabase instead of SauceManager singleton
	var sauces = SauceDatabase.get_random_sauces(3)
	for sauce in sauces:
		var sauce_card = SAUCE_CARD.instantiate()
		sauce_selection.add_child(sauce_card)
		sauce_card.update_visuals(sauce)
		sauce_card.choose_button.pressed.connect(_on_sauce_selected.bind(sauce))

func _on_sauce_selected(sauce: BaseSauceResource):
	InventoryManager.select_sauce(sauce)
	get_tree().paused = false
	queue_free()
