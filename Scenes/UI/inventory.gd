extends Control

@onready var equipped_container = %EquippedGrid
@onready var storage_container = %StorageGrid
@onready var close_button = $CloseInventory
@onready var bottle_details_panel = %BottleDetailsPanel

const INVENTORY_SLOT = preload("res://Scenes/UI/inventory_slot.tscn")

var current_selected_slot: InventorySlot = null

func _ready() -> void:
	close_button.pressed.connect(_on_close_inventory)

	# Create equipped slots
	for i in InventoryManager.max_equipped_size:
		create_slot("equipped", i)

	# Create storage slots
	for i in InventoryManager.max_inventory:
		create_slot("inventory", i)

func _on_close_inventory():
	get_tree().paused = false
	queue_free()

func create_slot(slot_type, slot_index):
	var inventory_slot = INVENTORY_SLOT.instantiate()
	inventory_slot.slot_type = slot_type
	inventory_slot.slot_index = slot_index

	# Connect to the slot selection signal
	inventory_slot.slot_selected.connect(_on_slot_selected)

	# Connect to drag started signal to clear selection
	inventory_slot.slot_drag_started.connect(_on_slot_drag_started)

	if slot_type == "equipped":
		equipped_container.add_child(inventory_slot)
	else:
		storage_container.add_child(inventory_slot)

func _on_slot_selected(slot: InventorySlot):
	#print("Slot selected: ", slot.slot_type, " index: ", slot.slot_index)

	# Deselect previously selected slot
	if current_selected_slot != null:
		current_selected_slot.set_selected(false)

	# Select new slot
	current_selected_slot = slot
	slot.set_selected(true)

	# Show bottle details if slot has a bottle
	if slot.sauce_bottle != null:
		bottle_details_panel.show_bottle_details(slot.sauce_bottle)
	else:
		bottle_details_panel.hide_details()

func _on_slot_drag_started(slot: InventorySlot):
	#print("Drag started, clearing selection")

	# Clear selection when drag starts
	if current_selected_slot != null:
		current_selected_slot.set_selected(false)
		current_selected_slot = null

	# Hide bottle details panel
	bottle_details_panel.hide_details()
