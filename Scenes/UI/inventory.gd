extends Control

@onready var equipped_container = %EquippedGrid
@onready var storage_container = %StorageGrid
@onready var close_button = $CloseInventory

const INVENTORY_SLOT = preload("res://Scenes/UI/inventory_slot.tscn")

func _ready() -> void:
	close_button.pressed.connect(_on_close_inventory)
	for i in InventoryManager.max_equipped_size:
		create_slot("equipped", i)

	for i in InventoryManager.max_inventory:
		create_slot("inventory", i)

func _on_close_inventory():
	get_tree().paused = false
	queue_free()

func create_slot(slot_type, slot_index):
		var inventory_slot = INVENTORY_SLOT.instantiate()
		inventory_slot.slot_type = slot_type
		inventory_slot.slot_index = slot_index
		if slot_type == "equipped":
			equipped_container.add_child(inventory_slot)
		else:
			storage_container.add_child(inventory_slot)
